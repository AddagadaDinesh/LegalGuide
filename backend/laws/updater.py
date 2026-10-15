import difflib
from datetime import date
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils import timezone
from .models import (
    Category,
    Law,
    LegalSection,
    LegalSectionVersion,
    LegalUpdateRecord,
    DatabaseSyncInfo,
    PublishedLegalUpdate,
)


def compute_text_diff(old_text: str, new_text: str) -> str:
    """Produces a clean unified diff between old and new statutory text."""
    old_lines = (old_text or "").splitlines(keepends=True)
    new_lines = (new_text or "").splitlines(keepends=True)
    diff = difflib.unified_diff(
        old_lines,
        new_lines,
        fromfile="Active Version",
        tofile="Official Proposed Update",
        n=2,
    )
    return "".join(diff)


def validate_legal_update_record(record: LegalUpdateRecord, raise_exception: bool = False) -> dict:
    """
    Validates the complete legal record before publishing:
    Ensures valid section numbers, legal text, effective dates, source URLs, and update types.
    """
    errors = []
    warnings = []
    if not record.section_number or not str(record.section_number).strip():
        errors.append("Section number is required.")
    if not record.proposed_legal_text or not str(record.proposed_legal_text).strip():
        errors.append("Proposed legal text is required.")
    if not record.proposed_title or not str(record.proposed_title).strip():
        errors.append("Proposed title is required.")
    if not record.source_url or not str(record.source_url).strip().startswith("http"):
        errors.append("A valid official source URL starting with http/https is required.")
    valid_types = [choice[0] for choice in LegalUpdateRecord.UPDATE_TYPE_CHOICES]
    if record.update_type not in valid_types:
        errors.append(f"Invalid update type: '{record.update_type}'.")
    if not record.section and not record.law and not record.act_name:
        errors.append("A reference to an existing section, law, or act name is required.")

    if not record.proposed_effective_date:
        warnings.append("Effective date is not specified.")

    is_valid = len(errors) == 0
    if raise_exception and not is_valid:
        raise ValidationError("; ".join(errors))

    return {
        "is_valid": is_valid,
        "errors": errors,
        "warnings": warnings,
    }


def check_official_sources(requested_by=None):
    """
    Connects to authoritative government sources (India Code / Official Gazette / Ministry of Law)
    to check reachability and monitors government endpoints.
    Measures latency, handles connectivity and limitations honestly, and logs the check.

    CRITICAL RULES:
    1. Distinguishes reachability from verified legal change. A reachable website is NOT proof of an amendment.
    2. Uses standard TLS certificate verification (no disabled hostname verification or ssl.CERT_NONE).
    3. Never inserts fabricated or merely illustrative candidate records into the real update queue.
    4. Only genuine legal updates from official sources may be staged, defaulting to unverified or needs-recheck.
    5. The automatic crawler never publishes changes autonomously.
    """
    import urllib.request
    import ssl
    import time

    now = timezone.now()
    sync_info = DatabaseSyncInfo.get_info()
    sync_info.last_source_check = now

    sources_to_check = [
        ("India Code Portal", "https://www.indiacode.gov.in/"),
        ("Official Gazette of India", "https://egazette.gov.in/"),
        ("Ministry of Law and Justice", "https://lawmin.gov.in/"),
    ]

    # Normal TLS verification - standard SSL context
    ctx = ssl.create_default_context()

    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) LegalGuide-Compliance/1.0'
    }

    results = []
    success_count = 0

    for name, url in sources_to_check:
        t0 = time.time()
        req = urllib.request.Request(url, headers=headers)
        try:
            with urllib.request.urlopen(req, context=ctx, timeout=6) as resp:
                elapsed = int((time.time() - t0) * 1000)
                code = resp.status
                results.append(f"{name} ({url}) reachable [HTTP {code}, {elapsed}ms]")
                success_count += 1
        except Exception as e:
            elapsed = int((time.time() - t0) * 1000)
            results.append(f"{name} ({url}) limited [{type(e).__name__}: {str(e)[:50]}]")

    summary_str = "; ".join(results)
    if success_count == len(sources_to_check):
        sync_info.last_source_check_status = f"Reachable ({success_count}/{len(sources_to_check)} sources online)"
    elif success_count > 0:
        sync_info.last_source_check_status = f"Partial ({success_count}/{len(sources_to_check)} sources online)"
    else:
        sync_info.last_source_check_status = "Unreachable (0 sources reached)"

    sync_info.last_source_check_summary = summary_str
    sync_info.save()

    # Zero fabricated records. Official updates require authenticated administrative review
    # and genuine Gazette notifications.
    created_records = []
    return created_records


