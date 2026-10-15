from django.db import models


class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    name_te = models.CharField(max_length=150, blank=True)
    description_te = models.TextField(blank=True)
    name_hi = models.CharField(max_length=150, blank=True)
    description_hi = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class Law(models.Model):
    name = models.CharField(max_length=200)
    short_name = models.CharField(max_length=50, blank=True)
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name="laws"
    )
    description = models.TextField(blank=True)
    year = models.IntegerField(null=True, blank=True, help_text="Year of enactment, e.g. 2023")
    act_number = models.CharField(max_length=50, blank=True, help_text="e.g. Act No. 45 of 2023")
    source_url = models.URLField(blank=True, default="https://www.indiacode.gov.in/")
    source_name = models.CharField(
        max_length=200,
        default="India Code — Ministry of Law & Justice, Govt. of India"
    )
    status = models.CharField(
        max_length=30,
        default="current",
        choices=[("current", "Current"), ("amended", "Amended"), ("repealed", "Repealed")]
    )
    last_verified = models.DateField(null=True, blank=True)
    name_te = models.CharField(max_length=200, blank=True)
    short_name_te = models.CharField(max_length=100, blank=True)
    description_te = models.TextField(blank=True)
    name_hi = models.CharField(max_length=200, blank=True)
    short_name_hi = models.CharField(max_length=100, blank=True)
    description_hi = models.TextField(blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        if self.short_name:
            return f"{self.name} ({self.short_name})"
        return self.name


class LegalSection(models.Model):
    STATUS_CHOICES = [
        ("current", "Current Legal Provision"),
        ("historical", "Historical / Former Provision"),
        ("amended", "Amended Provision"),
        ("repealed", "Repealed Provision"),
    ]

    law = models.ForeignKey(
        Law,
        on_delete=models.CASCADE,
        related_name="sections"
    )

    section_number = models.CharField(max_length=50)
    title = models.CharField(max_length=300)

    legal_text = models.TextField()
    simple_explanation = models.TextField()
    purpose = models.TextField()

    punishment = models.TextField(blank=True)
    relevant_documents = models.TextField(blank=True)

    key_elements = models.TextField(
        blank=True, help_text="One key element per line."
    )
    relevant_information = models.TextField(
        blank=True,
        help_text="Facts worth having clear before consulting a lawyer, one per line.",
    )
    keywords = models.TextField(
        blank=True, help_text="Comma-separated search keywords."
    )
    badge = models.CharField(
        max_length=50, blank=True, help_text="Short label, e.g. 'Most Searched'."
    )

    # Statutory Metadata & Verification
    effective_date = models.DateField(null=True, blank=True, help_text="Date when provision came into force, e.g. 2024-07-01")
    amendment_info = models.TextField(blank=True, help_text="Details of amendments or former law reference, e.g. Replaces IPC Section 378")
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="current")
    source = models.URLField(blank=True, default="https://www.indiacode.gov.in/")
    source_name = models.CharField(
        max_length=200,
        default="India Code — Ministry of Law & Justice, Govt. of India"
    )
    last_verified = models.DateField(null=True, blank=True)
    version = models.PositiveIntegerField(default=1)
    previous_version_ref = models.CharField(
        max_length=150,
        blank=True,
        help_text="Reference to former section / repealed provision (e.g. 'IPC Section 420')"
    )
    updated_at = models.DateTimeField(auto_now=True)

    related_sections = models.ManyToManyField(
        "self",
        blank=True,
        symmetrical=False
    )

    # Telugu translations of the interpretive/explanatory fields.
    title_te = models.CharField(max_length=300, blank=True)
    simple_explanation_te = models.TextField(blank=True)
    purpose_te = models.TextField(blank=True)
    punishment_te = models.TextField(blank=True)
    key_elements_te = models.TextField(blank=True)
    relevant_information_te = models.TextField(blank=True)
    relevant_documents_te = models.TextField(blank=True)

    # Hindi translations of the interpretive/explanatory fields.
    title_hi = models.CharField(max_length=300, blank=True)
    simple_explanation_hi = models.TextField(blank=True)
    purpose_hi = models.TextField(blank=True)
    punishment_hi = models.TextField(blank=True)
    key_elements_hi = models.TextField(blank=True)
    relevant_information_hi = models.TextField(blank=True)
    relevant_documents_hi = models.TextField(blank=True)

    # Universal Real-Life Example & Progressive Disclosure System
    source_type = models.CharField(max_length=150, default="Official Bare Act Gazette", blank=True)
    quick_answer = models.TextField(blank=True)
    quick_answer_te = models.TextField(blank=True)
    quick_answer_hi = models.TextField(blank=True)

    example_title = models.CharField(max_length=200, blank=True)
    example_title_te = models.CharField(max_length=200, blank=True)
    example_title_hi = models.CharField(max_length=200, blank=True)

    example_situation = models.TextField(blank=True)
    example_situation_te = models.TextField(blank=True)
    example_situation_hi = models.TextField(blank=True)

    example_explanation = models.TextField(blank=True)
    example_explanation_te = models.TextField(blank=True)
    example_explanation_hi = models.TextField(blank=True)

    example_disclaimer = models.TextField(blank=True)

    visual_image_url = models.URLField(blank=True)
    visual_caption = models.CharField(max_length=300, blank=True)
    visual_caption_te = models.CharField(max_length=300, blank=True)
    visual_caption_hi = models.CharField(max_length=300, blank=True)
    visual_alt_text = models.CharField(max_length=300, blank=True)
    is_visual_illustrative = models.BooleanField(default=True)

    video_url = models.URLField(blank=True)
    video_title = models.CharField(max_length=200, blank=True)
    video_duration = models.CharField(max_length=50, blank=True)
    video_thumbnail_url = models.URLField(blank=True)
    video_transcript = models.TextField(blank=True)

    example_steps = models.TextField(blank=True, help_text="JSON list of steps: order, title, description, icon")

    what_you_should_do = models.TextField(blank=True)
    what_you_should_do_te = models.TextField(blank=True)
    what_you_should_do_hi = models.TextField(blank=True)

    consequences_type = models.CharField(
        max_length=50,
        default="penal",
        blank=True,
        choices=[
            ("penal", "Punishment & Penalties"),
            ("civil", "Civil Consequences"),
            ("order", "Court Order & Enforcement"),
            ("fine", "Penalties & Fines"),
            ("procedural", "Procedural Consequences"),
        ],
    )

    provision_key = models.CharField(max_length=120, blank=True, db_index=True, help_text="Unique provision key: actId_section_sub")

    @staticmethod
    def normalize_section_number(raw):
        """
        Canonical section number normalization:
        - Trims whitespace
        - Strips 'section', 'article', 'sec', 'art' prefixes
        - Normalizes bracket spacing (e.g. '103 (1)' -> '103(1)')
        - Preserves subsection information ('103' != '103(1)')
        """
        if not raw:
            return ""
        import re
        s = str(raw).strip()
        s = re.sub(r'^(section|article|sec|art)\.?\s*', '', s, flags=re.I)
        s = re.sub(r'\s*\(\s*', '(', s)
        s = re.sub(r'\s*\)\s*', ')', s)
        s = re.sub(r'\s+', ' ', s).strip()
        return s

    @staticmethod
    def compute_provision_key(law_id, section_number):
        import re
        norm_sec = LegalSection.normalize_section_number(section_number)
        clean_sec = re.sub(r'[^a-z0-9]+', '_', (norm_sec or '').lower()).strip('_')
        clean_sec = re.sub(r'_+', '_', clean_sec)
        return f"{law_id}_{clean_sec}"

    def save(self, *args, **kwargs):
        if self.law_id and self.section_number:
            self.provision_key = self.compute_provision_key(self.law_id, self.section_number)
        super().save(*args, **kwargs)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["law", "section_number"],
                name="unique_law_section_number"
            )
        ]

    def __str__(self):
        return f"{self.law.short_name or self.law.name} - Section {self.section_number} (v{self.version})"


