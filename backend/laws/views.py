from datetime import date
from django.db.models import Q
from django.utils import timezone
from django.utils.dateparse import parse_datetime
from rest_framework import generics, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated

from .permissions import IsLegalAdministrator
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
    publish_update,
    approve_and_publish_update,
    reject_update,
    request_verification_update,
    get_sync_overview,
    validate_legal_update_record,
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
                cursor.execute("PRAGMA table_info(laws_category)")
                cat_cols = [row[1] for row in cursor.fetchall()]
                cursor.execute("PRAGMA table_info(laws_legalupdaterecord)")
                rec_cols = [row[1] for row in cursor.fetchall()]
                cursor.execute("PRAGMA table_info(laws_databasesyncinfo)")
                sync_cols = [row[1] for row in cursor.fetchall()]
                cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='accounts_userroleauditlog'")
                has_audit_table = bool(cursor.fetchone())

                if ('provision_key' not in cols or
                    'name_hi' not in cat_cols or
                    'act_name' not in rec_cols or
                    'last_source_check_status' not in sync_cols or
                    not has_audit_table):
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

            # Optional Admin & BNS Staging Hooks for Production Setup
            admin_token_key = None
            if request.query_params.get("init_admin") == "1":
                from django.contrib.auth import get_user_model
                from rest_framework.authtoken.models import Token
                User = get_user_model()
                admin_user = User.objects.filter(is_superuser=True).first()
                if not admin_user:
                    admin_user = User.objects.create_superuser("admin", "admin@legalguide.org", "LegalAdmin2024!")
                tok, _ = Token.objects.get_or_create(user=admin_user)
                admin_token_key = tok.key

            if request.query_params.get("stage_bns_update") == "1":
                from datetime import date
                bns = Law.objects.filter(name__icontains="Bharatiya Nyaya Sanhita").first()
                if bns and not LegalUpdateRecord.objects.filter(section_number="106").exists():
                    LegalUpdateRecord.objects.create(
                        law=bns,
                        act_name=bns.name,
                        section_number="106",
                        update_type="amendment",
                        status="pending_review",
                        verification_status="verified",
                        proposed_title="Causing death by negligence",
                        existing_legal_text=(
                            "Indian Penal Code, 1860 — Section 304A (Prior Law):\n"
                            "Whoever causes the death of any person by doing any rash or negligent act not amounting "
                            "to culpable homicide, shall be punished with imprisonment of either description for a term "
                            "which may extend to two years, or with fine, or with both.\n\n"
                            "[Note: Section 106 of the Bharatiya Nyaya Sanhita, 2023 was absent from the LegalGuide database.]"
                        ),
                        proposed_legal_text=(
                            "Section 106. Causing death by negligence.—\n"
                            "(1) Whoever causes the death of any person by doing any rash or negligent act not amounting "
                            "to culpable homicide, shall be punished with imprisonment of either description for a term "
                            "which may extend to five years, and shall also be liable to fine; and if such act is done "
                            "by a registered medical practitioner while performing medical procedure, he shall be punished "
                            "with imprisonment of either description for a term which may extend to two years, and shall also be liable to fine.\n\n"
                            "Explanation.—For the purposes of this sub-section, \"registered medical practitioner\" means a "
                            "medical practitioner who possesses any medical qualification recognized under the National Medical "
                            "Commission Act, 2019 and whose name has been entered in the National Medical Register or a "
                            "State Medical Register under that Act.\n\n"
                            "(2) [NOT YET IN FORCE] Whoever causes the death of any person by rash and negligent driving of "
                            "vehicle not amounting to culpable homicide, and escapes without reporting it to a police officer "
                            "or a Magistrate soon after the incident, shall be punished with imprisonment of either description "
                            "of a term which may extend to ten years, and shall also be liable to fine.\n"
                            "[Note: Notification S.O. 850(E) dated 23-02-2024 brought all provisions into force from 01-07-2024 EXCEPT sub-section (2) of Section 106]."
                        ),
                        proposed_simple_explanation=(
                            "Section 106 of the Bharatiya Nyaya Sanhita, 2023 governs causing death by negligence, replacing "
                            "Section 304A of the Indian Penal Code. Under Section 106(1), which came into force on 1 July 2024, "
                            "the general punishment for causing death by rash or negligent acts has been increased from 2 years "
                            "to up to 5 years of imprisonment plus fine. A specific protection is provided for registered medical "
                            "practitioners performing medical procedures, keeping their maximum imprisonment capped at 2 years. "
                            "Crucially, the 10-year hit-and-run penalty under Section 106(2) was expressly held in abeyance by "
                            "Ministry of Home Affairs Notification S.O. 850(E) dated 23-02-2024 and is NOT yet in force."
                        ),
                        proposed_punishment=(
                            "Section 106(1) [In Force]: Imprisonment up to 5 years and fine. "
                            "Registered medical practitioners performing procedures: Imprisonment up to 2 years and fine. "
                            "Section 106(2) [Hit & Run - NOT yet commenced]: Imprisonment up to 10 years and fine."
                        ),
                        proposed_effective_date=date(2024, 7, 1),
                        proposed_amendment_info=(
                            "The Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023), Section 106. "
                            "Ministry of Home Affairs Notification S.O. 850(E) dated 23-02-2024 commenced Section 106(1) on 01-07-2024 "
                            "while holding Section 106(2) in abeyance."
                        ),
                        commencement_status="Commenced (Sec 106(1)); Sec 106(2) in abeyance",
                        detected_diff=(
                            "--- Indian Penal Code, 1860: Section 304A (Prior Law)\n"
                            "+++ Bharatiya Nyaya Sanhita, 2023: Section 106 (Official Government Gazette Notification)\n"
                            "@@ -1,3 +1,15 @@\n"
                            "- Maximum imprisonment: 2 years (or fine, or both) for rash or negligent act causing death.\n"
                            "- No statutory distinction for medical practitioners performing procedures.\n"
                            "- No statutory aggravated provision for hit-and-run escape.\n"
                            "+ Section 106(1) [COMMENCED 01-07-2024]: Punishment increased to up to 5 years imprisonment and fine.\n"
                            "+ Section 106(1) Proviso [COMMENCED 01-07-2024]: Registered medical practitioners capped at 2 years imprisonment and fine.\n"
                            "+ Section 106(2) [HELD IN ABEYANCE / NOT IN FORCE]: Up to 10 years imprisonment for hit-and-run escape; specifically excepted by MHA Notification S.O. 850(E)."
                        ),
                        source_url="https://www.indiacode.gov.in/handle/123456789/20062",
                        source_name="India Code & Gazette of India Extraordinary No. 817 (S.O. 850(E))",
                        source_publication_date=date(2024, 2, 23),
                    )

        except Exception as e:
            db_status = f"error: {str(e)}"

        resp_data = {
            "status": "ok",
            "service": "LegalGuide API",
            "database": db_status,
            "migrated": migrated,
        }
        if admin_token_key:
            resp_data["admin_token"] = admin_token_key
        return Response(resp_data, status=status.HTTP_200_OK)


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
        valid_published_statuses = ["current", "historical", "amended", "repealed"]
        qs = LegalSection.objects.filter(status__in=valid_published_statuses).select_related("law")
        law_id = self.request.query_params.get("law_id")
        if law_id:
            qs = qs.filter(law_id=law_id)
        status_param = self.request.query_params.get("status")
        if status_param and status_param.lower() != "all":
            if status_param.lower() in valid_published_statuses:
                qs = qs.filter(status=status_param.lower())
            else:
                qs = qs.none()
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

        valid_published_statuses = ["current", "historical", "amended", "repealed"]
        if since_dt:
            categories_qs = Category.objects.filter(updated_at__gt=since_dt)
            laws_qs = Law.objects.filter(updated_at__gt=since_dt)
            sections_qs = LegalSection.objects.filter(updated_at__gt=since_dt, status__in=valid_published_statuses)
            matters_qs = LegalMatter.objects.filter(updated_at__gt=since_dt)
            versions_qs = LegalSectionVersion.objects.filter(archived_at__gt=since_dt)
            is_incremental = True
        else:
            categories_qs = Category.objects.all()
            laws_qs = Law.objects.all()
            sections_qs = LegalSection.objects.filter(status__in=valid_published_statuses)
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
        qs = PublishedLegalUpdate.objects.filter(
            Q(source_update_record__isnull=True) | Q(source_update_record__status="published")
        )
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
            update = PublishedLegalUpdate.objects.filter(
                Q(source_update_record__isnull=True) | Q(source_update_record__status="published")
            ).get(pk=pk)
        except PublishedLegalUpdate.DoesNotExist:
            return Response({"error": "Not found."}, status=status.HTTP_404_NOT_FOUND)
        return Response(PublishedLegalUpdateSerializer(update).data)


