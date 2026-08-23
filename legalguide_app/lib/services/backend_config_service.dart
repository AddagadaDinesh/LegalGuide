import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class BackendConfigService {
  static const _key = 'lg_backend_base_url_v1';
  static const defaultBaseUrl = 'http://127.0.0.1:8000/api';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      ApiService.baseUrl = saved;
    }
  }

  static Future<void> setBaseUrl(String url) async {
    final normalized = url.trim().replaceAll(RegExp(r'/+$'), '');
    ApiService.baseUrl = normalized.isEmpty ? defaultBaseUrl : normalized;
    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, normalized);
    }
  }
}
