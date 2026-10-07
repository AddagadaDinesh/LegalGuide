import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/data/legal_awareness_data.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/models/legal_awareness_item.dart';
import 'package:legalguide_app/screens/legal_awareness_screen.dart';
import 'package:legalguide_app/services/analytics_service.dart';
import 'package:legalguide_app/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleService.init();
    await LocaleService.setLanguage('en');
    LegalAwarenessData.resetToDefaults();
    AnalyticsService.cancelTimersForTesting();
  });

  tearDown(() {
    LegalAwarenessData.resetToDefaults();
    AnalyticsService.cancelTimersForTesting();
  });

  group('Legal Awareness Data Registry & Architecture Tests', () {
    test('Initial items contain exactly 3 categories in expected order', () {
      final active = LegalAwarenessData.activeItems;
      expect(active.length, 3);
      expect(active[0].id, 'emergency_rights');
      expect(active[0].order, 1);
      expect(active[1].id, 'railway_rules');
      expect(active[1].order, 2);
      expect(active[2].id, 'traffic_rules');
      expect(active[2].order, 3);
    });

    test('Disabling a category hides it from activeItems', () {
      expect(LegalAwarenessData.activeItems.length, 3);
      LegalAwarenessData.setItemEnabled('railway_rules', false);

      final active = LegalAwarenessData.activeItems;
      expect(active.length, 2);
      expect(active.any((item) => item.id == 'railway_rules'), isFalse);
      expect(active[0].id, 'emergency_rights');
      expect(active[1].id, 'traffic_rules');

      // Re-enable
      LegalAwarenessData.setItemEnabled('railway_rules', true);
      expect(LegalAwarenessData.activeItems.length, 3);
    });

    test('Future categories can be added dynamically and ordered correctly', () {
      final consumerRights = LegalAwarenessItem(
        id: 'consumer_rights',
        title: 'Consumer Rights',
        subtitle: 'Know your rights when buying products and services',
        icon: Icons.shopping_bag_rounded,
        screenBuilder: (_) => const Scaffold(body: Text('Consumer Rights Screen')),
        order: 4,
        enabled: true,
      );

      LegalAwarenessData.registerItem(consumerRights);

      final active = LegalAwarenessData.activeItems;
      expect(active.length, 4);
      expect(active.last.id, 'consumer_rights');
      expect(active.last.title, 'Consumer Rights');
      expect(active.last.order, 4);
    });

    test('findById returns item when exists and null when not found', () {
      expect(LegalAwarenessData.findById('emergency_rights'), isNotNull);
      expect(LegalAwarenessData.findById('non_existent'), isNull);
    });
  });

  group('Legal Awareness Localization Tests', () {
    test('Translates parent title and subtitle across English, Telugu, and Hindi', () async {
      await LocaleService.setLanguage('en');
      expect(tr('Legal Awareness'), 'Legal Awareness');
      expect(tr('Rights, rules & citizen protections'), 'Rights, rules & citizen protections');

      await LocaleService.setLanguage('te');
      expect(tr('Legal Awareness'), 'చట్టపరమైన అవగాహన');
      expect(tr('Rights, rules & citizen protections'), 'హక్కులు, నిబంధనలు & పౌరుల రక్షణలు');

      await LocaleService.setLanguage('hi');
      expect(tr('Legal Awareness'), 'कानूनी जागरूकता');
      expect(tr('Rights, rules & citizen protections'), 'अधिकार, नियम और नागरिक सुरक्षा');
    });

    test('Translates child category titles and descriptions across English, Telugu, and Hindi', () async {
      await LocaleService.setLanguage('en');
      expect(tr('Emergency Rights Guide'), 'Emergency Rights Guide');
      expect(tr('Indian Railway Rules & Fines'), 'Indian Railway Rules & Fines');
      expect(tr('Traffic Rules & Driver Rights'), 'Traffic Rules & Driver Rights');

      await LocaleService.setLanguage('te');
      expect(tr('Emergency Rights Guide'), 'అత్యవసర హక్కుల మార్గదర్శి');
      expect(tr('Indian Railway Rules & Fines'), 'రైల్వే నిబంధనలు & జరిమానాలు');
      expect(tr('Traffic Rules & Driver Rights'), 'ట్రాఫిక్ నిబంధనలు & డ్రైవర్ హక్కులు');

      await LocaleService.setLanguage('hi');
      expect(tr('Emergency Rights Guide'), 'आपातकालीन अधिकार गाइड');
      expect(tr('Indian Railway Rules & Fines'), 'भारतीय रेलवे नियम और जुर्माने');
      expect(tr('Traffic Rules & Driver Rights'), 'ट्रैफिक नियम एवं नागरिक अधिकार');
    });
  });

  group('LegalAwarenessScreen Widget Tests', () {
    testWidgets('Renders AppBar, header, and all 3 categories cleanly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalAwarenessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('Legal Awareness'), findsOneWidget);

      // Verify Header description
      expect(
        find.text('Explore important rights, rules and legal protections for everyday situations.'),
        findsOneWidget,
      );

      // Verify the three categories
      expect(find.text('Emergency Rights Guide'), findsOneWidget);
      expect(find.text('Indian Railway Rules & Fines'), findsOneWidget);
      expect(find.text('Traffic Rules & Driver Rights'), findsOneWidget);

      // Verify chevrons
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(3));
      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Tapping a category navigates to its screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalAwarenessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Emergency Rights Guide
      await tester.tap(find.text('Emergency Rights Guide'));
      await tester.pumpAndSettle();

      // Verifies Emergency Guide Screen opened
      expect(find.byType(LegalAwarenessScreen), findsNothing);
      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Dynamic category addition renders on screen without modifying layout', (tester) async {
      LegalAwarenessData.registerItem(
        LegalAwarenessItem(
          id: 'tenant_rules',
          title: 'Tenant & Rental Rules',
          subtitle: 'Rent agreements, eviction notice protections and security deposits',
          icon: Icons.home_work_rounded,
          screenBuilder: (_) => const Scaffold(body: Text('Tenant Screen')),
          order: 4,
          enabled: true,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: LegalAwarenessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tenant & Rental Rules'), findsOneWidget);
      expect(find.text('Rent agreements, eviction notice protections and security deposits'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNWidgets(4));
      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Disabled categories do not appear on screen', (tester) async {
      LegalAwarenessData.setItemEnabled('traffic_rules', false);

      await tester.pumpWidget(
        const MaterialApp(
          home: LegalAwarenessScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Emergency Rights Guide'), findsOneWidget);
      expect(find.text('Indian Railway Rules & Fines'), findsOneWidget);
      expect(find.text('Traffic Rules & Driver Rights'), findsNothing);
      AnalyticsService.cancelTimersForTesting();
    });
  });
}
