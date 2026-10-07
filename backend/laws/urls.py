from django.urls import path
from .views import (
    HealthCheckView,
    CategoryListView,
    LawListView,
    LegalSectionListView,
    LegalMatterListView,
    LegalSyncView,
    DatabaseSyncStatusView,
    # User-facing published updates
    PublishedLegalUpdatesView,
    PublishedLegalUpdateDetailView,
    # App version & Feature config
    AppVersionView,
    FeatureConfigView,
    # Admin-only endpoints
    AdminCheckUpdatesView,
    AdminApproveUpdateView,
    AdminRejectUpdateView,
    AdminPendingUpdatesView,
    AdminAllUpdatesView,
    AdminLegalDatabaseView,
    AdminPublishedUpdatesView,
)
from analytics.views import (
    AdminAnalyticsView,
    AdminStatusView,
    AdminUserListView,
    HeartbeatView,
    TrackActivityBatchView,
)

urlpatterns = [
    # ── Health ──────────────────────────────────────────
    path("health/", HealthCheckView.as_view(), name="health-check"),

    # ── App Version & Feature Configuration ─────────────
    path("app/version/", AppVersionView.as_view(), name="app-version"),
    path("app/features/", FeatureConfigView.as_view(), name="app-features"),

    # ── Public read-only legal data ──────────────────────
    path("categories/", CategoryListView.as_view(), name="category-list"),
    path("laws/", LawListView.as_view(), name="law-list"),
    path("sections/", LegalSectionListView.as_view(), name="section-list"),
    path("matters/", LegalMatterListView.as_view(), name="matter-list"),

    # ── Incremental database synchronisation ─────────────
    path("laws/sync/", LegalSyncView.as_view(), name="legal-sync"),
    path("laws/sync/status/", DatabaseSyncStatusView.as_view(), name="legal-sync-status"),

    # ── User: Published Legal Updates (VERIFIED only) ────
    path("legal-updates/", PublishedLegalUpdatesView.as_view(), name="published-legal-updates"),
    path("legal-updates/<int:pk>/", PublishedLegalUpdateDetailView.as_view(), name="published-legal-update-detail"),

    # ── Admin-only: Legal Update Pipeline ────────────────
    path("admin/legal-database/", AdminLegalDatabaseView.as_view(), name="admin-legal-database"),
    path("admin/legal-updates/", AdminAllUpdatesView.as_view(), name="admin-all-updates"),
    path("admin/legal-updates/pending/", AdminPendingUpdatesView.as_view(), name="admin-pending-updates"),
    path("admin/legal-updates/check-sources/", AdminCheckUpdatesView.as_view(), name="admin-check-updates"),
    path("admin/legal-updates/approve/", AdminApproveUpdateView.as_view(), name="admin-approve-update"),
    path("admin/legal-updates/reject/", AdminRejectUpdateView.as_view(), name="admin-reject-update"),
    path("admin/legal-updates/published/", AdminPublishedUpdatesView.as_view(), name="admin-published-updates"),

    # ── Admin Analytics & Central Tracking ──────────────
    path("admin/analytics/", AdminAnalyticsView.as_view(), name="laws-admin-analytics"),
    path("admin/users/", AdminUserListView.as_view(), name="laws-admin-users"),
    path("admin/status/", AdminStatusView.as_view(), name="laws-admin-status"),
    path("analytics/track/", TrackActivityBatchView.as_view(), name="laws-analytics-track"),
    path("analytics/heartbeat/", HeartbeatView.as_view(), name="laws-analytics-heartbeat"),
]