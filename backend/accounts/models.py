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


class UserBookmark(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="bookmarks",
    )
    section_id = models.IntegerField()
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ("user", "section_id")

    def __str__(self):
        return f"{self.user.username} -> Section {self.section_id}"


class UserProfile(models.Model):
    ROLE_CHOICES = [
        ("USER", "Regular User"),
        ("ADMIN", "Administrator"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="profile",
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default="USER")
    last_active_at = models.DateTimeField(null=True, blank=True, db_index=True)
    last_login_at = models.DateTimeField(null=True, blank=True)
    device_info = models.CharField(max_length=255, blank=True)
    welcome_email_sent = models.BooleanField(default=False)
    welcome_email_sent_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    @property
    def is_admin(self):
        return bool(self.user.is_staff or self.user.is_superuser or self.role == "ADMIN")

    def __str__(self):
        return f"{self.user.username} ({self.role})"


from django.db.models.signals import post_save
from django.dispatch import receiver


@receiver(post_save, sender=settings.AUTH_USER_MODEL)
def create_or_update_user_profile(sender, instance, created, **kwargs):
    target_role = "ADMIN" if (instance.is_staff or instance.is_superuser) else "USER"
    profile, prof_created = UserProfile.objects.get_or_create(
        user=instance,
        defaults={"role": target_role},
    )
    if not prof_created and (instance.is_staff or instance.is_superuser) and profile.role != "ADMIN":
        profile.role = "ADMIN"
        profile.save(update_fields=["role"])

