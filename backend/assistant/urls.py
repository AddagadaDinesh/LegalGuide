from django.urls import path

from .views import ChatAssistantView, SummarizeAnswerView

urlpatterns = [
    path("chat/", ChatAssistantView.as_view(), name="assistant-chat"),
    path("summarize/", SummarizeAnswerView.as_view(), name="assistant-summarize"),
]
