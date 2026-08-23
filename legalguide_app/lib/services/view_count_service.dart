import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ViewCountService {
  static const _key = 'lg_view_counts_v1';
  static const frequentThreshold = 2;

  static Future<Map<int, int>> getAllCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((key, value) => MapEntry(int.parse(key), value as int));
  }

  static Future<int> getCount(int sectionId) async {
    final counts = await getAllCounts();
    return counts[sectionId] ?? 0;
  }

  static Future<void> recordView(int sectionId) async {
    final counts = await getAllCounts();
    counts[sectionId] = (counts[sectionId] ?? 0) + 1;
    final prefs = await SharedPreferences.getInstance();
    final encoded = counts.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(_key, jsonEncode(encoded));
  }

  static Future<bool> isFrequent(int sectionId) async {
    return (await getCount(sectionId)) >= frequentThreshold;
  }
}
