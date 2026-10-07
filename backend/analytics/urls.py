from django.urls import path, re_path

from .views import (
    AdminAnalyticsView,
    AdminStatusView,
    AdminUserListView,
    HeartbeatView,
    TrackActivityBatchView,
)

urlpatterns = [
    # Full paths when included at api/
    path("admin/analytics/", AdminAnalyticsView.as_view(), name="admin-analytics"),
    re_path(r"^admin/analytics/?$", AdminAnalyticsView.as_view()),
    path("admin/users/", AdminUserListView.as_view(), name="admin-users"),
    re_path(r"^admin/users/?$", AdminUserListView.as_view()),
    path("admin/status/", AdminStatusView.as_view(), name="admin-status"),
    re_path(r"^admin/status/?$", AdminStatusView.as_view()),

    # Short paths when included at api/admin/
    path("analytics/", AdminAnalyticsView.as_view(), name="admin-analytics-short"),
    re_path(r"^analytics/?$", AdminAnalyticsView.as_view()),
    path("users/", AdminUserListView.as_view(), name="admin-users-short"),
    re_path(r"^users/?$", AdminUserListView.as_view()),
    path("status/", AdminStatusView.as_view(), name="admin-status-short"),
    re_path(r"^status/?$", AdminStatusView.as_view()),

    # Activity tracking and heartbeat
    path("analytics/track/", TrackActivityBatchView.as_view(), name="analytics-track"),
    re_path(r"^analytics/track/?$", TrackActivityBatchView.as_view()),
    path("analytics/heartbeat/", HeartbeatView.as_view(), name="analytics-heartbeat"),
    re_path(r"^analytics/heartbeat/?$", HeartbeatView.as_view()),
    path("track/", TrackActivityBatchView.as_view(), name="analytics-track-short"),
    re_path(r"^track/?$", TrackActivityBatchView.as_view()),
    path("heartbeat/", HeartbeatView.as_view(), name="analytics-heartbeat-short"),
    re_path(r"^heartbeat/?$", HeartbeatView.as_view()),
]


