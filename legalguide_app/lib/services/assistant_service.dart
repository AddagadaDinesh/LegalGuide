import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repositories/legal_data_repository.dart';
import 'api_service.dart';
import 'auth_service.dart';
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
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/assistant/chat/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({'message': message}),
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
