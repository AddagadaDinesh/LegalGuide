import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../models/legal_matter.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class LegalDataRepository {
  /// Best-effort refresh from the network into the local cache.
  /// Returns true only if all four collections synced successfully.
  static Future<bool> syncAll() async {
    final results = await Future.wait([
      _syncCategories(),
      _syncLaws(),
      _syncSections(),
      _syncMatters(),
    ]);

    final allOk = results.every((ok) => ok);
    if (allOk) {
      await CacheService.setLastSync(DateTime.now());
    }
    return allOk;
  }

  static Future<bool> _syncCategories() async {
    try {
      final categories = await ApiService.fetchCategories();
      await CacheService.saveCategories(categories.map((c) => c.toJson()).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _syncLaws() async {
    try {
      final laws = await ApiService.fetchLaws();
      await CacheService.saveLaws(laws.map((l) => l.toJson()).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _syncSections() async {
    try {
      final sections = await ApiService.fetchSections();
      await CacheService.saveSections(sections.map((s) => s.toJson()).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _syncMatters() async {
    try {
      final matters = await ApiService.fetchMatters();
      await CacheService.saveMatters(matters.map((m) => m.toJson()).toList());
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Category>> loadCategories() async {
    final raw = await CacheService.readCategories();
    return raw.map((json) => Category.fromJson(json)).toList();
  }

  static Future<List<Law>> loadLaws({int? categoryId}) async {
    final raw = await CacheService.readLaws();
    var laws = raw.map((json) => Law.fromJson(json)).toList();
    if (categoryId != null) {
      laws = laws.where((law) => law.categoryId == categoryId).toList();
    }
    return laws;
  }

  static Future<List<LegalSection>> loadSections({int? lawId}) async {
    final raw = await CacheService.readSections();
    var sections = raw.map((json) => LegalSection.fromJson(json)).toList();
    if (lawId != null) {
      sections = sections.where((sec) => sec.lawId == lawId).toList();
    }
    return sections;
  }

  static Future<List<LegalMatter>> loadMatters({int? categoryId}) async {
    final raw = await CacheService.readMatters();
    var matters = raw.map((json) => LegalMatter.fromJson(json)).toList();
    if (categoryId != null) {
      matters = matters.where((m) => m.categoryId == categoryId).toList();
    }
    return matters;
  }

  static Future<bool> hasSyncedBefore() => CacheService.hasSyncedBefore();
  static Future<DateTime?> lastSyncTime() => CacheService.getLastSync();
}
