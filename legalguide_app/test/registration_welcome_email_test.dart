import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/services/auth_service.dart';
import 'package:legalguide_app/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Registration Welcome Email Result & UI String Tests', () {
    test('AuthResult supports emailSent parameter', () {
      final successResult = AuthResult(success: true, emailSent: true);
      expect(successResult.success, isTrue);
      expect(successResult.emailSent, isTrue);
      expect(successResult.isEmailSent, isTrue);
      expect(successResult.isEmailFailed, isFalse);
      expect(successResult.error, isNull);

      final failedEmailResult = AuthResult(success: true, emailSent: false);
      expect(failedEmailResult.success, isTrue);
      expect(failedEmailResult.emailSent, isFalse);
      expect(failedEmailResult.isEmailSent, isFalse);
      expect(failedEmailResult.isEmailFailed, isTrue);

      final nullEmailResult = AuthResult(success: true, emailSent: null);
      expect(nullEmailResult.success, isTrue);
      expect(nullEmailResult.emailSent, isNull);
      expect(nullEmailResult.isEmailSent, isFalse);
      expect(nullEmailResult.isEmailFailed, isFalse);

      final defaultResult = AuthResult(success: false, error: 'User already exists');
      expect(defaultResult.emailSent, isNull);
      expect(defaultResult.error, equals('User already exists'));
    });

    test('Welcome email delivery message formatting in English', () async {
      await LocaleService.setLanguage('en');
      const testEmail = 'citizen@legalguide.org';

      // Provider success case
      final successMsg = '${tr("A welcome email has been sent to")} $testEmail.';
      expect(successMsg, equals('A welcome email has been sent to citizen@legalguide.org.'));

      // Provider not configured — UI must NOT fake success
      final fallbackMsg = tr("However, we couldn't send the welcome email. You can continue using your account.");
      expect(
        fallbackMsg,
        equals("However, we couldn't send the welcome email. You can continue using your account."),
      );

      // Dialog title
      expect(tr('Account created successfully! 🎉'), equals('Account created successfully! 🎉'));
    });

    test('Welcome email delivery message formatting in Telugu', () async {
      await LocaleService.setLanguage('te');
      const testEmail = 'citizen@legalguide.org';

      final successMsg = '${tr("A welcome email has been sent to")} $testEmail.';
      expect(successMsg, equals('స్వాగత ఈమెయిల్ పంపబడింది: citizen@legalguide.org.'));

      final fallbackMsg = tr("However, we couldn't send the welcome email. You can continue using your account.");
      expect(
        fallbackMsg,
        equals('అయితే, మేము స్వాగత ఈమెయిల్‌ను పంపలేకపోయాము. మీరు మీ ఖాతాను ఉపయోగించడం కొనసాగించవచ్చు.'),
      );

      expect(tr('Account created successfully! 🎉'), equals('ఖాతా విజయవంతంగా సృష్టించబడింది! 🎉'));

      await LocaleService.setLanguage('en');
    });

    test('Welcome email delivery message formatting in Hindi', () async {
      await LocaleService.setLanguage('hi');
      const testEmail = 'citizen@legalguide.org';

      final successMsg = '${tr("A welcome email has been sent to")} $testEmail.';
      expect(successMsg, equals('स्वागत ईमेल भेजा गया है: citizen@legalguide.org.'));

      final fallbackMsg = tr("However, we couldn't send the welcome email. You can continue using your account.");
      expect(
        fallbackMsg,
        equals('हालांकि, हम स्वागत ईमेल नहीं भेज सके। आप अपना खाता उपयोग जारी रख सकते हैं।'),
      );

      expect(tr('Account created successfully! 🎉'), equals('खाता सफलतापूर्वक बन गया! 🎉'));

      await LocaleService.setLanguage('en');
    });
  });
}
