import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/localization/app_strings.dart';
import 'package:legalguide_app/services/connectivity_status_service.dart';
import 'package:legalguide_app/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityStatusService & NetworkStatus Tests', () {
    test('NetworkStatus enum contains all 3 required states', () {
      expect(NetworkStatus.values, contains(NetworkStatus.online));
      expect(
        NetworkStatus.values,
        contains(NetworkStatus.internetAvailableBackendUnavailable),
      );
      expect(NetworkStatus.values, contains(NetworkStatus.offline));
    });

    test('isOnline boolean mirrors NetworkStatus.online', () {
      ConnectivityStatusService.status.value = NetworkStatus.online;
      ConnectivityStatusService.isOnline.value =
          (ConnectivityStatusService.status.value == NetworkStatus.online);
      expect(ConnectivityStatusService.isOnline.value, isTrue);
      expect(ConnectivityStatusService.isBackendAvailable, isTrue);
      expect(ConnectivityStatusService.isInternetConnected, isTrue);

      ConnectivityStatusService.status.value =
          NetworkStatus.internetAvailableBackendUnavailable;
      ConnectivityStatusService.isOnline.value =
          (ConnectivityStatusService.status.value == NetworkStatus.online);
      expect(ConnectivityStatusService.isOnline.value, isFalse);
      expect(ConnectivityStatusService.isBackendAvailable, isFalse);
      expect(ConnectivityStatusService.isInternetConnected, isTrue);

      ConnectivityStatusService.status.value = NetworkStatus.offline;
      ConnectivityStatusService.isOnline.value =
          (ConnectivityStatusService.status.value == NetworkStatus.online);
      expect(ConnectivityStatusService.isOnline.value, isFalse);
      expect(ConnectivityStatusService.isBackendAvailable, isFalse);
      expect(ConnectivityStatusService.isInternetConnected, isFalse);
    });
  });

  group('Localization of Network Status Strings', () {
    test('English translations return exact required text', () {
      LocaleService.language.value = 'en';

      expect(tr('Online'), equals('Online'));
      expect(
        tr('Offline · Using LegalGuide Knowledge'),
        equals('Offline · Using LegalGuide Knowledge'),
      );
      expect(
        tr('Internet connected · Server unavailable'),
        equals('Internet connected · Server unavailable'),
      );
    });

    test('Telugu translations return exact required text', () {
      LocaleService.language.value = 'te';

      expect(tr('Online'), equals('ఆన్లైన్'));
      expect(
        tr('Offline · Using LegalGuide Knowledge'),
        equals('ఆఫ్లైన్ · LegalGuide సమాచారాన్ని ఉపయోగిస్తోంది'),
      );
      expect(
        tr('Internet connected · Server unavailable'),
        equals('ఇంటర్నెట్ కనెక్ట్ అయింది · సర్వర్ అందుబాటులో లేదు'),
      );
    });

    test('Hindi translations return exact required text', () {
      LocaleService.language.value = 'hi';

      expect(tr('Online'), equals('ऑनलाइन'));
      expect(
        tr('Offline · Using LegalGuide Knowledge'),
        equals('ऑफ़लाइन · LegalGuide ज्ञान का उपयोग हो रहा है'),
      );
      expect(
        tr('Internet connected · Server unavailable'),
        equals('इंटरनेट कनेक्ट है · सर्वर उपलब्ध नहीं है'),
      );
    });
  });
}
