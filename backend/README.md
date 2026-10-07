# LegalGuide Backend

Production Django backend for LegalGuide application.

## Email Notification Setup (Production)

LegalGuide automatically sends a professional welcome email upon successful account registration. The backend supports multiple production email providers without hardcoding credentials:
- **Resend** (Recommended for cloud/serverless/PythonAnywhere over HTTPS port 443)
- **Brevo** (Sendinblue REST API)
- **SendGrid** (REST API)
- **SMTP** (Standard SMTP with TLS/SSL)
- **Console** (Local testing & fallback)

### Step-by-Step Production Configuration

1. **Create an email provider account**:
   - Sign up at [Resend](https://resend.com), [Brevo](https://brevo.com), or [SendGrid](https://sendgrid.com).
2. **Obtain API key**:
   - Generate a restricted API key with email-sending permissions.
3. **Configure verified sender/domain**:
   - Verify your custom domain or sender email in your provider dashboard (e.g. `notifications@yourdomain.com`, or for testing with Resend: `onboarding@resend.dev` to your registered account email).
4. **Add environment variables**:
   - Configure environment variables on your production hosting platform (e.g. PythonAnywhere Web tab / WSGI environment, Render, or `.env` file):
     ```bash
     EMAIL_PROVIDER=resend
     EMAIL_FROM=notifications@yourdomain.com
     EMAIL_FROM_NAME=LegalGuide
     EMAIL_API_KEY=your_provider_api_key
     ```
   - If using SMTP:
     ```bash
     EMAIL_PROVIDER=smtp
     SMTP_HOST=smtp.yourprovider.com
     SMTP_PORT=587
     SMTP_USER=your_smtp_user
     SMTP_PASSWORD=your_smtp_password
     SMTP_USE_TLS=true
     ```
5. **Deploy backend**:
   - Run migrations: `python manage.py migrate`
   - Reload webapp server.
6. **Test registration**:
   - Register a new user from the mobile app or via API endpoint `POST /api/v1/auth/signup/`.
7. **Check email delivery**:
   - Verify the welcome email arrives in the inbox of the registered email address.
   - Confirm backend returns `{"success": true, "emailSent": true}`.

> **Security Note:** Never commit `.env` or hardcode API keys or passwords in source control or mobile application code.
