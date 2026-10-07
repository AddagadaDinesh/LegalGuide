from datetime import date
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAdminUser, IsAuthenticated

from .models import (
    Category,
    Law,
    LegalSection,
    LegalMatter,
    LegalSectionVersion,
    LegalUpdateRecord,
    DatabaseSyncInfo,
    PublishedLegalUpdate,
)
from .serializers import (
    CategorySerializer,
    LawSerializer,
    LegalSectionSerializer,
    LegalMatterSerializer,
    LegalSectionVersionSerializer,
    LegalUpdateRecordSerializer,
    DatabaseSyncInfoSerializer,
    PublishedLegalUpdateSerializer,
)
from .updater import (
    check_official_sources,
    approve_update,
    reject_update,
    get_sync_overview,
)


# ─────────────────────────────────────────────────────────
# PUBLIC / USER ENDPOINTS
# ─────────────────────────────────────────────────────────

class HealthCheckView(APIView):
    """
    Production health check endpoint.
    Tests database connectivity without leaking credentials or secrets.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        db_status = "connected"
        migrated = False
        try:
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
                cursor.execute("PRAGMA table_info(laws_legalsection)")
                cols = [row[1] for row in cursor.fetchall()]
                if 'provision_key' not in cols:
                    from django.core.management import call_command
                    call_command('migrate', interactive=False)
                    migrated = True

            import re
            empty_keys = LegalSection.objects.filter(provision_key='')
            if empty_keys.exists():
                for s in empty_keys:
                    clean = re.sub(r'[^a-zA-Z0-9]', '_', s.section_number.lower()).strip('_')
                    clean = re.sub(r'_+', '_', clean)
                    s.provision_key = f"{s.law_id}_{clean}"
                    s.save(update_fields=['provision_key'])
        except Exception as e:
            db_status = f"error: {str(e)}"

        return Response({
            "status": "ok",
            "service": "LegalGuide API",
            "database": db_status,
            "migrated": migrated,
        }, status=status.HTTP_200_OK)


class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]


class LawListView(generics.ListAPIView):
    queryset = Law.objects.all()
    serializer_class = LawSerializer
    permission_classes = [AllowAny]


class LegalSectionListView(generics.ListAPIView):
    serializer_class = LegalSectionSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        qs = LegalSection.objects.all().select_related("law")
        law_id = self.request.query_params.get("law_id")
        if law_id:
            qs = qs.filter(law_id=law_id)
        status_param = self.request.query_params.get("status")
        if status_param and status_param.lower() != "all":
            qs = qs.filter(status=status_param.lower())
        return qs.order_by("law_id", "id").distinct()


class LegalMatterListView(generics.ListAPIView):
    queryset = LegalMatter.objects.all()
    serializer_class = LegalMatterSerializer
    permission_classes = [AllowAny]


class LegalSyncView(APIView):
    """
    Incremental delta synchronization endpoint for mobile clients.
    Supports ?since=<ISO_TIMESTAMP>.
    If since is provided, only modified and new records are transferred.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        since_param = request.query_params.get("since")
        since_dt = None
        if since_param:
            try:
                since_dt = parse_datetime(since_param)
            except Exception:
                since_dt = None

        sync_info = DatabaseSyncInfo.get_info()
        now = timezone.now()

        if since_dt:
            categories_qs = Category.objects.filter(updated_at__gt=since_dt)
            laws_qs = Law.objects.filter(updated_at__gt=since_dt)
            sections_qs = LegalSection.objects.filter(updated_at__gt=since_dt)
            matters_qs = LegalMatter.objects.filter(updated_at__gt=since_dt)
            versions_qs = LegalSectionVersion.objects.filter(archived_at__gt=since_dt)
            is_incremental = True
        else:
            categories_qs = Category.objects.all()
            laws_qs = Law.objects.all()
            sections_qs = LegalSection.objects.all()
            matters_qs = LegalMatter.objects.all()
            versions_qs = LegalSectionVersion.objects.all()
            is_incremental = False

        # Deleted / repealed section IDs
        deleted_ids = list(
            LegalSection.objects.filter(status="repealed").values_list("id", flat=True)
        )

        return Response({
            "sync_timestamp": now.isoformat(),
            "server_version": sync_info.server_version,
            "is_incremental": is_incremental,
            "source_name": sync_info.primary_source_name,
            "source_url": sync_info.primary_source_url,
            "last_verified": date.today().isoformat(),
            "categories": CategorySerializer(categories_qs, many=True).data,
            "laws": LawSerializer(laws_qs, many=True).data,
            "sections": LegalSectionSerializer(sections_qs, many=True).data,
            "matters": LegalMatterSerializer(matters_qs, many=True).data,
            "versions": LegalSectionVersionSerializer(versions_qs, many=True).data,
            "deleted_section_ids": deleted_ids if is_incremental else [],
        }, status=status.HTTP_200_OK)


