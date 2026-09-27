import '../models/legal_section.dart';
import 'locale_service.dart';

const _stopwords = {
  'a', 'an', 'the', 'is', 'are', 'of', 'to', 'in', 'and', 'or', 'for',
  'what', 'how', 'does', 'do', 'can', 'i', 'my', 'me', 'it', 'this',
  'that', 'be', 'was', 'were', 'about', 'if', 'when', 'who', 'which',
};

const _minScore = 2.0;

final _sectionRefPattern = RegExp(r'\bsec(?:tion)?\.?\s*#?\s*(\d+[a-zA-Z]*)\b', caseSensitive: false);

class OfflineQaService {
  static String? _extractRequestedSectionNumber(String query) {
    return _sectionRefPattern.firstMatch(query)?.group(1);
  }

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,.;:!?()\[\]{}""‘’“”/\-_+=@#$%^&*<>|]+'))
        .map((t) => t.trim())
        .where((t) => t.length > 1 && !_stopwords.contains(t))
        .toList();
  }

  static String _normalizeRef(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static double _score(LegalSection section, String queryLower, List<String> queryTokens) {
    double score = 0;
    final title = section.title.toLowerCase();
    final titleTe = section.titleTe.toLowerCase();
    final displayTitle = section.displayTitle.toLowerCase();
    final explanation = section.simpleExplanation.toLowerCase();
    final explanationTe = section.simpleExplanationTe.toLowerCase();
    final displayExplanation = section.displaySimpleExplanation.toLowerCase();
    final legalText = section.legalText.toLowerCase();
    final purpose = section.purpose.toLowerCase();
    final punishment = section.punishment.toLowerCase();
    final keywords = section.keywords.toLowerCase();

    for (final token in queryTokens) {
      if (title.contains(token) || titleTe.contains(token) || displayTitle.contains(token)) score += 4;
      if (keywords.contains(token)) score += 3;
      if (explanation.contains(token) || explanationTe.contains(token) || displayExplanation.contains(token)) score += 3;
      if (legalText.contains(token) || purpose.contains(token) || punishment.contains(token)) {
        score += 1;
      }
    }

    final normalizedSectionNumber = _normalizeRef(section.sectionNumber);
    final normalizedQuery = _normalizeRef(queryLower);
    if (normalizedSectionNumber.isNotEmpty && normalizedQuery.contains(normalizedSectionNumber)) {
      score += 10;
    }

    final trimmedQuery = queryLower.trim();
    if (trimmedQuery.length > 3 &&
        (legalText.contains(trimmedQuery) ||
         explanation.contains(trimmedQuery) ||
         explanationTe.contains(trimmedQuery) ||
         displayExplanation.contains(trimmedQuery))) {
      score += 5;
    }

    return score;
  }

  static List<LegalSection> rank(String query, List<LegalSection> sections, {int topN = 3}) {
    final queryLower = query.toLowerCase();
    final queryTokens = _tokenize(query);

    final scored = sections
        .map((s) => MapEntry(s, _score(s, queryLower, queryTokens)))
        .where((e) => e.value >= _minScore)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.take(topN).map((e) => e.key).toList();
  }

  static String answer(String query, List<LegalSection> sections) {
    if (sections.isEmpty) {
      if (LocaleService.isTelugu) {
        return 'ఈ పరికరంలో ఇంకా చట్టపరమైన డేటా నిల్వ చేయబడలేదు. యాప్ సింక్ కావడానికి ఒకసారి ఇంటర్నెట్‌కు కనెక్ట్ అవ్వండి.';
      }
      if (LocaleService.isHindi) {
        return 'इस डिवाइस पर अभी कोई कानूनी डेटा संग्रहीत नहीं है। ऐप सिंक होने के लिए एक बार इंटरनेट से कनेक्ट करें।';
      }
      return "I don't have any legal data stored on this device yet. "
          "Connect to the internet once so the app can sync, then I can help you offline.";
    }

    final requestedNumber = _extractRequestedSectionNumber(query);
    if (requestedNumber != null) {
      final normalizedRequested = _normalizeRef(requestedNumber);
      final exists = sections.any(
        (s) => _normalizeRef(s.sectionNumber).contains(normalizedRequested),
      );
      if (!exists) {
        if (LocaleService.isTelugu) {
          return 'నేను ప్రస్తుతం ఆఫ్‌లైన్‌లో ఉన్నాను మరియు ఈ సమాచారం ఆఫ్‌లైన్ పరిజ్ఞానంలో అందుబాటులో లేదు. సెక్షన్ "$requestedNumber" కనుగొనబడలేదు.';
        }
        if (LocaleService.isHindi) {
          return 'मैं वर्तमान में ऑफ़लाइन हूँ और यह जानकारी ऑफ़लाइन ज्ञान में उपलब्ध नहीं है। धारा "$requestedNumber" नहीं मिली।';
        }
        return "I'm currently offline and this information is not available in the "
            'LegalGuide offline knowledge. There is no section numbered '
            '"$requestedNumber" stored on this device — try a different section '
            'number, or connect to the internet to ask me anything.';
      }
    }

    final matches = rank(query, sections);
    if (matches.isEmpty) {
      if (LocaleService.isTelugu) {
        return 'నేను ప్రస్తుతం ఆఫ్‌లైన్‌లో ఉన్నాను మరియు ఈ సమాచారం ఆఫ్‌లైన్ నాలెడ్జ్‌లో లేదు. ప్రశ్నను మార్చి అడగండి లేదా ఆన్‌లైన్‌కి కనెక్ట్ అవ్వండి.';
      }
      if (LocaleService.isHindi) {
        return 'मैं वर्तमान में ऑफ़लाइन हूँ और यह जानकारी ऑफ़लाइन ज्ञान में उपलब्ध नहीं है। कृपया वाक्य बदलकर पूछें या ऑनलाइन कनेक्ट करें।';
      }
      return "I'm currently offline and this information is not available in the "
          "LegalGuide offline knowledge. Try rephrasing, or connect to the "
          "internet to ask me anything.";
    }

    final buffer = StringBuffer();
    buffer.writeln(LocaleService.isTelugu
        ? 'ఈ పరికరంలో నిల్వ చేయబడిన చట్టపరమైన డేటా ఆధారంగా:'
        : (LocaleService.isHindi
            ? 'इस डिवाइस पर संग्रहीत कानूनी डेटा के आधार पर:'
            : 'Based on the legal data stored on this device:'));
    for (final section in matches) {
      buffer.writeln();
      buffer.writeln('${section.sectionNumber} — ${section.displayTitle}');
      buffer.writeln(section.displaySimpleExplanation);
      if (section.displayPunishment.isNotEmpty) {
        buffer.writeln(LocaleService.isTelugu
            ? 'శిక్ష: ${section.displayPunishment}'
            : (LocaleService.isHindi
                ? 'सज़ा: ${section.displayPunishment}'
                : 'Punishment: ${section.displayPunishment}'));
      }
    }
    return buffer.toString().trim();
  }
}
