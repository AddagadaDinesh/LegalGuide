import '../models/category.dart';
import '../models/law.dart';
import '../models/legal_section.dart';
import '../models/legal_section_version.dart';
import '../models/legal_matter.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/sqlite_legal_db.dart';

class LegalDataRepository {
  /// Delta refresh from the network into local SQLite database.
  /// Downloads only changed records (incremental delta).
  static Future<bool> syncAll() async {
    try {
      final lastSyncStr = await SqliteLegalDb.getLastSyncTimestamp();
      final delta = await ApiService.fetchDeltaSync(sinceTimestamp: lastSyncStr);
      final applied = await SqliteLegalDb.applyDeltaSync(delta);
      if (applied) {
        await CacheService.setLastSync(DateTime.now());
        return true;
      }
    } catch (_) {
      // Fallback: try individual collections if delta endpoint fails
      try {
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
      } catch (_) {}
    }
    return false;
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
    try {
      final dbCategories = await SqliteLegalDb.getCategories();
      if (dbCategories.isNotEmpty) return dbCategories;
    } catch (_) {}
    final raw = await CacheService.readCategories();
    return raw.map((json) => Category.fromJson(json)).toList();
  }

  static Future<List<Law>> loadLaws({int? categoryId}) async {
    try {
      final dbLaws = await SqliteLegalDb.getLaws(categoryId: categoryId);
      if (dbLaws.isNotEmpty) return dbLaws;
    } catch (_) {}
    final raw = await CacheService.readLaws();
    var laws = raw.map((json) => Law.fromJson(json)).toList();
    if (categoryId != null) {
      laws = laws.where((law) => law.categoryId == categoryId).toList();
    }
    return laws;
  }

  static Future<List<LegalSection>> loadSections({int? lawId}) async {
    List<LegalSection> result = [];
    try {
      final dbSections = await SqliteLegalDb.getSections(lawId: lawId);
      if (dbSections.isNotEmpty) result = dbSections;
    } catch (_) {}
    if (result.isEmpty) {
      try {
        final remoteSections = await ApiService.fetchSections(lawId: lawId);
        if (remoteSections.isNotEmpty) result = remoteSections;
      } catch (_) {}
    }
    if (result.isEmpty) {
      final raw = await CacheService.readSections();
      var sections = raw.map((json) => LegalSection.fromJson(json)).toList();
      if (lawId != null) {
        sections = sections.where((sec) => sec.lawId == lawId).toList();
      }
      result = sections;
    }
    // Defensive deduplication using stable legal provision key (Act ID + Section + Subsection)
    final seen = <String>{};
    return result.where((sec) => seen.add(sec.provisionKey)).toList();
  }

  static Future<List<LegalSectionVersion>> loadSectionVersions(int sectionId) async {
    try {
      return await SqliteLegalDb.getSectionVersions(sectionId);
    } catch (_) {
      return [];
    }
  }

  static Future<List<LegalMatter>> loadMatters({int? categoryId}) async {
    try {
      final dbMatters = await SqliteLegalDb.getMatters(categoryId: categoryId);
      if (dbMatters.isNotEmpty) return dbMatters;
    } catch (_) {}
    final raw = await CacheService.readMatters();
    var matters = raw.map((json) => LegalMatter.fromJson(json)).toList();
    if (categoryId != null) {
      matters = matters.where((m) => m.categoryId == categoryId).toList();
    }
    return matters;
  }

  static Future<bool> hasSyncedBefore() async {
    final last = await SqliteLegalDb.getLastSyncDateTime();
    if (last != null) return true;
    return CacheService.hasSyncedBefore();
  }

  static Future<DateTime?> lastSyncTime() async {
    final last = await SqliteLegalDb.getLastSyncDateTime();
    if (last != null) return last;
    return CacheService.getLastSync();
  }

  static Future<String> primarySourceName() async {
    try {
      return await SqliteLegalDb.getPrimarySourceName();
    } catch (_) {
      return 'India Code (Official Government Source)';
    }
  }

  static Future<String> lastVerifiedDate() async {
    try {
      return await SqliteLegalDb.getLastVerifiedDate();
    } catch (_) {
      return '2024-07-01';
    }
  }

  static Future<Map<String, int>> getDatabaseStats() async {
    try {
      return await SqliteLegalDb.getDatabaseStats();
    } catch (_) {
      return {'acts': 0, 'sections': 0, 'versions': 0};
    }
  }
}

