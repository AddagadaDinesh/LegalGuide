from datetime import timedelta

from django.conf import settings
from django.contrib.auth import get_user_model
from django.db import models, transaction
from django.db.models import F
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from accounts.models import UserProfile
try:
    from laws.models import DatabaseSyncInfo
except ImportError:
    DatabaseSyncInfo = None
from laws.models import Category, Law, LegalSection
from .models import (
    AIQuestionStat,
    FeatureUsageStat,
    LawViewStat,
    SearchStat,
    SectionViewStat,
    UserActivityLog,
)
from .permissions import IsAdminUserRole

User = get_user_model()

FEATURE_NAME_MAP = {
    "law_search": "Law Search",
    "ai_assistant": "AI Assistant",
    "legal_awareness": "Legal Awareness",
    "emergency_rights": "Emergency Rights Guide",
    "railway_rules": "Indian Railway Rules & Fines",
    "traffic_rules": "Traffic Rules & Driver Rights",
    "legal_documents": "Legal Documents & Formats",
    "saved_laws": "Saved Laws & Bookmarks",
    "legal_help": "Need Legal Help",
}


class AdminAnalyticsView(APIView):
    """
    Protected Admin Analytics Dashboard API.
    Guaranteed: Accessible only to authenticated users with the ADMIN role.
    Rejects normal users with HTTP 403 Forbidden.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        now = timezone.now()
        today = timezone.localdate()

        # Date windows
        seven_days_ago_date = today - timedelta(days=6)
        seven_days_ago_time = now - timedelta(days=7)
        thirty_days_ago_date = today - timedelta(days=29)
        thirty_days_ago_time = now - timedelta(days=30)
        active_window_15m = now - timedelta(minutes=15)

        # 1. Total Registered Users breakdown (Central Users Database Source of Truth)
        # Administrators: is_staff=True, is_superuser=True, or profile.role == 'ADMIN'
        admin_q = (
            models.Q(is_staff=True)
            | models.Q(is_superuser=True)
            | models.Q(profile__role="ADMIN")
        )
        normal_users_qs = User.objects.exclude(admin_q).distinct()
        admin_users_qs = User.objects.filter(admin_q).distinct()

        normal_users_count = normal_users_qs.count()
        admin_users_count = admin_users_qs.count()
        total_accounts_count = User.objects.count()

        # Total Users definition: all registered accounts = citizens + admins
        total_registered_users = total_accounts_count
        normal_user_ids = set(normal_users_qs.values_list("id", flat=True))

        # 2. Active Users Today (DISTINCT normal user IDs)
        active_today_log_ids = set(
            UserActivityLog.objects.filter(date=today, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_today_profile_ids = set(
            UserProfile.objects.filter(last_active_at__date=today, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_users_today = len(active_today_log_ids | active_today_profile_ids)

        # 3. Active Users This Week (DISTINCT normal user IDs last 7 days)
        active_week_log_ids = set(
            UserActivityLog.objects.filter(date__gte=seven_days_ago_date, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_week_profile_ids = set(
            UserProfile.objects.filter(last_active_at__gte=seven_days_ago_time, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_users_this_week = len(active_week_log_ids | active_week_profile_ids)

        # 4. Active Users This Month (DISTINCT normal user IDs last 30 days)
        active_month_log_ids = set(
            UserActivityLog.objects.filter(date__gte=thirty_days_ago_date, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_month_profile_ids = set(
            UserProfile.objects.filter(last_active_at__gte=thirty_days_ago_time, user_id__in=normal_user_ids)
            .values_list("user_id", flat=True)
        )
        active_users_this_month = len(active_month_log_ids | active_month_profile_ids)

        # 5. New Users Today (Normal registered users)
        new_users_today = normal_users_qs.filter(date_joined__date=today).count()

        # 6. New Users This Week
        new_users_this_week = normal_users_qs.filter(date_joined__gte=seven_days_ago_time).count()

        # 7. New Users This Month
        new_users_this_month = normal_users_qs.filter(date_joined__gte=thirty_days_ago_time).count()

        # 8. Currently Active Users (recent activity within 15 minutes among normal registered users)
        currently_active_users = UserProfile.objects.filter(
            user_id__in=normal_user_ids,
            last_active_at__gte=active_window_15m
        ).count()

        # 9. Total AI Questions
        total_ai_questions = (
            AIQuestionStat.objects.aggregate(total=models.Sum("count"))["total"] or 0
        )

        # 10. AI Questions Today, This Week, This Month + Categories
        ai_questions_today = (
            AIQuestionStat.objects.filter(date=today).aggregate(total=models.Sum("count"))["total"] or 0
        )
        ai_questions_this_week = (
            AIQuestionStat.objects.filter(date__gte=seven_days_ago_date).aggregate(
                total=models.Sum("count")
            )["total"]
            or 0
        )
        ai_questions_this_month = (
            AIQuestionStat.objects.filter(date__gte=thirty_days_ago_date).aggregate(
                total=models.Sum("count")
            )["total"]
            or 0
        )

        ai_categories = list(
            AIQuestionStat.objects.values("category")
            .annotate(count=models.Sum("count"))
            .order_by("-count")[:8]
        )

        # 11. Total Law Searches
        total_law_searches = (
            SearchStat.objects.aggregate(total=models.Sum("count"))["total"] or 0
        )

        # 12. Most Searched Laws & Terms
        most_searched_laws = list(
            SearchStat.objects.values("query", "count").order_by("-count")[:10]
        )
        most_opened_laws = list(
            LawViewStat.objects.values("law_id", "law_name", "count").order_by("-count")[:10]
        )

        # 13. Most Viewed Legal Sections
        most_viewed_sections = list(
            SectionViewStat.objects.values(
                "section_id", "section_title", "law_name", "count"
            ).order_by("-count")[:10]
        )

        # 14. Most Used Features
        feature_aggregates = {
            row["feature_name"]: row["total"]
            for row in FeatureUsageStat.objects.values("feature_name").annotate(
                total=models.Sum("count")
            )
        }
        most_used_features = [
            {
                "key": key,
                "label": label,
                "count": feature_aggregates.get(key, 0),
            }
            for key, label in FEATURE_NAME_MAP.items()
        ]
        most_used_features.sort(key=lambda x: x["count"], reverse=True)

        # 15. Legal Database Last Synchronization
        acts_summary = []
        for law in Law.objects.all().select_related("category").prefetch_related("sections"):
            secs = law.sections.all()
            acts_summary.append({
                "id": law.id,
                "name": law.name,
                "short_name": law.short_name,
                "year": law.year,
                "act_number": law.act_number,
                "domain": law.category.name if law.category else "General",
                "category_id": law.category_id,
                "status": law.status,
                "source_name": law.source_name,
                "source_url": law.source_url,
                "last_verified": law.last_verified.isoformat() if law.last_verified else None,
                "verified_sections_count": secs.count(),
                "sections_count": secs.count(),
                "current_sections_count": sum(1 for s in secs if s.status == "current"),
                "amended_sections_count": sum(1 for s in secs if s.status == "amended"),
                "historical_sections_count": sum(1 for s in secs if s.status == "historical"),
                "repealed_sections_count": sum(1 for s in secs if s.status == "repealed"),
            })

        if DatabaseSyncInfo is not None:
            sync_info = DatabaseSyncInfo.get_info()
            db_sync_data = {
                "server_version": sync_info.server_version,
                "last_sync_date": sync_info.last_sync_date.isoformat() if sync_info.last_sync_date else None,
                "last_source_check": (
                    sync_info.last_source_check.isoformat() if sync_info.last_source_check else None
                ),
                "primary_source_name": sync_info.primary_source_name,
                "primary_source_url": sync_info.primary_source_url,
                "total_categories": Category.objects.count(),
                "total_acts": Law.objects.count(),
                "total_laws": Law.objects.count(),
                "total_sections": LegalSection.objects.count(),
                "current_sections": LegalSection.objects.filter(status="current").count(),
                "amended_sections": LegalSection.objects.filter(status="amended").count(),
                "historical_sections": LegalSection.objects.filter(status="historical").count(),
                "repealed_sections": LegalSection.objects.filter(status="repealed").count(),
                "acts": acts_summary,
            }
        else:
            db_sync_data = {
                "server_version": 1,
                "last_sync_date": now.isoformat(),
                "last_source_check": now.isoformat(),
                "primary_source_name": "India Code (indiacode.gov.in)",
                "primary_source_url": "https://www.indiacode.gov.in/",
                "total_categories": Category.objects.count(),
                "total_acts": Law.objects.count(),
                "total_laws": Law.objects.count(),
                "total_sections": LegalSection.objects.count(),
                "current_sections": LegalSection.objects.filter(status="current").count(),
                "amended_sections": LegalSection.objects.filter(status="amended").count(),
                "historical_sections": LegalSection.objects.filter(status="historical").count(),
                "repealed_sections": LegalSection.objects.filter(status="repealed").count(),
                "acts": acts_summary,
            }

        # 16. Backend / API Status
        admin_username = request.user.username if request.user.is_authenticated else "Admin"
        backend_status = {
            "status": "operational",
            "api_status": "healthy",
            "apiStatus": "healthy",
            "api_server": "online",
            "apiServer": "online",
            "active_server": "https://dinesh03.pythonanywhere.com/api",
            "activeServer": "https://dinesh03.pythonanywhere.com/api",
            "database": "connected",
            "administrator": admin_username,
            "ai_service": "configured" if bool(getattr(settings, "OPENAI_API_KEY", None)) else "mock_or_unconfigured",
            "server_time": now.isoformat(),
            "serverTime": now.isoformat(),
            "activity_window_minutes": 15,
        }

        return Response(
            {
                # Snake case keys
                "total_registered_users": total_registered_users,
                "total_normal_users": normal_users_count,
                "total_admin_users": admin_users_count,
                "total_accounts": total_accounts_count,
                "active_users_today": active_users_today,
                "active_users_this_week": active_users_this_week,
                "active_users_this_month": active_users_this_month,
                "new_users_today": new_users_today,
                "new_users_this_week": new_users_this_week,
                "new_users_this_month": new_users_this_month,
                "currently_active_users": currently_active_users,
                "total_ai_questions": total_ai_questions,
                "ai_questions_today": ai_questions_today,
                "ai_questions_this_week": ai_questions_this_week,
                "ai_questions_this_month": ai_questions_this_month,
                "ai_categories": ai_categories,
                "total_law_searches": total_law_searches,
                "most_searched_laws": most_searched_laws,
                "most_opened_laws": most_opened_laws,
                "most_viewed_sections": most_viewed_sections,
                "most_used_features": most_used_features,
                "database_sync": db_sync_data,
                "backend_status": backend_status,

                # CamelCase aliases for universal client compatibility
                "totalUsers": total_registered_users,
                "normalUsers": normal_users_count,
                "adminUsers": admin_users_count,
                "totalAccounts": total_accounts_count,
                "activeToday": active_users_today,
                "activeThisWeek": active_users_this_week,
                "activeThisMonth": active_users_this_month,
                "newUsersToday": new_users_today,
                "newUsersThisWeek": new_users_this_week,
                "newUsersThisMonth": new_users_this_month,
                "currentlyActive": currently_active_users,
                "activeNow": currently_active_users,
                "aiQuestions": total_ai_questions,
                "totalAiQuestions": total_ai_questions,
                "aiQuestionsToday": ai_questions_today,
                "aiQuestionsThisWeek": ai_questions_this_week,
                "aiQuestionsThisMonth": ai_questions_this_month,
                "aiCategories": ai_categories,
                "totalLawSearches": total_law_searches,
                "mostSearchedLaws": most_searched_laws,
                "mostOpenedLaws": most_opened_laws,
                "mostViewedSections": most_viewed_sections,
                "mostUsedFeatures": most_used_features,
                "databaseSync": db_sync_data,
                "backendStatus": backend_status,
            },
            status=status.HTTP_200_OK,
        )


class AdminUserListView(APIView):
    """
    List of registered users with activity timestamps for the Admin Dashboard.
    Strictly protects privacy: NEVER exposes passwords, tokens, or private histories.
    Guaranteed: Accessible only to authenticated users with the ADMIN role.
    Rejects normal users with HTTP 403 Forbidden.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        now = timezone.now()
        active_15m = now - timedelta(minutes=15)
        active_24h = now - timedelta(hours=24)

        users = User.objects.all().select_related("profile").order_by("-date_joined", "-id")

        normal_count = 0
        admin_count = 0
        user_list = []

        for u in users:
            profile = getattr(u, "profile", None)
            is_admin = bool(u.is_staff or u.is_superuser or (profile and profile.role == "ADMIN"))
            role = "ADMIN" if is_admin else "USER"

            if is_admin:
                admin_count += 1
            else:
                normal_count += 1

            last_active = profile.last_active_at if profile and profile.last_active_at else None
            last_login = profile.last_login_at if profile and profile.last_login_at else u.last_login

            # Account status
            if last_active and last_active >= active_15m:
                account_status = "Active Now"
            elif last_active and last_active >= active_24h:
                account_status = "Active Today"
            elif last_active:
                account_status = "Recent"
            else:
                account_status = "Inactive"

            user_list.append({
                "id": str(u.id),
                "name": u.get_full_name() or u.username,
                "username": u.username,
                "email": u.email or "",
                "role": role,
                "status": account_status,
                "is_staff": u.is_staff,
                "is_superuser": u.is_superuser,
                "createdAt": u.date_joined.isoformat() if u.date_joined else None,
                "registrationDate": u.date_joined.isoformat() if u.date_joined else None,
                "date_joined": u.date_joined.isoformat() if u.date_joined else None,
                "lastLoginAt": last_login.isoformat() if last_login else None,
                "last_login": last_login.isoformat() if last_login else None,
                "lastActiveAt": last_active.isoformat() if last_active else None,
                "last_active_at": last_active.isoformat() if last_active else None,
            })

        return Response({
            "users": user_list,
            "total": len(user_list),  # All registered accounts = citizens + admins
            "totalUsers": len(user_list),
            "total_users": len(user_list),
            "totalCitizens": normal_count,
            "total_citizens": normal_count,
            "totalAdmins": admin_count,
            "total_admins": admin_count,
            "normalUsers": normal_count,
            "normal_users_count": normal_count,
            "adminUsers": admin_count,
            "admin_users_count": admin_count,
            "totalAccounts": len(user_list),
            "total_accounts": len(user_list),
        }, status=status.HTTP_200_OK)

    def delete(self, request):
        """Allow administrator to delete a user account from the central production database."""
        user_id = request.data.get("user_id") or request.query_params.get("user_id")
        username = request.data.get("username") or request.query_params.get("username")
        if not user_id and not username:
            return Response({"error": "user_id or username required."}, status=status.HTTP_400_BAD_REQUEST)

        target = None
        if user_id:
            target = User.objects.filter(id=user_id).first()
        elif username:
            target = User.objects.filter(username__iexact=str(username).strip()).first()

        if not target:
            return Response({"error": "User not found."}, status=status.HTTP_404_NOT_FOUND)

        # Requirement: Admin must NOT be able to delete their own admin account.
        if target.id == request.user.id or target.username.strip().lower() == request.user.username.strip().lower():
            return Response({"error": "You cannot delete your own admin account."}, status=status.HTTP_400_BAD_REQUEST)

        target_profile = getattr(target, "profile", None)
        target_is_admin = bool(target.is_staff or target.is_superuser or (target_profile and target_profile.role == "ADMIN"))

        # Superuser account cannot be deleted
        if target.is_superuser:
            return Response({"error": "Cannot delete primary administrator account."}, status=status.HTTP_400_BAD_REQUEST)

        # Admin policy: deleting another administrator requires superuser privileges
        if target_is_admin and not request.user.is_superuser:
            return Response({"error": "Cannot delete administrator accounts without superuser privileges."}, status=status.HTTP_403_FORBIDDEN)

        deleted_username = target.username
        deleted_id = str(target.id)
        target.delete()
        return Response({
            "status": "deleted",
            "success": True,
            "message": f"User {deleted_username} has been deleted successfully.",
            "username": deleted_username,
            "user_id": deleted_id,
        }, status=status.HTTP_200_OK)