class LegalSectionVersion(models.Model):
    """Immutable archive of previous versions of a LegalSection."""
    section = models.ForeignKey(
        LegalSection,
        on_delete=models.CASCADE,
        related_name="versions"
    )
    version = models.PositiveIntegerField()
    legal_text = models.TextField()
    simple_explanation = models.TextField(blank=True)
    punishment = models.TextField(blank=True)
    effective_date = models.DateField(null=True, blank=True)
    amendment_info = models.TextField(blank=True)
    status = models.CharField(max_length=30, default="historical")
    source = models.URLField(blank=True, default="https://www.indiacode.gov.in/")
    source_name = models.CharField(max_length=200, blank=True)
    archived_at = models.DateTimeField(auto_now_add=True)
    verified_by = models.CharField(max_length=150, blank=True)

    class Meta:
        ordering = ["-version"]
        unique_together = ("section", "version")

    def __str__(self):
        return f"{self.section.section_number} (v{self.version})"


class LegalUpdateRecord(models.Model):
    """
    Incoming update records from official government sources (India Code / Gazette).
    Enforces HUMAN VERIFICATION: stays in 'pending' until an admin approves or rejects.
    The AI never autonomously alters this table or the active law.
    """
    UPDATE_TYPE_CHOICES = [
        ("new_act", "New Act"),
        ("new_section", "New Section"),
        ("amendment", "Amendment / Changed Section"),
        ("repeal", "Repeal / Repealed Provision"),
        ("commencement_change", "Commencement Date Change"),
        ("correction", "Correction / Errata"),
        ("rule_change", "Rule Change / Notification"),
        ("changed_penalty", "Changed Penalty"),
        ("changed_section", "Changed Section / Amendment"),
        ("repealed_provision", "Repealed Provision"),
        ("amended_act", "Amended Act"),
        ("new_rule", "New Rule / Notification"),
    ]

    STATUS_CHOICES = [
        ("detected", "Detected"),
        ("pending_review", "Pending Review"),
        ("pending", "Pending Review (Legacy)"),
        ("needs_verification", "Needs Verification / Correction"),
        ("approved", "Approved"),
        ("published", "Published"),
        ("rejected", "Rejected"),
    ]

    section = models.ForeignKey(
        LegalSection,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="update_records"
    )
    law = models.ForeignKey(
        Law,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="update_records"
    )
    act_name = models.CharField(max_length=255, blank=True)
    section_number = models.CharField(max_length=50)
    update_type = models.CharField(max_length=40, choices=UPDATE_TYPE_CHOICES, default="amendment")
    status = models.CharField(max_length=30, choices=STATUS_CHOICES, default="pending_review")
    verification_status = models.CharField(
        max_length=50,
        default="verified",
        blank=True,
        help_text="verified, unverified, needs_recheck, source_limited"
    )

    proposed_title = models.CharField(max_length=300)
    proposed_legal_text = models.TextField()
    proposed_simple_explanation = models.TextField(blank=True)
    proposed_punishment = models.TextField(blank=True)
    proposed_effective_date = models.DateField(null=True, blank=True)
    proposed_amendment_info = models.TextField(blank=True)

    existing_legal_text = models.TextField(blank=True, help_text="Snapshot of previous content before update.")
    detected_diff = models.TextField(blank=True, help_text="Detailed comparison / diff between existing and proposed version.")
    source_url = models.URLField(default="https://www.indiacode.gov.in/")
    source_name = models.CharField(max_length=200, default="India Code — Ministry of Law & Justice, Govt. of India")
    source_publication_date = models.DateField(null=True, blank=True)
    commencement_status = models.CharField(max_length=50, default="In Force", blank=True)

    detected_at = models.DateTimeField(auto_now_add=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    reviewed_by = models.CharField(max_length=150, blank=True)
    verified_at = models.DateTimeField(null=True, blank=True)
    verified_by = models.CharField(max_length=150, blank=True)
    published_at = models.DateTimeField(null=True, blank=True)
    published_by = models.CharField(max_length=150, blank=True)
    admin_notes = models.TextField(blank=True)

    previous_version = models.PositiveIntegerField(null=True, blank=True)
    approved_version = models.PositiveIntegerField(null=True, blank=True)

    @property
    def is_pending(self):
        return self.status in ["detected", "pending_review", "pending", "needs_verification"]

    @property
    def is_approved(self):
        return self.status == "approved"

    @property
    def is_published(self):
        return self.status == "published"

    @property
    def is_rejected(self):
        return self.status == "rejected"

    class Meta:
        ordering = ["-detected_at"]

    def __str__(self):
        return f"[{self.get_status_display()}] {self.section_number} - {self.get_update_type_display()}"


class DatabaseSyncInfo(models.Model):
    """Tracks global synchronization versions and official source verification status."""
    server_version = models.PositiveIntegerField(default=1)
    last_sync_date = models.DateTimeField(auto_now=True)
    last_source_check = models.DateTimeField(null=True, blank=True)
    primary_source_name = models.CharField(
        max_length=200,
        default="India Code (indiacode.gov.in) & Official Gazette of India"
    )
    primary_source_url = models.URLField(default="https://www.indiacode.gov.in/")
    last_source_check_status = models.CharField(max_length=50, default="verified", blank=True)
    last_source_check_summary = models.TextField(blank=True)

    @classmethod
    def get_info(cls):
        info, _ = cls.objects.get_or_create(id=1)
        return info

    def __str__(self):
        return f"Database Sync v{self.server_version} (Last Source Check: {self.last_source_check})"


class LegalMatter(models.Model):
    category = models.ForeignKey(
        Category,
        on_delete=models.CASCADE,
        related_name="matters"
    )
    name = models.CharField(max_length=150)
    description = models.TextField(blank=True)
    name_te = models.CharField(max_length=200, blank=True)
    description_te = models.TextField(blank=True)
    related_sections = models.ManyToManyField(
        LegalSection,
        blank=True,
        related_name="matters"
    )
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.category.name} - {self.name}"


