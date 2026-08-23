from django.urls import path
from .views import (
    CategoryListView,
    LawListView,
    LegalSectionListView,
    LegalMatterListView,
)

urlpatterns = [
    path("categories/", CategoryListView.as_view(), name="category-list"),
    path("laws/", LawListView.as_view(), name="law-list"),
    path("sections/", LegalSectionListView.as_view(), name="section-list"),
    path("matters/", LegalMatterListView.as_view(), name="matter-list"),
]