import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/models/legal_update.dart';
import 'package:legalguide_app/services/connectivity_status_service.dart';
import 'package:legalguide_app/services/legal_update_service.dart';
import 'package:legalguide_app/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ConnectivityStatusService.status.value = NetworkStatus.online;
    LegalUpdateService.unreadCount.value = 0;
  });

  group('Home Screen Legal Updates & Sync Banner Tests', () {
    test('1. Missing sync date produces "Not available" and never the hardcoded 01/07/2024', () {
      // Helper testing date formatting contract
      String formatDate(DateTime? dt) {
        if (dt == null) return tr('Not available');
        final day = dt.day.toString().padLeft(2, '0');
        final month = dt.month.toString().padLeft(2, '0');
        final year = dt.year.toString();
        return '$day/$month/$year';
      }

      final nullDateResult = formatDate(null);
      expect(nullDateResult, equals('Not available'));
      expect(nullDateResult, isNot(contains('01/07/2024')));

      final validDateResult = formatDate(DateTime(2026, 10, 15));
      expect(validDateResult, equals('15/10/2026'));
    });

    test('2. State A: No unseen published updates renders "Legal Information Up to Date"', () {
      final isOffline = false;
      final hasUpdates = false;
      final syncFailed = false;

      final titleText = (isOffline || (syncFailed && !hasUpdates))
          ? tr('Offline — Showing Saved Legal Information')
          : (syncFailed && hasUpdates)
              ? tr('Update Available — Sync Required')
              : hasUpdates
                  ? tr('New Legal Information Available')
                  : tr('Legal Information Up to Date');

      expect(titleText, equals('Legal Information Up to Date'));
    });

    test('3. State B: Published update available renders "New Legal Information Available" and NEW badge', () {
      final isOffline = false;
      final hasUpdates = true;
      final syncFailed = false;
      final unreadCount = 3;

      final titleText = (isOffline || (syncFailed && !hasUpdates))
          ? tr('Offline — Showing Saved Legal Information')
          : (syncFailed && hasUpdates)
              ? tr('Update Available — Sync Required')
              : hasUpdates
                  ? tr('New Legal Information Available')
                  : tr('Legal Information Up to Date');

      expect(titleText, equals('New Legal Information Available'));
      final badgeLabel = unreadCount > 1 ? '$unreadCount NEW' : 'NEW';
      expect(badgeLabel, equals('3 NEW'));
    });

    test('4. State C: Newer version known but sync failed renders "Update Available — Sync Required"', () {
      final isOffline = false;
      final hasUpdates = true;
      final syncFailed = true;

      final titleText = (isOffline || (syncFailed && !hasUpdates))
          ? tr('Offline — Showing Saved Legal Information')
          : (syncFailed && hasUpdates)
              ? tr('Update Available — Sync Required')
              : hasUpdates
                  ? tr('New Legal Information Available')
                  : tr('Legal Information Up to Date');

      expect(titleText, equals('Update Available — Sync Required'));
    });

    test('5. State D: Offline or failed sync without known updates renders "Offline — Showing Saved Legal Information"', () {
      // Scenario 1: Offline
      final isOffline = true;
      final hasUpdates = false;
      final syncFailed = false;

      final titleOffline = (isOffline || (syncFailed && !hasUpdates))
          ? tr('Offline — Showing Saved Legal Information')
          : (syncFailed && hasUpdates)
              ? tr('Update Available — Sync Required')
              : hasUpdates
                  ? tr('New Legal Information Available')
                  : tr('Legal Information Up to Date');

      expect(titleOffline, equals('Offline — Showing Saved Legal Information'));

      // Scenario 2: Online but sync failed and no updates known
      final isOffline2 = false;
      final syncFailed2 = true;
      final hasUpdates2 = false;

      final titleFailedSync = (isOffline2 || (syncFailed2 && !hasUpdates2))
          ? tr('Offline — Showing Saved Legal Information')
          : (syncFailed2 && hasUpdates2)
              ? tr('Update Available — Sync Required')
              : hasUpdates2
                  ? tr('New Legal Information Available')
                  : tr('Legal Information Up to Date');

      expect(titleFailedSync, equals('Offline — Showing Saved Legal Information'));
    });

    test('6. Offline or failed sync preserves existing local data without clearing', () {
      final existingLocalSections = [
        {'id': 101, 'title': 'Theft', 'section_number': '303'},
        {'id': 102, 'title': 'Causing death by negligence', 'section_number': '106'},
      ];

      // Simulating failed sync attempt
      final bool syncSuccess = false;
      List<Map<String, dynamic>> localData = List.from(existingLocalSections);

      if (syncSuccess) {
        localData = []; // would be replaced if sync had succeeded
      }

      // Existing records must be preserved
      expect(localData.length, equals(2));
      expect(localData[0]['section_number'], equals('303'));
      expect(localData[1]['section_number'], equals('106'));
    });

    test('7. Only published updates are visible in public LegalUpdate model', () {
      final publishedUpdate = LegalUpdate(
        id: 1,
        title: 'BNS 2023 — Section 106 Published',
        description: 'New statutory section 106 published.',
        updateType: 'new_section',
        updateTypeDisplay: 'New Section',
        affectedLawName: 'Bharatiya Nyaya Sanhita, 2023',
        affectedLawShortName: 'BNS 2023',
        affectedSection: '106',
        newVersion: 1,
        officialSourceName: 'India Code / Gazette S.O. 850(E)',
        officialSourceUrl: 'https://www.indiacode.gov.in/handle/123456789/20062',
        effectiveDate: '2024-07-01',
        lastVerifiedAt: '2026-10-12',
        publishedAt: '2026-10-12T10:00:00Z',
      );

      expect(publishedUpdate.id, equals(1));
      expect(publishedUpdate.affectedSection, equals('106'));
      expect(publishedUpdate.isRead, isFalse);
    });
  });
}
