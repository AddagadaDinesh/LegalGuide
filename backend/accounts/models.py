from django.conf import settings
from django.db import models


class AbuseEvent(models.Model):
    """A record that something suspicious happened, kept for abuse
    prevention. Deliberately holds no message text and no per-user
    activity log — only a category, a timestamp, and (when known) which
    account triggered it, so a repeat offender's account can be
    rate-limited or suspended without building a profile of what anyone
    searched for.
    """

    CATEGORY_CHOICES = [
        ("harmful_request", "AI Assistant asked to help with a harmful/illegal act"),
        ("auth_abuse", "Repeated failed login attempts (possible brute force)"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="abuse_events",
    )
    category = models.CharField(max_length=30, choices=CATEGORY_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.category} @ {self.created_at:%Y-%m-%d %H:%M}"
