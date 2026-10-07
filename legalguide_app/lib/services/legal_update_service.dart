import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/legal_update.dart';
import 'api_service.dart';
import 'connectivity_status_service.dart';

/// Service for fetching and caching published legal updates for normal users.
/// Only PUBLISHED (admin-approved) updates are exposed here.
/// Admin internal pipeline is accessed via AdminAnalyticsService only.
class LegalUpdateService {
  static const String _cacheKey = 'cached_legal_updates';
  static const String _readIdsKey = 'read_legal_update_ids';
  static const String _lastSyncKey = 'legal_updates_last_sync';

  /// In-memory cache of current updates (refreshed on sync)
  static List<LegalUpdate> _cachedUpdates = [];
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  static List<LegalUpdate> get cachedUpdates => List.unmodifiable(_cachedUpdates);

  /// Loads updates from local cache, then optionally syncs from server.
  static Future<List<LegalUpdate>> loadUpdates({bool forceSync = false}) async {
    // First load from local cache
    await _loadFromCache();

    // Sync from server if online
    final isOnline = ConnectivityStatusService.isInternetConnected;
    if (isOnline || forceSync) {
      await syncFromServer();
    }

    _refreshUnreadCount();
    return _cachedUpdates;
  }

  /// Fetches only new published updates since last sync (incremental).
  static Future<bool> syncFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      String url = '${ApiService.baseUrl}/legal-updates/';
      if (lastSync != null && lastSync.isNotEmpty) {
        url += '?since=${Uri.encodeComponent(lastSync)}';
      }

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> rawUpdates = json['updates'] as List? ?? [];

        if (rawUpdates.isNotEmpty) {
          final newUpdates = rawUpdates
              .map((e) => LegalUpdate.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();

          // Merge with existing — avoid duplicates by id
          final existingIds = _cachedUpdates.map((u) => u.id).toSet();
          final readIds = await _getReadIds();

          for (final update in newUpdates) {
            if (!existingIds.contains(update.id)) {
              update.isRead = readIds.contains(update.id);
              _cachedUpdates.insert(0, update);
            }
          }

          // Sort by publishedAt descending
          _cachedUpdates.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

          await _saveToCache();
        }

        // Save last sync timestamp from server
        final serverSync = json['last_sync'] as String?;
        if (serverSync != null) {
          await prefs.setString(_lastSyncKey, serverSync);
        }

        _refreshUnreadCount();
        return true;
      }
    } catch (e) {
      debugPrint('[LegalUpdateService] Sync error: $e');
    }
    return false;
  }

  /// Marks an update as read locally. Does not call any server endpoint.
  static Future<void> markAsRead(int updateId) async {
    final readIds = await _getReadIds();
    readIds.add(updateId);
    await _saveReadIds(readIds);

    // Update in-memory flag
    for (final u in _cachedUpdates) {
      if (u.id == updateId) {
        u.isRead = true;
        break;
      }
    }
    _refreshUnreadCount();
  }

  /// Marks all updates as read.
  static Future<void> markAllAsRead() async {
    final allIds = _cachedUpdates.map((u) => u.id).toSet();
    await _saveReadIds(allIds);
    for (final u in _cachedUpdates) {
      u.isRead = true;
    }
    _refreshUnreadCount();
  }

  static void _refreshUnreadCount() {
    final count = _cachedUpdates.where((u) => !u.isRead).length;
    unreadCount.value = count;
  }

  /// Returns the last sync timestamp (to display to user).
  static Future<String?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSyncKey);
  }

  static Future<String> getFormattedLastSync() async {
    final ts = await getLastSyncTimestamp();
    if (ts == null) return '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return ts;
    }
  }

  // ── Private helpers ──────────────────────────────────────────────

  static Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw) as List;
        final readIds = await _getReadIds();
        _cachedUpdates = list
            .map((e) {
              final u = LegalUpdate.fromJson(Map<String, dynamic>.from(e as Map));
              u.isRead = readIds.contains(u.id);
              return u;
            })
            .toList();
      }
    } catch (e) {
      debugPrint('[LegalUpdateService] Cache load error: $e');
    }
  }

  static Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cachedUpdates.map((u) => u.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('[LegalUpdateService] Cache save error: $e');
    }
  }

  static Future<Set<int>> _getReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_readIdsKey);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => e as int).toSet();
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveReadIds(Set<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readIdsKey, jsonEncode(ids.toList()));
  }
}
