import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'auth_service.dart';

class BookmarkService {
  static String? _activeUserId;
  static Set<int>? _cachedIds;

  /// Global notifier to trigger UI updates across screens when saved state changes
  static final ValueNotifier<int> bookmarkVersion = ValueNotifier<int>(0);

  /// Generates isolated local storage key per authenticated user
  static String _storageKeyFor(String? userId) {
    if (userId == null || userId.trim().isEmpty) {
      return 'lg_saved_guest_v2';
    }
    final sanitized = userId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    return 'lg_saved_user_${sanitized}_v2';
  }

  /// Initializes the service for the specified user account
  static Future<void> initForUser(String? userId) async {
    _activeUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKeyFor(userId);
    final list = prefs.getStringList(key) ?? [];
    _cachedIds = list.map((e) => int.tryParse(e)).whereType<int>().toSet();
    bookmarkVersion.value++;
  }

  /// Called when a user successfully authenticates
  static Future<void> onUserLoggedIn(String userId) async {
    await initForUser(userId);
    await syncWithServer();
  }

  /// Called when the current user logs out
  static Future<void> onUserLoggedOut() async {
    _activeUserId = null;
    _cachedIds = <int>{};
    bookmarkVersion.value++;
  }

  /// Returns the current account's bookmarked section IDs
  static Future<Set<int>> getBookmarkedIds() async {
    if (_cachedIds != null) {
      return Set<int>.from(_cachedIds!);
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKeyFor(_activeUserId);
    final list = prefs.getStringList(key) ?? [];
    _cachedIds = list.map((e) => int.tryParse(e)).whereType<int>().toSet();
    return Set<int>.from(_cachedIds!);
  }

  /// Checks if a section is bookmarked by the active user
  static Future<bool> isBookmarked(int sectionId) async {
    return (await getBookmarkedIds()).contains(sectionId);
  }

  /// Toggles a section bookmark for the active user account
  static Future<void> toggle(int sectionId) async {
    final current = await getBookmarkedIds();
    final isAdding = !current.contains(sectionId);
    if (isAdding) {
      current.add(sectionId);
    } else {
      current.remove(sectionId);
    }
    _cachedIds = Set<int>.from(current);

    // Save to user's isolated local offline cache
    final prefs = await SharedPreferences.getInstance();
    final key = _storageKeyFor(_activeUserId);
    await prefs.setStringList(key, current.map((id) => id.toString()).toList());
    bookmarkVersion.value++;

    // Synchronize to backend if user is logged in
    final token = AuthService.token;
    if (token != null) {
      if (isAdding) {
        _postToServerBackground(sectionId);
      } else {
        _deleteFromServerBackground(sectionId);
      }
    }
  }

  /// Returns the number of saved sections for the active user
  static Future<int> count() async => (await getBookmarkedIds()).length;

  /// Synchronizes bookmarks with backend for the active authenticated user
  static Future<void> syncWithServer() async {
    final token = AuthService.token;
    final userId = _activeUserId;
    if (token == null || userId == null || userId.isEmpty) return;

    try {
      final url = Uri.parse('${ApiService.baseUrl}/saved/');
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List<dynamic>? serverList = data['section_ids'] as List<dynamic>?;
        if (serverList == null && data['saved'] is List) {
          serverList = (data['saved'] as List)
              .map((item) => item['section_id'] ?? item['legalItemId'])
              .toList();
        }

        if (serverList != null) {
          final serverSet = serverList.map((e) => (e as num).toInt()).toSet();

          // Get local isolated items for this user
          final prefs = await SharedPreferences.getInstance();
          final key = _storageKeyFor(userId);
          final localList = prefs.getStringList(key) ?? [];
          final localSet = localList.map((e) => int.tryParse(e)).whereType<int>().toSet();

          // If there are local offline items not on the server, push them
          final offlineOnly = localSet.difference(serverSet);
          for (final sid in offlineOnly) {
            _postToServerBackground(sid);
          }

          // Merge server items with local items
          final unifiedSet = localSet.union(serverSet);
          _cachedIds = unifiedSet;
          await prefs.setStringList(key, unifiedSet.map((id) => id.toString()).toList());
          bookmarkVersion.value++;
        }
      }
    } catch (_) {
      // Best-effort offline/background sync
    }
  }

  static void _postToServerBackground(int sectionId) async {
    final token = AuthService.token;
    if (token == null) return;

    try {
      final url = Uri.parse('${ApiService.baseUrl}/saved/');
      await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'section_id': sectionId,
        }),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  static void _deleteFromServerBackground(int sectionId) async {
    final token = AuthService.token;
    if (token == null) return;

    try {
      final url = Uri.parse('${ApiService.baseUrl}/saved/$sectionId/');
      await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}
  }
}
