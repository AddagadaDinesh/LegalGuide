import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'locale_service.dart';

/// Service to handle Text-To-Speech audio readouts across legal sections.
class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final FlutterTts _flutterTts = FlutterTts();
  bool _isInitialized = false;

  /// ID of the content currently playing, or null if idle/stopped.
  final ValueNotifier<String?> currentlyPlayingId = ValueNotifier<String?>(null);

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setSpeechRate(0.48); // Natural, clear cadence for legal text
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      _flutterTts.setCompletionHandler(() {
        currentlyPlayingId.value = null;
      });

      _flutterTts.setCancelHandler(() {
        currentlyPlayingId.value = null;
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        debugPrint('TtsService error: $msg');
        currentlyPlayingId.value = null;
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('TtsService initialization error: $e');
    }
  }

  /// Toggle speech: if already playing with [id], stop it; otherwise speak [text].
  Future<void> toggle({required String text, required String id}) async {
    if (currentlyPlayingId.value == id) {
      await stop();
    } else {
      await speak(text, id: id);
    }
  }

  /// Speak [text] aloud.
  Future<void> speak(String text, {String? id}) async {
    await _init();

    // If something else was playing, stop first
    if (currentlyPlayingId.value != null) {
      await _flutterTts.stop();
    }

    try {
      // Set appropriate voice language based on current app locale
      if (LocaleService.isTelugu) {
        await _flutterTts.setLanguage('te-IN');
      } else if (LocaleService.isHindi) {
        await _flutterTts.setLanguage('hi-IN');
      } else {
        await _flutterTts.setLanguage('en-IN');
      }

      currentlyPlayingId.value = id ?? 'generic_tts';
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TtsService speak error: $e');
      currentlyPlayingId.value = null;
    }
  }

  /// Stop any active audio playback.
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TtsService stop error: $e');
    } finally {
      currentlyPlayingId.value = null;
    }
  }
}
