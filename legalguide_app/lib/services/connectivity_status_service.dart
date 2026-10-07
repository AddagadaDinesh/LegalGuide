import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../repositories/legal_data_repository.dart';
import 'api_service.dart';
import 'backend_config_service.dart';

/// Network connectivity states:
/// 1. [online]: Device has active internet AND backend is reachable with database connected.
/// 2. [serverOnlineDatabaseUnavailable]: Backend is reachable, but database is disconnected.
/// 3. [internetAvailableBackendUnavailable]: Device has active internet, but backend is unreachable or returning error.
/// 4. [offline]: Device has no active internet connection.
enum NetworkStatus {
  online,
  serverOnlineDatabaseUnavailable,
  internetAvailableBackendUnavailable,
  offline,
}

class ConnectivityStatusService {
  /// Tri-state notifier representing the real network and backend status.
  static final ValueNotifier<NetworkStatus> status =
      ValueNotifier<NetworkStatus>(NetworkStatus.offline);

  /// Backward-compatible notifier for components that check boolean online status
  /// (true when status == NetworkStatus.online || status == NetworkStatus.serverOnlineDatabaseUnavailable).
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);

  /// Timestamp of the last successful health probe.
  static final ValueNotifier<DateTime?> lastChecked =
      ValueNotifier<DateTime?>(null);

  static Timer? _pollTimer;
  static Timer? _debounceTimer;
  static StreamSubscription<List<ConnectivityResult>>? _networkSub;
  static int _checkId = 0;
  static bool _isChecking = false;

  static NetworkStatus get currentStatus => status.value;
  static bool get isInternetConnected => status.value != NetworkStatus.offline;
  static bool get isBackendAvailable =>
      status.value == NetworkStatus.online ||
      status.value == NetworkStatus.serverOnlineDatabaseUnavailable;

  static void start({Duration pollInterval = const Duration(seconds: 30)}) {
    _checkNow();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _checkNow());

    _networkSub?.cancel();
    _networkSub = Connectivity().onConnectivityChanged.listen((results) {
      _onConnectivityChanged(results);
    });
  }

  static void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _networkSub?.cancel();
    _networkSub = null;
  }

  static void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none)) {
      _applyStatus(
        NetworkStatus.offline,
        reason: 'No active network interfaces',
      );
      return;
    }

    // Debounce network changes by 700ms to allow interface/DHCP to stabilize
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 700), () {
      _checkNow();
    });
  }

  static Future<void> checkNow({bool force = false}) async {
    await _checkNow(force: force);
  }

  static Future<void> _checkNow({bool force = false}) async {
    if (_isChecking && !force) return;
    _isChecking = true;
    final thisCheck = ++_checkId;

    try {
      // 1. Check network interface
      final connectivityResults = await Connectivity().checkConnectivity();
      final hasInterface = connectivityResults.isNotEmpty &&
          !connectivityResults.every((r) => r == ConnectivityResult.none);

      final netType = connectivityResults.map((r) => r.name).join(', ');

      if (!hasInterface) {
        if (thisCheck == _checkId) {
          _logState(
            netType: netType.isEmpty ? 'None' : netType,
            hasInternet: false,
            backendResponse: null,
            failureReason: 'No network interface',
            newStatus: NetworkStatus.offline,
          );
          _applyStatus(NetworkStatus.offline, reason: 'No network interface');
        }
        return;
      }

      // 2. Real lightweight Internet validation (No Google dependency)
      final hasInternet = await _checkInternetReachability();
      if (!hasInternet) {
        if (thisCheck == _checkId) {
          _logState(
            netType: netType,
            hasInternet: false,
            backendResponse: null,
            failureReason: 'DNS/Socket reachability check failed',
            newStatus: NetworkStatus.offline,
          );
          _applyStatus(NetworkStatus.offline, reason: 'Internet unreachable');
        }
        return;
      }

      // 3. Device has active internet! Now check backend reachability
      await BackendConfigService.refreshFromPointer();

      String? backendResponse;
      String? failureReason;
      bool backendReachable = false;
      bool isDbConnected = true;

      // Attempt 1: health probe
      final probeResult1 = await _probeBackend();
      if (probeResult1.isSuccess) {
        backendReachable = true;
        isDbConnected = probeResult1.isDatabaseConnected;
        backendResponse = 'HTTP ${probeResult1.statusCode}';
      } else {
        // Retry logic: wait 1.2s and retry once to avoid false negative on transient network blip
        await Future.delayed(const Duration(milliseconds: 1200));
        if (thisCheck != _checkId) return;

        final probeResult2 = await _probeBackend();
        if (probeResult2.isSuccess) {
          backendReachable = true;
          isDbConnected = probeResult2.isDatabaseConnected;
          backendResponse = 'HTTP ${probeResult2.statusCode} (retry)';
        } else {
          backendResponse = probeResult2.statusCode != null
              ? 'HTTP ${probeResult2.statusCode}'
              : null;
          failureReason = probeResult2.errorMessage;
        }
      }

      if (thisCheck != _checkId) return;

      final classifiedStatus = backendReachable
          ? (isDbConnected
              ? NetworkStatus.online
              : NetworkStatus.serverOnlineDatabaseUnavailable)
          : NetworkStatus.internetAvailableBackendUnavailable;

      _logState(
        netType: netType,
        hasInternet: true,
        backendResponse: backendResponse,
        failureReason: failureReason,
        newStatus: classifiedStatus,
      );

      _applyStatus(classifiedStatus);
    } catch (e, stack) {
      debugPrint('[ConnectivityStatusService] Error during check: $e\n$stack');
    } finally {
      _isChecking = false;
    }
  }

  /// Lightweight reachability check without Google dependency.
  /// Tests DNS resolution and TCP socket connect to standard global DNS ports.
  static Future<bool> _checkInternetReachability() async {
    // Strategy 1: DNS lookup to reliable public DNS resolvers (Cloudflare, Quad9)
    const hostnames = ['one.one.one.one', 'cloudflare.com', 'quad9.net'];
    for (final host in hostnames) {
      try {
        final res = await InternetAddress.lookup(host)
            .timeout(const Duration(milliseconds: 2500));
        if (res.isNotEmpty && res.first.rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        // Try next host
      }
    }

    // Strategy 2: Direct TCP socket connect to standard DNS ports (1.1.1.1:53 or 9.9.9.9:53)
    const testIps = ['1.1.1.1', '1.0.0.1', '9.9.9.9'];
    for (final ip in testIps) {
      try {
        final socket = await Socket.connect(
          ip,
          53,
          timeout: const Duration(milliseconds: 2000),
        );
        socket.destroy();
        return true;
      } catch (_) {
        // Try next IP
      }
    }

    return false;
  }

  /// Probe LegalGuide backend health endpoint with fallback
  static Future<_ProbeResult> _probeBackend() async {
    final healthUri = Uri.parse('${ApiService.baseUrl}/health/');
    try {
      final response =
          await http.get(healthUri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        bool dbConnected = true;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded['database'] == 'disconnected') {
            dbConnected = false;
          }
        } catch (_) {}
        return _ProbeResult(
          isSuccess: true,
          statusCode: 200,
          isDatabaseConnected: dbConnected,
        );
      }

      // If health endpoint returns 404 (e.g. older deployment), fallback probe /categories/
      if (response.statusCode == 404) {
        final fallbackUri = Uri.parse('${ApiService.baseUrl}/categories/');
        final fallbackResp =
            await http.get(fallbackUri).timeout(const Duration(seconds: 10));
        if (fallbackResp.statusCode == 200) {
          return _ProbeResult(
            isSuccess: true,
            statusCode: 200,
            isDatabaseConnected: true,
          );
        }
        return _ProbeResult(
          isSuccess: false,
          statusCode: fallbackResp.statusCode,
          errorMessage: 'Backend returned HTTP ${fallbackResp.statusCode}',
        );
      }

      return _ProbeResult(
        isSuccess: false,
        statusCode: response.statusCode,
        errorMessage: 'Backend returned HTTP ${response.statusCode}',
      );
    } on SocketException catch (e) {
      return _ProbeResult(
        isSuccess: false,
        errorMessage: 'SocketException: ${e.message}',
      );
    } on TimeoutException {
      return _ProbeResult(
        isSuccess: false,
        errorMessage: 'TimeoutException: Request timed out',
      );
    } on HandshakeException catch (e) {
      return _ProbeResult(
        isSuccess: false,
        errorMessage: 'SSL HandshakeException: ${e.message}',
      );
    } on HttpException catch (e) {
      return _ProbeResult(
        isSuccess: false,
        errorMessage: 'HttpException: ${e.message}',
      );
    } catch (e) {
      return _ProbeResult(isSuccess: false, errorMessage: e.toString());
    }
  }

  static void _applyStatus(NetworkStatus newStatus, {String? reason}) {
    lastChecked.value = DateTime.now();
    final previous = status.value;
    status.value = newStatus;
    isOnline.value = (newStatus == NetworkStatus.online ||
        newStatus == NetworkStatus.serverOnlineDatabaseUnavailable);

    // Auto-sync when transitioning to online
    if (previous != NetworkStatus.online && newStatus == NetworkStatus.online) {
      _triggerBackgroundSync();
    }
  }

  static void _triggerBackgroundSync() {
    LegalDataRepository.syncAll().catchError((e) {
      debugPrint('[ConnectivityStatusService] Background sync error: $e');
      return false;
    });
  }

  static void _logState({
    required String netType,
    required bool hasInternet,
    required String? backendResponse,
    required String? failureReason,
    required NetworkStatus newStatus,
  }) {
    debugPrint(
      '[ConnectivityStatusService]\n'
      '  Network type: $netType\n'
      '  Internet reachability: $hasInternet\n'
      '  Backend URL: ${ApiService.baseUrl}\n'
      '  Backend response: ${backendResponse ?? "N/A"}\n'
      '  Failure: ${failureReason ?? "None"}\n'
      '  Classified status: ${newStatus.name}',
    );
  }
}

class _ProbeResult {
  final bool isSuccess;
  final int? statusCode;
  final String? errorMessage;
  final bool isDatabaseConnected;

  _ProbeResult({
    required this.isSuccess,
    this.statusCode,
    this.errorMessage,
    this.isDatabaseConnected = true,
  });
}
