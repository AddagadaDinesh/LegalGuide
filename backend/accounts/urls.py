from django.urls import path

from .views import BookmarkSyncView, ForgotPasswordView, LoginView, LogoutView, MeView, SignupView

urlpatterns = [
    path("signup/", SignupView.as_view(), name="auth-signup"),
    path("login/", LoginView.as_view(), name="auth-login"),
    path("logout/", LogoutView.as_view(), name="auth-logout"),
    path("me/", MeView.as_view(), name="auth-me"),
    path("forgot-password/", ForgotPasswordView.as_view(), name="auth-forgot-password"),
    path("bookmarks/sync/", BookmarkSyncView.as_view(), name="auth-bookmarks-sync"),
]
