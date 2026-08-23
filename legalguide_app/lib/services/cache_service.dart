import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _categoriesKey = 'lg_cache_categories_v1';
  static const _lawsKey = 'lg_cache_laws_v1';
  static const _sectionsKey = 'lg_cache_sections_v1';
  static const _mattersKey = 'lg_cache_matters_v1';
  static const _lastSyncKey = 'lg_cache_last_sync_v1';

  static Future<void> _saveList(String key, List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items));
  }

  static Future<List<Map<String, dynamic>>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];
    final List<dynamic> decoded = jsonDecode(raw);
    return decoded.cast<Map<String, dynamic>>();
  }

  static Future<void> saveCategories(List<Map<String, dynamic>> items) =>
      _saveList(_categoriesKey, items);
  static Future<List<Map<String, dynamic>>> readCategories() =>
      _readList(_categoriesKey);

  static Future<void> saveLaws(List<Map<String, dynamic>> items) =>
      _saveList(_lawsKey, items);
  static Future<List<Map<String, dynamic>>> readLaws() => _readList(_lawsKey);

  static Future<void> saveSections(List<Map<String, dynamic>> items) =>
      _saveList(_sectionsKey, items);
  static Future<List<Map<String, dynamic>>> readSections() =>
      _readList(_sectionsKey);

  static Future<void> saveMatters(List<Map<String, dynamic>> items) =>
      _saveList(_mattersKey, items);
  static Future<List<Map<String, dynamic>>> readMatters() =>
      _readList(_mattersKey);

  static Future<void> setLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  static Future<bool> hasSyncedBefore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_lastSyncKey);
  }
}
