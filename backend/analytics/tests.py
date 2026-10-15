from datetime import timedelta
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from accounts.models import UserProfile, UserRoleAuditLog
from analytics.models import (
    AIQuestionStat,
    FeatureUsageStat,
    LawViewStat,
    SearchStat,
    SectionViewStat,
    UserActivityLog,
)
from laws.models import Category, DatabaseSyncInfo, Law, LegalSection

User = get_user_model()


class AdminAnalyticsSecurityAndFunctionalityTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Admin user (reusing the existing pattern)
        self.admin_user = User.objects.create_user(
            username="TestAdmin",
            email="admin@legalguide.org",
            password="AdminPassword123!",
            is_staff=True,
            is_superuser=True,
        )
        self.admin_token, _ = Token.objects.get_or_create(user=self.admin_user)

        # Normal user
        self.normal_user = User.objects.create_user(
            username="TestNormal",
            email="normal@legalguide.org",
            password="NormalPassword123!",
            is_staff=False,
            is_superuser=False,
        )
        self.normal_token, _ = Token.objects.get_or_create(user=self.normal_user)

        # Setup mock legal content for sync and views
        self.category = Category.objects.create(name="Criminal Law")
        self.law = Law.objects.create(name="Bharatiya Nyaya Sanhita", short_name="BNS", category=self.category)
        self.section = LegalSection.objects.create(
            law=self.law,
            section_number="303",
            title="Theft",
            legal_text="Whoever intending to take dishonestly...",
            simple_explanation="Theft occurs when...",
            purpose="Protects property...",
        )
        DatabaseSyncInfo.objects.get_or_create(id=1, defaults={"server_version": 1})

    def test_anonymous_user_cannot_access_admin_analytics(self):
        """Unauthenticated requests must be rejected."""
        response = self.client.get("/api/admin/analytics/")
        self.assertIn(response.status_code, [status.HTTP_401_UNAUTHORIZED, status.HTTP_403_FORBIDDEN])

    def test_normal_user_cannot_access_admin_analytics(self):
        """Authenticated normal users (without ADMIN role) MUST receive 403 Forbidden."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.normal_token.key}")
        response = self.client.get("/api/admin/analytics/")
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)

    def test_admin_user_can_access_all_16_analytics_metrics(self):
        """Admin users receive 200 OK with all 16 metrics populated."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        response = self.client.get("/api/admin/analytics/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.json()

        # Verify key metrics exist
        self.assertIn("total_registered_users", data)
        self.assertIn("active_users_today", data)
        self.assertIn("active_users_this_week", data)
        self.assertIn("active_users_this_month", data)
        self.assertIn("new_users_today", data)
        self.assertIn("new_users_this_week", data)
        self.assertIn("new_users_this_month", data)
        self.assertIn("currently_active_users", data)
        self.assertIn("total_ai_questions", data)
        self.assertIn("ai_questions_today", data)
        self.assertIn("total_law_searches", data)
        self.assertIn("most_searched_laws", data)
        self.assertIn("most_viewed_sections", data)
        self.assertIn("most_used_features", data)
        self.assertIn("database_sync", data)
        self.assertIn("backend_status", data)

        # Check DB sync info
        self.assertGreaterEqual(data["database_sync"]["total_sections"], 1)
        self.assertEqual(data["backend_status"]["status"], "operational")

    def test_batch_tracking_endpoint(self):
        """Clients (online and offline-synced) can report batched events."""
        payload = {
            "events": [
                {"type": "feature", "name": "law_search", "count": 3},
                {"type": "search", "query": "bns section 303"},
                {"type": "section_view", "section_id": self.section.id, "title": self.section.title, "law_name": "BNS"},
                {"type": "law_view", "law_id": self.law.id, "law_name": self.law.name},
            ]
        }
        response = self.client.post("/api/analytics/track/", payload, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json()["processed"], 4)

        # Verify counts in database
        self.assertTrue(SearchStat.objects.filter(query="bns section 303").exists())
        self.assertTrue(SectionViewStat.objects.filter(section_id=self.section.id).exists())
        self.assertTrue(LawViewStat.objects.filter(law_id=self.law.id).exists())
        fstat = FeatureUsageStat.objects.filter(feature_name="law_search").first()
        self.assertIsNotNone(fstat)
        self.assertGreaterEqual(fstat.count, 3)

    def test_heartbeat_updates_user_last_active_at(self):
        """Heartbeat updates last_active_at for authenticated users without spamming."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.normal_token.key}")
        response = self.client.post("/api/analytics/heartbeat/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()["authenticated"])

        self.normal_user.profile.refresh_from_db()
        self.assertIsNotNone(self.normal_user.profile.last_active_at)

    def test_admin_user_list_endpoint(self):
        """Admin can retrieve user statistics without exposing sensitive secrets."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        response = self.client.get("/api/admin/users/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        users = response.json()["users"]
        self.assertGreaterEqual(len(users), 2)
        for u in users:
            self.assertIn("id", u)
            self.assertIn("username", u)
            self.assertIn("role", u)
            self.assertNotIn("password", u)
            self.assertNotIn("token", u)

    def test_admin_deletes_citizen_successfully(self):
        """Admin can delete a citizen user account from central database."""
        citizen = User.objects.create_user(
            username="delete_me_citizen",
            email="delete_me@legalguide.org",
            password="CitizenPassword123!",
        )
        initial_count = User.objects.count()

        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        response = self.client.delete(
            "/api/admin/users/",
            {"user_id": citizen.id},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.json().get("status"), "deleted")
        self.assertEqual(User.objects.count(), initial_count - 1)
        self.assertFalse(User.objects.filter(id=citizen.id).exists())

    def test_admin_cannot_delete_own_account(self):
        """Admin is strictly blocked from deleting their own admin account."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        response = self.client.delete(
            "/api/admin/users/",
            {"user_id": self.admin_user.id},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("own admin account", response.json().get("error", "").lower())
        self.assertTrue(User.objects.filter(id=self.admin_user.id).exists())

    def test_admin_deletes_another_admin_policy(self):
        """Standard admin without superuser status cannot delete another admin; superusers cannot be deleted."""
        # Create non-superuser admin
        staff_admin = User.objects.create_user(
            username="StaffAdmin",
            email="staff@legalguide.org",
            password="StaffPassword123!",
            is_staff=True,
            is_superuser=False,
        )
        staff_token, _ = Token.objects.get_or_create(user=staff_admin)

        target_admin = User.objects.create_user(
            username="TargetAdmin",
            email="target@legalguide.org",
            password="TargetPassword123!",
            is_staff=True,
            is_superuser=False,
        )

        # Staff admin attempts to delete target admin -> blocked by policy (403)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {staff_token.key}")
        res = self.client.delete(
            "/api/admin/users/",
            {"user_id": target_admin.id},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(User.objects.filter(id=target_admin.id).exists())

        # Superuser admin attempts to delete superuser -> blocked (400)
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        res2 = self.client.delete(
            "/api/admin/users/",
            {"user_id": self.admin_user.id},
            format="json",
        )
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)

    def test_non_admin_cannot_delete_user(self):
        """Normal citizen cannot call delete endpoint directly."""
        citizen_victim = User.objects.create_user(
            username="victim_user",
            email="victim@legalguide.org",
            password="VictimPassword123!",
        )
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.normal_token.key}")
        response = self.client.delete(
            "/api/admin/users/",
            {"user_id": citizen_victim.id},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertTrue(User.objects.filter(id=citizen_victim.id).exists())

    def test_deleted_user_cannot_login_after_deletion(self):
        """Once deleted, the user cannot log in from any client device."""
        temp_user = User.objects.create_user(
            username="login_test_user",
            email="login_test@legalguide.org",
            password="TestLoginPass123!",
        )
        # Login works before deletion
        login_res1 = self.client.post(
            "/api/auth/login/",
            {"username": "login_test_user", "password": "TestLoginPass123!"},
            format="json",
        )
        self.assertEqual(login_res1.status_code, status.HTTP_200_OK)

        # Admin deletes the user
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.admin_token.key}")
        del_res = self.client.delete(
            "/api/admin/users/",
            {"user_id": temp_user.id},
            format="json",
        )
        self.assertEqual(del_res.status_code, status.HTTP_200_OK)

        # Login fails after deletion (401 or 400 Invalid username or password)
        self.client.credentials()  # clear credentials
        login_res2 = self.client.post(
            "/api/auth/login/",
            {"username": "login_test_user", "password": "TestLoginPass123!"},
            format="json",
        )
        self.assertIn(login_res2.status_code, [status.HTTP_400_BAD_REQUEST, status.HTTP_401_UNAUTHORIZED])


class AdminPromotionAndAuthorizationTests(TestCase):
    def setUp(self):
        self.client = APIClient()

        # Primary admin (superuser)
        self.primary_admin = User.objects.create_user(
            username="PrimaryAdmin",
            email="primary@legalguide.org",
            password="PrimaryAdminPass123!",
            is_staff=True,
            is_superuser=True,
        )
        self.primary_admin_token, _ = Token.objects.get_or_create(user=self.primary_admin)

        # Dinesh_Admin account (critical to preserve)
        self.dinesh_admin = User.objects.create_user(
            username="Dinesh_Admin",
            email="dinesh@legalguide.org",
            password="DineshAdminPass123!",
            is_staff=True,
            is_superuser=True,
        )
        self.dinesh_admin_token, _ = Token.objects.get_or_create(user=self.dinesh_admin)

        # Regular citizen user
        self.citizen_user = User.objects.create_user(
            username="citizen_jane",
            email="jane@example.com",
            password="CitizenPassword123!",
            is_staff=False,
            is_superuser=False,
        )
        self.citizen_token, _ = Token.objects.get_or_create(user=self.citizen_user)

    def test_cannot_delete_dinesh_admin(self):
        """Primary Dinesh_Admin account cannot be deleted by any administrator."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.primary_admin_token.key}")
        response = self.client.delete(
            "/api/admin/users/",
            {"username": "Dinesh_Admin"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(User.objects.filter(username="Dinesh_Admin").exists())

    def test_cannot_delete_last_remaining_admin(self):
        """If only one administrator exists, deleting that admin must be prevented."""
        # Delete secondary admin accounts so only Dinesh_Admin remains
        self.primary_admin.delete()
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.dinesh_admin_token.key}")

        # Attempt to delete self or only admin
        response = self.client.delete(
            "/api/admin/users/",
            {"user_id": self.dinesh_admin.id},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertTrue(User.objects.filter(id=self.dinesh_admin.id).exists())

    def test_user_directory_privacy_no_secrets_exposed(self):
        """User Directory strictly excludes password hashes, tokens, or auth secrets."""
        self.client.credentials(HTTP_AUTHORIZATION=f"Token {self.primary_admin_token.key}")
        response = self.client.get("/api/admin/users/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        users = response.json().get("users", [])
        self.assertGreaterEqual(len(users), 1)

        sensitive_keys = {"password", "password_hash", "token", "auth_token", "secret", "private_key"}
        for u in users:
            keys_present = set(u.keys())
            self.assertTrue(sensitive_keys.isdisjoint(keys_present), f"Sensitive key found in user card: {keys_present & sensitive_keys}")

