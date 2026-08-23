import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';

class SectionLookup {
  final Map<int, Law> _lawsById;
  final Map<int, Category> _categoriesById;

  SectionLookup(List<Law> laws, List<Category> categories)
      : _lawsById = {for (final l in laws) l.id: l},
        _categoriesById = {for (final c in categories) c.id: c};

  Law? lawFor(LegalSection section) => _lawsById[section.lawId];

  Category? categoryFor(LegalSection section) {
    final law = lawFor(section);
    if (law == null) return null;
    return _categoriesById[law.categoryId];
  }

  String lawShortNameFor(LegalSection section) =>
      lawFor(section)?.shortName ?? '';

  String categoryNameFor(LegalSection section) =>
      categoryFor(section)?.name ?? '';

  String breadcrumbFor(LegalSection section) {
    final category = categoryNameFor(section);
    final law = lawFor(section)?.name ?? '';
    if (category.isEmpty && law.isEmpty) return '';
    if (category.isEmpty) return law;
    if (law.isEmpty) return category;
    return '$category · $law';
  }
}
