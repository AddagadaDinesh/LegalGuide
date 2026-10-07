import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/services/locale_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Registration Email Validation Tests', () {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    test('Valid email addresses pass regex validation', () {
      expect(emailRegex.hasMatch('example@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('john.doe@company.org'), isTrue);
      expect(emailRegex.hasMatch('citizen_123@gov.in'), isTrue);
      expect(emailRegex.hasMatch('test+filter@law.co.in'), isTrue);
    });

    test('Invalid email addresses fail regex validation', () {
      expect(emailRegex.hasMatch(''), isFalse);
      expect(emailRegex.hasMatch('   '), isFalse);
      expect(emailRegex.hasMatch('abc'), isFalse);
      expect(emailRegex.hasMatch('abc@'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('user@domain'), isFalse);
      expect(emailRegex.hasMatch('user @domain.com'), isFalse);
      expect(emailRegex.hasMatch('user@.com'), isFalse);
    });

    test('Email trimming cleans leading and trailing whitespaces', () {
      const rawEmail = '   citizen@legalguide.in   ';
      final trimmed = rawEmail.trim();
      expect(trimmed, equals('citizen@legalguide.in'));
      expect(emailRegex.hasMatch(trimmed), isTrue);
    });

    test('Email validation localization strings exist in Telugu and Hindi', () async {
      // English defaults
      await LocaleService.setLanguage('en');
      expect(tr('Email *'), equals('Email *'));
      expect(tr('Email is required'), equals('Email is required'));
      expect(tr('Enter a valid email address'), equals('Enter a valid email address'));
      expect(tr('Ask your legal question...'), equals('Ask your legal question...'));

      // Telugu translations
      await LocaleService.setLanguage('te');
      expect(tr('Email *'), equals('ఈమెయిల్ *'));
      expect(tr('Email is required'), equals('ఈమెయిల్ తప్పనిసరి'));
      expect(tr('Enter a valid email address'), equals('సరైన ఈమెయిల్ చిరునామాను నమోదు చేయండి'));
      expect(tr('Ask your legal question...'), equals('మీ చట్టపరమైన ప్రశ్నను అడగండి...'));

      // Hindi translations
      await LocaleService.setLanguage('hi');
      expect(tr('Email *'), equals('ईमेल *'));
      expect(tr('Email is required'), equals('ईमेल आवश्यक है'));
      expect(tr('Enter a valid email address'), equals('एक मान्य ईमेल पता दर्ज करें'));
      expect(tr('Ask your legal question...'), equals('अपना कानूनी प्रश्न पूछें...'));

      // Reset to English
      await LocaleService.setLanguage('en');
    });
  });
}
