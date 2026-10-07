from django.contrib import admin
from django.utils.html import format_html
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
from .updater import approve_update, reject_update, check_official_sources


@admin.register(DatabaseSyncInfo)
class DatabaseSyncInfoAdmin(admin.ModelAdmin):
    list_display = ("server_version", "last_sync_date", "last_source_check", "primary_source_name")
    readonly_fields = ("server_version", "last_sync_date", "last_source_check")


@admin.register(LegalSectionVersion)
class LegalSectionVersionAdmin(admin.ModelAdmin):
    list_display = ("section", "version", "status", "effective_date", "archived_at", "verified_by")
    list_filter = ("status", "version")
    search_fields = ("section__section_number", "section__title", "legal_text")
    readonly_fields = ("archived_at",)


@admin.register(LegalUpdateRecord)
class LegalUpdateRecordAdmin(admin.ModelAdmin):
    list_display = (
        "section_number",
        "update_type_badge",
        "status_badge",
        "source_name",
        "detected_at",
        "verified_at",
        "verified_by",
    )
    list_filter = ("status", "update_type", "detected_at")
    search_fields = ("section_number", "proposed_title", "detected_diff")
    readonly_fields = ("detected_at", "detected_diff_view")
    actions = ["approve_selected", "reject_selected", "trigger_source_check"]

    def status_badge(self, obj):
        colors = {
            "pending": "#f59e0b",
            "approved": "#10b981",
            "rejected": "#ef4444",
        }
        color = colors.get(obj.status, "#6b7280")
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 6px; font-weight: bold; font-size: 11px;">{}</span>',
            color,
            obj.get_status_display(),
        )
    status_badge.short_description = "Verification Status"

    def update_type_badge(self, obj):
        return format_html(
            '<span style="background-color: #4f46e5; color: white; padding: 2px 7px; border-radius: 4px; font-size: 11px;">{}</span>',
            obj.get_update_type_display(),
        )
    update_type_badge.short_description = "Update Type"

    def detected_diff_view(self, obj):
        return format_html(
            '<pre style="background: #1e1e2e; color: #a6accd; padding: 12px; border-radius: 8px; overflow-x: auto; font-family: monospace;">{}</pre>',
            obj.detected_diff or "No diff recorded."
        )
    detected_diff_view.short_description = "Statutory Diff"

    @admin.action(description="Approve selected updates and publish to LegalGuide database")
    def approve_selected(self, request, queryset):
        count = 0
        for record in queryset.filter(status="pending"):
            approve_update(record.id, admin_user=request.user.username or "admin")
            count += 1
        self.message_user(request, f"Successfully approved and published {count} legal update(s).")

    @admin.action(description="Reject selected updates")
    def reject_selected(self, request, queryset):
        count = 0
        for record in queryset.filter(status="pending"):
            reject_update(record.id, admin_user=request.user.username or "admin", reason="Rejected via Admin Dashboard")
            count += 1
        self.message_user(request, f"Rejected {count} update(s).")

    @admin.action(description="Check Official Sources (India Code) for Updates")
    def trigger_source_check(self, request, queryset):
        created = check_official_sources()
        self.message_user(request, f"Official source check complete. Found {len(created)} update(s) pending human verification.")


@admin.register(LegalSection)
class LegalSectionAdmin(admin.ModelAdmin):
    list_display = (
        "section_number",
        "title",
        "law",
        "version_badge",
        "status_badge",
        "effective_date",
        "last_verified",
    )
    list_filter = ("status", "law", "consequences_type", "last_verified")
    search_fields = ("section_number", "title", "legal_text", "example_situation", "example_explanation", "keywords")

    fieldsets = (
        ("Basic Information", {
            "fields": ("law", "section_number", "title", "status", "badge", "keywords")
        }),
        ("Statutory Text & Explanations", {
            "fields": ("legal_text", "simple_explanation", "quick_answer", "purpose", "key_elements", "relevant_information")
        }),
        ("Real-Life Example & Progressive Disclosure", {
            "fields": ("example_title", "example_situation", "example_explanation", "example_disclaimer", "what_you_should_do", "example_steps")
        }),
        ("Consequences & Documents", {
            "fields": ("consequences_type", "punishment", "relevant_documents")
        }),
        ("Visual & Video Media (Optional)", {
            "fields": ("visual_image_url", "visual_caption", "visual_alt_text", "is_visual_illustrative", "video_url", "video_title", "video_duration", "video_thumbnail_url", "video_transcript")
        }),
        ("Statutory Verification & Source", {
            "fields": ("version", "effective_date", "amendment_info", "previous_version_ref", "source", "source_name", "source_type", "last_verified")
        }),
        ("Telugu Localization", {
            "classes": ("collapse",),
            "fields": ("title_te", "simple_explanation_te", "quick_answer_te", "example_title_te", "example_situation_te", "example_explanation_te", "purpose_te", "punishment_te", "key_elements_te", "relevant_information_te", "relevant_documents_te", "what_you_should_do_te", "visual_caption_te")
        }),
        ("Hindi Localization", {
            "classes": ("collapse",),
            "fields": ("title_hi", "simple_explanation_hi", "quick_answer_hi", "example_title_hi", "example_situation_hi", "example_explanation_hi", "purpose_hi", "punishment_hi", "key_elements_hi", "relevant_information_hi", "relevant_documents_hi", "what_you_should_do_hi", "visual_caption_hi")
        }),
        ("Related Provisions", {
            "fields": ("related_sections",)
        }),
    )

    def version_badge(self, obj):
        return format_html(
            '<span style="background-color: #6366f1; color: white; padding: 2px 6px; border-radius: 4px; font-weight: bold; font-size: 11px;">v{}</span>',
            obj.version,
        )
    version_badge.short_description = "Version"

    def status_badge(self, obj):
        colors = {
            "current": "#10b981",
            "historical": "#f59e0b",
            "amended": "#3b82f6",
            "repealed": "#ef4444",
        }
        color = colors.get(obj.status, "#6b7280")
        return format_html(
            '<span style="background-color: {}; color: white; padding: 2px 6px; border-radius: 4px; font-size: 11px;">{}</span>',
            color,
            obj.get_status_display(),
        )
    status_badge.short_description = "Status"


@admin.register(Law)
class LawAdmin(admin.ModelAdmin):
    list_display = ("name", "short_name", "category", "year", "status", "last_verified")
    list_filter = ("status", "category")
    search_fields = ("name", "short_name")


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("name", "name_te", "updated_at")
    search_fields = ("name",)


@admin.register(LegalMatter)
class LegalMatterAdmin(admin.ModelAdmin):
    list_display = ("name", "category", "updated_at")
    list_filter = ("category",)
    search_fields = ("name",)


@admin.register(PublishedLegalUpdate)
class PublishedLegalUpdateAdmin(admin.ModelAdmin):
    list_display = (
        "title", "update_type", "affected_law_short_name",
        "affected_section", "published_at", "effective_date",
    )
    list_filter = ("update_type", "affected_law_short_name")
    readonly_fields = ("published_at",)
    search_fields = ("title", "affected_law_name", "affected_section")