class PublishedLegalUpdate(models.Model):
    """
    A user-visible notification record created ONLY after an Admin approves
    and publishes a legal update.  Normal users can read this table.
    The Admin verification pipeline (LegalUpdateRecord) stays private.
    """
    UPDATE_TYPE_CHOICES = [
        ("amendment", "Amendment"),
        ("new_section", "New Section"),
        ("repeal", "Repeal"),
        ("rule_change", "Rule / Notification Change"),
        ("penalty_change", "Changed Penalty"),
        ("new_act", "New Act"),
    ]

    title = models.CharField(max_length=300)
    description = models.TextField(blank=True)
    update_type = models.CharField(max_length=40, choices=UPDATE_TYPE_CHOICES, default="amendment")

    # Optional link back to the internal record
    source_update_record = models.OneToOneField(
        LegalUpdateRecord,
        on_delete=models.SET_NULL,
        null=True, blank=True,
        related_name="published_update"
    )

    # Human-readable affected law / section
    affected_law_name = models.CharField(max_length=200, blank=True)
    affected_law_short_name = models.CharField(max_length=50, blank=True)
    affected_section = models.CharField(max_length=50, blank=True)
    old_version = models.PositiveIntegerField(null=True, blank=True)
    new_version = models.PositiveIntegerField(null=True, blank=True)

    official_source_name = models.CharField(
        max_length=200,
        default="India Code — Ministry of Law & Justice, Govt. of India"
    )
    official_source_url = models.URLField(default="https://www.indiacode.gov.in/")

    effective_date = models.DateField(null=True, blank=True)
    published_at = models.DateTimeField(auto_now_add=True)
    last_verified_at = models.DateField(null=True, blank=True)

    class Meta:
        ordering = ["-published_at"]

    def __str__(self):
        return f"[Published] {self.title} — {self.affected_law_short_name} s.{self.affected_section}"