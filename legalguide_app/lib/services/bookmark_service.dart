import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'auth_service.dart';

class BookmarkService {
  static const _key = 'lg_bookmarked_section_ids_v1';

  static Future<Set<int>> getBookmarkedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    return list.map(int.parse).toSet();
  }

  static Future<bool> isBookmarked(int sectionId) async {
    return (await getBookmarkedIds()).contains(sectionId);
  }

  static Future<void> toggle(int sectionId) async {
    final ids = await getBookmarkedIds();
    if (ids.contains(sectionId)) {
      ids.remove(sectionId);
    } else {
      ids.add(sectionId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, ids.map((id) => id.toString()).toList());

    // Asynchronously sync to server if logged in
    if (AuthService.token != null) {
      _syncToServerBackground(ids);
    }
  }

  static Future<int> count() async => (await getBookmarkedIds()).length;

  /// Syncs bookmarks with backend: merges local with server, updates local
  static Future<void> syncWithServer() async {
    final token = AuthService.token;
    if (token == null) return;

    try {
      final localIds = await getBookmarkedIds();
      final url = Uri.parse('${ApiService.baseUrl}/accounts/bookmarks/sync/');
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'section_ids': localIds.toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final serverList = data['section_ids'] as List<dynamic>?;
        if (serverList != null) {
          final mergedSet = serverList.map((e) => (e as num).toInt()).toSet();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setStringList(_key, mergedSet.map((id) => id.toString()).toList());
        }
      }
    } catch (_) {
      // Best-effort offline/background sync
    }
  }

  static void _syncToServerBackground(Set<int> ids) async {
    final token = AuthService.token;
    if (token == null) return;

    try {
      final url = Uri.parse('${ApiService.baseUrl}/accounts/bookmarks/sync/');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'section_ids': ids.toList(),
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Best-effort background sync
    }
  }
}
