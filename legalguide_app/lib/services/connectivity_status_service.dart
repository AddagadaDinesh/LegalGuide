import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ConnectivityStatusService {
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(false);
  static Timer? _timer;

  static void start({Duration interval = const Duration(seconds: 20)}) {
    _checkNow();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _checkNow());
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _checkNow() async {
    try {
      final response = await http
          .get(Uri.parse('${ApiService.baseUrl}/categories/'))
          .timeout(const Duration(seconds: 4));
      isOnline.value = response.statusCode == 200;
    } catch (_) {
      isOnline.value = false;
    }
  }
}
