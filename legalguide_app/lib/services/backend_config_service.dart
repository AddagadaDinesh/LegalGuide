import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class BackendConfigService {
  static const _key = 'lg_backend_base_url_v1';
  static const defaultBaseUrl = 'https://dinesh03.pythonanywhere.com/api';

  // Stable address that never changes; its contents point at whichever
  // tunnel URL is currently fronting the dev backend, so the app can
  // rediscover the backend automatically instead of needing a manually
  // pasted URL every time the tunnel restarts with a new address.
  static const _pointerUrl = 'https://legalguide-pointer.pages.dev/backend_url.txt';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.isNotEmpty) {
      ApiService.baseUrl = saved;
    }
  }

  static Future<void> refreshFromPointer() async {
    try {
      final response = await http.get(Uri.parse(_pointerUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final url = response.body.trim();
        if (url.isNotEmpty && url != ApiService.baseUrl) {
          await setBaseUrl(url);
        }
      }
    } catch (_) {
      // Pointer unreachable; keep using whatever base URL is already set.
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
