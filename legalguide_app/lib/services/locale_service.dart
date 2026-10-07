import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleService {
  static const _key = 'lg_language_v1';
  static final ValueNotifier<String> language = ValueNotifier<String>('en');

  static bool get isTelugu => language.value == 'te';
  static bool get isHindi => language.value == 'hi';
  static bool get isTamil => language.value == 'ta';
  static String get currentLanguage => language.value;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    language.value = prefs.getString(_key) ?? 'en';
  }

  static Future<void> setLanguage(String code) async {
    language.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