class DatabaseSyncStatusView(APIView):
    """Returns database sync status, official source verification, and update counts."""
    permission_classes = [AllowAny]

    def get(self, request):
        overview = get_sync_overview()
        return Response(overview, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────────────────
# USER: Published Legal Updates  (VERIFIED, PUBLISHED only)
# Normal users receive ONLY what has been admin-approved.
# ─────────────────────────────────────────────────────────

class PublishedLegalUpdatesView(APIView):
    """
    Returns the list of published (admin-approved) legal updates for normal users.
    Supports ?since=<ISO_TIMESTAMP> for incremental sync.
    Optionally filter with ?latest=1 to return only the newest N updates.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        since_param = request.query_params.get("since")
        latest_param = request.query_params.get("latest")
        qs = PublishedLegalUpdate.objects.all()
        if since_param:
            try:
                since_dt = parse_datetime(since_param)
                if since_dt:
                    qs = qs.filter(published_at__gt=since_dt)
            except Exception:
                pass
        if latest_param:
            try:
                qs = qs[:int(latest_param)]
            except ValueError:
                pass
        serializer = PublishedLegalUpdateSerializer(qs, many=True)
        return Response({
            "count": qs.count() if not latest_param else len(serializer.data),
            "last_sync": timezone.now().isoformat(),
            "updates": serializer.data,
        }, status=status.HTTP_200_OK)


class PublishedLegalUpdateDetailView(APIView):
    """Returns detail for a single published legal update."""
    permission_classes = [AllowAny]

    def get(self, request, pk):
        try:
            update = PublishedLegalUpdate.objects.get(pk=pk)
        except PublishedLegalUpdate.DoesNotExist:
            return Response({"error": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(PublishedLegalUpdateSerializer(update).data)


# ─────────────────────────────────────────────────────────
# ADMIN-ONLY ENDPOINTS  (IsAdminUser enforced on every route)
# ─────────────────────────────────────────────────────────

class AdminCheckUpdatesView(APIView):
    """Triggers an official government source scan (India Code / Gazette). ADMIN ONLY."""
    permission_classes = [IsAdminUser]

    def post(self, request):
        created = check_official_sources()
        serializer = LegalUpdateRecordSerializer(created, many=True)
        return Response({
            "message": f"Source check complete. Found {len(created)} update(s).",
            "new_updates_count": len(created),
            "updates": serializer.data,
        }, status=status.HTTP_200_OK)


class AdminApproveUpdateView(APIView):
    """Approves a pending update, promotes it to active legal data, creates user notification. ADMIN ONLY."""
    permission_classes = [IsAdminUser]

    def post(self, request):
        update_id = request.data.get("update_id")
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            sec = approve_update(update_id, admin_user=request.user.username)
            return Response({
                "message": f"Section {sec.section_number} updated to v{sec.version}. User notification published.",
                "section": LegalSectionSerializer(sec).data,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminRejectUpdateView(APIView):
    """Rejects a pending update record. ADMIN ONLY."""
    permission_classes = [IsAdminUser]

    def post(self, request):
        update_id = request.data.get("update_id")
        reason = request.data.get("reason", "")
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        try:
            record = reject_update(update_id, admin_user=request.user.username, reason=reason)
            return Response({
                "message": f"Update {record.id} rejected.",
                "record_id": record.id,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminPendingUpdatesView(APIView):
    """Returns all pending update records (for admin review). ADMIN ONLY."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = LegalUpdateRecord.objects.filter(status="pending")
        return Response({
            "count": qs.count(),
            "updates": LegalUpdateRecordSerializer(qs, many=True).data,
        }, status=status.HTTP_200_OK)


class AdminAllUpdatesView(APIView):
    """Returns all update records (pending, approved, rejected) for Admin dashboard. ADMIN ONLY."""
    permission_classes = [IsAdminUser]

    def get(self, request):
        status_filter = request.query_params.get("status")
        qs = LegalUpdateRecord.objects.all()
        if status_filter:
            qs = qs.filter(status=status_filter)
        return Response({
            "count": qs.count(),
            "updates": LegalUpdateRecordSerializer(qs, many=True).data,
        }, status=status.HTTP_200_OK)


class AdminLegalDatabaseView(APIView):
    """
    Admin-only comprehensive database view:
    - total laws/acts, sections, versions
    - dynamic list of acts with verified sections count
    - section status breakdown (current, amended, historical, repealed)
    - pending / approved / rejected update counts
    - published notifications count
    - last sync info
    ADMIN ONLY.
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        from django.db.models import Q
        sync_info = DatabaseSyncInfo.get_info()
        overview = get_sync_overview()

        acts_qs = Law.objects.all().select_related("category").prefetch_related("sections")

        search_query = request.query_params.get("search", "").strip()
        if search_query:
            acts_qs = acts_qs.filter(
                Q(name__icontains=search_query) |
                Q(short_name__icontains=search_query) |
                Q(year__icontains=search_query) |
                Q(category__name__icontains=search_query)
            )

        status_filter = request.query_params.get("status", "").strip()
        if status_filter and status_filter.lower() != "all":
            acts_qs = acts_qs.filter(status=status_filter.lower())

        domain_filter = request.query_params.get("domain", "").strip()
        if domain_filter and domain_filter.lower() != "all":
            acts_qs = acts_qs.filter(category__name__iexact=domain_filter)

        acts_list = []
        for law in acts_qs:
            secs = law.sections.all()
            acts_list.append({
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
                "updated_at": law.updated_at.isoformat() if law.updated_at else None,
                "verified_sections_count": secs.count(),
                "sections_count": secs.count(),
                "current_sections_count": sum(1 for s in secs if s.status == "current"),
                "amended_sections_count": sum(1 for s in secs if s.status == "amended"),
                "historical_sections_count": sum(1 for s in secs if s.status == "historical"),
                "repealed_sections_count": sum(1 for s in secs if s.status == "repealed"),
            })

        overview.update({
            "total_acts": Law.objects.count(),
            "total_laws": Law.objects.count(),
            "total_sections": LegalSection.objects.count(),
            "current_sections": LegalSection.objects.filter(status="current").count(),
            "amended_sections": LegalSection.objects.filter(status="amended").count(),
            "historical_sections": LegalSection.objects.filter(status="historical").count(),
            "repealed_sections": LegalSection.objects.filter(status="repealed").count(),
            "total_section_versions": LegalSectionVersion.objects.count(),
            "published_updates_count": PublishedLegalUpdate.objects.count(),
            "server_version": sync_info.server_version,
            "primary_source_name": sync_info.primary_source_name,
            "primary_source_url": sync_info.primary_source_url,
            "acts": acts_list,
        })
        return Response(overview, status=status.HTTP_200_OK)


class AdminPublishedUpdatesView(APIView):
    """
    Admin view of all PublishedLegalUpdate records (what users see).
    ADMIN ONLY — used for admin dashboard / audit trail.
    """
    permission_classes = [IsAdminUser]

    def get(self, request):
        qs = PublishedLegalUpdate.objects.all()
        return Response({
            "count": qs.count(),
            "updates": PublishedLegalUpdateSerializer(qs, many=True).data,
        }, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────────────────
# APPLICATION VERSION & REMOTE FEATURE CONFIGURATION
# ─────────────────────────────────────────────────────────

class AppVersionView(APIView):
    """
    Returns application binary version, minimum supported version, release notes, and store URL.
    Used for genuine APK / Google Play updates (distinct from remote content / legal sync).
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "latestVersion": "1.0.0",
            "minimumSupportedVersion": "1.0.0",
            "updateAvailable": False,
            "forceUpdate": False,
            "releaseNotes": [
                "Emergency Rights Guide",
                "Indian Railway Rules & Fines",
                "Traffic Rules & Driver Rights",
                "Centralized User Analytics & User Directory",
                "Verified Legal Database Synchronization"
            ],
            "storeUrl": "https://play.google.com/store/apps/details?id=com.example.legalguide_app"
        }, status=status.HTTP_200_OK)


