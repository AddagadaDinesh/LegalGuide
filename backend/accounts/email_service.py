import html
import json
import logging
import os
import re
import urllib.error
import urllib.request
from typing import Optional

from django.conf import settings
from django.core.cache import cache
from django.utils import timezone

logger = logging.getLogger("accounts.email_service")

EMAIL_REGEX = re.compile(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")

WELCOME_SUBJECT = "Welcome to LegalGuide"
LOGIN_SUBJECT = "LegalGuide – New Login to Your Account"
LOGIN_DEBOUNCE_SECONDS = 60


class EmailDeliveryResult(tuple):
    """
    Result tuple (success, error) that evaluates to its success boolean
    when checked in boolean context, while providing explicit tuple unpacking,
    named properties, and message_id.
    """
    def __new__(cls, success: bool, error: Optional[str] = None, message_id: Optional[str] = None):
        instance = super().__new__(cls, (bool(success), error))
        instance.message_id = message_id
        return instance

    @property
    def success(self) -> bool:
        return self[0]

    @property
    def error(self) -> Optional[str]:
        return self[1]

    def __bool__(self) -> bool:
        return self[0]


def build_welcome_text(username: str, email: str) -> str:
    """Builds the canonical plain-text welcome email matching LegalGuide specifications."""
    return (
        "Welcome to LegalGuide!\n\n"
        "Your account has been created successfully.\n\n"
        f"Username: {username}\n"
        f"Email: {email}\n\n"
        "LegalGuide helps you access simplified legal information and legal assistance.\n\n"
        "You can now use LegalGuide to:\n\n"
        "• Explore Indian laws in simple language\n"
        "• Understand citizen rights and legal awareness topics\n"
        "• Search verified legal information\n"
        "• Use the LegalGuide AI Assistant\n"
        "• Access Emergency Rights, Railway Rules, Traffic Rules and other legal topics\n"
        "• Save useful legal information for later\n\n"
        "Account email:\n"
        f"{email}\n\n"
        "Thank you for using LegalGuide.\n\n"
        "LegalGuide provides general legal information and educational guidance. "
        "It is not a substitute for professional legal advice or legal representation.\n\n"
        "Regards,\n"
        "LegalGuide Team\n"
    )


def build_welcome_html(username: str, email: str) -> str:
    """Builds a responsive, modern HTML email with LegalGuide branding."""
    safe_name = html.escape(username)
    safe_email = html.escape(email)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{WELCOME_SUBJECT}</title>
  <style>
    body {{
      margin: 0;
      padding: 0;
      background-color: #F8FAFC;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #0F172A;
      line-height: 1.6;
    }}
    .wrapper {{
      width: 100%;
      background-color: #F8FAFC;
      padding: 32px 16px;
      box-sizing: border-box;
    }}
    .card {{
      max-width: 580px;
      margin: 0 auto;
      background-color: #FFFFFF;
      border: 1px solid #E2E8F0;
      border-radius: 14px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(15, 23, 42, 0.05);
    }}
    .header {{
      background: linear-gradient(135deg, #1E1B4B 0%, #312E81 100%);
      padding: 28px 24px;
      text-align: center;
      color: #FFFFFF;
    }}
    .header h1 {{
      margin: 0 0 6px 0;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: -0.3px;
    }}
    .header .subtitle {{
      margin: 0;
      font-size: 13px;
      color: #C7D2FE;
    }}
    .content {{
      padding: 28px 24px;
    }}
    .greeting {{
      font-size: 17px;
      font-weight: 600;
      color: #1E1B4B;
      margin-bottom: 12px;
    }}
    .feature-box {{
      background-color: #F1F5F9;
      border-radius: 10px;
      padding: 16px 20px;
      margin: 20px 0;
      border-left: 4px solid #4338CA;
    }}
    .feature-box h4 {{
      margin: 0 0 10px 0;
      font-size: 14px;
      color: #1E1B4B;
      font-weight: 600;
    }}
    .feature-box ul {{
      margin: 0;
      padding-left: 20px;
    }}
    .feature-box li {{
      margin-bottom: 7px;
      font-size: 13.5px;
      color: #334155;
    }}
    .account-badge {{
      background-color: #EEF2FF;
      border: 1px solid #C7D2FE;
      border-radius: 8px;
      padding: 10px 14px;
      margin: 20px 0;
      font-size: 13px;
      color: #312E81;
    }}
    .disclaimer {{
      font-size: 12px;
      color: #64748B;
      background-color: #F8FAFC;
      border-top: 1px solid #E2E8F0;
      padding: 18px 24px;
      line-height: 1.5;
    }}
    .footer {{
      text-align: center;
      padding: 20px 24px;
      font-size: 12px;
      color: #94A3B8;
    }}
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="card">
      <div class="header">
        <h1>LegalGuide</h1>
        <p class="subtitle">Simplified Legal Knowledge & Citizen Rights</p>
      </div>
      <div class="content">
        <p class="greeting">Welcome to LegalGuide!</p>
        <p style="font-size: 15px; color: #334155; margin-bottom: 16px;">
          Your account has been created successfully.
        </p>

        <div class="account-badge">
          <div style="margin-bottom: 6px;"><strong>Username:</strong> {safe_name}</div>
          <div><strong>Email:</strong> {safe_email}</div>
        </div>

        <p style="font-size: 14px; color: #334155; line-height: 1.6;">
          LegalGuide helps you access simplified legal information and legal assistance.
        </p>

        <div class="feature-box">
          <h4>With your LegalGuide account, you can:</h4>
          <ul>
            <li>Explore Indian laws in simple language</li>
            <li>Understand citizen rights and legal awareness topics</li>
            <li>Search verified legal information</li>
            <li>Use the LegalGuide AI Assistant</li>
            <li>Access Emergency Rights, Railway Rules, Traffic Rules and other legal topics</li>
            <li>Save useful legal information for later</li>
          </ul>
        </div>

        <p style="margin-bottom: 0;">Regards,<br><strong>LegalGuide Team</strong></p>
      </div>
      <div class="disclaimer">
        <strong>Important Note:</strong> LegalGuide provides general legal information and educational guidance. It is not a substitute for professional legal advice or legal representation.
      </div>
      <div class="footer">
        © {timezone.now().year} LegalGuide. All rights reserved.
      </div>
    </div>
  </div>
</body>
</html>
"""


def build_login_text(name: str, email: str) -> str:
    """Builds the canonical plain-text login notification email matching LegalGuide specifications."""
    return (
        f"Hi {name},\n\n"
        f"Your LegalGuide account was successfully logged in.\n\n"
        f"Account email:\n"
        f"{email}\n\n"
        f"If this login was made by you, no action is required.\n\n"
        f"If you do not recognize this login, please secure your account and change your password.\n\n"
        f"Regards,\n"
        f"LegalGuide Team\n"
    )


def build_login_html(name: str, email: str) -> str:
    """Builds a responsive, modern HTML email for login notifications."""
    safe_name = html.escape(name)
    safe_email = html.escape(email)

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{LOGIN_SUBJECT}</title>
  <style>
    body {{
      margin: 0;
      padding: 0;
      background-color: #F8FAFC;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      color: #0F172A;
      line-height: 1.6;
    }}
    .wrapper {{
      width: 100%;
      background-color: #F8FAFC;
      padding: 32px 16px;
      box-sizing: border-box;
    }}
    .card {{
      max-width: 580px;
      margin: 0 auto;
      background-color: #FFFFFF;
      border: 1px solid #E2E8F0;
      border-radius: 14px;
      overflow: hidden;
      box-shadow: 0 4px 12px rgba(15, 23, 42, 0.05);
    }}
    .header {{
      background: linear-gradient(135deg, #1E1B4B 0%, #312E81 100%);
      padding: 28px 24px;
      text-align: center;
      color: #FFFFFF;
    }}
    .header h1 {{
      margin: 0 0 6px 0;
      font-size: 24px;
      font-weight: 700;
      letter-spacing: -0.3px;
    }}
    .header .subtitle {{
      margin: 0;
      font-size: 13px;
      color: #C7D2FE;
    }}
    .content {{
      padding: 28px 24px;
    }}
    .greeting {{
      font-size: 17px;
      font-weight: 600;
      color: #1E1B4B;
      margin-bottom: 12px;
    }}
    .account-badge {{
      background-color: #EEF2FF;
      border: 1px solid #C7D2FE;
      border-radius: 8px;
      padding: 12px 16px;
      margin: 20px 0;
      font-size: 13.5px;
      color: #312E81;
    }}
    .security-note {{
      background-color: #FEF3C7;
      border-left: 4px solid #D97706;
      border-radius: 6px;
      padding: 12px 16px;
      margin: 20px 0;
      font-size: 13px;
      color: #92400E;
    }}
    .footer {{
      text-align: center;
      padding: 20px 24px;
      font-size: 12px;
      color: #94A3B8;
    }}
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="card">
      <div class="header">
        <h1>LegalGuide</h1>
        <p class="subtitle">Security Notification</p>
      </div>
      <div class="content">
        <p class="greeting">Hi <strong>{safe_name}</strong>,</p>
        <p>Your LegalGuide account was successfully logged in.</p>
        
        <div class="account-badge">
          <strong>Account email:</strong> {safe_email}
        </div>

        <p>If this login was made by you, no action is required.</p>
        
        <div class="security-note">
          <strong>Security Notice:</strong> If you do not recognize this login, please secure your account and change your password immediately.
        </div>

        <p style="margin-bottom: 0;">Regards,<br><strong>LegalGuide Team</strong></p>
      </div>
      <div class="footer">
        © {timezone.now().year} LegalGuide. All rights reserved.
      </div>
    </div>
  </div>
</body>
</html>
"""


def _send_via_resend(api_key: str, from_email: str, to_email: str, subject: str, text: str, html_str: str) -> tuple[bool, Optional[str], Optional[str]]:
    """Sends email via Resend REST API (HTTPS)."""
    url = "https://api.resend.com/emails"
    payload = {
        "from": from_email,
        "to": [to_email],
        "subject": subject,
        "text": text,
        "html": html_str,
    }
    data = json.dumps(payload).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "LegalGuide/1.0",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            resp_body = resp.read().decode("utf-8", errors="ignore")
            message_id = None
            try:
                parsed_resp = json.loads(resp_body)
                if isinstance(parsed_resp, dict):
                    message_id = parsed_resp.get("id")
            except Exception:
                pass
            if resp.status in (200, 201):
                logger.info("Email '%s' accepted by Resend for %s (id: %s)", subject, to_email, message_id)
                return True, None, message_id
            logger.warning("Resend returned unexpected status %s for %s: %s", resp.status, to_email, resp_body)
            return False, f"Email provider responded with status {resp.status}.", None
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        logger.error("Resend API HTTP error %s: %s", e.code, body)
        err_msg = "Email delivery service rejected the request."
        try:
            parsed = json.loads(body)
            if isinstance(parsed, dict) and "message" in parsed:
                err_msg = parsed["message"]
        except Exception:
            pass
        return False, err_msg, None
    except Exception as e:
        logger.error("Resend dispatch error: %s", str(e))
        return False, "Failed to connect to email provider.", None


def _send_via_brevo(api_key: str, from_email: str, from_name: str, to_email: str, to_name: str, subject: str, text: str, html_str: str) -> tuple[bool, Optional[str], Optional[str]]:
    """Sends email via Brevo REST API (HTTPS)."""
    url = "https://api.brevo.com/v3/smtp/email"
    sender_email = from_email
    match = re.search(r"<([^>]+)>", from_email)
    if match:
        sender_email = match.group(1).strip()

    sender_name = from_name.strip() if from_name else "LegalGuide"

    payload = {
        "sender": {"name": sender_name, "email": sender_email},
        "to": [{"email": to_email, "name": to_name or to_email.split('@')[0]}],
        "subject": subject,
        "textContent": text,
        "htmlContent": html_str,
    }
    data = json.dumps(payload).encode("utf-8")
    headers = {
        "api-key": api_key,
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": "LegalGuide/1.0",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            resp_body = resp.read().decode("utf-8", errors="ignore")
            message_id = None
            try:
                parsed_resp = json.loads(resp_body)
                if isinstance(parsed_resp, dict):
                    message_id = parsed_resp.get("messageId")
            except Exception:
                pass
            if resp.status in (200, 201, 202):
                logger.info("Email '%s' accepted by Brevo for %s (messageId: %s)", subject, to_email, message_id)
                return True, None, message_id
            logger.warning("Brevo returned unexpected status %s for %s: %s", resp.status, to_email, resp_body)
            return False, f"Email provider responded with status {resp.status}.", None
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        logger.error("Brevo API HTTP error %s: %s", e.code, body)
        err_msg = "Email delivery service rejected the request."
        try:
            parsed = json.loads(body)
            if isinstance(parsed, dict) and "message" in parsed:
                err_msg = parsed["message"]
        except Exception:
            pass
        return False, err_msg, None
    except Exception as e:
        logger.error("Brevo dispatch error: %s", str(e))
        return False, "Failed to connect to email provider.", None


def _send_via_sendgrid(api_key: str, from_email: str, from_name: str, to_email: str, to_name: str, subject: str, text: str, html_str: str) -> tuple[bool, Optional[str]]:
    """Sends email via SendGrid REST API (HTTPS)."""
    url = "https://api.sendgrid.com/v3/mail/send"
    sender_email = from_email
    match = re.search(r"<([^>]+)>", from_email)
    if match:
        sender_email = match.group(1).strip()

    payload = {
        "personalizations": [{"to": [{"email": to_email, "name": to_name}]}],
        "from": {"email": sender_email, "name": from_name},
        "subject": subject,
        "content": [
            {"type": "text/plain", "value": text},
            {"type": "text/html", "value": html_str},
        ],
    }
    data = json.dumps(payload).encode("utf-8")
    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "User-Agent": "LegalGuide/1.0",
    }
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            if resp.status in (200, 202):
                logger.info("Email '%s' accepted by SendGrid for %s", subject, to_email)
                return True, None
            logger.warning("SendGrid returned unexpected status %s for %s", resp.status, to_email)
            return False, f"Email provider responded with status {resp.status}."
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        logger.error("SendGrid API HTTP error %s: %s", e.code, body)
        return False, "Email delivery service rejected the request."
    except Exception as e:
        logger.error("SendGrid dispatch error: %s", str(e))
        return False, "Failed to connect to email provider."


def _send_via_smtp(from_email: str, to_email: str, subject: str, text: str, html_str: str) -> tuple[bool, Optional[str]]:
    """Sends email via Django SMTP / EmailMultiAlternatives."""
    try:
        from django.core.mail import EmailMultiAlternatives

        msg = EmailMultiAlternatives(
            subject=subject,
            body=text,
            from_email=from_email,
            to=[to_email],
        )
        msg.attach_alternative(html_str, "text/html")
        sent_count = msg.send(fail_silently=False)
        if sent_count > 0:
            logger.info("Email '%s' sent successfully to %s via SMTP.", subject, to_email)
            return True, None
        logger.warning("SMTP returned 0 sent messages for %s", to_email)
        return False, "SMTP server accepted 0 messages."
    except Exception as e:
        logger.error("SMTP dispatch error: %s", str(e))
        return False, "SMTP connection or authentication failed."


def _dispatch_payload(to_email: str, to_name: str, subject: str, text_content: str, html_content: str) -> EmailDeliveryResult:
    """Common email dispatch pipeline resolving provider and credentials."""
    provider = os.environ.get("EMAIL_PROVIDER", "").strip().lower()
    from_email = os.environ.get("EMAIL_FROM", "dineshaddagada@gmail.com").strip()
    from_name = os.environ.get("EMAIL_FROM_NAME", "LegalGuide").strip()
    api_key = os.environ.get("EMAIL_API_KEY", "").strip()

    if not provider:
        if api_key.startswith("xkeysib-"):
            provider = "brevo"
        elif api_key.startswith("re_"):
            provider = "resend"
        elif api_key.startswith("SG."):
            provider = "sendgrid"
        elif os.environ.get("SMTP_HOST"):
            provider = "smtp"
        else:
            provider = "none"

    logger.info("Dispatching email '%s' to %s via provider: %s", subject, to_email, provider)

    try:
        if provider == "brevo":
            if not api_key:
                logger.error("Brevo provider requested but EMAIL_API_KEY is not configured.")
                return EmailDeliveryResult(False, "Email provider API key is not configured.")
            success, err, msg_id = _send_via_brevo(api_key, from_email, from_name, to_email, to_name, subject, text_content, html_content)
            return EmailDeliveryResult(success, err, message_id=msg_id)

        elif provider == "resend":
            if not api_key:
                logger.error("Resend provider requested but EMAIL_API_KEY is not configured.")
                return EmailDeliveryResult(False, "Email provider API key is not configured.")
            success, err, msg_id = _send_via_resend(api_key, from_email, to_email, subject, text_content, html_content)
            return EmailDeliveryResult(success, err, message_id=msg_id)

        elif provider == "sendgrid":
            if not api_key:
                logger.error("SendGrid provider requested but EMAIL_API_KEY is not configured.")
                return EmailDeliveryResult(False, "Email provider API key is not configured.")
            success, err = _send_via_sendgrid(api_key, from_email, from_name, to_email, to_name, subject, text_content, html_content)
            return EmailDeliveryResult(success, err)

        elif provider == "smtp":
            success, err = _send_via_smtp(from_email, to_email, subject, text_content, html_content)
            return EmailDeliveryResult(success, err)

        elif provider == "test":
            # For isolated test execution where EMAIL_PROVIDER="test" is explicitly set
            logger.info("[Test Email Mode] Subject: %s | To: %s", subject, to_email)
            return EmailDeliveryResult(True, None, message_id="test-msg-id-12345")

        elif provider == "console":
            logger.info("[Console Email Logged] Subject: %s | To: %s\n%s", subject, to_email, text_content)
            return EmailDeliveryResult(False, "Console email logging is active; external email was not sent.")

        else:
            logger.warning("Email provider is not configured. Email was NOT dispatched to %s", to_email)
            return EmailDeliveryResult(False, "Email delivery service is not configured.")

    except Exception as exc:
        logger.error("Unexpected error in email dispatch to %s: %s", to_email, str(exc))
        return EmailDeliveryResult(False, "Unexpected email service error.")


def send_welcome_email(user=None, email: Optional[str] = None, name: Optional[str] = None) -> EmailDeliveryResult:
    """
    Production-ready welcome email dispatcher.
    Returns EmailDeliveryResult(success, error).
    Idempotent: If user has already received the welcome email (profile.welcome_email_sent=True),
    skips sending and returns EmailDeliveryResult(True, None).
    """
    target_email = ""
    target_name = ""
    profile = None

    if user is not None:
        target_email = (user.email or "").strip().lower()
        target_name = (user.get_full_name() or user.username or "").strip()
        profile = getattr(user, "profile", None)

    if email:
        target_email = email.strip().lower()
    if name:
        target_name = name.strip()

    if not target_name:
        target_name = "Citizen"

    # 1. Email format validation
    if not target_email or not EMAIL_REGEX.match(target_email):
        logger.warning("Cannot send welcome email: Invalid or missing email '%s'", target_email)
        return EmailDeliveryResult(False, "Invalid or missing recipient email.")

    # 2. Idempotency Check: Prevent duplicate welcome emails
    if profile is not None and profile.welcome_email_sent:
        logger.info("Welcome email already sent to %s at %s. Skipping duplicate.", target_email, profile.welcome_email_sent_at)
        return EmailDeliveryResult(True, None)

    # 3. Build email representations
    text_content = build_welcome_text(target_name, target_email)
    html_content = build_welcome_html(target_name, target_email)

    # 4. Dispatch email
    result = _dispatch_payload(target_email, target_name, WELCOME_SUBJECT, text_content, html_content)

    # 5. On verified acceptance, record idempotent state on UserProfile
    if result.success and profile is not None:
        try:
            profile.welcome_email_sent = True
            profile.welcome_email_sent_at = timezone.now()
            profile.save(update_fields=["welcome_email_sent", "welcome_email_sent_at"])
            logger.info("Marked welcome_email_sent=True for user %s (%s)", getattr(user, "username", target_name), target_email)
        except Exception as e:
            logger.warning("Failed to save welcome_email_sent timestamp on profile: %s", e)

    return result


def send_login_notification_email(user=None, email: Optional[str] = None, name: Optional[str] = None) -> bool:
    """
    Sends a login notification email to the authenticated user.
    Includes rate-limiting/debouncing to prevent duplicate emails from rapid double-taps or network retries.
    """
    target_email = ""
    target_name = ""

    if user is not None:
        target_email = (user.email or "").strip().lower()
        target_name = (user.get_full_name() or user.username or "").strip()

    if email:
        target_email = email.strip().lower()
    if name:
        target_name = name.strip()

    if not target_name:
        target_name = "Citizen"

    # 1. Validation
    if not target_email or not EMAIL_REGEX.match(target_email):
        logger.info("Skipping login notification: user '%s' has no valid email '%s'", target_name, target_email)
        return False

    # 2. Idempotency / Debounce: Prevent duplicate emails from double-taps or network retries
    debounce_id = user.id if user else target_email
    debounce_key = f"login_email_debounce:{debounce_id}"
    if cache.get(debounce_key):
        logger.info("Login notification recently dispatched to %s. Debouncing duplicate email.", target_email)
        return True

    cache.set(debounce_key, True, LOGIN_DEBOUNCE_SECONDS)

    # 3. Build email representations
    text_content = build_login_text(target_name, target_email)
    html_content = build_login_html(target_name, target_email)

    # 4. Dispatch
    return bool(_dispatch_payload(target_email, target_name, LOGIN_SUBJECT, text_content, html_content))
