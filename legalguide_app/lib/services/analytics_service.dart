import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'connectivity_status_service.dart';

class AnalyticsService {
  static const String _queueKey = 'lg_pending_analytics_events_v1';
  static const String _lastHeartbeatKey = 'lg_last_heartbeat_timestamp';

  static final List<Map<String, dynamic>> _queue = [];
  static bool _isFlushing = false;
  static Timer? _debounceTimer;
  static bool _initialized = false;

  /// Initializes the analytics service, loads any offline pending events,
  /// and listens to connectivity changes to sync upon reconnecting.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_queueKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson);
        if (decoded is List) {
          _queue.addAll(decoded.map((e) => Map<String, dynamic>.from(e as Map)));
        }
      }
    } catch (_) {
      // Ignore corruption
    }

    // Auto-flush when device becomes online
    ConnectivityStatusService.status.addListener(() {
      if (ConnectivityStatusService.status.value == NetworkStatus.online) {
        flushQueue();
        sendHeartbeat();
      }
    });

    // If already online, schedule initial flush and heartbeat
    if (ConnectivityStatusService.status.value == NetworkStatus.online) {
      flushQueue();
      sendHeartbeat();
    }
  }

  /// Track a core app feature usage (aggregate count).
  static void trackFeature(String featureName, {int count = 1}) {
    final cleanName = featureName.trim().toLowerCase();
    if (cleanName.isEmpty) return;
    _enqueue({
      'type': 'feature',
      'name': cleanName,
      'count': count,
    });
  }

  /// Track a search term aggregate.
  static void trackSearch(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty || cleanQuery.length > 150) return;
    _enqueue({
      'type': 'search',
      'query': cleanQuery,
    });
  }

  /// Track a section view.
  static void trackSectionView(int sectionId, String title, {String? lawName}) {
    _enqueue({
      'type': 'section_view',
      'section_id': sectionId,
      'title': title,
      'law_name': lawName ?? '',
    });
  }

  /// Track a law opened.
  static void trackLawView(int lawId, String lawName) {
    _enqueue({
      'type': 'law_view',
      'law_id': lawId,
      'law_name': lawName,
    });
  }

  /// Enqueue event with persistence and debounced sync
  static void _enqueue(Map<String, dynamic> event) {
    _queue.add(event);
    _saveQueue();

    // Debounce flush by 4 seconds
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 4), () {
      if (ConnectivityStatusService.status.value == NetworkStatus.online) {
        flushQueue();
      }
    });
  }

  @visibleForTesting
  static void cancelDebounceTimer() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  static Future<void> _saveQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_queue.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        // Cap offline queue at 150 events to preserve storage
        final toSave = _queue.length > 150 ? _queue.sublist(_queue.length - 150) : _queue;
        await prefs.setString(_queueKey, jsonEncode(toSave));
      }
    } catch (_) {}
  }

  /// Sends lightweight periodic heartbeat for authenticated users.
  /// Throttled to maximum once every 10 minutes to conserve battery.
  static Future<void> sendHeartbeat() async {
    if (!AuthService.isLoggedIn) return;
    if (ConnectivityStatusService.status.value != NetworkStatus.online) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMs = prefs.getInt(_lastHeartbeatKey) ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      // Throttle: 10 minutes (600,000 ms)
      if (nowMs - lastMs < 10 * 60 * 1000) {
        return;
      }

      final token = AuthService.token;
      if (token == null) return;

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/analytics/heartbeat/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        await prefs.setInt(_lastHeartbeatKey, nowMs);
      }
    } catch (_) {
      // Non-critical background ping
    }
  }

  /// Flushes pending queue to backend batch endpoint
  static Future<void> flushQueue() async {
    if (_isFlushing || _queue.isEmpty) return;
    if (ConnectivityStatusService.status.value != NetworkStatus.online) return;

    _isFlushing = true;
    final batchToSend = List<Map<String, dynamic>>.from(_queue);

    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (AuthService.token != null) {
        headers['Authorization'] = 'Token ${AuthService.token}';
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/analytics/track/'),
        headers: headers,
        body: jsonEncode({'events': batchToSend}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Remove successfully sent items from queue
        _queue.removeRange(0, batchToSend.length.clamp(0, _queue.length));
        await _saveQueue();
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AnalyticsService] Failed to flush analytics batch: $e');
      }
    } finally {
      _isFlushing = false;
    }
  }

  /// Cancels any active debounce timers (useful for test isolation)
  @visibleForTesting
  static void cancelTimersForTesting() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }
}
