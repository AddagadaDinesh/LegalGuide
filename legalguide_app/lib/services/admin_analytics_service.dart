import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/law.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'sqlite_legal_db.dart';

class AdminAnalyticsData {
  final int totalRegisteredUsers;
  final int normalUsers;
  final int adminUsers;
  final int totalAccounts;
  final int activeUsersToday;
  final int activeUsersThisWeek;
  final int activeUsersThisMonth;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final int currentlyActiveUsers;

  final int totalAiQuestions;
  final int aiQuestionsToday;
  final int aiQuestionsThisWeek;
  final int aiQuestionsThisMonth;
  final List<Map<String, dynamic>> aiCategories;

  final int totalLawSearches;
  final List<Map<String, dynamic>> mostSearchedLaws;
  final List<Map<String, dynamic>> mostOpenedLaws;
  final List<Map<String, dynamic>> mostViewedSections;

  final List<Map<String, dynamic>> mostUsedFeatures;
  final Map<String, dynamic> databaseSync;
  final Map<String, dynamic> backendStatus;

  AdminAnalyticsData({
    required this.totalRegisteredUsers,
    required this.normalUsers,
    required this.adminUsers,
    required this.totalAccounts,
    required this.activeUsersToday,
    required this.activeUsersThisWeek,
    required this.activeUsersThisMonth,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.currentlyActiveUsers,
    required this.totalAiQuestions,
    required this.aiQuestionsToday,
    required this.aiQuestionsThisWeek,
    required this.aiQuestionsThisMonth,
    required this.aiCategories,
    required this.totalLawSearches,
    required this.mostSearchedLaws,
    required this.mostOpenedLaws,
    required this.mostViewedSections,
    required this.mostUsedFeatures,
    required this.databaseSync,
    required this.backendStatus,
  });

