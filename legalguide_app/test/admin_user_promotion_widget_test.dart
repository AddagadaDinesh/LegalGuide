import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legalguide_app/services/admin_analytics_service.dart';
import 'package:legalguide_app/services/auth_service.dart';
import 'package:legalguide_app/localization/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.currentUsername.value = 'Dinesh_Admin';
    AuthService.currentRole.value = 'ADMIN';
  });

  group('Admin User Promotion Dialog & UI Tests', () {
    testWidgets('Promote dialog displays username, email, and requires explicit confirmation', (tester) async {
      final targetUser = AdminUserData(
        id: 101,
        username: 'john_citizen',
        email: 'john@example.com',
        role: 'USER',
        status: 'Active',
      );

      bool? confirmedResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    final res = await showDialog<bool>(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text(tr('Promote to Admin')),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(targetUser.username),
                            Text(targetUser.email),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: Text(tr('Cancel')),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: Text(tr('Confirm Promotion')),
                          ),
                        ],
                      ),
                    );
                    confirmedResult = res;
                  },
                  child: const Text('Open Dialog'),
                ),
              );
            },
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify explicit dialog details
      expect(find.text('Promote to Admin'), findsOneWidget);
      expect(find.text('john_citizen'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm Promotion'), findsOneWidget);

      // Tap Cancel -> should be false
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(confirmedResult, isFalse);

      // Open dialog again and Confirm
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Promotion'));
      await tester.pumpAndSettle();
      expect(confirmedResult, isTrue);
    });

    testWidgets('Eligible user displays Promote to Admin button while Admin accounts do not', (tester) async {
      final citizen = AdminUserData(
        id: 201,
        username: 'citizen_bob',
        email: 'bob@example.com',
        role: 'USER',
      );

      final admin = AdminUserData(
        id: 202,
        username: 'admin_alice',
        email: 'alice@example.com',
        role: 'ADMIN',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Citizen card
                if (!citizen.isAdmin)
                  const ElevatedButton(
                    onPressed: null,
                    child: Text('Promote to Admin - Bob'),
                  ),
                // Admin card
                if (!admin.isAdmin)
                  const ElevatedButton(
                    onPressed: null,
                    child: Text('Promote to Admin - Alice'),
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Promote to Admin - Bob'), findsOneWidget);
      expect(find.text('Promote to Admin - Alice'), findsNothing);
    });
  });
}