def approve_update(record_id: int, admin_user: str = "admin", notes: str = "") -> LegalUpdateRecord:
    """
    Approves a pending update record:
    State transition: PENDING_REVIEW / DETECTED / NEEDS_VERIFICATION -> APPROVED.
    
    CRITICAL RULE:
    Approval authorizes the update, but does NOT publish it to the canonical database.
    Publication is an explicit subsequent step so the administrator can perform
    a final review before it goes live to users.
    """
    record = LegalUpdateRecord.objects.get(id=record_id)
    if record.status == "rejected":
        raise ValueError(f"Record {record_id} is rejected and cannot be approved.")
    if record.status in ["approved", "published"]:
        raise ValueError(f"Record {record_id} is already {record.status}.")

    # Validate complete record before marking approved
    validate_legal_update_record(record, raise_exception=True)

    record.status = "approved"
    record.reviewed_by = admin_user
    record.reviewed_at = timezone.now()
    record.verified_by = admin_user
    record.verified_at = timezone.now()
    if notes:
        record.admin_notes = f"{record.admin_notes}\n[Approval Notes]: {notes}".strip()
    record.save()
    return record


@transaction.atomic
def publish_update(record_id: int, admin_user: str = "admin") -> tuple:
    """
    Publishes an approved update to the canonical backend database:
    1. Validates the complete legal record.
    2. Ensures state is APPROVED (unapproved records cannot be published).
    3. Preserves previous version in LegalSectionVersion (version history).
    4. Applies changes to canonical LegalSection (or creates new section/law).
    5. Bumps global database synchronization version (DatabaseSyncInfo.server_version).
    6. Records publication timestamp and administrator ID.
    7. Creates user-visible PublishedLegalUpdate notification.
    8. Ensures all operations occur inside an atomic transaction.
    """
    record = LegalUpdateRecord.objects.select_for_update().get(id=record_id)
    if record.status == "rejected":
        raise ValueError(f"Record {record_id} has been rejected and cannot be published.")
    if record.status == "published":
        raise ValueError(f"Record {record_id} is already published.")
    if record.status not in ["approved"]:
        raise ValueError(
            f"Record {record_id} must be approved before publication. Current status: '{record.status}'."
        )

    validate_legal_update_record(record, raise_exception=True)

    section = record.section
    old_version = 0

    # 1. Update Existing Section or Create New Section
    if section:
        old_version = section.version
        # Archive current active version to LegalSectionVersion
        LegalSectionVersion.objects.create(
            section=section,
            version=section.version,
            legal_text=section.legal_text,
            simple_explanation=section.simple_explanation,
            punishment=section.punishment,
            effective_date=section.effective_date,
            amendment_info=section.amendment_info,
            status="historical",
            source=section.source,
            source_name=section.source_name,
            verified_by=admin_user,
        )

        # Handle Repeals vs Amendments
        if record.update_type in ["repeal", "repealed_provision"]:
            section.status = "repealed"
            section.version += 1
            section.last_verified = date.today()
            section.updated_at = timezone.now()
            section.save()
        else:
            section.legal_text = record.proposed_legal_text
            if record.proposed_title:
                section.title = record.proposed_title
            if record.proposed_simple_explanation:
                section.simple_explanation = record.proposed_simple_explanation
            if record.proposed_punishment:
                section.punishment = record.proposed_punishment
            if record.proposed_effective_date:
                section.effective_date = record.proposed_effective_date
            if record.proposed_amendment_info:
                section.amendment_info = record.proposed_amendment_info
            section.source = record.source_url
            section.source_name = record.source_name
            section.last_verified = date.today()
            section.version += 1
            section.status = "current"
            section.updated_at = timezone.now()
            section.save()
    else:
        # New section creation
        target_law = record.law
        clean_act_name = (record.act_name or "").strip()
        if not target_law and clean_act_name:
            target_law = (
                Law.objects.filter(name__iexact=clean_act_name).first()
                or Law.objects.filter(short_name__iexact=clean_act_name).first()
                or Law.objects.filter(name__icontains=clean_act_name).first()
            )

        # Support genuinely new Act when explicitly indicated or update_type == 'new_act'
        if not target_law and record.update_type == "new_act":
            if not clean_act_name:
                raise ValidationError("Cannot publish new Act: Act name is required.")
            eff_year = record.proposed_effective_date.year if record.proposed_effective_date else timezone.now().year
            category = Category.objects.filter(name__icontains="Criminal").first() or Category.objects.first()
            if not category:
                category = Category.objects.create(name="General", description="General statutory laws")

            # Check for duplicate Act before creating
            target_law = Law.objects.filter(name__iexact=clean_act_name).first()
            if not target_law:
                target_law = Law.objects.create(
                    name=clean_act_name,
                    short_name=clean_act_name[:50],
                    year=eff_year,
                    category=category,
                    act_number=f"Act of {eff_year}",
                    source_url=record.source_url or "https://www.indiacode.gov.in/",
                    source_name=record.source_name or "Official Government Gazette",
                    status="current",
                )

        if not target_law:
            raise ValidationError(
                f"Cannot publish section: Target Act '{record.act_name or 'Unspecified'}' is not recognized. "
                f"An update must be associated with a verified Act and cannot use a fallback Act."
            )

        # Prevent duplicate sections by checking existing section by provision_key or (law, section_number)
        import re
        clean_num = re.sub(r'[^a-zA-Z0-9]', '_', str(record.section_number).lower()).strip('_')
        clean_num = re.sub(r'_+', '_', clean_num)
        prov_key = f"{target_law.id}_{clean_num}"

        existing_sec = (
            LegalSection.objects.filter(provision_key=prov_key).first()
            or LegalSection.objects.filter(law=target_law, section_number=record.section_number).first()
        )

        if existing_sec:
            # Update existing section transactionally and archive previous version in LegalSectionVersion
            old_version = existing_sec.version
            LegalSectionVersion.objects.create(
                section=existing_sec,
                version=old_version,
                legal_text=existing_sec.legal_text,
                simple_explanation=existing_sec.simple_explanation,
                purpose=existing_sec.purpose,
                punishment=existing_sec.punishment,
                effective_date=existing_sec.effective_date,
                amendment_info=existing_sec.amendment_info,
                source_name=existing_sec.source_name,
                source_url=existing_sec.source,
                status="historical",
                verified_by=admin_user,
                archived_at=timezone.now(),
                change_summary=f"Superseded by published update {record.id}",
            )
            existing_sec.title = record.proposed_title
            existing_sec.legal_text = record.proposed_legal_text
            if record.proposed_simple_explanation:
                existing_sec.simple_explanation = record.proposed_simple_explanation
            if record.proposed_punishment:
                existing_sec.punishment = record.proposed_punishment
            if record.proposed_effective_date:
                existing_sec.effective_date = record.proposed_effective_date
            if record.proposed_amendment_info:
                existing_sec.amendment_info = record.proposed_amendment_info
            existing_sec.source = record.source_url
            existing_sec.source_name = record.source_name
            existing_sec.last_verified = date.today()
            existing_sec.version += 1
            existing_sec.status = "current"
            existing_sec.updated_at = timezone.now()
            existing_sec.save()
            section = existing_sec
        else:
            section = LegalSection.objects.create(
                law=target_law,
                section_number=record.section_number,
                provision_key=prov_key,
                title=record.proposed_title,
                legal_text=record.proposed_legal_text,
                simple_explanation=record.proposed_simple_explanation or record.proposed_title,
                purpose=record.proposed_simple_explanation or record.proposed_title,
                punishment=record.proposed_punishment,
                effective_date=record.proposed_effective_date,
                amendment_info=record.proposed_amendment_info,
                source=record.source_url,
                source_name=record.source_name,
                last_verified=date.today(),
                version=1,
                status="current",
            )
            old_version = 0

        record.section = section
        record.law = target_law

    # 2. Update record status to published with audit trail
    record.status = "published"
    record.published_by = admin_user
    record.published_at = timezone.now()
    record.previous_version = old_version
    record.approved_version = section.version
    record.save()

    # 3. Bump global synchronization version to notify clients via delta sync
    sync_info = DatabaseSyncInfo.get_info()
    sync_info.server_version += 1
    sync_info.last_sync_date = timezone.now()
    sync_info.save()

    # 4. Create user-visible PublishedLegalUpdate notification
    update_type_map = {
        "amendment": "amendment",
        "changed_section": "amendment",
        "new_section": "new_section",
        "repeal": "repeal",
        "repealed_provision": "repeal",
        "changed_penalty": "penalty_change",
        "new_act": "new_act",
        "rule_change": "rule_change",
        "correction": "amendment",
        "commencement_change": "rule_change",
    }
    pub_type = update_type_map.get(record.update_type, "amendment")
    law_name = section.law.name if section.law else (record.act_name or "Indian Law")
    law_short = section.law.short_name if section.law else ""

    pub_notif = PublishedLegalUpdate.objects.create(
        title=f"{law_short or law_name} — Section {section.section_number} Updated",
        description=(
            f"{section.title} (Section {section.section_number}) has been verified and published "
            f"under {law_short or law_name}."
        ),
        update_type=pub_type,
        source_update_record=record,
        affected_law_name=law_name,
        affected_law_short_name=law_short,
        affected_section=section.section_number,
        old_version=old_version if old_version > 0 else None,
        new_version=section.version,
        official_source_name=record.source_name,
        official_source_url=record.source_url,
        effective_date=record.proposed_effective_date,
        last_verified_at=date.today(),
    )

    return section, pub_notif


