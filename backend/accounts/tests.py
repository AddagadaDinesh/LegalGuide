import os
from unittest.mock import MagicMock, patch
from django.contrib.auth import get_user_model
from django.db import DatabaseError
from django.test import TestCase, override_settings
from rest_framework import status
from rest_framework.test import APIClient

from accounts.email_service import (
    build_login_html,
    build_login_text,
    build_welcome_html,
    build_welcome_text,
    send_login_notification_email,
    send_welcome_email,
)
from accounts.models import UserBookmark, UserProfile

User = get_user_model()


class RegistrationAndWelcomeEmailTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.signup_url = "/api/auth/signup/"

    @patch("accounts.views.send_welcome_email")
    def test_1_valid_new_registration(self, mock_email):
        mock_email.return_value = True

        payload = {
            "username": "newcitizen",
            "email": "citizen@legalguide.org",
            "password": "StrongPassword123!",
        }
        response = self.client.post(self.signup_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data.get("success"))
        self.assertTrue(response.data.get("emailSent"))
        self.assertIn("token", response.data)
        self.assertIn("user", response.data)

        # Check DB user
        user = User.objects.filter(username="newcitizen").first()
        self.assertIsNotNone(user)
        self.assertEqual(user.email, "citizen@legalguide.org")
        mock_email.assert_called_once_with(user=user)

    @patch("accounts.views.send_welcome_email")
    def test_2_missing_email(self, mock_email):
        payload = {
            "username": "noemailuser",
            "password": "StrongPassword123!",
        }
        response = self.client.post(self.signup_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(username="noemailuser").exists())
        mock_email.assert_not_called()

        # Also test empty string email
        payload_empty = {
            "username": "noemailuser2",
            "email": "   ",
            "password": "StrongPassword123!",
        }
        response2 = self.client.post(self.signup_url, payload_empty, format="json")
        self.assertEqual(response2.status_code, status.HTTP_400_BAD_REQUEST)
        mock_email.assert_not_called()

    @patch("accounts.views.send_welcome_email")
    def test_3_invalid_email(self, mock_email):
        payload = {
            "username": "bademailuser",
            "email": "not-a-valid-email",
            "password": "StrongPassword123!",
        }
        response = self.client.post(self.signup_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertFalse(User.objects.filter(username="bademailuser").exists())
        mock_email.assert_not_called()

    @patch("accounts.views.send_welcome_email")
    def test_4_existing_email(self, mock_email):
        User.objects.create_user(
            username="existinguser",
            email="existing@legalguide.org",
            password="ExistingPass123!",
        )

        # Attempt to signup with same email (case-insensitive)
        payload = {
            "username": "differentuser",
            "email": "EXISTING@legalguide.org",
            "password": "StrongPassword123!",
        }
        response = self.client.post(self.signup_url, payload, format="json")

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("email", response.data)
        self.assertFalse(User.objects.filter(username="differentuser").exists())
        mock_email.assert_not_called()

    @patch("accounts.serializers.User.objects.create_user")
    @patch("accounts.views.send_welcome_email")
    def test_5_database_failure(self, mock_email, mock_create):
        mock_create.side_effect = DatabaseError("Database unavailable")

        payload = {
            "username": "dbfailuser",
            "email": "dbfail@legalguide.org",
            "password": "StrongPassword123!",
        }
        with self.assertRaises(DatabaseError):
            self.client.post(self.signup_url, payload, format="json")

        mock_email.assert_not_called()

    @patch("accounts.views.send_welcome_email")
    def test_6_email_provider_failure_after_account_creation(self, mock_email):
        # Email service returns False (e.g. timeout or API 500)
        mock_email.return_value = False

        payload = {
            "username": "providerfailuser",
            "email": "providerfail@legalguide.org",
            "password": "StrongPassword123!",
        }
        response = self.client.post(self.signup_url, payload, format="json")

        # Account remains created and registration succeeds
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(response.data.get("success"))
        self.assertFalse(response.data.get("emailSent"))
        self.assertIn("token", response.data)

        # User is in DB and can authenticate
        user = User.objects.filter(username="providerfailuser").first()
        self.assertIsNotNone(user)

    @patch("accounts.views.send_welcome_email")
    def test_7_duplicate_registration_request_retry(self, mock_email):
        mock_email.return_value = True

        payload = {
            "username": "doubletapper",
            "email": "doubletap@legalguide.org",
            "password": "StrongPassword123!",
        }
        # First request succeeds
        res1 = self.client.post(self.signup_url, payload, format="json")
        self.assertEqual(res1.status_code, status.HTTP_201_CREATED)
        self.assertEqual(mock_email.call_count, 1)

        # Second request (duplicate tap / network retry) fails
        res2 = self.client.post(self.signup_url, payload, format="json")
        self.assertEqual(res2.status_code, status.HTTP_400_BAD_REQUEST)
        # Email call count remains 1
        self.assertEqual(mock_email.call_count, 1)

    @patch("accounts.views.send_welcome_email")
    def test_8_registration_from_multiple_devices(self, mock_email):
        initial_count = User.objects.count()

        # Phone 1
        payload_a = {
            "username": "phoneUserA",
            "email": "userA@gmail.com",
            "password": "Password123!",
        }
        res_a = self.client.post(self.signup_url, payload_a, format="json")
        self.assertEqual(res_a.status_code, status.HTTP_201_CREATED)

        # Phone 2
        payload_b = {
            "username": "phoneUserB",
            "email": "userB@gmail.com",
            "password": "Password123!",
        }
        res_b = self.client.post(self.signup_url, payload_b, format="json")
        self.assertEqual(res_b.status_code, status.HTTP_201_CREATED)

        # Central DB has both users
        self.assertEqual(User.objects.count(), initial_count + 2)
        user_a = User.objects.get(username="phoneUserA")
        user_b = User.objects.get(username="phoneUserB")
        self.assertEqual(user_a.email, "usera@gmail.com")
        self.assertEqual(user_b.email, "userb@gmail.com")

        # Both received email attempts with their respective user records
        self.assertEqual(mock_email.call_count, 2)


class EmailServiceUnitTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="testcitizen",
            email="test@legalguide.org",
            password="StrongPassword123!",
        )

    def test_welcome_email_content_and_sanitization(self):
        # Prevent HTML injection
        malicious_name = '<script>alert("hacked")</script>John & Doe'
        html = build_welcome_html(malicious_name, "test@legalguide.org")
        text = build_welcome_text(malicious_name, "test@legalguide.org")

        self.assertNotIn("<script>", html)
        self.assertIn("&lt;script&gt;", html)
        self.assertIn("Welcome to LegalGuide", html)
        self.assertIn("test@legalguide.org", html)
        self.assertIn("LegalGuide helps you access simplified legal information", html)
        self.assertIn("LegalGuide helps you access simplified legal information", text)
        self.assertIn("LegalGuide provides general legal information", html)
        self.assertIn("LegalGuide provides general legal information", text)

    def test_idempotent_email_sending(self):
        # First send succeeds via test mode
        with patch.dict("os.environ", {"EMAIL_PROVIDER": "test"}):
            first_sent = send_welcome_email(user=self.user)
            self.assertTrue(first_sent)
            self.assertTrue(first_sent.success)
            self.assertIsNone(first_sent.error)

            profile = UserProfile.objects.get(user=self.user)
            self.assertTrue(profile.welcome_email_sent)
            self.assertIsNotNone(profile.welcome_email_sent_at)

            # Second send for the same user is skipped due to idempotency
            second_sent = send_welcome_email(user=self.user)
            self.assertTrue(second_sent)  # returns True without re-dispatching

    def test_unconfigured_email_provider_never_fakes_success(self):
        # When unconfigured, emailSent must be False and return error reason
        unconfigured_user = User.objects.create_user(
            username="unconfigured_user",
            email="unconfigured@legalguide.org",
            password="StrongPassword123!",
        )
        with patch.dict("os.environ", {"EMAIL_PROVIDER": "", "EMAIL_API_KEY": "", "SMTP_HOST": ""}, clear=True):
            result = send_welcome_email(user=unconfigured_user)
            self.assertFalse(result)
            self.assertFalse(result.success)
            self.assertIsNotNone(result.error)

            # Profile should NOT record welcome_email_sent as True
            profile = UserProfile.objects.get(user=unconfigured_user)
            self.assertFalse(profile.welcome_email_sent)

    def test_login_notification_email_content(self):
        text = build_login_text("John Doe", "john@example.com")
        html = build_login_html("John Doe", "john@example.com")

        self.assertIn("Hi John Doe,", text)
        self.assertIn("Account email:\njohn@example.com", text)
        self.assertIn("If you do not recognize this login", text)
        self.assertIn("LegalGuide Team", text)
        self.assertNotIn("password", text.lower().replace("change your password", ""))

        self.assertIn("john@example.com", html)
        self.assertIn("LegalGuide", html)


class LoginNotificationEmailFlowTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.login_url = "/api/auth/login/"
        self.user = User.objects.create_user(
            username="logincitizen",
            email="citizen_login@legalguide.org",
            password="StrongPassword123!",
        )

    @patch("accounts.views.send_login_notification_email")
    def test_successful_login_triggers_login_notification(self, mock_login_email):
        mock_login_email.return_value = True

        res = self.client.post(
            self.login_url,
            {"username": "logincitizen", "password": "StrongPassword123!"},
            format="json",
        )
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("token", res.data)
        mock_login_email.assert_called_once_with(user=self.user)

    @patch("accounts.views.send_login_notification_email")
    def test_login_succeeds_even_if_email_fails(self, mock_login_email):
        mock_login_email.side_effect = Exception("Email provider down")

        res = self.client.post(
            self.login_url,
            {"username": "logincitizen", "password": "StrongPassword123!"},
            format="json",
        )
        # Login must succeed regardless of email failure
        self.assertEqual(res.status_code, status.HTTP_200_OK)
        self.assertIn("token", res.data)


class AccountSpecificSavedItemTests(TestCase):
    def setUp(self):
        self.client_a = APIClient()
        self.client_b = APIClient()

        self.user_a = User.objects.create_user(
            username="user_a",
            email="usera@test.com",
            password="Password123!",
        )
        self.user_b = User.objects.create_user(
            username="user_b",
            email="userb@test.com",
            password="Password123!",
        )

        from rest_framework.authtoken.models import Token
        self.token_a = Token.objects.create(user=self.user_a)
        self.token_b = Token.objects.create(user=self.user_b)

        self.client_a.credentials(HTTP_AUTHORIZATION=f"Token {self.token_a.key}")
        self.client_b.credentials(HTTP_AUTHORIZATION=f"Token {self.token_b.key}")

        self.saved_url = "/api/saved/"

    def test_saved_items_are_account_specific(self):
        # 1. Unauthenticated access blocked
        anon_client = APIClient()
        res_anon = anon_client.get(self.saved_url)
        self.assertEqual(res_anon.status_code, status.HTTP_401_UNAUTHORIZED)

        # 2. Account A initially has 0 saved items
        res_a_init = self.client_a.get(self.saved_url)
        self.assertEqual(res_a_init.status_code, status.HTTP_200_OK)
        self.assertEqual(res_a_init.data["section_ids"], [])

        # 3. Account A saves 3 items: 101, 102, 103
        for sid in [101, 102, 103]:
            post_res = self.client_a.post(self.saved_url, {"section_id": sid}, format="json")
            self.assertIn(post_res.status_code, [status.HTTP_200_OK, status.HTTP_201_CREATED])

        res_a = self.client_a.get(self.saved_url)
        self.assertEqual(sorted(res_a.data["section_ids"]), [101, 102, 103])
        self.assertEqual(res_a.data["count"], 3)

        # 4. Account B on same app/device queries saved items -> strictly empty!
        res_b = self.client_b.get(self.saved_url)
        self.assertEqual(res_b.status_code, status.HTTP_200_OK)
        self.assertEqual(res_b.data["section_ids"], [])
        self.assertEqual(res_b.data["count"], 0)

        # 5. Account B saves 1 item: 205
        post_b = self.client_b.post(self.saved_url, {"section_id": 205}, format="json")
        self.assertIn(post_b.status_code, [status.HTTP_200_OK, status.HTTP_201_CREATED])

        res_b2 = self.client_b.get(self.saved_url)
        self.assertEqual(res_b2.data["section_ids"], [205])
        self.assertEqual(res_b2.data["count"], 1)

        # 6. Account A's saved items are still intact: 101, 102, 103
        res_a2 = self.client_a.get(self.saved_url)
        self.assertEqual(sorted(res_a2.data["section_ids"]), [101, 102, 103])
        self.assertEqual(res_a2.data["count"], 3)

        # 7. Account B attempts to delete Account A's saved item (101) -> blocked (404)
        del_b_attack = self.client_b.delete(f"/api/saved/101/")
        self.assertEqual(del_b_attack.status_code, status.HTTP_404_NOT_FOUND)

        # Confirm Account A still has 101
        self.assertTrue(UserBookmark.objects.filter(user=self.user_a, section_id=101).exists())

        # 8. Account A deletes item 101 -> succeeds
        del_a = self.client_a.delete(f"/api/saved/101/")
        self.assertEqual(del_a.status_code, status.HTTP_200_OK)
        res_a3 = self.client_a.get(self.saved_url)
        self.assertEqual(sorted(res_a3.data["section_ids"]), [102, 103])


class BrevoEmailIntegrationTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.signup_url = "/api/auth/signup/"

    @patch("urllib.request.urlopen")
    def test_brevo_direct_send_success(self, mock_urlopen):
        from accounts.email_service import _send_via_brevo
        # Mock 201 response with messageId from Brevo API
        mock_resp = MagicMock()
        mock_resp.status = 201
        mock_resp.read.return_value = b'{"messageId":"<20261006.12345@smtp-relay.mailin.fr>"}'
        mock_resp.__enter__.return_value = mock_resp
        mock_urlopen.return_value = mock_resp

        success, err, msg_id = _send_via_brevo(
            api_key=os.environ.get("TEST_BREVO_API_KEY", "test_placeholder_key"),
            from_email=os.environ.get("EMAIL_FROM", "noreply@legalguide.org"),
            from_name="LegalGuide",
            to_email="testrecipient@legalguide.org",
            to_name="Citizen",
            subject="Welcome to LegalGuide",
            text="Hello citizen",
            html_str="<p>Hello citizen</p>",
        )

        self.assertTrue(success)
        self.assertIsNone(err)
        self.assertEqual(msg_id, "<20261006.12345@smtp-relay.mailin.fr>")

    @patch("urllib.request.urlopen")
    def test_brevo_direct_send_failure(self, mock_urlopen):
        import urllib.error
        import io
        from accounts.email_service import _send_via_brevo

        # Mock HTTP 401 error from Brevo
        err_body = b'{"code":"unauthorized","message":"Key not found"}'
        mock_urlopen.side_effect = urllib.error.HTTPError(
            url="https://api.brevo.com/v3/smtp/email",
            code=401,
            msg="Unauthorized",
            hdrs={},
            fp=io.BytesIO(err_body),
        )

        success, err, msg_id = _send_via_brevo(
            api_key=os.environ.get("TEST_INVALID_API_KEY", "invalid_placeholder_key"),
            from_email=os.environ.get("EMAIL_FROM", "noreply@legalguide.org"),
            from_name="LegalGuide",
            to_email="testrecipient@legalguide.org",
            to_name="Citizen",
            subject="Welcome to LegalGuide",
            text="Hello citizen",
            html_str="<p>Hello citizen</p>",
        )

        self.assertFalse(success)
        self.assertEqual(err, "Key not found")
        self.assertIsNone(msg_id)

    @patch("accounts.views.send_welcome_email")
    def test_signup_view_reports_brevo_success(self, mock_email):
        from accounts.email_service import EmailDeliveryResult
        mock_email.return_value = EmailDeliveryResult(True, None, message_id="<brevo-123>")

        payload = {
            "username": "brevo_user_success",
            "email": "brevo_success@legalguide.org",
            "password": "Password123!",
        }
        res = self.client.post(self.signup_url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data["success"])
        self.assertTrue(res.data["emailSent"])
        self.assertTrue(res.data["email_sent"])
        self.assertIsNone(res.data["emailError"])
        self.assertIsNone(res.data["email_error"])

    @patch("accounts.views.send_welcome_email")
    def test_signup_view_reports_brevo_failure(self, mock_email):
        from accounts.email_service import EmailDeliveryResult
        mock_email.return_value = EmailDeliveryResult(False, "Sender is not verified.")

        payload = {
            "username": "brevo_user_fail",
            "email": "brevo_fail@legalguide.org",
            "password": "Password123!",
        }
        res = self.client.post(self.signup_url, payload, format="json")
        self.assertEqual(res.status_code, status.HTTP_201_CREATED)
        self.assertTrue(res.data["success"])
        self.assertFalse(res.data["emailSent"])
        self.assertFalse(res.data["email_sent"])
        self.assertEqual(res.data["emailError"], "Sender is not verified.")
        self.assertEqual(res.data["email_error"], "Sender is not verified.")


