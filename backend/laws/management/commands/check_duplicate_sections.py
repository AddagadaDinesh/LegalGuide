import re
from collections import defaultdict
from django.core.management.base import BaseCommand
from laws.models import LegalSection, Law


class Command(BaseCommand):
    help = (
        "Audits the legal sections database for any duplicate records by "
        "canonical provision identity (Act + normalized section number). "
        "Reports Act, Law ID, Section Number, Provision Key, IDs, Versions, and Updated dates."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            "--fix",
            action="store_true",
            help="Safely merges and eliminates duplicate sections, retaining the newest/best record.",
        )

    def handle(self, *args, **options):
        fix_mode = options.get("fix", False)
        self.stdout.write(self.style.NOTICE("Auditing legal database for duplicate provisions..."))

        sections = LegalSection.objects.all().select_related("law")
        groups = defaultdict(list)

        for s in sections:
            norm_sec = LegalSection.normalize_section_number(s.section_number)
            # Group key by law and normalized section number
            key = (s.law_id, norm_sec)
            groups[key].append(s)

        duplicates_found = 0
        for (law_id, norm_sec), sec_list in groups.items():
            if len(sec_list) > 1:
                duplicates_found += 1
                law = sec_list[0].law
                self.stdout.write(
                    self.style.WARNING(
                        f"\n[DUPLICATE DETECTED] Act: '{law.name}' ({law.short_name}) | Law ID: {law_id} | Normalized Sec: '{norm_sec}'"
                    )
                )
                for s in sec_list:
                    self.stdout.write(
                        f"  -> ID={s.id} | Section Number='{s.section_number}' | Provision Key='{s.provision_key}' | "
                        f"Version=v{s.version} | Updated At={s.updated_at.isoformat() if s.updated_at else 'N/A'}"
                    )

                if fix_mode:
                    # Sort to pick best record: newest updated_at -> highest version -> non-empty content
                    sorted_secs = sorted(
                        sec_list,
                        key=lambda x: (
                            x.updated_at or "",
                            x.version,
                            bool(x.visual_image_url),
                            bool(x.legal_text),
                        ),
                        reverse=True,
                    )
                    best = sorted_secs[0]
                    duplicates_to_remove = sorted_secs[1:]

                    # Merge useful non-empty fields from inferior duplicates into best
                    for dup in duplicates_to_remove:
                        if not best.visual_image_url and dup.visual_image_url:
                            best.visual_image_url = dup.visual_image_url
                        if not best.video_url and dup.video_url:
                            best.video_url = dup.video_url
                        if not best.example_situation and dup.example_situation:
                            best.example_situation = dup.example_situation

                    best.save()
                    for dup in duplicates_to_remove:
                        self.stdout.write(self.style.ERROR(f"     Deleting inferior duplicate ID={dup.id}"))
                        dup.delete()

        if duplicates_found == 0:
            self.stdout.write(
                self.style.SUCCESS(
                    f"Audit complete: 0 duplicate provisions found across {sections.count()} total sections. "
                    "Database is strictly clean and unique."
                )
            )
        else:
            self.stdout.write(
                self.style.WARNING(
                    f"\nAudit complete: Found {duplicates_found} duplicate provision group(s)."
                )
            )