@transaction.atomic
def approve_and_publish_update(record_id: int, admin_user: str = "admin", notes: str = "") -> tuple:
    """Convenience method: performs validation, approval, and publication atomically."""
    approve_update(record_id, admin_user=admin_user, notes=notes)
    return publish_update(record_id, admin_user=admin_user)


def reject_update(record_id: int, admin_user: str = "admin", reason: str = "") -> LegalUpdateRecord:
    """
    Rejects a pending or approved update record.
    Requires a non-empty explanation/reason.
    State transition: PENDING_REVIEW / NEEDS_VERIFICATION / APPROVED -> REJECTED.
    """
    if not reason or not reason.strip():
        raise ValueError("A clear rejection reason or note is required.")

    record = LegalUpdateRecord.objects.get(id=record_id)
    if record.status == "published":
        raise ValueError("Cannot reject an update that has already been published to the canonical database.")

    record.status = "rejected"
    record.reviewed_by = admin_user
    record.reviewed_at = timezone.now()
    record.verified_by = admin_user
    record.verified_at = timezone.now()
    record.admin_notes = f"[Rejected by {admin_user}]: {reason.strip()}"
    record.save()
    return record


def request_verification_update(record_id: int, admin_user: str = "admin", notes: str = "") -> LegalUpdateRecord:
    """
    Marks an update as requiring additional verification or correction before approval.
    State transition: PENDING_REVIEW / DETECTED -> NEEDS_VERIFICATION.
    """
    if not notes or not notes.strip():
        raise ValueError("Notes describing the required verification or correction are required.")

    record = LegalUpdateRecord.objects.get(id=record_id)
    if record.status in ["published", "rejected"]:
        raise ValueError(f"Cannot request verification for a record that is already {record.status}.")

    record.status = "needs_verification"
    record.reviewed_by = admin_user
    record.reviewed_at = timezone.now()
    record.admin_notes = f"[Verification Requested by {admin_user}]: {notes.strip()}"
    record.save()
    return record


def get_sync_overview():
    sync_info = DatabaseSyncInfo.get_info()
    return {
        "server_version": sync_info.server_version,
        "sync_version": sync_info.server_version,
        "last_sync_date": sync_info.last_sync_date.isoformat() if sync_info.last_sync_date else None,
        "last_synchronized": sync_info.last_sync_date.isoformat() if sync_info.last_sync_date else None,
        "last_source_check": sync_info.last_source_check.isoformat() if sync_info.last_source_check else None,
        "last_source_check_status": getattr(sync_info, 'last_source_check_status', 'verified'),
        "primary_source_name": sync_info.primary_source_name,
        "primary_source_url": sync_info.primary_source_url,
        "total_acts": Law.objects.count(),
        "total_sections": LegalSection.objects.count(),
        "pending_updates_count": LegalUpdateRecord.objects.filter(
            status__in=["pending_review", "pending", "detected", "needs_verification"]
        ).count(),
        "approved_updates_count": LegalUpdateRecord.objects.filter(status="approved").count(),
        "published_updates_count": LegalUpdateRecord.objects.filter(status="published").count(),
        "rejected_updates_count": LegalUpdateRecord.objects.filter(status="rejected").count(),
        "last_verified_date": date.today().isoformat(),
    }

