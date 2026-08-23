from rest_framework import generics

from .models import Category, Law, LegalSection, LegalMatter
from .serializers import (
    CategorySerializer,
    LawSerializer,
    LegalSectionSerializer,
    LegalMatterSerializer,
)


class CategoryListView(generics.ListAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer


class LawListView(generics.ListAPIView):
    queryset = Law.objects.all()
    serializer_class = LawSerializer


class LegalSectionListView(generics.ListAPIView):
    queryset = LegalSection.objects.all()
    serializer_class = LegalSectionSerializer


class LegalMatterListView(generics.ListAPIView):
    queryset = LegalMatter.objects.all()
    serializer_class = LegalMatterSerializer