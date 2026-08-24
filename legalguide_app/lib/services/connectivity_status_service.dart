import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ConnectivityStatusService {
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  static Timer? _pollTimer;
  static StreamSubscription<List<ConnectivityResult>>? _networkSub;
  static int _checkId = 0;

  static void start({Duration pollInterval = const Duration(seconds: 6)}) {
    _checkNow();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(pollInterval, (_) => _checkNow());

    _networkSub?.cancel();
    _networkSub = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none)) {
        isOnline.value = false;
      }
      _checkNow();
    });
  }

  static void stop() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _networkSub?.cancel();
    _networkSub = null;
  }

  static Future<void> _checkNow() async {
    final thisCheck = ++_checkId;
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/categories/'))
          .timeout(const Duration(seconds: 8));
      if (thisCheck == _checkId) isOnline.value = response.statusCode == 200;
    } catch (_) {
      if (thisCheck == _checkId) isOnline.value = false;
    }
  }
}
