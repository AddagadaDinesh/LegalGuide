from rest_framework import serializers
from .models import (
    Category,
    Law,
    LegalSection,
    LegalMatter,
    LegalSectionVersion,
    LegalUpdateRecord,
    DatabaseSyncInfo,
    PublishedLegalUpdate,
)


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
    law_short_name = serializers.CharField(
        source="law.short_name",
        read_only=True
    )

    class Meta:
        model = LegalSection
        fields = "__all__"


class LegalSectionVersionSerializer(serializers.ModelSerializer):
    section_number = serializers.CharField(
        source="section.section_number",
        read_only=True
    )
    law_name = serializers.CharField(
        source="section.law.name",
        read_only=True
    )

    class Meta:
        model = LegalSectionVersion
        fields = "__all__"


class LegalUpdateRecordSerializer(serializers.ModelSerializer):
    law_name = serializers.CharField(
        source="law.name",
        read_only=True
    )

    class Meta:
        model = LegalUpdateRecord
        fields = "__all__"


class LegalMatterSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(
        source="category.name",
        read_only=True
    )

    class Meta:
        model = LegalMatter
        fields = "__all__"


class DatabaseSyncInfoSerializer(serializers.ModelSerializer):
    class Meta:
        model = DatabaseSyncInfo
        fields = "__all__"


class PublishedLegalUpdateSerializer(serializers.ModelSerializer):
    """User-safe serializer: only exposes published, verified legal update info."""
    update_type_display = serializers.CharField(
        source='get_update_type_display',
        read_only=True
    )

    class Meta:
        model = PublishedLegalUpdate
        fields = [
            'id',
            'title',
            'description',
            'update_type',
            'update_type_display',
            'affected_law_name',
            'affected_law_short_name',
            'affected_section',
            'old_version',
            'new_version',
            'official_source_name',
            'official_source_url',
            'effective_date',
            'published_at',
            'last_verified_at',
        ]