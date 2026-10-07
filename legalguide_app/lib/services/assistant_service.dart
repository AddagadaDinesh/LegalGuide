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
      String langInstruction;
      if (lang == 'te') {
        langInstruction =
            '[CRITICAL REQUIREMENT: The user has selected TELUGU (తెలుగు) as their application language. '
            'You MUST formulate your entire response in clear, helpful TELUGU (తెలుగు script). '
            'All section headers MUST be in Telugu:\n'
            '### త్వరిత సమాధానం (Quick Answer in 2-4 sentences)\n'
            '### ముఖ్య అంశాలు (Key Points)\n'
            '### మీరు ఏమి చేయాలి (What You Should Do)\n'
            '### మీ హక్కులు (Your Rights)\n'
            '### సంబంధిత చట్టం (Relevant Law)\n'
            '### మరిన్ని వివరాలు (More Details)\n'
            'Keep official Act names (e.g., Bharatiya Nyaya Sanhita) recognizable.]';
      } else if (lang == 'hi') {
        langInstruction =
            '[CRITICAL REQUIREMENT: The user has selected HINDI (हिन्दी) as their application language. '
            'You MUST formulate your entire response in clear, helpful HINDI (हिन्दी script). '
            'All section headers MUST be in Hindi:\n'
            '### त्वरित उत्तर (Quick Answer in 2-4 sentences)\n'
            '### मुख्य बिंदु (Key Points)\n'
            '### आपको क्या करना चाहिए (What You Should Do)\n'
            '### आपके अधिकार (Your Rights)\n'
            '### प्रासंगिक कानून (Relevant Law)\n'
            '### अधिक विवरण (More Details)\n'
            'Keep official Act names (e.g., Bharatiya Nyaya Sanhita) recognizable.]';
      } else {
        langInstruction =
            '[Instruction: User language is English. Start with "### Quick Answer" followed by 2-4 direct sentences, '
            'then add relevant sections: "### Key Points", "### What You Should Do", "### Relevant Law", and "### More Details".]';
      }

      final contextualMessage =
          '$langInstruction\n\n'
          'User Question: $message';

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

  /// Generates a concise 3–5 bullet summary ONLY from the already generated answer.
  /// If online and authenticated, calls the dedicated /assistant/summarize/ endpoint.
  /// Otherwise or on timeout/failure, falls back to an extractive summary of the existing answer.
  static Future<List<String>> summarize(String answerText) async {
    final token = AuthService.token;
    final lang = LocaleService.language.value;

    if (token != null) {
      try {
        final response = await http
            .post(
              Uri.parse('${ApiService.baseUrl}/assistant/summarize/'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token $token',
              },
              body: jsonEncode({
                'text': answerText,
                'language': lang,
              }),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final summaryStr = data['summary'];
          if (summaryStr is String && summaryStr.trim().isNotEmpty) {
            final bullets = summaryStr
                .split('\n')
                .map((l) => l.trim())
                .where((l) => l.isNotEmpty)
                .map((l) => l.replaceFirst(RegExp(r'^[-*•\d.]\s*'), '').trim())
                .where((l) => l.isNotEmpty)
                .toList();
            if (bullets.isNotEmpty) {
              return bullets;
            }
          }
        }
      } catch (_) {
        // Fall back to local extractive summary
      }
    }

    return extractLocalSummary(answerText);
  }

  /// Extracts a 2–4 point summary directly from the existing answer text.
  /// Strictly bounded to text present in [answerText]; does not invent new facts.
  static List<String> extractLocalSummary(String answerText) {
    // Strip raw tags
    final cleaned = answerText
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'#{1,6}\s*'), '');

    final lines = cleaned.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final bullets = <String>[];

    // Check if there are explicit bullet points or numbered points in the answer
    for (final line in lines) {
      final isBullet = RegExp(r'^[-*•]\s+(.*)$').firstMatch(line);
      final isNumbered = RegExp(r'^\d+[\.)]\s*(.*)$').firstMatch(line);
      if (isBullet != null) {
        final content = isBullet.group(1)?.replaceAll(RegExp(r'\*\*'), '').trim();
        if (content != null && content.length > 10 && !content.toLowerCase().contains('relevant law')) {
          bullets.add(content);
        }
      } else if (isNumbered != null) {
        final content = isNumbered.group(1)?.replaceAll(RegExp(r'\*\*'), '').trim();
        if (content != null && content.length > 10) {
          bullets.add(content);
        }
      }
      if (bullets.length >= 4) break;
    }

    // If we gathered 2-4 bullets, return them
    if (bullets.length >= 2) {
      return bullets;
    }

    // Otherwise, split paragraphs into sentences
    final cleanPlain = cleaned
        .replaceAll(RegExp(r'\*\*'), '')
        .replaceAll(RegExp(r'[-*•]'), '')
        .replaceAll(RegExp(r'Quick Answer|త్వరిత సమాధానం|त्वरित उत्तर', caseSensitive: false), '')
        .trim();

    final sentenceRegex = RegExp(r'(?<=[.!?।])\s+');
    final sentences = cleanPlain
        .split(sentenceRegex)
        .map((s) => s.trim())
        .where((s) => s.length > 15 && !s.startsWith('|') && !s.contains('---'))
        .take(4)
        .toList();

    if (sentences.isNotEmpty) {
      return sentences;
    }

    return [cleanPlain.length > 120 ? '${cleanPlain.substring(0, 117)}...' : cleanPlain];
  }
}
