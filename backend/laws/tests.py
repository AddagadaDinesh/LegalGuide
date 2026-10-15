from datetime import date
from django.test import TestCase
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from rest_framework import status

from laws.models import (
    Category,
    Law,
    LegalSection,
    LegalSectionVersion,
    LegalUpdateRecord,
    DatabaseSyncInfo,
    PublishedLegalUpdate,
)
from laws.updater import (
    approve_update,
    check_official_sources,
    publish_update,
    reject_update,
    validate_legal_update_record,
)

User = get_user_model()


class LegalUpdateWorkflowTests(TestCase):
    """
    Exhaustive tests for the complete Legal Update, Admin Review, Publication,
    and Synchronization pipeline.
    """

    def setUp(self):
        self.client = APIClient()
        self.category = Category.objects.create(name="Criminal Law", description="Offences and Penalties")
        self.law = Law.objects.create(
            name="Bharatiya Nyaya Sanhita, 2023",
            short_name="BNS 2023",
            category=self.category,
            year=2023,
            act_number="Act No. 45 of 2023",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            source_name="India Code — Ministry of Law & Justice, Govt. of India",
            status="current",
        )
        self.sync_info = DatabaseSyncInfo.get_info()
        self.sync_info.server_version = 1
        self.sync_info.save()

        # Regular citizen user
        self.citizen = User.objects.create_user(
            username="citizen_user",
            email="citizen@example.com",
            password="Password123!",
        )

        # Admin user
        self.admin = User.objects.create_user(
            username="dinesh_admin",
            email="admin@legalguide.org",
            password="AdminPassword123!",
            is_staff=True,
            is_superuser=True,
        )

    def test_1_pending_update_remains_isolated_from_public_sync(self):
        """A pending update MUST NEVER appear in public user sync or published updates."""
        pending_record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            verification_status="verified",
            proposed_title="Causing death by negligence",
            existing_legal_text="",
            proposed_legal_text=(
                "Section 106. Causing death by negligence.—\n"
                "(1) Whoever causes the death of any person by doing any rash or negligent act..."
            ),
            proposed_simple_explanation="Punishment for rash or negligent acts causing death.",
            proposed_punishment="Up to 5 years imprisonment and fine (2 years for medical practitioner).",
            proposed_effective_date=date(2024, 7, 1),
            commencement_status="In Force",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            source_name="India Code — Act No. 45 of 2023",
            source_publication_date=date(2024, 2, 23),
        )

        # 1. Public sync does NOT include section 106
        res_sync = self.client.get("/api/laws/sync/")
        self.assertEqual(res_sync.status_code, status.HTTP_200_OK)
        sections = res_sync.data["sections"]
        self.assertFalse(any(s["section_number"] == "106" for s in sections))

        # 2. Public published-updates does NOT include this record
        res_pub = self.client.get("/api/legal-updates/")
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)
        self.assertEqual(res_pub.data["count"], 0)

    def test_2_unauthenticated_or_non_admin_cannot_approve_or_publish(self):
        """Only authenticated administrators can approve or publish updates."""
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 text",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
        )

        # Anonymous approval attempt
        res_anon = self.client.post("/api/admin/legal-updates/approve/", {"update_id": record.id})
        self.assertIn(res_anon.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        # Normal citizen approval attempt
        self.client.force_authenticate(user=self.citizen)
        res_citizen = self.client.post("/api/admin/legal-updates/approve/", {"update_id": record.id})
        self.assertEqual(res_citizen.status_code, status.HTTP_403_FORBIDDEN)

        # Normal citizen publish attempt
        res_citizen_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id})
        self.assertEqual(res_citizen_pub.status_code, status.HTTP_403_FORBIDDEN)

    def test_3_admin_approves_update_without_premature_publishing(self):
        """Admin approval transitions status to 'approved' but does NOT publish to canonical database."""
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            verification_status="verified",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 text",
            proposed_simple_explanation="Explanation of Section 106",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            proposed_effective_date=date(2024, 7, 1),
        )

        self.client.force_authenticate(user=self.admin)
        res_app = self.client.post(
            "/api/admin/legal-updates/approve/",
            {"update_id": record.id, "notes": "Verified against Gazette Notification S.O. 850(E)."},
        )
        self.assertEqual(res_app.status_code, status.HTTP_200_OK)

        record.refresh_from_db()
        self.assertEqual(record.status, "approved")
        self.assertEqual(record.reviewed_by, "dinesh_admin")
        self.assertIn("Verified against Gazette Notification", record.admin_notes)

        # Active canonical database MUST NOT contain the section yet
        self.assertFalse(LegalSection.objects.filter(section_number="106").exists())
        self.assertEqual(PublishedLegalUpdate.objects.count(), 0)

    def test_4_unapproved_update_cannot_be_published(self):
        """An update in 'pending_review' cannot be directly published without prior approval."""
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 text",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            proposed_effective_date=date(2024, 7, 1),
        )

        self.client.force_authenticate(user=self.admin)
        res_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id})
        self.assertEqual(res_pub.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("must be approved before publication", res_pub.data["error"])

    def test_5_full_approval_publication_and_delta_sync_workflow(self):
        """
        Complete end-to-end workflow:
        1. Stage real pending update
        2. Admin approves with notes
        3. Admin publishes
        4. Verifies canonical section creation, sync version bump, published notification
        5. Verifies delta sync delivers the new section to clients
        """
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            verification_status="verified",
            proposed_title="Causing death by negligence",
            proposed_legal_text=(
                "Section 106. Causing death by negligence.—\n"
                "(1) Whoever causes the death of any person by doing any rash or negligent act "
                "not amounting to culpable homicide, shall be punished with imprisonment of either "
                "description for a term which may extend to five years, and shall also be liable to fine; "
                "and if such act is done by a registered medical practitioner while performing medical "
                "procedure, he shall be punished with imprisonment of either description for a term which "
                "may extend to two years, and shall also be liable to fine.\n"
                "(2) Whoever causes the death of any person by rash and negligent driving of vehicle not "
                "amounting to culpable homicide, and escapes without reporting it to a police officer or a "
                "Magistrate soon after the incident, shall be punished with imprisonment of either "
                "description of a term which may extend to ten years, and shall also be liable to fine."
            ),
            proposed_simple_explanation=(
                "Section 106 of BNS 2023 replaces IPC Section 304A. Sub-section (1) punishes rash or "
                "negligent acts causing death with up to 5 years imprisonment (2 years for medical procedures). "
                "Note: Sub-section (2) (hit-and-run) is stayed by Notification S.O. 850(E) and is not yet commenced."
            ),
            proposed_punishment="Up to 5 years jail and fine (s.106(1)); 2 years for registered medical practitioners.",
            proposed_effective_date=date(2024, 7, 1),
            commencement_status="In Force",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            source_name="India Code — Bharatiya Nyaya Sanhita, 2023 (Act No. 45 of 2023)",
            source_publication_date=date(2024, 2, 23),
        )

        self.client.force_authenticate(user=self.admin)

        # Step A: Admin Approves
        res_app = self.client.post(
            "/api/admin/legal-updates/approve/",
            {"update_id": record.id, "notes": "Approved by Administrator after official Gazette verification."},
        )
        self.assertEqual(res_app.status_code, status.HTTP_200_OK)

        # Step B: Admin Publishes
        res_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id})
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)

        # Step C: Verify canonical database state
        sec = LegalSection.objects.get(section_number="106")
        self.assertEqual(sec.title, "Causing death by negligence")
        self.assertEqual(sec.version, 1)
        self.assertEqual(sec.status, "current")
        self.assertEqual(sec.law, self.law)

        # Step D: Verify DatabaseSyncInfo bumped
        self.sync_info.refresh_from_db()
        self.assertEqual(self.sync_info.server_version, 2)

        # Step E: Verify PublishedLegalUpdate created
        pub_notif = PublishedLegalUpdate.objects.get(affected_section="106")
        self.assertIn("Section 106 Updated", pub_notif.title)

        # Step F: Client Delta Sync receives the new provision
        client_sync = self.client.get("/api/laws/sync/")
        self.assertEqual(client_sync.status_code, status.HTTP_200_OK)
        synced_sections = client_sync.data["sections"]
        synced_106 = next((s for s in synced_sections if s["section_number"] == "106"), None)
        self.assertIsNotNone(synced_106)
        self.assertEqual(synced_106["title"], "Causing death by negligence")

        # Step G: Public legal-updates endpoint delivers the publication notification
        client_updates = self.client.get("/api/legal-updates/")
        self.assertEqual(client_updates.status_code, status.HTTP_200_OK)
        self.assertEqual(client_updates.data["count"], 1)
        self.assertEqual(client_updates.data["updates"][0]["affected_section"], "106")

    def test_6_rejected_updates_never_reach_users_and_cannot_be_published(self):
        """Rejected updates must NEVER reach users or be published to canonical database."""
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="999",
            update_type="amendment",
            status="pending_review",
            proposed_title="Defective Proposed Amendment",
            proposed_legal_text="Unverified draft text",
            source_url="https://example.com/unverified",
        )

        # 1. Admin rejects update with mandatory explanation
        self.client.force_authenticate(user=self.admin)
        res_reject = self.client.post(
            "/api/admin/legal-updates/reject/",
            {"update_id": record.id, "reason": "Official Gazette contradicts proposed text; notification was draft only."},
        )
        self.assertEqual(res_reject.status_code, status.HTTP_200_OK)
        record.refresh_from_db()
        self.assertEqual(record.status, "rejected")

        # 2. Public legal endpoints must NOT contain rejected record
        self.client.force_authenticate(user=None)
        res_sync = self.client.get("/api/laws/sync/")
        self.assertEqual(res_sync.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "999" for s in res_sync.data["sections"]))

        res_sections = self.client.get("/api/sections/")
        self.assertEqual(res_sections.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "999" for s in res_sections.data))

        res_pub = self.client.get("/api/legal-updates/")
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)
        self.assertEqual(res_pub.data["count"], 0)

        # 3. Attempting to publish or approve a rejected update must fail
        self.client.force_authenticate(user=self.admin)
        res_pub_attempt = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id})
        self.assertEqual(res_pub_attempt.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("rejected and cannot be published", res_pub_attempt.data["error"])

        res_app_attempt = self.client.post("/api/admin/legal-updates/approve/", {"update_id": record.id})
        self.assertEqual(res_app_attempt.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("rejected and cannot be approved", res_app_attempt.data["error"])

    def test_7_connecting_phone_or_sync_does_not_publish_or_reveal_pending_info(self):
        """
        When a phone connects to the internet and synchronizes, it must:
        - NEVER alter the status of pending update records.
        - NEVER publish pending records.
        - NEVER reveal pending text in the sync response.
        - NEVER bump server_version prematurely.
        """
        initial_version = self.sync_info.server_version
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="amendment",
            status="pending_review",
            verification_status="verified",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 pending text",
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            proposed_effective_date=date(2024, 7, 1),
        )

        # Simulate mobile client connecting and running delta sync with various timestamps
        client_sync_1 = self.client.get("/api/laws/sync/")
        self.assertEqual(client_sync_1.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "106" for s in client_sync_1.data["sections"]))

        client_sync_2 = self.client.get("/api/laws/sync/?since=2026-01-01T00:00:00Z")
        self.assertEqual(client_sync_2.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "106" for s in client_sync_2.data["sections"]))

        # Check that backend record status remains strictly unchanged
        record.refresh_from_db()
        self.assertEqual(record.status, "pending_review")
        self.assertIsNone(record.published_at)

        # Check server_version remained unbumped
        self.sync_info.refresh_from_db()
        self.assertEqual(self.sync_info.server_version, initial_version)

        # Canonical database still does NOT have the section
        self.assertFalse(LegalSection.objects.filter(section_number="106").exists())

    def test_8_amendment_preserves_old_version_and_history_in_legalsectionversion(self):
        """
        When an amendment is proposed:
        - The old active version remains active for ordinary users until publication.
        - Upon publication, the old version is preserved in LegalSectionVersion.
        - The canonical section increments its version counter.
        - Version history is accessible and audit fields are recorded.
        """
        # Create existing active section (v1)
        section = LegalSection.objects.create(
            law=self.law,
            section_number="303",
            title="Theft",
            legal_text="Whoever intending to take dishonestly any movable property... commits theft.",
            simple_explanation="Original definition of theft.",
            punishment="Imprisonment up to 3 years, or fine, or both.",
            version=1,
            status="current",
            source="https://www.indiacode.gov.in/",
            last_verified=date(2024, 1, 1),
        )

        # Stage amendment (v2 proposal) with community service proviso
        amendment_record = LegalUpdateRecord.objects.create(
            section=section,
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="303",
            update_type="amendment",
            status="pending_review",
            verification_status="verified",
            proposed_title="Theft (Amended with Community Service)",
            existing_legal_text=section.legal_text,
            proposed_legal_text=section.legal_text + "\nProvided that where value is less than 5000, community service.",
            proposed_simple_explanation="Amended explanation with community service for petty theft under Rs 5,000.",
            proposed_punishment="Up to 3 years imprisonment or fine; community service if value < 5000.",
            proposed_effective_date=date(2024, 7, 1),
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
            source_name="Gazette Notification S.O. 850(E)",
        )

        # 1. Ordinary users STILL see only v1
        res_user_sec = self.client.get("/api/sections/")
        self.assertEqual(res_user_sec.status_code, status.HTTP_200_OK)
        sec_data = next(s for s in res_user_sec.data if s["section_number"] == "303")
        self.assertEqual(sec_data["version"], 1)
        self.assertNotIn("community service", sec_data["legal_text"])

        # 2. Admin approves amendment — users STILL see only v1
        self.client.force_authenticate(user=self.admin)
        res_app = self.client.post("/api/admin/legal-updates/approve/", {"update_id": amendment_record.id})
        self.assertEqual(res_app.status_code, status.HTTP_200_OK)

        self.client.force_authenticate(user=None)
        res_user_sec_after_app = self.client.get("/api/sections/")
        sec_data_after_app = next(s for s in res_user_sec_after_app.data if s["section_number"] == "303")
        self.assertEqual(sec_data_after_app["version"], 1)
        self.assertNotIn("community service", sec_data_after_app["legal_text"])

        # 3. Admin publishes amendment
        self.client.force_authenticate(user=self.admin)
        res_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": amendment_record.id})
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)

        # 4. Verify version history in LegalSectionVersion
        historical_versions = LegalSectionVersion.objects.filter(section=section)
        self.assertEqual(historical_versions.count(), 1)
        v1_archived = historical_versions.first()
        self.assertEqual(v1_archived.version, 1)
        self.assertEqual(v1_archived.status, "historical")
        self.assertIn("Original definition of theft.", v1_archived.simple_explanation)
        self.assertEqual(v1_archived.verified_by, "dinesh_admin")

        # 5. Active section is now v2 with new content
        section.refresh_from_db()
        self.assertEqual(section.version, 2)
        self.assertIn("community service", section.legal_text)

        # 6. Delta sync now delivers v2 and the archived version
        self.client.force_authenticate(user=None)
        res_sync = self.client.get("/api/laws/sync/")
        self.assertEqual(res_sync.status_code, status.HTTP_200_OK)
        synced_303 = next(s for s in res_sync.data["sections"] if s["section_number"] == "303")
        self.assertEqual(synced_303["version"], 2)
        synced_versions = res_sync.data["versions"]
        self.assertTrue(any(v["version"] == 1 and v["section"] == section.id for v in synced_versions))

    def test_9_client_cannot_publish_by_supplying_status_in_request(self):
        """
        Clients must NEVER be allowed to publish updates by supplying a status in a request.
        Normal users cannot alter statuses, and admin PATCH endpoints reject status manipulation.
        """
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 pending text",
            source_url="https://www.indiacode.gov.in/",
        )

        # 1. Unauthenticated client attempting to POST to sections with status=published
        res_post_sec = self.client.post("/api/sections/", {"section_number": "106", "status": "published"})
        self.assertEqual(res_post_sec.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

        # 2. Citizen user attempting to POST or PATCH
        self.client.force_authenticate(user=self.citizen)
        res_citizen_post = self.client.post("/api/sections/", {"section_number": "106", "status": "published"})
        self.assertEqual(res_citizen_post.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

        res_citizen_sync = self.client.post("/api/laws/sync/", {"status": "published"})
        self.assertEqual(res_citizen_sync.status_code, status.HTTP_405_METHOD_NOT_ALLOWED)

        # 3. Citizen user calling admin publish endpoint
        res_citizen_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id, "status": "published"})
        self.assertEqual(res_citizen_pub.status_code, status.HTTP_403_FORBIDDEN)

        # 4. Record status remains strictly pending_review
        record.refresh_from_db()
        self.assertEqual(record.status, "pending_review")

    def test_10_approved_but_unpublished_update_remains_strictly_invisible_to_all_public_endpoints(self):
        """
        An update that is APPROVED by an admin but NOT yet published must remain
        completely invisible across all public endpoints:
        - /api/laws/sync/
        - /api/legal-updates/
        - /api/sections/
        """
        record = LegalUpdateRecord.objects.create(
            law=self.law,
            act_name="Bharatiya Nyaya Sanhita, 2023",
            section_number="106",
            update_type="new_section",
            status="pending_review",
            verification_status="verified",
            proposed_title="Causing death by negligence",
            proposed_legal_text="Section 106 pending text",
            proposed_simple_explanation="Causing death by negligence explanation",
            proposed_effective_date=date(2024, 7, 1),
            source_url="https://www.indiacode.gov.in/handle/123456789/20062",
        )

        # Admin approves
        self.client.force_authenticate(user=self.admin)
        res_app = self.client.post("/api/admin/legal-updates/approve/", {"update_id": record.id, "notes": "Approved for staging."})
        self.assertEqual(res_app.status_code, status.HTTP_200_OK)

        record.refresh_from_db()
        self.assertEqual(record.status, "approved")
        self.assertIsNone(record.published_at)

        # Now test from perspective of ordinary public user (anonymous)
        self.client.force_authenticate(user=None)

        # 1. /api/laws/sync/
        res_sync = self.client.get("/api/laws/sync/")
        self.assertEqual(res_sync.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "106" for s in res_sync.data["sections"]))

        # 2. /api/legal-updates/
        res_pub = self.client.get("/api/legal-updates/")
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)
        self.assertEqual(res_pub.data["count"], 0)

        # 3. /api/sections/
        res_sec = self.client.get("/api/sections/")
        self.assertEqual(res_sec.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "106" for s in res_sec.data))

        # 4. /api/sections/?law_id=...
        res_sec_law = self.client.get(f"/api/sections/?law_id={self.law.id}")
        self.assertEqual(res_sec_law.status_code, status.HTTP_200_OK)
        self.assertFalse(any(s["section_number"] == "106" for s in res_sec_law.data))

    def test_11_check_official_sources_endpoint_authorized_and_unauthorized(self):
        """
        Verify check-sources endpoint:
        - Admin user invokes endpoint -> returns HTTP 200 without TypeError.
        - Anonymous request -> HTTP 401.
        - Citizen request -> HTTP 403.
        """
        # 1. Anonymous request denied
        res_anon = self.client.post("/api/admin/legal-updates/check-sources/")
        self.assertIn(res_anon.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

        # 2. Citizen user denied
        self.client.force_authenticate(user=self.citizen)
        res_cit = self.client.post("/api/admin/legal-updates/check-sources/")
        self.assertEqual(res_cit.status_code, status.HTTP_403_FORBIDDEN)

        # 3. Admin user allowed and returns controlled structured response
        self.client.force_authenticate(user=self.admin)
        res_admin = self.client.post("/api/admin/legal-updates/check-sources/")
        self.assertEqual(res_admin.status_code, status.HTTP_200_OK)
        data = res_admin.data
        self.assertIn("message", data)
        self.assertIn("status", data)
        self.assertIn("summary", data)
        self.assertIn("new_updates_count", data)
        self.assertEqual(data["new_updates_count"], 0)

    def test_12_source_reachability_does_not_create_fabricated_verified_updates(self):
        """
        Reaching an official source does NOT create fabricated updates or mark them verified.
        No hardcoded provisions (BNS 303, MV 185, BNSS 107, Draft-Rule-4) are created.
        """
        initial_records_count = LegalUpdateRecord.objects.count()

        created = check_official_sources(requested_by="dinesh_admin")
        self.assertEqual(len(created), 0)
        self.assertEqual(LegalUpdateRecord.objects.count(), initial_records_count)

        # Sync info records reachability honestly without falsely claiming legal changes are verified
        sync_info = DatabaseSyncInfo.get_info()
        self.assertIsNotNone(sync_info.last_source_check)
        self.assertNotIn("Verified", sync_info.last_source_check_status)
        self.assertTrue(
            any(w in sync_info.last_source_check_status for w in ["Reachable", "Partial", "Unreachable"])
        )

    def test_13_publication_refuses_unsafe_fallback_to_arbitrary_act(self):
        """
        Attempting to publish a new section with an unknown Act must fail with a clear
        error and NEVER fall back to Law.objects.first().
        """
        # Create a second dummy law to verify it doesn't get arbitrarily picked
        other_law = Law.objects.create(
            name="Motor Vehicles Act, 1988",
            short_name="MVA 1988",
            category=self.category,
            year=1988,
            act_number="Act No. 59 of 1988",
            source_url="https://www.indiacode.gov.in/",
            status="current",
        )

        record = LegalUpdateRecord.objects.create(
            law=None,
            act_name="Completely Unknown Fictional Act, 2099",
            section_number="42",
            update_type="new_section",
            status="approved",
            verification_status="verified",
            proposed_title="Unknown Section Title",
            proposed_legal_text="Section text for unknown act",
            source_url="https://www.indiacode.gov.in/",
        )

        self.client.force_authenticate(user=self.admin)
        res_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": record.id})
        self.assertEqual(res_pub.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("not recognized", res_pub.data["error"].lower())

        # Verify no section was created under self.law or other_law
        self.assertFalse(LegalSection.objects.filter(section_number="42").exists())

    def test_14_publishing_existing_section_updates_in_place_and_preserves_version(self):
        """
        When publishing an update for an existing section, the section is updated in place,
        its version is incremented, and its previous version is archived in LegalSectionVersion.
        No duplicate LegalSection record is created.
        """
        existing_sec = LegalSection.objects.create(
            law=self.law,
            section_number="299",
            provision_key=f"{self.law.id}_299",
            title="Culpable homicide",
            legal_text="Original culpable homicide text",
            simple_explanation="Original simple explanation",
            version=1,
            status="current",
        )

        initial_total_sections = LegalSection.objects.count()

        update_record = LegalUpdateRecord.objects.create(
            section=existing_sec,
            law=self.law,
            act_name=self.law.name,
            section_number="299",
            update_type="amendment",
            status="approved",
            verification_status="verified",
            proposed_title="Culpable homicide (Amended)",
            proposed_legal_text="Amended culpable homicide text with clarified mental element",
            proposed_simple_explanation="Clarified simple explanation",
            source_url="https://www.indiacode.gov.in/",
        )

        self.client.force_authenticate(user=self.admin)
        res_pub = self.client.post("/api/admin/legal-updates/publish/", {"update_id": update_record.id})
        self.assertEqual(res_pub.status_code, status.HTTP_200_OK)

        # Section count MUST NOT increase (no duplicate section created)
        self.assertEqual(LegalSection.objects.count(), initial_total_sections)

        # Existing section was updated in place
        existing_sec.refresh_from_db()
        self.assertEqual(existing_sec.version, 2)
        self.assertEqual(existing_sec.title, "Culpable homicide (Amended)")
        self.assertEqual(existing_sec.legal_text, "Amended culpable homicide text with clarified mental element")

        # Previous version is in LegalSectionVersion
        historical = LegalSectionVersion.objects.filter(section=existing_sec, version=1).first()
        self.assertIsNotNone(historical)
        self.assertEqual(historical.legal_text, "Original culpable homicide text")


