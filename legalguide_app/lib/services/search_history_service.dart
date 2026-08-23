import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const _key = 'lg_search_history_v1';
  static const _minQueryLength = 2;

  static Future<Map<String, int>> _getCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((key, value) => MapEntry(key, value as int));
  }

  static Future<void> recordQuery(String query) async {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.length < _minQueryLength) return;
    final counts = await _getCounts();
    counts[trimmed] = (counts[trimmed] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(counts));
  }

  static Future<List<String>> getTopQueries({int limit = 6}) async {
    final counts = await _getCounts();
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }
}