  factory AdminAnalyticsData.fromJson(Map<String, dynamic> json) {
    final rawTotal = json['total_registered_users'] as int? ?? json['totalUsers'] as int? ?? 0;
    final normalCount = json['normal_users'] as int? ?? json['normalUsers'] as int? ?? rawTotal;
    final adminCount = json['admin_users'] as int? ?? json['adminUsers'] as int? ?? json['total_admin_users'] as int? ?? 0;
    final totalAccounts = json['total_accounts'] as int? ?? json['totalAccounts'] as int? ?? (normalCount + adminCount);

    return AdminAnalyticsData(
      totalRegisteredUsers: totalAccounts,
      normalUsers: normalCount,
      adminUsers: adminCount,
      totalAccounts: totalAccounts,
      activeUsersToday: json['active_users_today'] as int? ?? json['activeToday'] as int? ?? 0,
      activeUsersThisWeek: json['active_users_this_week'] as int? ?? json['activeThisWeek'] as int? ?? 0,
      activeUsersThisMonth: json['active_users_this_month'] as int? ?? json['activeThisMonth'] as int? ?? 0,
      newUsersToday: json['new_users_today'] as int? ?? json['newUsersToday'] as int? ?? 0,
      newUsersThisWeek: json['new_users_this_week'] as int? ?? json['newUsersThisWeek'] as int? ?? 0,
      newUsersThisMonth: json['new_users_this_month'] as int? ?? json['newUsersThisMonth'] as int? ?? 0,
      currentlyActiveUsers: json['currently_active_users'] as int? ?? json['currentlyActive'] as int? ?? json['activeNow'] as int? ?? 0,
      totalAiQuestions: json['total_ai_questions'] as int? ?? json['aiQuestions'] as int? ?? json['totalAiQuestions'] as int? ?? 0,
      aiQuestionsToday: json['ai_questions_today'] as int? ?? json['aiQuestionsToday'] as int? ?? 0,
      aiQuestionsThisWeek: json['ai_questions_this_week'] as int? ?? json['aiQuestionsThisWeek'] as int? ?? 0,
      aiQuestionsThisMonth: json['ai_questions_this_month'] as int? ?? json['aiQuestionsThisMonth'] as int? ?? 0,
      aiCategories: List<Map<String, dynamic>>.from(
        (json['ai_categories'] ?? json['aiCategories'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      totalLawSearches: json['total_law_searches'] as int? ?? json['totalLawSearches'] as int? ?? 0,
      mostSearchedLaws: List<Map<String, dynamic>>.from(
        (json['most_searched_laws'] ?? json['mostSearchedLaws'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      mostOpenedLaws: List<Map<String, dynamic>>.from(
        (json['most_opened_laws'] ?? json['mostOpenedLaws'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      mostViewedSections: List<Map<String, dynamic>>.from(
        (json['most_viewed_sections'] ?? json['mostViewedSections'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      mostUsedFeatures: List<Map<String, dynamic>>.from(
        (json['most_used_features'] ?? json['mostUsedFeatures'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      databaseSync: Map<String, dynamic>.from(json['database_sync'] ?? json['databaseSync'] as Map? ?? {}),
      backendStatus: Map<String, dynamic>.from(json['backend_status'] ?? json['backendStatus'] as Map? ?? {}),
    );
  }
}

class AdminUserData {
  final dynamic id;
  final String name;
  final String username;
  final String email;
  final String role;
  final String status;
  final String? registrationDate;
  final String? createdAt;
  final String? lastLoginAt;
  final String? lastActiveAt;

  AdminUserData({
    required this.id,
    this.name = '',
    required this.username,
    required this.email,
    required this.role,
    this.status = 'Active',
    this.registrationDate,
    this.createdAt,
    this.lastLoginAt,
    this.lastActiveAt,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory AdminUserData.fromJson(Map<String, dynamic> json) {
    final rawRole = (json['role'] as String? ?? 'USER').toUpperCase().trim();
    final rawStatus = json['status'] as String? ?? (rawRole == 'ADMIN' ? 'Admin' : 'Active');
    final regDate = json['registrationDate'] as String? ?? json['createdAt'] as String? ?? json['date_joined'] as String?;
    final uName = (json['username'] as String? ?? json['name'] as String? ?? '').trim();
    final displayName = (json['name'] as String? ?? uName).trim();

    return AdminUserData(
      id: json['id'] ?? 0,
      name: displayName.isNotEmpty ? displayName : uName,
      username: uName,
      email: json['email'] as String? ?? '',
      role: rawRole,
      status: rawStatus,
      registrationDate: regDate,
      createdAt: regDate,
      lastLoginAt: json['lastLoginAt'] as String? ?? json['last_login'] as String?,
      lastActiveAt: json['lastActiveAt'] as String? ?? json['last_active'] as String?,
    );
  }
}

class AdminUsersResult {
  final bool success;
  final bool isForbidden;
  final String? error;
  final int total;
  final int normalUsers;
  final int adminUsers;
  final int totalAccounts;
  final List<AdminUserData> users;

  AdminUsersResult({
    required this.success,
    this.isForbidden = false,
    this.error,
    this.total = 0,
    this.normalUsers = 0,
    this.adminUsers = 0,
    this.totalAccounts = 0,
    this.users = const [],
  });

  bool get isSuccess => success;
  String? get errorMessage => error;

  factory AdminUsersResult.fromJson(Map<String, dynamic> json) {
    List rawList = [];
    if (json['users'] is List) {
      rawList = json['users'] as List;
    } else if (json['results'] is List) {
      rawList = json['results'] as List;
    } else if (json['data'] is List) {
      rawList = json['data'] as List;
    }

    final list = rawList
        .map((u) => AdminUserData.fromJson(Map<String, dynamic>.from(u as Map)))
        .toList();

    final normalFromList = list.where((u) => u.role.toUpperCase() == 'USER' || !u.isAdmin).length;
    final adminFromList = list.where((u) => u.role.toUpperCase() == 'ADMIN' || u.isAdmin).length;

    final normalCount = json['totalCitizens'] as int? ??
        json['normalUsers'] as int? ??
        json['normal_users'] as int? ??
        (rawList.isEmpty && json['totalUsers'] == null && json['total'] == null
            ? 0
            : (json['totalUsers'] as int? ?? json['total'] as int? ?? normalFromList));

    final adminCount = json['totalAdmins'] as int? ??
        json['adminUsers'] as int? ??
        json['admin_users'] as int? ??
        (rawList.isEmpty && json['adminUsers'] == null && json['totalAdmins'] == null
            ? 0
            : adminFromList);

    final totalAccounts = json['totalAccounts'] as int? ??
        json['total_accounts'] as int? ??
        json['count'] as int? ??
        (normalCount + adminCount);

    final total = json['totalUsers'] as int? ??
        json['total'] as int? ??
        json['total_users'] as int? ??
        totalAccounts;

    return AdminUsersResult(
      success: true,
      total: total,
      normalUsers: normalCount,
      adminUsers: adminCount,
      totalAccounts: totalAccounts,
      users: list,
    );
  }

  factory AdminUsersResult.forbidden() => AdminUsersResult(
        success: false,
        isForbidden: true,
        error: 'Administrator privilege required (403)',
      );

  factory AdminUsersResult.failure(String message) => AdminUsersResult(
        success: false,
        error: message,
      );
}

class AdminDeleteUserResult {
  final bool success;
  final String? error;
  final String? message;

  AdminDeleteUserResult({
    required this.success,
    this.error,
    this.message,
  });
}

class AdminAnalyticsResult {
  final bool success;
  final bool isForbidden;
  final bool isFallback;
  final String? error;
  final AdminAnalyticsData? data;

  AdminAnalyticsResult({
    required this.success,
    this.isForbidden = false,
    this.isFallback = false,
    this.error,
    this.data,
  });
}

class AdminStatusResult {
  final String apiServer;
  final String apiStatus;
  final String administrator;
  final String database;
  final String? serverTime;
  final String? activeServer;

  AdminStatusResult({
    required this.apiServer,
    required this.apiStatus,
    required this.administrator,
    required this.database,
    this.serverTime,
    this.activeServer,
  });

  bool get isOnline => apiServer.toLowerCase() == 'online' || apiStatus.toLowerCase() == 'healthy';

  factory AdminStatusResult.fromJson(Map<String, dynamic> json) {
    return AdminStatusResult(
      apiServer: json['apiServer'] as String? ?? json['api_server'] as String? ?? 'online',
      apiStatus: json['apiStatus'] as String? ?? json['api_status'] as String? ?? 'healthy',
      administrator: json['administrator'] as String? ?? json['admin'] as String? ?? 'Dinesh_Admin',
      database: json['database'] as String? ?? 'connected',
      serverTime: json['serverTime'] as String? ?? json['server_time'] as String?,
      activeServer: json['activeServer'] as String? ?? json['active_server'] as String?,
    );
  }
}


class AdminAnalyticsService {
  /// Fetches comprehensive dashboard analytics from the central backend.
  /// Server validates token and verifies ADMIN role.
  static Future<AdminAnalyticsResult> fetchAnalytics() async {
    final token = AuthService.token;
    if (token == null && !AuthService.isAdmin) {
      return AdminAnalyticsResult(
        success: false,
        isForbidden: true,
        error: 'Admin authentication required.',
      );
    }

    final endpointUrl = '${ApiService.baseUrl}/admin/analytics/';

    // Development & Diagnostic logging (no credentials or sensitive information logged)
    assert(() {
      // ignore: avoid_print
      print('[AdminAnalytics] Requesting URL: $endpointUrl');
      // ignore: avoid_print
      print('[AdminAnalytics] Authenticated user: ${AuthService.currentUsername.value}, Role: ${AuthService.currentRole.value}');
      return true;
    }());

    try {
      final response = await http.get(
        Uri.parse(endpointUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 8));

      assert(() {
        // ignore: avoid_print
        print('[AdminAnalytics] Status code: ${response.statusCode}');
        // ignore: avoid_print
        print('[AdminAnalytics] Response payload: ${response.body}');
        return true;
      }());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = AdminAnalyticsData.fromJson(json);
        if (data.databaseSync['total_acts'] == null ||
            data.databaseSync['total_acts'] == '-' ||
            data.databaseSync['total_acts'] == 0) {
          try {
            final localStats = await SqliteLegalDb.getDetailedDatabaseStats();
            data.databaseSync.addAll(localStats);
          } catch (_) {}
        }
        return AdminAnalyticsResult(
          success: true,
          data: data,
        );
      } else if (response.statusCode == 401) {
        return AdminAnalyticsResult(
          success: false,
          isForbidden: true,
          error: 'Admin authentication required.',
        );
      } else if (response.statusCode == 403) {
        return AdminAnalyticsResult(
          success: false,
          isForbidden: true,
          error: 'Admin access required.',
        );
      } else if (response.statusCode == 404) {
        return AdminAnalyticsResult(
          success: false,
          error: 'Analytics endpoint not available ($endpointUrl).',
        );
      } else if (response.statusCode >= 500) {
        return AdminAnalyticsResult(
          success: false,
          error: 'Analytics server error.',
        );
      } else {
        return AdminAnalyticsResult(
          success: false,
          error: 'Analytics server error (${response.statusCode}).',
        );
      }
    } catch (e) {
      assert(() {
        // ignore: avoid_print
        print('[AdminAnalytics] Network connection exception: $e');
        return true;
      }());
      return AdminAnalyticsResult(
        success: false,
        error: 'Unable to connect to analytics server.',
      );
    }
  }

  /// Fetches unique Acts & Laws with their verified section counts.
  /// First attempts remote Admin API, then seamlessly falls back to local SQLite.
  static Future<List<Law>> fetchAdminActs({
    String? status,
    String? domain,
    String? search,
  }) async {
    final token = AuthService.token;
    if (token != null) {
      try {
        final queryParams = <String, String>{};
        if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
          queryParams['status'] = status;
        }
        if (domain != null && domain.isNotEmpty && domain.toLowerCase() != 'all') {
          queryParams['domain'] = domain;
        }
        if (search != null && search.trim().isNotEmpty) {
          queryParams['search'] = search.trim();
        }

        final uri = Uri.parse('${ApiService.baseUrl}/admin/legal-database/').replace(
          queryParameters: queryParams.isNotEmpty ? queryParams : null,
        );

        final response = await http.get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          final rawActs = json['acts'] as List? ?? [];
          if (rawActs.isNotEmpty) {
            return rawActs.map((e) => Law.fromJson(Map<String, dynamic>.from(e as Map))).toList();
          }
        }
      } catch (_) {
        // Fall back to local SQLite
      }
    }

    return await SqliteLegalDb.getActsWithSectionCounts(
      status: status,
      domain: domain,
      query: search,
    );
  }

  /// Fetches registered user directory with activity dates.
  static Future<AdminUsersResult> fetchUsers() async {
    final token = AuthService.token;
    if (token == null && !AuthService.isAdmin) {
      return AdminUsersResult(
        success: false,
        isForbidden: true,
        error: 'Admin authentication required.',
      );
    }

    final endpoints = [
      '${ApiService.baseUrl}/admin/users/',
      '${ApiService.baseUrl}/auth/admin/users/',
      '${ApiService.baseUrl}/admin/users/users/',
      '${ApiService.baseUrl}/users/',
    ];

    http.Response? response;
    String? lastError;

    for (final endpointUrl in endpoints) {
      try {
        final res = await http.get(
          Uri.parse(endpointUrl),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 8));

        if (res.statusCode == 200) {
          try {
            final decoded = jsonDecode(res.body);
            // Verify that the response actually contains a users list
            final bool hasUserRecords = (decoded is Map &&
                    (decoded['users'] is List ||
                        decoded['results'] is List ||
                        decoded['data'] is List)) ||
                (decoded is List);
            if (hasUserRecords) {
              response = res;
              break;
            } else {
              // Keep as lowest priority fallback if no other endpoint provides user list
              response ??= res;
            }
          } catch (_) {
            response ??= res;
          }
        } else if (res.statusCode == 401 || res.statusCode == 403) {
          return AdminUsersResult(
            success: false,
            isForbidden: true,
            error: 'Administrator access required (HTTP ${res.statusCode}).',
          );
        } else if (res.statusCode != 404) {
          lastError = 'Server error (${res.statusCode})';
        }
      } catch (e) {
        lastError = 'Network error: $e';
      }
    }

    if (response != null && response.statusCode == 200) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return AdminUsersResult.fromJson(decoded);
        } else if (decoded is List) {
          final list = decoded
              .map((u) => AdminUserData.fromJson(Map<String, dynamic>.from(u as Map)))
              .toList();
          final normalCount = list.where((u) => !u.isAdmin).length;
          final adminCount = list.where((u) => u.isAdmin).length;
          return AdminUsersResult(
            success: true,
            total: normalCount,
            normalUsers: normalCount,
            adminUsers: adminCount,
            totalAccounts: list.length,
            users: list,
          );
        }
      } catch (e) {
        return AdminUsersResult(
          success: false,
          error: 'Failed to parse user directory: $e',
        );
      }
    }

    return AdminUsersResult(
      success: false,
      error: lastError ?? 'Unable to connect to users server.',
    );
  }

  /// Deletes a user account from the central production database.
  /// Accessible only to authenticated Administrators.
  static Future<AdminDeleteUserResult> deleteUser(String userId, {String? username}) async {
    final token = AuthService.token;
    if (token == null && !AuthService.isAdmin) {
      return AdminDeleteUserResult(
        success: false,
        error: 'Administrator authentication required.',
      );
    }

    final endpoints = [
      '${ApiService.baseUrl}/admin/users/',
      '${ApiService.baseUrl}/auth/admin/users/',
      '${ApiService.baseUrl}/users/',
    ];

    String? lastError;
    for (final endpointUrl in endpoints) {
      try {
        final uri = Uri.parse(endpointUrl);
        final payload = <String, dynamic>{'user_id': userId};
        if (username != null) {
          payload['username'] = username;
        }

        final response = await http.delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Token $token',
          },
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        Map<String, dynamic>? data;
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {}

        if (response.statusCode == 200 || response.statusCode == 204) {
          return AdminDeleteUserResult(
            success: true,
            message: data?['message'] as String? ?? 'User deleted successfully.',
          );
        }

        final errorMsg = data?['error'] as String? ??
            data?['detail'] as String? ??
            'Failed to delete user (${response.statusCode})';

        if (response.statusCode == 400 || response.statusCode == 403 || response.statusCode == 404) {
          return AdminDeleteUserResult(
            success: false,
            error: errorMsg,
          );
        }

        lastError = errorMsg;
      } catch (e) {
        lastError = 'Network error: $e';
      }
    }

    return AdminDeleteUserResult(
      success: false,
      error: lastError ?? 'Unable to connect to users server.',
    );
  }

  /// Fetches system and API status for the admin panel.
  static Future<Map<String, dynamic>?> fetchAdminStatus() async {
    final token = AuthService.token;
    if (token == null) return null;
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static AdminAnalyticsData getLocalFallbackData({String? cloudStatus}) {
    final currentAdmin = AuthService.currentUsername.value ?? 'Dinesh_Admin';
    return AdminAnalyticsData(
      totalRegisteredUsers: 1,
      normalUsers: 1,
      adminUsers: 1,
      totalAccounts: 2,
      activeUsersToday: 1,
      activeUsersThisWeek: 1,
      activeUsersThisMonth: 1,
      newUsersToday: 0,
      newUsersThisWeek: 0,
      newUsersThisMonth: 1,
      currentlyActiveUsers: 1,
      totalAiQuestions: 18,
      aiQuestionsToday: 6,
      aiQuestionsThisWeek: 14,
      aiQuestionsThisMonth: 18,
      aiCategories: [
        {'category': 'Criminal Law & Arrest Rights', 'count': 8},
        {'category': 'Traffic & Vehicle Challans', 'count': 5},
        {'category': 'Railway Rules & Travel Rights', 'count': 3},
        {'category': 'Consumer Protection & Civil', 'count': 2},
      ],
      totalLawSearches: 34,
      mostSearchedLaws: [
        {'term': 'Section 303', 'count': 12},

        {'term': 'Bail rights', 'count': 8},
        {'term': 'Police FIR rules', 'count': 7},
        {'term': 'Traffic fine challan', 'count': 5},
        {'term': 'Platform ticket rules', 'count': 2},
      ],
      mostOpenedLaws: [
        {'code': 'BNS', 'name': 'Bharatiya Nyaya Sanhita, 2023', 'views': 45},
        {'code': 'BNSS', 'name': 'Bharatiya Nagarik Suraksha Sanhita, 2023', 'views': 32},
        {'code': 'MV_ACT', 'name': 'Motor Vehicles Act, 1988', 'views': 28},
        {'code': 'RAILWAYS_ACT', 'name': 'The Railways Act, 1989', 'views': 14},
      ],
      mostViewedSections: [
        {'code': 'BNS', 'section': 'Section 303', 'title': 'Theft', 'views': 26},
        {'code': 'BNSS', 'section': 'Section 35', 'title': 'When police may arrest without warrant', 'views': 20},
        {'code': 'BNS', 'section': 'Section 351', 'title': 'Criminal Intimidation', 'views': 15},
        {'code': 'MV_ACT', 'section': 'Section 185', 'title': 'Driving by a drunken person', 'views': 12},
      ],
      mostUsedFeatures: [
        {'feature': 'Law Search', 'count': 34},
        {'feature': 'AI Assistant', 'count': 18},
        {'feature': 'Legal Awareness', 'count': 16},
        {'feature': 'Emergency Rights Guide', 'count': 12},
        {'feature': 'Traffic Rules & Driver Rights', 'count': 10},
        {'feature': 'Indian Railway Rules & Fines', 'count': 7},
        {'feature': 'Legal Documents Generator', 'count': 6},
      ],
      databaseSync: {
        'last_synchronized': '2026-09-29T19:30:00Z',
        'version': '1',
        'server_version': '1',
        'total_acts': 16,
        'total_laws': 16,
        'total_sections': 34,
        'current_sections': 34,
        'amended_sections': 0,
        'historical_sections': 0,
        'repealed_sections': 0,
        'sync_status': 'SQLite',
      },
      backendStatus: {
        'api_status': cloudStatus ?? 'Active Server: ${ApiService.baseUrl}',
        'connected': true,
        'database': 'SQLite Database Engine',
        'active_server': ApiService.baseUrl,
        'administrator': currentAdmin,
      },
    );
  }

  static List<AdminUserData> getLocalFallbackUsers() {
    final currentAdmin = AuthService.currentUsername.value ?? 'Dinesh_Admin';
    return [
      AdminUserData(
        id: 1,
        username: currentAdmin,
        email: 'dineshaddagada@gmail.com',
        role: 'ADMIN',
        registrationDate: '2026-09-27T10:00:00Z',
        lastLoginAt: '2026-09-29T19:30:00Z',
        lastActiveAt: '2026-09-29T20:20:00Z',
      ),
    ];
  }
}
