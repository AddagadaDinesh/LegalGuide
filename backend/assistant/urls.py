from django.urls import path

from .views import ChatAssistantView

urlpatterns = [
    path("chat/", ChatAssistantView.as_view(), name="assistant-chat"),
]
