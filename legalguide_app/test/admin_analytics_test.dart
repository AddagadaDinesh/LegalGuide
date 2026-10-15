import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legalguide_app/services/admin_analytics_service.dart';
import 'package:legalguide_app/services/analytics_service.dart';
import 'package:legalguide_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.currentUsername.value = null;
    AuthService.currentRole.value = null;
  });

  group('Admin Analytics Data Model Tests', () {
    test('AdminAnalyticsData correctly parses full backend analytics response', () {
      final json = {
        'total_registered_users': 1248,
        'active_users_today': 327,
        'active_users_this_week': 842,
        'active_users_this_month': 1120,
        'new_users_today': 42,
        'new_users_this_week': 156,
        'new_users_this_month': 310,
        'currently_active_users': 86,
        'total_ai_questions': 12420,
        'ai_questions_today': 816,
        'ai_questions_this_week': 4200,
        'ai_questions_this_month': 12420,
        'ai_categories': [
          {'category': 'Criminal / BNS', 'count': 4500},
          {'category': 'Traffic & Driver Rights', 'count': 3200},
        ],
        'total_law_searches': 1430,
        'most_searched_laws': [
          {'query': 'bns section 303', 'count': 420},
          {'query': 'arrest rights', 'count': 310},
        ],
        'most_opened_laws': [
          {'law_id': 1, 'law_name': 'Bharatiya Nyaya Sanhita', 'count': 890},
        ],
        'most_viewed_sections': [
          {'section_id': 142, 'section_title': 'Section 303 - Theft', 'law_name': 'BNS', 'count': 560},
        ],
        'most_used_features': [
          {'key': 'law_search', 'label': 'Law Search', 'count': 1430},
          {'key': 'ai_assistant', 'label': 'AI Assistant', 'count': 816},
          {'key': 'emergency_rights', 'label': 'Emergency Rights Guide', 'count': 620},
          {'key': 'legal_documents', 'label': 'Legal Documents & Formats', 'count': 245},
        ],
        'database_sync': {
          'server_version': 1,
          'last_sync_date': '2026-09-29T10:00:00Z',
          'last_source_check': '2026-09-29T08:00:00Z',
          'primary_source_name': 'India Code (indiacode.gov.in)',
          'total_categories': 12,
          'total_laws': 35,
          'total_sections': 540,
        },
        'backend_status': {
          'status': 'operational',
          'database': 'connected',
          'ai_service': 'configured',
          'server_time': '2026-09-29T14:00:00Z',
        },
      };

      final data = AdminAnalyticsData.fromJson(json);

      expect(data.totalRegisteredUsers, 1248);
      expect(data.activeUsersToday, 327);
      expect(data.activeUsersThisWeek, 842);
      expect(data.activeUsersThisMonth, 1120);
      expect(data.newUsersToday, 42);
      expect(data.currentlyActiveUsers, 86);
      expect(data.totalAiQuestions, 12420);
      expect(data.aiQuestionsToday, 816);
      expect(data.totalLawSearches, 1430);
      expect(data.mostSearchedLaws.length, 2);
      expect(data.mostOpenedLaws.first['law_name'], 'Bharatiya Nyaya Sanhita');
      expect(data.mostUsedFeatures.length, 4);
      expect(data.databaseSync['server_version'], 1);
      expect(data.backendStatus['status'], 'operational');
    });

    test('AdminAnalyticsData correctly parses camelCase backend analytics response', () {
      final json = {
        'totalUsers': 2,
        'activeToday': 2,
        'activeThisWeek': 2,
        'activeThisMonth': 2,
        'newUsersToday': 1,
        'newUsersThisWeek': 2,
        'newUsersThisMonth': 2,
        'activeNow': 2,
        'totalAiQuestions': 18,
        'aiQuestionsToday': 6,
        'aiQuestionsThisWeek': 14,
        'aiQuestionsThisMonth': 18,
        'aiCategories': [
          {'category': 'Criminal Law & Arrest Rights', 'count': 8},
          {'category': 'Traffic & Vehicle Challans', 'count': 5},
        ],
        'totalLawSearches': 34,
        'mostSearchedLaws': [
          {'query': 'Section 303', 'count': 12},
        ],
        'mostOpenedLaws': [
          {'law_id': 1, 'law_name': 'Bharatiya Nyaya Sanhita, 2023', 'count': 45},
        ],
        'mostViewedSections': [
          {'section_id': 1, 'section_title': 'Theft', 'law_name': 'BNS', 'count': 26},
        ],
        'mostUsedFeatures': [
          {'key': 'law_search', 'label': 'Law Search', 'count': 34},
        ],
        'databaseSync': {
          'server_version': 1,
          'total_acts': 5,
        },
        'backendStatus': {
          'status': 'operational',
          'database': 'connected',
        },
      };

      final data = AdminAnalyticsData.fromJson(json);

      expect(data.totalRegisteredUsers, 2);
      expect(data.activeUsersToday, 2);
      expect(data.activeUsersThisWeek, 2);
      expect(data.activeUsersThisMonth, 2);
      expect(data.newUsersToday, 1);
      expect(data.currentlyActiveUsers, 2);
      expect(data.totalAiQuestions, 18);
      expect(data.aiQuestionsToday, 6);
      expect(data.totalLawSearches, 34);
    });


    test('AdminUserData correctly parses user directory fields', () {
      final userJson = {
        'id': 1,
        'username': 'Dinesh',
        'email': 'dineshaddagada@gmail.com',
        'role': 'ADMIN',
        'registrationDate': '2026-08-18T15:55:38Z',
        'lastLoginAt': '2026-09-29T13:40:00Z',
        'lastActiveAt': '2026-09-29T13:50:00Z',
      };

      final user = AdminUserData.fromJson(userJson);
      expect(user.id, 1);
      expect(user.username, 'Dinesh');
      expect(user.role, 'ADMIN');
      expect(user.email, 'dineshaddagada@gmail.com');
      expect(user.lastActiveAt, '2026-09-29T13:50:00Z');
      expect(user.isAdmin, isTrue);
    });

    test('AdminUsersResult parses user directory counts and list correctly', () {
      final json = {
        'total': 3,
        'normalUsers': 3,
        'adminUsers': 1,
        'totalAccounts': 4,
        'users': [
          {
            'id': '101',
            'username': 'CitizenOne',
            'email': 'citizen1@legalguide.in',
            'role': 'USER',
            'status': 'Active Today',
            'createdAt': '2026-09-20T10:00:00Z',
            'lastActiveAt': '2026-10-02T09:00:00Z',
          },
          {
            'id': 102,
            'username': 'CitizenTwo',
            'email': 'citizen2@legalguide.in',
            'role': 'USER',
            'status': 'Inactive',
            'createdAt': '2026-09-22T10:00:00Z',
          },
        ],
      };

      final result = AdminUsersResult.fromJson(json);
      expect(result.isSuccess, isTrue);
      expect(result.users.length, 2);
      expect(result.total, 3);
      expect(result.normalUsers, 3);
      expect(result.adminUsers, 1);
      expect(result.totalAccounts, 4);
      expect(result.users.first.id.toString(), '101');
      expect(result.users.first.username, 'CitizenOne');
      expect(result.users.first.role, 'USER');
      expect(result.users.first.isAdmin, isFalse);
    });

    test('AdminUsersResult handles forbidden 403 and error responses gracefully', () {
      final forbiddenResult = AdminUsersResult.forbidden();
      expect(forbiddenResult.isForbidden, isTrue);
      expect(forbiddenResult.isSuccess, isFalse);
      expect(forbiddenResult.errorMessage, contains('Administrator privilege required'));

      final errorResult = AdminUsersResult.failure('Backend server timed out (504)');
      expect(errorResult.isSuccess, isFalse);
      expect(errorResult.isForbidden, isFalse);
      expect(errorResult.errorMessage, 'Backend server timed out (504)');
    });

    test('AdminStatusResult parses status endpoint JSON correctly', () {
      final json = {
        'apiServer': 'online',
        'apiStatus': 'healthy',
        'administrator': 'Dinesh_Admin',
        'database': 'connected',
        'serverTime': '2026-10-02T10:30:00Z',
        'activeServer': 'pythonanywhere',
      };

      final status = AdminStatusResult.fromJson(json);
      expect(status.apiServer, 'online');
      expect(status.apiStatus, 'healthy');
      expect(status.administrator, 'Dinesh_Admin');
      expect(status.database, 'connected');
      expect(status.isOnline, isTrue);
    });

    test('Count definitions strictly derive from the same parsed users list (citizens=2, admin=1, total=3)', () {
      final json = {
        'total_registered_users': 3,
        'normal_users': 2,
        'admin_users': 1,
        'total_accounts': 3,
        'active_users_today': 1,
        'active_users_this_week': 2,
        'active_users_this_month': 3,
        'new_users_today': 0,
        'new_users_this_week': 1,
        'new_users_this_month': 3,
        'currently_active_users': 1,
        'total_ai_questions': 5,
        'ai_questions_today': 1,
        'ai_questions_this_week': 3,
        'ai_questions_this_month': 5,
        'ai_categories': [],
        'total_law_searches': 10,
        'most_searched_laws': [],
        'most_opened_laws': [],
        'most_viewed_sections': [],
        'most_used_features': [],
        'database_sync': {},
        'backend_status': {},
      };

      final analytics = AdminAnalyticsData.fromJson(json);
      // Analytics Total Users = all registered accounts = citizens + admins
      expect(analytics.totalRegisteredUsers, 3);
      expect(analytics.normalUsers, 2);
      expect(analytics.adminUsers, 1);
      expect(analytics.totalAccounts, 3);

      final usersJson = {
        'total': 3,
        'totalUsers': 3,
        'totalCitizens': 2,
        'totalAdmins': 1,
        'normalUsers': 2,
        'adminUsers': 1,
        'totalAccounts': 3,
        'users': [
          {
            'id': 1,
            'username': 'Dinesh_Admin',
            'name': 'Dinesh Administrator',
            'email': 'admin@legalguide.in',
            'role': 'ADMIN',
            'status': 'Active Now',
          },
          {
            'id': 2,
            'username': 'DineshCh',
            'name': 'Dinesh Citizen',
            'email': 'dineshchowdary2607@gmail.com',
            'role': 'USER',
            'status': 'Active Today',
          },
          {
            'id': 3,
            'username': 'dimpy',
            'name': 'Dimpy',
            'email': 'abc123@gmail.com',
            'role': 'USER',
            'status': 'Active Today',
          },
        ],
      };

      final usersResult = AdminUsersResult.fromJson(usersJson);
      expect(usersResult.users.length, 3);

      final allUsers = usersResult.users;
      final citizens = allUsers.where((u) => u.role.toUpperCase() == 'USER').toList();
      final admins = allUsers.where((u) => u.role.toUpperCase() == 'ADMIN').toList();

      expect(allUsers.length, 3);
      expect(citizens.length, 2);
      expect(admins.length, 1);
      expect(analytics.totalRegisteredUsers, allUsers.length);
      expect(citizens.length + admins.length, allUsers.length);
    });
  });

  group('AuthService Admin Role Detection Tests', () {
    test('AuthService strictly validates ADMIN role from backend without username heuristics', () {
      AuthService.currentUsername.value = 'regular_citizen';
      AuthService.currentRole.value = 'ADMIN';
      expect(AuthService.isAdmin, isTrue);

      AuthService.currentRole.value = 'USER';
      expect(AuthService.isAdmin, isFalse);

      AuthService.currentRole.value = null;
      expect(AuthService.isAdmin, isFalse);

      // Even if username is Dinesh_Admin, without ADMIN role, isAdmin is false
      AuthService.currentUsername.value = 'Dinesh_Admin';
      AuthService.currentRole.value = 'USER';
      expect(AuthService.isAdmin, isFalse);

      // When role is ADMIN, isAdmin is true
      AuthService.currentRole.value = 'ADMIN';
      expect(AuthService.isAdmin, isTrue);
    });
  });

  group('AnalyticsService Offline Queue Tests', () {
    test('AnalyticsService tracks feature usage and searches without throwing', () async {
      await AnalyticsService.init();

      expect(() => AnalyticsService.trackFeature('law_search'), returnsNormally);
      expect(() => AnalyticsService.trackFeature('ai_assistant'), returnsNormally);
      expect(() => AnalyticsService.trackSearch('bns section 303'), returnsNormally);
      expect(() => AnalyticsService.trackSectionView(142, 'Theft'), returnsNormally);
      expect(() => AnalyticsService.trackLawView(1, 'BNS'), returnsNormally);
    });
  });

  group('Admin User Deletion Service and Result Tests', () {
    test('AdminDeleteUserResult parses success and error responses correctly', () {
      final successResult = AdminDeleteUserResult(
        success: true,
        message: 'User deleted successfully.',
      );
      expect(successResult.success, isTrue);
      expect(successResult.message, equals('User deleted successfully.'));
      expect(successResult.error, isNull);

      final failedResult = AdminDeleteUserResult(
        success: false,
        error: 'You cannot delete your own admin account.',
      );
      expect(failedResult.success, isFalse);
      expect(failedResult.error, equals('You cannot delete your own admin account.'));
    });

    test('deleteUser requires authenticated admin privileges', () async {
      AuthService.currentRole.value = 'USER';
      final result = await AdminAnalyticsService.deleteUser('999', username: 'victim');
      expect(result.success, isFalse);
      expect(result.error, contains('authentication required'));
    });
  });

  group('Admin User Directory Model Tests', () {
    test('AdminUserData identifies admin vs eligible citizen accounts correctly', () {
      final citizen = AdminUserData(
        id: 1,
        username: 'regular_citizen',
        email: 'citizen@example.com',
        role: 'USER',
      );
      expect(citizen.isAdmin, isFalse);
      expect(citizen.role, equals('USER'));

      final admin = AdminUserData(
        id: 2,
        username: 'promoted_admin',
        email: 'admin@example.com',
        role: 'ADMIN',
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.role, equals('ADMIN'));
    });
  });
}

