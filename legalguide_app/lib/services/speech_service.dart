import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'locale_service.dart';

class SpeechService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static bool _isInitialized = false;

  static final ValueNotifier<bool> isListeningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<String> lastWordsNotifier = ValueNotifier<String>('');
  static final ValueNotifier<double> soundLevelNotifier = ValueNotifier<double>(0.0);

  static Future<bool> initialize() async {
    if (_isInitialized && _speech.isAvailable) return true;
    try {
      _isInitialized = await _speech.initialize(
        onStatus: (status) {
          debugPrint('SpeechService status: $status');
          if (status == 'listening') {
            isListeningNotifier.value = true;
          } else if (status == 'notListening' || status == 'done') {
            isListeningNotifier.value = false;
            soundLevelNotifier.value = 0.0;
          }
        },
        onError: (errorNotification) {
          debugPrint('SpeechService error: ${errorNotification.errorMsg} (permanent: ${errorNotification.permanent})');
          isListeningNotifier.value = false;
          soundLevelNotifier.value = 0.0;
        },
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('SpeechService initialize exception: $e');
      return false;
    }
  }

  static bool get isListening => _speech.isListening;
  static bool get isAvailable => _speech.isAvailable;

  /// Returns all speech locales supported by the device
  static Future<List<stt.LocaleName>> getLocales() async {
    final ready = await initialize();
    if (!ready) return [];
    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint('Error getting locales: $e');
      return [];
    }
  }

  /// Returns system default locale id
  static Future<String> getSystemLocaleId() async {
    final ready = await initialize();
    if (!ready) return 'en_IN';
    try {
      final systemLocale = await _speech.systemLocale();
      return systemLocale?.localeId ?? 'en_IN';
    } catch (_) {
      return 'en_IN';
    }
  }

  static String getLocaleIdForCurrentLanguage() {
    final lang = LocaleService.language.value;
    if (lang == 'te') return 'te_IN';
    if (lang == 'hi') return 'hi_IN';
    return 'en_IN';
  }

  /// Start listening and stream results through onResult callback
  static Future<bool> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(String error)? onError,
    Function(double soundLevel)? onSoundLevel,
    String? localeId,
  }) async {
    final ready = await initialize();
    if (!ready) {
      onError?.call('Speech recognition not available on this device');
      return false;
    }

    if (_speech.isListening) {
      await stopListening();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    final targetLocale = (localeId == null || localeId == 'auto' || localeId.isEmpty)
        ? await getSystemLocaleId()
        : localeId;

    var effectiveLocale = targetLocale;
    try {
      final locales = await _speech.locales();
      if (locales.isNotEmpty) {
        final exactMatch = locales.any((l) => l.localeId.toLowerCase() == targetLocale.toLowerCase());
        if (!exactMatch) {
          final langPrefix = targetLocale.split('_').first.toLowerCase();
          final prefixMatch = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith(langPrefix),
            orElse: () => locales.firstWhere(
              (l) => l.localeId.toLowerCase().startsWith('en'),
              orElse: () => locales.first,
            ),
          );
          effectiveLocale = prefixMatch.localeId;
        }
      }
    } catch (e) {
      debugPrint('Locale resolution fallback: $e');
    }

    debugPrint('SpeechService starting listening with locale: $effectiveLocale');

    lastWordsNotifier.value = '';
    isListeningNotifier.value = true;

    try {
      await _speech.listen(
        onResult: (result) {
          lastWordsNotifier.value = result.recognizedWords;
          onResult(result.recognizedWords, result.finalResult);
        },
        // ignore: deprecated_member_use
        localeId: effectiveLocale,
        onSoundLevelChange: (level) {
          soundLevelNotifier.value = level;
          onSoundLevel?.call(level);
        },
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false, // Don't abort on minor noise or brief pauses
          listenMode: stt.ListenMode.search, // Search mode is fast, reliable and handles voice queries
          onDevice: false, // Allow cloud recognition for rich multilingual vocabulary
        ),
      );
      return true;
    } catch (e) {
      isListeningNotifier.value = false;
      debugPrint('Error starting speech listen: $e');
      onError?.call(e.toString());
      return false;
    }
  }

  static Future<void> stopListening() async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {}
    isListeningNotifier.value = false;
    soundLevelNotifier.value = 0.0;
  }

  static Future<void> cancelListening() async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {}
    isListeningNotifier.value = false;
    soundLevelNotifier.value = 0.0;
  }
}
