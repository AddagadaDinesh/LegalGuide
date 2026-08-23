from rest_framework import serializers
from .models import Category, Law, LegalSection, LegalMatter


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = "__all__"


class LawSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(
        source="category.name",
        read_only=True
    )

    class Meta:
        model = Law
        fields = "__all__"


class LegalSectionSerializer(serializers.ModelSerializer):
    law_name = serializers.CharField(
        source="law.name",
        read_only=True
    )

    class Meta:
        model = LegalSection
        fields = "__all__"


class LegalMatterSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(
        source="category.name",
        read_only=True
    )

    class Meta:
        model = LegalMatter
        fields = "__all__"