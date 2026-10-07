import logging
import os

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.core.cache import cache
from django.db import models
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated
from rest_framework.response import Response
from rest_framework.throttling import ScopedRateThrottle
from rest_framework.views import APIView

from .email_service import EMAIL_REGEX, send_login_notification_email, send_welcome_email
from .models import AbuseEvent, UserBookmark, UserProfile
from .serializers import LoginSerializer, SignupSerializer, UserSerializer

logger = logging.getLogger(__name__)

LOCKOUT_THRESHOLD = 5
LOCKOUT_WINDOW_SECONDS = 15 * 60


def _client_ip(request):
    # Behind the Cloudflare tunnel, every request's REMOTE_ADDR is the tunnel's
    # local loopback connection, not the real client — use Cloudflare's header instead.
    cf_ip = request.META.get("HTTP_CF_CONNECTING_IP")
    if cf_ip:
        return cf_ip
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.META.get("REMOTE_ADDR", "unknown")


class SignupView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = SignupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        token, _ = Token.objects.get_or_create(user=user)

        email_sent = False
        email_error = None
        try:
            result = send_welcome_email(user=user)
            if isinstance(result, tuple):
                email_sent = bool(result[0])
                email_error = result[1]
            else:
                email_sent = bool(result)
                email_error = None if email_sent else "Email delivery service unavailable."
        except Exception as exc:
            logger.error("Failed to dispatch welcome email for user %s: %s", user.username, exc)
            email_sent = False
            email_error = "Unable to dispatch welcome email at this time."

        response_payload = {
            "success": True,
            "message": "Account created successfully.",
            "emailSent": bool(email_sent),
            "email_sent": bool(email_sent),
            "emailError": None if email_sent else (str(email_error) if email_error else "Unable to send welcome email."),
            "email_error": None if email_sent else (str(email_error) if email_error else "Unable to send welcome email."),
            "token": token.key,
            "user": UserSerializer(user).data,
        }

        return Response(response_payload, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        username = serializer.validated_data["username"].strip()
        password = serializer.validated_data["password"]

        try:
            matched_user = User.objects.get(username__iexact=username)
            username = matched_user.username
        except User.DoesNotExist:
            pass

        lockout_key = f"login_fail:{username.lower()}:{_client_ip(request)}"
        if cache.get(lockout_key, 0) >= LOCKOUT_THRESHOLD:
            return Response(
                {"detail": "Too many failed attempts. Try again in a few minutes."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        user = authenticate(request, username=username, password=password)
        if user is None:
            try:
                new_count = cache.incr(lockout_key)
            except ValueError:
                cache.set(lockout_key, 1, LOCKOUT_WINDOW_SECONDS)
                new_count = 1
            if new_count >= LOCKOUT_THRESHOLD:
                AbuseEvent.objects.create(category="auth_abuse")
            return Response(
                {"detail": "Invalid username or password."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        cache.delete(lockout_key)
        now = timezone.now()
        profile, _ = UserProfile.objects.get_or_create(
            user=user,
            defaults={"role": "ADMIN" if (user.is_staff or user.is_superuser) else "USER"},
        )
        profile.last_login_at = now
        profile.last_active_at = now
        profile.save(update_fields=["last_login_at", "last_active_at"])

        token, _ = Token.objects.get_or_create(user=user)

        # Dispatch login notification email safely without failing login if email provider is down
        try:
            send_login_notification_email(user=user)
        except Exception as exc:
            logger.error("Failed to dispatch login notification email for user %s: %s", user.username, exc)

        return Response({"token": token.key, "user": UserSerializer(user).data})


class LogoutView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        Token.objects.filter(user=request.user).delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(
            user=request.user,
            defaults={"role": "ADMIN" if (request.user.is_staff or request.user.is_superuser) else "USER"},
        )
        profile.last_active_at = timezone.now()
        profile.save(update_fields=["last_active_at"])
        return Response(UserSerializer(request.user).data)


class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]
    throttle_classes = [ScopedRateThrottle]
    throttle_scope = "auth"

    def post(self, request):
        username = request.data.get("username", "").strip()
        email = request.data.get("email", "").strip().lower()
        new_password = request.data.get("new_password", "")

        if not username or not email or not new_password:
            return Response(
                {"detail": "Username, email, and new password are all required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if len(new_password) < 8:
            return Response(
                {"detail": "Password must be at least 8 characters long."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            user = User.objects.get(username__iexact=username, email__iexact=email)
        except User.DoesNotExist:
            return Response(
                {"detail": "No account found matching this username and email."},
                status=status.HTTP_404_NOT_FOUND,
            )

        user.set_password(new_password)
        user.save()
        Token.objects.filter(user=user).delete()
        token = Token.objects.create(user=user)

        return Response(
            {
                "detail": "Password reset successfully. You can now log in with your new password.",
                "token": token.key,
                "user": UserSerializer(user).data,
            },
            status=status.HTTP_200_OK,
        )


class BookmarkSyncView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        section_ids = list(
            UserBookmark.objects.filter(user=request.user).values_list("section_id", flat=True)
        )
        return Response({"section_ids": section_ids}, status=status.HTTP_200_OK)

    def post(self, request):
        incoming_ids = request.data.get("section_ids", [])
        if not isinstance(incoming_ids, list):
            return Response(
                {"error": "section_ids must be a list of integers"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        existing_ids = set(
            UserBookmark.objects.filter(user=request.user).values_list("section_id", flat=True)
        )
        incoming_set = {int(x) for x in incoming_ids if str(x).isdigit() or isinstance(x, int)}

        new_ids = incoming_set - existing_ids
        for sid in new_ids:
            UserBookmark.objects.create(user=request.user, section_id=sid)

        unified_ids = sorted(list(existing_ids | incoming_set))
        return Response({"section_ids": unified_ids}, status=status.HTTP_200_OK)


class SavedItemView(APIView):
    """
    Dedicated account-specific Saved Items API.
    All operations are strictly scoped to the authenticated user ID (request.user).
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        """
        Returns only the saved items belonging to the authenticated user.
        Conceptually: WHERE user_id = authenticated_user_id
        """
        bookmarks = UserBookmark.objects.filter(user=request.user).order_by("-created_at")
        saved_items = [
            {
                "id": b.id,
                "userId": b.user_id,
                "legalItemId": b.section_id,
                "section_id": b.section_id,
                "createdAt": b.created_at.isoformat(),
            }
            for b in bookmarks
        ]
        section_ids = [b.section_id for b in bookmarks]
        return Response(
            {
                "success": True,
                "count": len(saved_items),
                "saved": saved_items,
                "section_ids": section_ids,
            },
            status=status.HTTP_200_OK,
        )

    def post(self, request):
        """
        Associate the record with the authenticated user automatically.
        Never trust arbitrary client userId.
        """
        target_id = request.data.get("section_id") or request.data.get("legalItemId") or request.data.get("id")
        if target_id is not None:
            try:
                sid = int(target_id)
            except (ValueError, TypeError):
                return Response({"error": "Invalid section_id"}, status=status.HTTP_400_BAD_REQUEST)

            bookmark, created = UserBookmark.objects.get_or_create(
                user=request.user, section_id=sid
            )
            return Response(
                {
                    "success": True,
                    "created": created,
                    "saved": {
                        "id": bookmark.id,
                        "userId": bookmark.user_id,
                        "legalItemId": bookmark.section_id,
                        "section_id": bookmark.section_id,
                        "createdAt": bookmark.created_at.isoformat(),
                    },
                },
                status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
            )

        section_ids = request.data.get("section_ids")
        if isinstance(section_ids, list):
            valid_ids = []
            for s in section_ids:
                try:
                    valid_ids.append(int(s))
                except (ValueError, TypeError):
                    continue

            action = request.data.get("action", "merge")
            if action == "replace":
                UserBookmark.objects.filter(user=request.user).exclude(section_id__in=valid_ids).delete()

            for sid in valid_ids:
                UserBookmark.objects.get_or_create(user=request.user, section_id=sid)

            current_ids = list(
                UserBookmark.objects.filter(user=request.user).order_by("section_id").values_list("section_id", flat=True)
            )
            return Response({"success": True, "section_ids": current_ids}, status=status.HTTP_200_OK)

        return Response({"error": "section_id is required"}, status=status.HTTP_400_BAD_REQUEST)

    def delete(self, request, item_id=None):
        """
        Verify that the saved record belongs to the authenticated user before deleting it.
        A user can never delete another user's saved records.
        """
        target = item_id or request.data.get("section_id") or request.data.get("legalItemId") or request.data.get("id")
        if target is None:
            return Response({"error": "section_id or id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            tid = int(target)
        except (ValueError, TypeError):
            return Response({"error": "Invalid id"}, status=status.HTTP_400_BAD_REQUEST)

        deleted_count, _ = (
            UserBookmark.objects.filter(user=request.user)
            .filter(models.Q(id=tid) | models.Q(section_id=tid))
            .delete()
        )

        if deleted_count == 0:
            return Response(
                {"error": "Saved item not found or does not belong to your account."},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(
            {"success": True, "message": "Saved item removed successfully."},
            status=status.HTTP_200_OK,
        )


class AdminEmailTestView(APIView):
    """
    Controlled diagnostic endpoint for verifying Brevo / transactional email delivery
    directly from the production backend without creating database users.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        target_email = request.data.get("email", "").strip().lower()
        if not target_email or not EMAIL_REGEX.match(target_email):
            return Response({"error": "A valid target email address is required."}, status=status.HTTP_400_BAD_REQUEST)

        from .email_service import build_welcome_html, build_welcome_text, _dispatch_payload
        text_content = build_welcome_text("LegalGuide Tester", target_email)
        html_content = build_welcome_html("LegalGuide Tester", target_email)

        result = _dispatch_payload(
            target_email,
            "LegalGuide Tester",
            "Welcome to LegalGuide",
            text_content,
            html_content,
        )

        return Response({
            "success": result.success,
            "emailSent": result.success,
            "email_sent": result.success,
            "emailError": result.error,
            "email_error": result.error,
            "messageId": getattr(result, "message_id", None),
            "provider": os.environ.get("EMAIL_PROVIDER", "").strip().lower(),
            "from_email": os.environ.get("EMAIL_FROM", "").strip(),
            "from_name": os.environ.get("EMAIL_FROM_NAME", "").strip(),
        }, status=status.HTTP_200_OK)


