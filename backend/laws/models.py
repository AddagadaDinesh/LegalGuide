from django.db import models


class Category(models.Model):
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    name_te = models.CharField(max_length=150, blank=True)
    description_te = models.TextField(blank=True)

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

    def __str__(self):
        if self.short_name:
            return f"{self.name} ({self.short_name})"
        return self.name


class LegalSection(models.Model):
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

    source = models.URLField(blank=True)
    last_verified = models.DateField(null=True, blank=True)

    related_sections = models.ManyToManyField(
        "self",
        blank=True,
        symmetrical=False
    )

    # Telugu translations of the interpretive/explanatory fields. The
    # official statutory text (legal_text) is deliberately left untranslated
    # — it must stay the verbatim bare-act wording, not a paraphrase.
    title_te = models.CharField(max_length=300, blank=True)
    simple_explanation_te = models.TextField(blank=True)
    purpose_te = models.TextField(blank=True)
    punishment_te = models.TextField(blank=True)
    key_elements_te = models.TextField(blank=True)
    relevant_information_te = models.TextField(blank=True)
    relevant_documents_te = models.TextField(blank=True)

    def __str__(self):
        return f"{self.law.short_name or self.law.name} - Section {self.section_number}"


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

    def __str__(self):
        return f"{self.category.name} - {self.name}"