class FeatureConfigView(APIView):
    """
    Returns dynamic feature toggles and remote configurations for installed capabilities.
    Allows enabling/disabling Legal Awareness categories without requiring an APK update.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "version": 1,
            "features": [
                {
                    "featureKey": "emergency_rights",
                    "enabled": True,
                    "type": "LEGAL_AWARENESS",
                    "title": {
                        "en": "Emergency Rights Guide",
                        "te": "అత్యవసర హక్కుల గైడ్",
                        "hi": "आपातकालीन अधिकार गाइड"
                    }
                },
                {
                    "featureKey": "railway_rules",
                    "enabled": True,
                    "type": "LEGAL_AWARENESS",
                    "title": {
                        "en": "Indian Railway Rules & Fines",
                        "te": "భారతీయ రైల్వే నిబంధనలు & జరిమానాలు",
                        "hi": "भारतीय रेलवे नियम और जुर्माना"
                    }
                },
                {
                    "featureKey": "traffic_rules",
                    "enabled": True,
                    "type": "LEGAL_AWARENESS",
                    "title": {
                        "en": "Traffic Rules & Driver Rights",
                        "te": "ట్రాఫిక్ నిబంధనలు & డ్రైవర్ హక్కులు",
                        "hi": "ट्रैफिक नियम और ड्राइवर अधिकार"
                    }
                }
            ]
        }, status=status.HTTP_200_OK)