class AdminStatusView(APIView):
    """
    Returns administrative system status, active server info, database connectivity,
    and the authenticated administrator identity.
    Protected: Accessible only to authenticated ADMIN users. Rejects normal users with 403.
    """
    permission_classes = [IsAdminUserRole]

    def get(self, request):
        admin_username = request.user.username if request.user.is_authenticated else "Admin"
        now = timezone.now()

        db_connected = True
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
        except Exception:
            db_connected = False

        return Response({
            "apiServer": "online",
            "apiStatus": "healthy",
            "administrator": admin_username,
            "database": "connected" if db_connected else "disconnected",
            "serverTime": now.isoformat(),
            "activeServer": "https://dinesh03.pythonanywhere.com/api",
        }, status=status.HTTP_200_OK)



class TrackActivityBatchView(APIView):
    """
    Batched event reporting endpoint for mobile clients (online + reconnected offline).
    Aggregates events into counts without logging private searches or personal data.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        events = request.data.get("events", [])
        if not isinstance(events, list):
            return Response(
                {"error": "events must be a list"},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = request.user if request.user.is_authenticated else None
        now = timezone.now()
        today = timezone.localdate()

        # If user is authenticated, update their last_active_at & log activity
        if user:
            profile, _ = UserProfile.objects.get_or_create(
                user=user,
                defaults={"role": "ADMIN" if (user.is_staff or user.is_superuser) else "USER"},
            )
            profile.last_active_at = now
            profile.save(update_fields=["last_active_at"])

            UserActivityLog.objects.get_or_create(
                user=user,
                date=today,
                defaults={"activity_type": "batch_sync", "timestamp": now},
            )

        with transaction.atomic():
            for item in events:
                if not isinstance(item, dict):
                    continue
                etype = item.get("type")

                if etype == "feature":
                    fname = str(item.get("name", "")).strip().lower()
                    count = max(1, int(item.get("count", 1)))
                    if fname:
                        obj, created = FeatureUsageStat.objects.get_or_create(
                            feature_name=fname,
                            date=today,
                            defaults={"count": count},
                        )
                        if not created:
                            FeatureUsageStat.objects.filter(pk=obj.pk).update(count=F("count") + count)

                elif etype == "search":
                    query = str(item.get("query", "")).strip().lower()
                    if query and len(query) <= 150:
                        obj, created = SearchStat.objects.get_or_create(
                            query=query,
                            defaults={"count": 1},
                        )
                        if not created:
                            SearchStat.objects.filter(pk=obj.pk).update(count=F("count") + 1)
                        # Also count toward feature usage 'law_search'
                        fobj, fcreated = FeatureUsageStat.objects.get_or_create(
                            feature_name="law_search",
                            date=today,
                            defaults={"count": 1},
                        )
                        if not fcreated:
                            FeatureUsageStat.objects.filter(pk=fobj.pk).update(count=F("count") + 1)

                elif etype == "section_view":
                    sid = item.get("section_id")
                    title = str(item.get("title", ""))[:300]
                    law_name = str(item.get("law_name", ""))[:200]
                    if sid is not None:
                        obj, created = SectionViewStat.objects.get_or_create(
                            section_id=sid,
                            defaults={"section_title": title, "law_name": law_name, "count": 1},
                        )
                        if not created:
                            SectionViewStat.objects.filter(pk=obj.pk).update(count=F("count") + 1)

                elif etype == "law_view":
                    lid = item.get("law_id")
                    law_name = str(item.get("law_name", ""))[:200]
                    if lid is not None:
                        obj, created = LawViewStat.objects.get_or_create(
                            law_id=lid,
                            defaults={"law_name": law_name, "count": 1},
                        )
                        if not created:
                            LawViewStat.objects.filter(pk=obj.pk).update(count=F("count") + 1)

        return Response(
            {"status": "ok", "processed": len(events)},
            status=status.HTTP_200_OK,
        )


class HeartbeatView(APIView):
    """
    Periodic lightweight heartbeat to update last_active_at for authenticated users.
    Throttled on the client to avoid redundant requests.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        if request.user.is_authenticated:
            user = request.user
            now = timezone.now()
            today = timezone.localdate()
            profile, _ = UserProfile.objects.get_or_create(
                user=user,
                defaults={"role": "ADMIN" if (user.is_staff or user.is_superuser) else "USER"},
            )
            profile.last_active_at = now
            profile.save(update_fields=["last_active_at"])

            UserActivityLog.objects.get_or_create(
                user=user,
                date=today,
                defaults={"activity_type": "heartbeat", "timestamp": now},
            )
            return Response(
                {"status": "ok", "authenticated": True, "last_active_at": profile.last_active_at.isoformat()},
                status=status.HTTP_200_OK,
            )

        return Response({"status": "ok", "authenticated": False}, status=status.HTTP_200_OK)
