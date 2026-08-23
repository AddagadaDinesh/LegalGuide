import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  AuthResult({required this.success, this.error});
}

class AuthService {
  static const _tokenKey = 'lg_auth_token_v1';
  static const _usernameKey = 'lg_auth_username_v1';

  static String? _token;
  static final ValueNotifier<String?> currentUsername = ValueNotifier<String?>(null);

  static String? get token => _token;
  static bool get isLoggedIn => _token != null;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    currentUsername.value = prefs.getString(_usernameKey);
  }

  static Future<AuthResult> signup(String username, String email, String password) {
    return _authRequest('signup', {
      'username': username,
      'email': email,
      'password': password,
    });
  }

  static Future<AuthResult> login(String username, String password) {
    return _authRequest('login', {
      'username': username,
      'password': password,
    });
  }

  static Future<AuthResult> _authRequest(String endpoint, Map<String, String> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/$endpoint/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 || response.statusCode == 201) {
        _token = data['token'] as String;
        final username = (data['user'] as Map<String, dynamic>)['username'] as String;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_usernameKey, username);
        currentUsername.value = username;
        return AuthResult(success: true);
      }
      final detail = data['detail'] ?? _firstFieldError(data) ?? 'Something went wrong.';
      return AuthResult(success: false, error: detail.toString());
    } catch (_) {
      return AuthResult(success: false, error: 'Could not reach the server. Check your connection.');
    }
  }

  static String? _firstFieldError(Map<String, dynamic> data) {
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
    }
    return null;
  }

  static Future<void> logout() async {
    final currentToken = _token;
    _token = null;
    currentUsername.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    if (currentToken != null) {
      try {
        await http.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout/'),
          headers: {'Authorization': 'Token $currentToken'},
        ).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Local session is already cleared either way.
      }
    }
  }
}
