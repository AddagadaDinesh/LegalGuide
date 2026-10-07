"""
URL configuration for legalguide project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from laws.views import HealthCheckView
from accounts.views import SavedItemView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", HealthCheckView.as_view(), name="api-health-slash"),
    path("api/health", HealthCheckView.as_view(), name="api-health-noslash"),
    path("health/", HealthCheckView.as_view(), name="root-health-slash"),
    path("health", HealthCheckView.as_view(), name="root-health-noslash"),
    path("api/saved/", SavedItemView.as_view(), name="api-saved-list"),
    path("api/saved/<int:item_id>/", SavedItemView.as_view(), name="api-saved-detail"),
    path("api/saved", SavedItemView.as_view()),
    path("api/", include("laws.urls")),
    path("api/assistant/", include("assistant.urls")),
    path("api/auth/", include("accounts.urls")),
    path("api/accounts/", include("accounts.urls")),
    path("api/", include("analytics.urls")),
]
