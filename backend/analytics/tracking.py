from django.db import transaction
from django.db.models import F
from django.utils import timezone

from accounts.models import UserProfile
from .models import AIQuestionStat, FeatureUsageStat, UserActivityLog


def classify_question_category(text: str) -> str:
    """
    Classifies a legal question into a high-level category for aggregate reporting.
    Does NOT store the question itself.
    """
    lower = text.lower()
    if any(k in lower for k in ["bns", "ipc", "police", "arrest", "theft", "murder", "fir", "bail", "crime", "criminal", "custody"]):
        return "Criminal / BNS"
    if any(k in lower for k in ["traffic", "challan", "dl", "rc", "helmet", "signal", "vehicle", "fine", "speed"]):
        return "Traffic & Driver Rights"
    if any(k in lower for k in ["train", "railway", "ticket", "platform", "tt", "berth", "ttc", "irctc"]):
        return "Indian Railway"
    if any(k in lower for k in ["property", "tenant", "rent", "land", "eviction", "lease", "deed", "possession"]):
        return "Tenancy & Property"
    if any(k in lower for k in ["divorce", "marriage", "maintenance", "dowry", "domestic", "child", "spouse"]):
        return "Family & Matrimonial"
    if any(k in lower for k in ["bank", "fraud", "upi", "cyber", "scam", "phishing", "atm", "account"]):
        return "Cyber & Banking"
    if any(k in lower for k in ["consumer", "refund", "warranty", "defective", "service"]):
        return "Consumer Rights"
    if any(k in lower for k in ["salary", "labour", "employment", "wage", "boss", "termination"]):
        return "Labour & Employment"
    return "General Legal"


def record_ai_question_event(user, question_text: str):
    """
    Records an AI question in aggregate analytics.
    Maintains strict user privacy: NO question text, message content, or chat transcript is saved.
    """
    category = classify_question_category(question_text)
    today = timezone.localdate()
    now = timezone.now()

    try:
        with transaction.atomic():
            # Increment AIQuestionStat
            q_stat, created = AIQuestionStat.objects.get_or_create(
                date=today,
                category=category,
                defaults={"count": 1},
            )
            if not created:
                AIQuestionStat.objects.filter(pk=q_stat.pk).update(count=F("count") + 1)

            # Increment FeatureUsageStat for ai_assistant
            f_stat, f_created = FeatureUsageStat.objects.get_or_create(
                feature_name="ai_assistant",
                date=today,
                defaults={"count": 1},
            )
            if not f_created:
                FeatureUsageStat.objects.filter(pk=f_stat.pk).update(count=F("count") + 1)

            # If user is authenticated, update their activity
            if user and user.is_authenticated:
                profile, _ = UserProfile.objects.get_or_create(
                    user=user,
                    defaults={"role": "ADMIN" if (user.is_staff or user.is_superuser) else "USER"},
                )
                profile.last_active_at = now
                profile.save(update_fields=["last_active_at"])

                UserActivityLog.objects.get_or_create(
                    user=user,
                    date=today,
                    defaults={"activity_type": "ai_question", "timestamp": now},
                )
    except Exception:
        # Never break core AI assistant functionality if analytics tracking encounters an issue
        pass
