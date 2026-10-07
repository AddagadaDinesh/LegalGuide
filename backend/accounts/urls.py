from django.urls import path

from .views import (
    AdminEmailTestView,
    BookmarkSyncView,
    ForgotPasswordView,
    LoginView,
    LogoutView,
    MeView,
    SavedItemView,
    SignupView,
)
from analytics.views import AdminAnalyticsView, AdminUserListView, HeartbeatView, TrackActivityBatchView

urlpatterns = [
    path("signup/", SignupView.as_view(), name="auth-signup"),
    path("signup", SignupView.as_view()),
    path("register/", SignupView.as_view(), name="auth-register"),
    path("register", SignupView.as_view()),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("login", LoginView.as_view()),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path("logout", LogoutView.as_view()),
    path("me/", MeView.as_view(), name="auth-me"),
    path("me", MeView.as_view()),
    path("forgot-password/", ForgotPasswordView.as_view(), name="auth-forgot-password"),
    path("forgot-password", ForgotPasswordView.as_view()),
    path("saved/", SavedItemView.as_view(), name="auth-saved-list"),
    path("saved/<int:item_id>/", SavedItemView.as_view(), name="auth-saved-detail"),
    path("saved", SavedItemView.as_view()),
    path("bookmarks/sync/", BookmarkSyncView.as_view(), name="auth-bookmarks-sync"),
    path("admin/analytics/", AdminAnalyticsView.as_view(), name="auth-admin-analytics"),
    path("admin/users/", AdminUserListView.as_view(), name="auth-admin-users"),
    path("admin/test-email/", AdminEmailTestView.as_view(), name="auth-admin-test-email"),
    path("analytics/heartbeat/", HeartbeatView.as_view(), name="auth-analytics-heartbeat"),
    path("analytics/track/", TrackActivityBatchView.as_view(), name="auth-analytics-track"),
]