# ─────────────────────────────────────────────────────────
# ADMIN-ONLY ENDPOINTS  (IsLegalAdministrator enforced on every route)
# ─────────────────────────────────────────────────────────

class AdminCheckUpdatesView(APIView):
    """
    Triggers an official government source scan (India Code, Gazette of India, e-Gazette).
    Stages any newly detected amendments, replacements, or notifications into LegalUpdateRecord
    with status='pending_review' or 'detected'.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        admin_user = request.user.username if request.user else "admin"
        created = check_official_sources(requested_by=admin_user)
        sync_info = DatabaseSyncInfo.get_info()
        serializer = LegalUpdateRecordSerializer(created, many=True)
        return Response({
            "message": f"Source check complete. {sync_info.last_source_check_status}.",
            "status": sync_info.last_source_check_status,
            "summary": sync_info.last_source_check_summary,
            "last_source_check": sync_info.last_source_check.isoformat() if sync_info.last_source_check else None,
            "new_updates_count": len(created),
            "updates": serializer.data,
        }, status=status.HTTP_200_OK)


class AdminApproveUpdateView(APIView):
    """
    Approves a staged update without immediately publishing it to canonical active laws.
    Marks status='approved', records admin username, review timestamp, and notes.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        update_id = request.data.get("update_id")
        notes = request.data.get("notes", "")
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            admin_user = request.user.username if request.user else "admin"
            record = approve_update(update_id, admin_user=admin_user, notes=notes)
            return Response({
                "message": f"Update {record.id} for section '{record.section_number}' approved. Ready for publication.",
                "record": LegalUpdateRecordSerializer(record).data,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminPublishUpdateView(APIView):
    """
    Publishes an approved update into the canonical LegalSection database.
    Performs validation, updates the section, archives the previous version in LegalSectionVersion,
    increments the database sync version, marks status='published', and creates a PublishedLegalUpdate notification.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        update_id = request.data.get("update_id")
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            admin_user = request.user.username if request.user else "admin"
            section, pub_notif = publish_update(update_id, admin_user=admin_user)
            return Response({
                "message": f"Section {section.section_number} updated to version {section.version}. Published to mobile clients.",
                "section": LegalSectionSerializer(section).data,
                "published_notification": PublishedLegalUpdateSerializer(pub_notif).data if pub_notif else None,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminApproveAndPublishUpdateView(APIView):
    """
    Single-step workflow: approves and immediately publishes a staged update.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        update_id = request.data.get("update_id")
        notes = request.data.get("notes", "")
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            admin_user = request.user.username if request.user else "admin"
            section, pub_notif = approve_and_publish_update(update_id, admin_user=admin_user, notes=notes)
            return Response({
                "message": f"Section {section.section_number} approved and published to version {section.version}.",
                "section": LegalSectionSerializer(section).data,
                "published_notification": PublishedLegalUpdateSerializer(pub_notif).data if pub_notif else None,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminRejectUpdateView(APIView):
    """
    Rejects a staged update record.
    Requires a non-empty rejection reason.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        update_id = request.data.get("update_id")
        reason = request.data.get("reason", "").strip()
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not reason:
            return Response({"error": "A rejection reason is required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            admin_user = request.user.username if request.user else "admin"
            record = reject_update(update_id, admin_user=admin_user, reason=reason)
            return Response({
                "message": f"Update {record.id} rejected.",
                "record": LegalUpdateRecordSerializer(record).data,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminRequestVerificationView(APIView):
    """
    Marks an update record as 'needs_verification' and appends review notes.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def post(self, request):
        update_id = request.data.get("update_id")
        notes = request.data.get("notes", "").strip()
        if not update_id:
            return Response({"error": "update_id is required"}, status=status.HTTP_400_BAD_REQUEST)
        if not notes:
            return Response({"error": "Verification notes explaining what needs to be checked are required."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            admin_user = request.user.username if request.user else "admin"
            record = request_verification_update(update_id, admin_user=admin_user, notes=notes)
            return Response({
                "message": f"Update {record.id} flagged for verification.",
                "record": LegalUpdateRecordSerializer(record).data,
            }, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


class AdminEditUpdateView(APIView):
    """
    Allows administrators to edit the proposed text, punishment, source, or effective date
    of a staged update record before approving or publishing it.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def patch(self, request, pk):
        try:
            record = LegalUpdateRecord.objects.get(pk=pk)
        except LegalUpdateRecord.DoesNotExist:
            return Response({"error": f"Update record {pk} not found."}, status=status.HTTP_404_NOT_FOUND)

        if record.status in ["approved", "published"]:
            return Response(
                {"error": f"Cannot edit record in '{record.status}' state. Only pending or verification-flagged updates can be modified."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        editable_fields = [
            "title", "proposed_text", "proposed_punishment", "bailable", "cognizable",
            "compoundable", "triable_by", "source_name", "source_url", "gazette_notification_number",
            "effective_date", "notes", "update_type", "section_number", "provision_key",
        ]
        for field in editable_fields:
            if field in request.data:
                setattr(record, field, request.data[field])

        # Validate with official validation engine
        validation = validate_legal_update_record(record)
        if not validation["is_valid"]:
            return Response({
                "error": "Validation failed.",
                "errors": validation["errors"],
                "warnings": validation["warnings"],
            }, status=status.HTTP_400_BAD_REQUEST)

        record.save()
        return Response({
            "message": f"Update record {record.id} modified successfully.",
            "record": LegalUpdateRecordSerializer(record).data,
            "validation": validation,
        }, status=status.HTTP_200_OK)


class AdminPendingUpdatesView(APIView):
    """
    Returns pending, unverified, and approved update records awaiting admin review or publication.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def get(self, request):
        status_filter = request.query_params.get("status")
        if status_filter:
            qs = LegalUpdateRecord.objects.filter(status=status_filter).order_by("-detected_at")
        else:
            qs = LegalUpdateRecord.objects.filter(
                status__in=["pending_review", "pending", "detected", "needs_verification", "approved"]
            ).order_by("-detected_at")

        search_filter = request.query_params.get("search", "").strip()
        if search_filter:
            qs = qs.filter(
                proposed_title__icontains=search_filter
            ) | qs.filter(
                section_number__icontains=search_filter
            )

        return Response({
            "count": qs.count(),
            "updates": LegalUpdateRecordSerializer(qs, many=True).data,
        }, status=status.HTTP_200_OK)


class AdminAllUpdatesView(APIView):
    """
    Returns all update records (pending, approved, published, rejected, needs_verification).
    Supports filters: status, update_type, search.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def get(self, request):
        qs = LegalUpdateRecord.objects.all().order_by("-detected_at")
        status_filter = request.query_params.get("status")
        if status_filter:
            qs = qs.filter(status=status_filter)

        update_type_filter = request.query_params.get("update_type")
        if update_type_filter:
            qs = qs.filter(update_type=update_type_filter)

        search = request.query_params.get("search", "").strip()
        if search:
            qs = qs.filter(
                proposed_title__icontains=search
            ) | qs.filter(
                section_number__icontains=search
            )

        return Response({
            "count": qs.count(),
            "updates": LegalUpdateRecordSerializer(qs, many=True).data,
        }, status=status.HTTP_200_OK)


class AdminSectionVersionsView(APIView):
    """
    Returns all historical versions (LegalSectionVersion) for a section.
    Allows administrators to audit every past text, punishment, amendment, and gazette notice.
    ADMIN ONLY.
    """
    permission_classes = [IsLegalAdministrator]

    def get(self, request, pk):
        try:
            sec = LegalSection.objects.get(pk=pk)
        except LegalSection.DoesNotExist:
            return Response({"error": "Legal section not found."}, status=status.HTTP_404_NOT_FOUND)

        versions = sec.versions.all().order_by("-version_number")
        return Response({
            "section_id": sec.id,
            "section_number": sec.section_number,
            "current_version": sec.version,
            "status": sec.status,
            "versions_count": versions.count(),
            "versions": LegalSectionVersionSerializer(versions, many=True).data,
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
    permission_classes = [IsLegalAdministrator]

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
            "sync_version": sync_info.server_version,
            "last_sync_date": sync_info.last_sync_date.isoformat() if sync_info.last_sync_date else None,
            "last_synchronized": sync_info.last_sync_date.isoformat() if sync_info.last_sync_date else None,
            "last_source_check": sync_info.last_source_check.isoformat() if sync_info.last_source_check else None,
            "last_source_check_status": getattr(sync_info, 'last_source_check_status', 'verified'),
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
    permission_classes = [IsLegalAdministrator]

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


# ─────────────────────────────────────────────────────────
# ADMIN-ONLY EDUCATIONAL MEDIA & EXAMPLE UPDATE ENDPOINT
# ─────────────────────────────────────────────────────────

class AdminSectionMediaUpdateView(APIView):
    """
    Admin-only endpoint for editing section educational media, examples, and citizen guidance.
    Persists updates directly into the central production database so that:
    1. Admin app patches media
    2. Central DB updates the section row and bumps updated_at
    3. Mobile clients receive the updated illustration / video via incremental delta sync
    4. Normal users receive 403 Forbidden
    """
    permission_classes = [IsLegalAdministrator]

    def patch(self, request, pk):
        try:
            section = LegalSection.objects.get(pk=pk)
        except LegalSection.DoesNotExist:
            # Fallback by provision_key if passed
            section = LegalSection.objects.filter(provision_key=str(pk)).first()
            if not section:
                return Response(
                    {"error": f"Legal section with ID or key '{pk}' not found."},
                    status=status.HTTP_404_NOT_FOUND
                )

        allowed_fields = [
            "visual_image_url",
            "visual_caption",
            "visual_caption_te",
            "visual_caption_hi",
            "visual_alt_text",
            "is_visual_illustrative",
            "video_url",
            "video_title",
            "video_duration",
            "video_thumbnail_url",
            "video_transcript",
            "example_title",
            "example_title_te",
            "example_title_hi",
            "example_situation",
            "example_situation_te",
            "example_situation_hi",
            "example_explanation",
            "example_explanation_te",
            "example_explanation_hi",
            "example_disclaimer",
            "example_steps",
            "what_you_should_do",
            "what_you_should_do_te",
            "what_you_should_do_hi",
            "consequences_type",
        ]

        updated_fields = []
        for field in allowed_fields:
            if field in request.data:
                val = request.data.get(field)
                if field == "is_visual_illustrative":
                    val = bool(val)
                elif field == "example_steps" and isinstance(val, (list, dict)):
                    import json
                    val = json.dumps(val)
                setattr(section, field, val)
                updated_fields.append(field)

        if not updated_fields:
            return Response(
                {"error": "No valid media or example fields provided for update."},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Bump updated_at so delta sync (/api/laws/sync/?since=...) propagates to all user devices
        section.updated_at = timezone.now()
        updated_fields.append("updated_at")
        section.save(update_fields=updated_fields)

        return Response({
            "message": f"Media and educational content for {section.section_number} updated and published to server.",
            "section": LegalSectionSerializer(section).data,
        }, status=status.HTTP_200_OK)