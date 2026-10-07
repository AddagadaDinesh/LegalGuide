import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'bookmark_service.dart';

class AuthResult {
  final bool success;
  final String? error;
  final bool? emailSent;
  final String? emailError;

  AuthResult({
    required this.success,
    this.error,
    this.emailSent,
    this.emailError,
  });

  bool get isEmailSent => emailSent == true;
  bool get isEmailFailed => emailSent == false;
}

class AuthService {
  static const _tokenKey = 'lg_auth_token_v1';
  static const _usernameKey = 'lg_auth_username_v1';
  static const _roleKey = 'lg_auth_role_v1';
  static const _userIdKey = 'lg_auth_user_id_v1';

  static String? _token;
  static final ValueNotifier<String?> currentUsername = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentRole = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> currentUserId = ValueNotifier<String?>(null);

  static String? get token => _token;
  static bool get isLoggedIn => _token != null;

  static bool get isAdmin {
    final role = currentRole.value?.toUpperCase().trim();
    return role == 'ADMIN';
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    currentUsername.value = prefs.getString(_usernameKey);
    currentRole.value = prefs.getString(_roleKey);
    final storedUserId = prefs.getString(_userIdKey) ?? currentUsername.value;
    currentUserId.value = storedUserId;

    await BookmarkService.initForUser(storedUserId);

    if (_token != null) {
      BookmarkService.syncWithServer();
      refreshRole();
    }
  }

  static Future<void> refreshRole() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/auth/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $_token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final role = (data['role'] as String? ?? 'USER').toUpperCase().trim();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_roleKey, role);
        currentRole.value = role;
      } else if (response.statusCode == 401) {
        await logout();
      }
    } catch (_) {}
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

  static Future<AuthResult> resetPassword(
    String username,
    String email,
    String newPassword,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/forgot-password/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        return AuthResult(success: true);
      }
      if (response.statusCode == 404) {
        return AuthResult(success: false, error: 'User not found.');
      }
      if (response.statusCode >= 500) {
        return AuthResult(success: false, error: 'Server error. Please try again.');
      }
      final errorMsg =
          data?['detail'] as String? ?? _firstFieldError(data ?? {}) ?? 'Failed to reset password.';
      return AuthResult(success: false, error: errorMsg);
    } on SocketException {
      return AuthResult(success: false, error: 'No internet connection.');
    } on TimeoutException {
      return AuthResult(success: false, error: 'Server took too long to respond.');
    } catch (_) {
      return AuthResult(
        success: false,
        error: 'Unable to connect to the server.',
      );
    }
  }

  static Future<AuthResult> _authRequest(String endpoint, Map<String, String> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/$endpoint/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      Map<String, dynamic>? data;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        // Body was not JSON (e.g. HTML 500 error)
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data != null && data['token'] != null) {
          _token = data['token'] as String;
          final userObj = data['user'] as Map<String, dynamic>? ?? {};
          final username = (userObj['username'] as String?) ?? body['username'] ?? '';
          final role = (userObj['role'] as String? ?? 'USER').toUpperCase().trim();
          final rawId = userObj['id'];
          final userId = rawId != null ? rawId.toString() : (username.isNotEmpty ? username : 'user_default');

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, _token!);
          await prefs.setString(_usernameKey, username);
          await prefs.setString(_roleKey, role);
          await prefs.setString(_userIdKey, userId);
          currentUsername.value = username;
          currentRole.value = role;
          currentUserId.value = userId;

          await BookmarkService.onUserLoggedIn(userId);

          // Robust, null-safe parsing of email delivery status
          bool? emailSent;
          final dynamic rawEmail = data['emailSent'] ?? data['email_sent'];
          if (rawEmail != null) {
            if (rawEmail is bool) {
              emailSent = rawEmail;
            } else if (rawEmail is String) {
              final lower = rawEmail.trim().toLowerCase();
              if (lower == 'true' || lower == '1') {
                emailSent = true;
              } else if (lower == 'false' || lower == '0') {
                emailSent = false;
              }
            } else if (rawEmail is num) {
              emailSent = rawEmail == 1;
            }
          }

          final String? emailError =
              (data['emailError'] ?? data['email_error'])?.toString();

          return AuthResult(
            success: true,
            emailSent: emailSent,
            emailError: emailError,
          );
        }
      }

      if (response.statusCode == 401) {
        final detail = data?['detail'] ?? _firstFieldError(data ?? {}) ?? 'Invalid username or password.';
        return AuthResult(success: false, error: detail.toString());
      }
      if (response.statusCode == 400) {
        final detail = data?['detail'] ?? _firstFieldError(data ?? {}) ?? 'Invalid input data.';
        return AuthResult(success: false, error: detail.toString());
      }
      if (response.statusCode == 403) {
        return AuthResult(success: false, error: 'Administrator access required.');
      }
      if (response.statusCode == 404) {
        return AuthResult(success: false, error: 'Requested API endpoint was not found.');
      }
      if (response.statusCode >= 500) {
        return AuthResult(success: false, error: 'Server error. Please try again.');
      }

      final detail = data?['detail'] ?? _firstFieldError(data ?? {}) ?? 'Something went wrong.';
      return AuthResult(success: false, error: detail.toString());
    } on SocketException {
      return AuthResult(success: false, error: 'No internet connection.');
    } on TimeoutException {
      return AuthResult(success: false, error: 'Server took too long to respond.');
    } catch (_) {
      return AuthResult(success: false, error: 'Unable to connect to the server.');
    }
  }

  static String? _firstFieldError(Map<String, dynamic> data) {
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  static Future<void> logout() async {
    final currentToken = _token;
    _token = null;
    currentUsername.value = null;
    currentRole.value = null;
    currentUserId.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);

    await BookmarkService.onUserLoggedOut();
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
