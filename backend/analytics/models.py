from django.conf import settings
from django.db import models
from django.utils import timezone


class UserActivityLog(models.Model):
    """
    Maintains a record of user activity by date for distinct DAU/WAU/MAU calculations.
    Does NOT store sensitive contents, private queries, or chat transcripts.
    """
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="activity_logs",
    )
    date = models.DateField(default=timezone.localdate, db_index=True)
    timestamp = models.DateTimeField(default=timezone.now, db_index=True)
    activity_type = models.CharField(max_length=64, default="interaction")
    device_info = models.CharField(max_length=200, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["date", "user"]),
            models.Index(fields=["timestamp"]),
        ]
        verbose_name = "User Activity Log"
        verbose_name_plural = "User Activity Logs"

    def __str__(self):
        username = self.user.username if self.user else "Anonymous"
        return f"{username} ({self.activity_type}) on {self.date}"


class FeatureUsageStat(models.Model):
    """
    Aggregate usage statistics for core application features.
    Maintains daily aggregate counts without per-user sensitive logging.
    """
    feature_name = models.CharField(max_length=64, db_index=True)
    date = models.DateField(default=timezone.localdate, db_index=True)
    count = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ("feature_name", "date")
        indexes = [
            models.Index(fields=["feature_name", "date"]),
        ]
        verbose_name = "Feature Usage Stat"
        verbose_name_plural = "Feature Usage Stats"

    def __str__(self):
        return f"{self.feature_name}: {self.count} ({self.date})"


class SearchStat(models.Model):
    """
    Aggregate search terms count.
    Never exposes personal search histories or maps queries to specific users.
    """
    query = models.CharField(max_length=150, unique=True, db_index=True)
    count = models.PositiveIntegerField(default=1)
    last_searched_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Search Term Stat"
        verbose_name_plural = "Search Term Stats"
        ordering = ["-count"]

    def __str__(self):
        return f"'{self.query}': {self.count} searches"


class SectionViewStat(models.Model):
    """
    Aggregate section view counts.
    """
    section_id = models.IntegerField(unique=True, db_index=True)
    section_title = models.CharField(max_length=300)
    law_name = models.CharField(max_length=200, blank=True)
    count = models.PositiveIntegerField(default=1)
    last_viewed_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Section View Stat"
        verbose_name_plural = "Section View Stats"
        ordering = ["-count"]

    def __str__(self):
        return f"{self.section_title} ({self.law_name}): {self.count} views"


class LawViewStat(models.Model):
    """
    Aggregate law view counts.
    """
    law_id = models.IntegerField(null=True, blank=True, unique=True, db_index=True)
    law_name = models.CharField(max_length=200, db_index=True)
    count = models.PositiveIntegerField(default=1)
    last_viewed_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Law View Stat"
        verbose_name_plural = "Law View Stats"
        ordering = ["-count"]

    def __str__(self):
        return f"{self.law_name}: {self.count} opens"


class AIQuestionStat(models.Model):
    """
    Aggregate AI question count by category and date.
    Strictly preserves privacy: NEVER stores question text or user messages.
    """
    date = models.DateField(default=timezone.localdate, db_index=True)
    category = models.CharField(max_length=100, default="General", db_index=True)
    count = models.PositiveIntegerField(default=1)

    class Meta:
        unique_together = ("date", "category")
        indexes = [
            models.Index(fields=["date", "category"]),
        ]
        verbose_name = "AI Question Stat"
        verbose_name_plural = "AI Question Stats"

    def __str__(self):
        return f"{self.category} ({self.date}): {self.count} questions"
