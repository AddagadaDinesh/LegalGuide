import os
import sys
import json
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'legalguide.settings')
django.setup()

from laws.models import Category, Law, LegalSection, LegalMatter
from laws.serializers import CategorySerializer, LawSerializer, LegalSectionSerializer, LegalMatterSerializer

seed_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'legalguide_app', 'assets', 'seed'))
os.makedirs(seed_dir, exist_ok=True)

# 1. Categories
categories = Category.objects.all()
cat_data = CategorySerializer(categories, many=True).data
with open(os.path.join(seed_dir, 'categories.json'), 'w', encoding='utf-8') as f:
    json.dump(cat_data, f, ensure_ascii=False, indent=2)
print(f"Exported {len(cat_data)} categories to {os.path.join(seed_dir, 'categories.json')}")

# 2. Laws
laws = Law.objects.all()
laws_data = LawSerializer(laws, many=True).data
with open(os.path.join(seed_dir, 'laws.json'), 'w', encoding='utf-8') as f:
    json.dump(laws_data, f, ensure_ascii=False, indent=2)
print(f"Exported {len(laws_data)} laws to {os.path.join(seed_dir, 'laws.json')}")

# 3. Sections
sections = LegalSection.objects.all()
sec_data = LegalSectionSerializer(sections, many=True).data
with open(os.path.join(seed_dir, 'sections.json'), 'w', encoding='utf-8') as f:
    json.dump(sec_data, f, ensure_ascii=False, indent=2)
print(f"Exported {len(sec_data)} sections to {os.path.join(seed_dir, 'sections.json')}")

# 4. Matters
matters = LegalMatter.objects.all()
mat_data = LegalMatterSerializer(matters, many=True).data
with open(os.path.join(seed_dir, 'matters.json'), 'w', encoding='utf-8') as f:
    json.dump(mat_data, f, ensure_ascii=False, indent=2)
print(f"Exported {len(mat_data)} matters to {os.path.join(seed_dir, 'matters.json')}")
