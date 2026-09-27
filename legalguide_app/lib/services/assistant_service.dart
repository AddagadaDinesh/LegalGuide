import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/legal_data_repository.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'locale_service.dart';
import 'offline_qa_service.dart';

class AssistantAnswer {
  final String reply;
  final bool isOnline;
  final bool requiresLogin;
  AssistantAnswer({required this.reply, required this.isOnline, this.requiresLogin = false});
}

class AssistantService {
  static Future<AssistantAnswer> ask(String message) async {
    final token = AuthService.token;

    if (token == null) {
      return _offlineAnswer(message, requiresLogin: true);
    }

    try {
      final lang = LocaleService.language.value;
      final langName = LocaleService.isTelugu
          ? 'Telugu'
          : (LocaleService.isHindi ? 'Hindi' : 'English');

      final contextualMessage =
          '[Instruction: You are the LegalGuide assistant for Indian laws and citizen rights. Understand the language or transliterated dialect the user is asking in (e.g. Telugu, Hindi, Tamil, Kannada, Marathi, English, or transliterated Telugish/Hinglish like "em app idhii" or "yeh kya app hai"). You MUST reply in the EXACT SAME LANGUAGE that the user used. If asked what this app is, warmly explain that LegalGuide is an Indian law guide for citizen rights and legal sections in simple words. User locale is: $langName]\n\nUser Question: $message';

      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/assistant/chat/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({
              'message': contextualMessage,
              'language': lang,
            }),
          )
          .timeout(const Duration(seconds: 50));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['reply'];
        if (reply is String && reply.trim().isNotEmpty) {
          return AssistantAnswer(reply: reply, isOnline: true);
        }
      }
      throw Exception('Assistant request failed (${response.statusCode})');
    } catch (_) {
      return _offlineAnswer(message, requiresLogin: false);
    }
  }

  static Future<AssistantAnswer> _offlineAnswer(String message, {required bool requiresLogin}) async {
    final sections = await LegalDataRepository.loadSections();
    return AssistantAnswer(
      reply: OfflineQaService.answer(message, sections),
      isOnline: false,
      requiresLogin: requiresLogin,
    );
  }
}
