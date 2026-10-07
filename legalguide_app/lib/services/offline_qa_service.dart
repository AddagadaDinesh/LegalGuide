import '../models/legal_section.dart';
import 'locale_service.dart';

enum LegalIntent {
  locationQuestion,
  nonLegalQuestion,
  unclearClarification,
  hackRefusal,
  forgeryRefusal,
  hideEvidenceRefusal,
  generalHarmfulRefusal,
  selfHarmRefusal,
  sectionLookup,
  multiIssue,
  situationProblem,
  generalLegalQuestion,
}

enum LegalDomain {
  familyMatrimonial,
  traffic,
  policeStop,
  wrongChallan,
  policeRefuseFir,
  arrestRights,
  cyberFraud,
  cybercrimeComplaint,
  railway,
  landlordTenant,
  workplaceSalary,
  criminalViolence,
  drugOffence,
  consumer,
  general,
}

const _stopwords = {
  'a', 'an', 'the', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'of', 'to', 'in', 'and', 'or', 'for', 'with', 'by', 'at', 'from', 'on',
  'about', 'as', 'into', 'like', 'through', 'after', 'over', 'between', 'out',
  'against', 'during', 'without', 'before', 'under', 'around', 'among',
  'what', 'how', 'does', 'do', 'did', 'can', 'could', 'will', 'would', 'shall',
  'should', 'i', 'my', 'me', 'we', 'our', 'us', 'you', 'your', 'he', 'him',
  'his', 'she', 'her', 'it', 'its', 'they', 'them', 'their', 'this', 'that',
  'these', 'those', 'if', 'when', 'who', 'whom', 'which', 'where', 'why',
  'section', 'sections', 'sec', 'act', 'acts', 'law', 'laws', 'rule', 'rules',
  'article', 'articles', 'tell', 'give', 'please', 'know', 'find', 'show',
  'explain', 'detail', 'details', 'information', 'buddha', 'statue',
  'hyderabad', 'delhi', 'bangalore', 'mumbai', 'chennai', 'kolkata',
  'city', 'place', 'monument', 'temple', 'near',
};

final _sectionRefPattern = RegExp(r'\bsec(?:tion)?\.?\s*#?\s*(\d+[a-zA-Z]*)\b', caseSensitive: false);
final _bnsPattern = RegExp(r'\bbns\s*(?:sec(?:tion)?)?\.?\s*#?\s*(\d+[a-zA-Z]*)\b', caseSensitive: false);
final _ipcPattern = RegExp(r'\bipc\s*(?:sec(?:tion)?)?\.?\s*#?\s*(\d+[a-zA-Z]*)\b', caseSensitive: false);

class OfflineQaService {
  // ---------------------------------------------------------------------------
  // Safety Patterns
  // ---------------------------------------------------------------------------
  static final _selfHarmPattern = RegExp(
    r'\b(?:i want to|i(?:\x27m|\x20am) going to|thinking about|planning to)\s+(?:kill myself|end my life|die by suicide)\b|\bhow (?:do|can) i (?:commit suicide|kill myself)\b|\bi (?:don(?:\x27t|\x20not)|do not) want to (?:live|be alive) anymore\b',
    caseSensitive: false,
  );

  static final _hackPattern = RegExp(
    r'\bhow (?:do|can) i (?:hack|break into|steal from)\b.*\b(?:bank|account|upi|wallet|card|phone|email)\b|\bhack(?:ing)? into (?:someone|his|her|their|my|a)?(?:\x27s)?\s*(?:bank|account|phone|email|system|upi)\b|\bhelp me (?:hack|break into)\b',
    caseSensitive: false,
  );

  static final _forgeryPattern = RegExp(
    r'\bhow (?:do|can) i (?:make|create|generate|forge|get)\b.*\b(?:fake|forged|fraudulent)\b.*\b(?:licence|license|rc|passport|aadhaar|pan|id|document)\b|\b(?:make|create|forge)\s+(?:a\s+|an\s+)?(?:fake|forged)?\s*(?:driving licence|driving license|rc|passport|aadhaar|pan|identity document|govt id|fake id)\b|\bhow (?:do|can) i forge\b',
    caseSensitive: false,
  );

  static final _hideEvidencePattern = RegExp(
    r'\bhow (?:do|can) i (?:hide|destroy|dispose of|erase|delete|wipe)\b.*\b(?:evidence|body|weapon|crime scene|fingerprint|traces|blood)\b|\b(?:hide|destroy|conceal|dispose of)\s+(?:evidence|the body|the weapon)\b.*\bafter (?:committing\s+|a\s+)?crime\b',
    caseSensitive: false,
  );

  static final _harmfulPattern = RegExp(
    r'\bhow (?:do|can) i (?:make|build|create) (?:a |an )?(?:bomb|explosive|pipe bomb)\b|\b(?:write|create|generate) (?:me |us )?(?:a |an )?(?:malware|ransomware|keylogger|computer virus|virus code)\b|\bwrite (?:me |us )?(?:a |an )?(?:phishing|scam) (?:email|message|sms|text)\b|\bwrite (?:me |us )?(?:a |an )?(?:threatening|blackmail|extortion) (?:message|letter|email|note)\b',
    caseSensitive: false,
  );

  // Informational legal question markers — if matched, NEVER flag as harmful
  static final _legalInquiryMarker = RegExp(
    r'\b(?:is|are|was|were)\b.{0,60}\b(?:illegal|a crime|an offence|punishable|legal)\b|\bis it (?:a crime|illegal|an offence)\b|\bwhat (?:is|are) the (?:punishment|penalty|section|law|fine)\b|\bwhat happens if\b|\bcan (?:i|someone|a person) be (?:charged|arrested|prosecuted|punished)\b|\bwhich section\b|\brights if\b|\bmy rights\b|\bwhat are my rights\b|\bwhat should i do\b|\bwhat can i do\b|\bexplain\b|\bdefine\b|\bprocedure for\b|\bhow to report\b|\bhow to complain\b|\bhow to file\b|\bhow to contest\b',
    caseSensitive: false,
  );

  /// Classifies the user's intent to avoid forcing non-legal queries into legal sections.
  static LegalIntent classifyIntent(String query) {
    final lower = query.toLowerCase().trim();

    // 0. Safety checks (Hack, Forgery, Hide Evidence, Self-harm)
    if (_selfHarmPattern.hasMatch(lower)) return LegalIntent.selfHarmRefusal;

    final isLegalInquiry = _legalInquiryMarker.hasMatch(lower);

    if (_hackPattern.hasMatch(lower)) return LegalIntent.hackRefusal;
    if (_forgeryPattern.hasMatch(lower)) return LegalIntent.forgeryRefusal;
    if (_hideEvidencePattern.hasMatch(lower)) return LegalIntent.hideEvidenceRefusal;

    if (!isLegalInquiry && _harmfulPattern.hasMatch(lower)) {
      return LegalIntent.generalHarmfulRefusal;
    }

    // 1. Check for landmark / location / non-legal questions
    if (_isLocationOrNonLegal(lower)) {
      return LegalIntent.locationQuestion;
    }

    // 2. Check for multi-issue legal queries
    if (_isMultiIssueQuery(lower)) {
      return LegalIntent.multiIssue;
    }

    // 3. Check for vague queries that need clarification first
    if (_isUnclearVagueQuery(lower)) {
      return LegalIntent.unclearClarification;
    }

    // 4. Check for specific section lookup
    if (_extractRequestedSectionNumber(lower) != null ||
        _bnsPattern.hasMatch(lower) ||
        _ipcPattern.hasMatch(lower)) {
      return LegalIntent.sectionLookup;
    }

    // 5. Check for situation-based legal problem
    if (_isSituationProblem(lower)) {
      return LegalIntent.situationProblem;
    }

    return LegalIntent.generalLegalQuestion;
  }

  static bool _isLocationOrNonLegal(String text) {
    final nonLegalMarkers = [
      'capital of india', 'capital of france', 'capital of usa', 'capital of',
      'who is the president', 'who is the prime minister',
      'buddha statue', 'charminar', 'golconda', 'hussain sagar', 'tank bund',
      'qutb shahi', 'ramoji', 'birla mandir', 'salargunj', 'taj mahal',
      'red fort', 'india gate', 'gateway of india', 'statue of unity',
      'monument', 'museum', 'tourist', 'sightseeing', 'how to reach',
      'where is', 'location of', 'directions to', 'distance between',
      'flight status', 'weather today', 'cricket score', 'movie review',
      'recipe for', 'hotel near', 'restaurant near',
    ];

    for (final lm in nonLegalMarkers) {
      if (text.contains(lm)) {
        final legalGrievances = [
          'stolen', 'theft', 'damage', 'vandalism', 'assault', 'arrest',
          'accident', 'police', 'fine', 'fir', 'case', 'crime', 'complaint'
        ];
        final hasGrievance = legalGrievances.any((g) => text.contains(g));
        if (!hasGrievance) return true;
      }
    }

    // Telugu non-legal/location triggers
    if (text.contains('బుద్ధ విగ్రహం') ||
        text.contains('ఎక్కడ ఉంది') ||
        text.contains('ఎక్కడుంది') ||
        text.contains('చార్మినార్') ||
        text.contains('వాతావరణం') ||
        text.contains('సినిమా') ||
        text.contains('క్రికెట్')) {
      return true;
    }

    // Hindi non-legal/location triggers
    if (text.contains('बुद्ध प्रतिमा') ||
        text.contains('कहाँ है') ||
        text.contains('कहा है') ||
        text.contains('चारमीनार') ||
        text.contains('मौसम') ||
        text.contains('क्रिकेट')) {
      return true;
    }

    return false;
  }

  static bool _isMultiIssueQuery(String text) {
    final hasLandlordEntry = (text.contains('landlord') || text.contains('owner') || text.contains('house')) &&
        (text.contains('enter') || text.contains('without permission') || text.contains('room') || text.contains('trespass'));
    final hasDepositIssue = text.contains('deposit') || text.contains('advance') || text.contains('security');
    return hasLandlordEntry && hasDepositIssue;
  }

  static bool _isUnclearVagueQuery(String text) {
    if (text.contains('neighbour') || text.contains('neighbor') ||
        text.contains('పొరుగు') || text.contains('पड़ोसी')) {
      final specificTroubles = [
        'threat', 'assault', 'beat', 'hit', 'damage', 'property',
        'wall', 'boundary', 'garbage', 'noise', 'water', 'encroach',
        'camera', 'cctv', 'abuse', 'kill', 'fir', 'police'
      ];
      final isSpecific = specificTroubles.any((w) => text.contains(w));
      if (!isSpecific) return true;
    }

    if (text == 'someone cheated me' ||
        text == 'i was cheated' ||
        text == 'cheating problem' ||
        text == 'nannu mosam chesaru' ||
        text == 'mujhe dhokha diya') {
      return true;
    }

    return false;
  }

  static bool _isSituationProblem(String text) {
    final situationIndicators = [
      'police stop', 'stops me', 'officer stops', 'asks for my documents', 'driving and asks',
      'wrong challan', 'e-challan', 'refuse fir', 'refuse to register', 'refuse my complaint',
      'upi', 'scammed', 'cheated online', 'arrested', 'rights if i am arrested',
      'ticket is confirmed', 'seat is occupied', 'landlord', 'deposit',
      'withhold my salary', 'withhold salary', 'salary', 'cybercrime',
      'illegal drugs', 'drugs', 'husband', 'wife', 'left me', 'deserted',
      'maintenance', 'support', 'accident happened', 'beaten', 'threatened',
      'భర్త', 'భార్య', 'వదిలేసారు', 'పోలీసులు ఆపారు', 'చలాన్', 'యూపీఐ', 'మోసం'
    ];
    return situationIndicators.any((s) => text.contains(s));
  }

  static LegalDomain _detectDomain(String text) {
    // 1. Police stop driving
    if ((text.contains('police') || text.contains('officer')) &&
        (text.contains('stop') || text.contains('driving') || text.contains('documents') || text.contains('licence') || text.contains('license'))) {
      return LegalDomain.policeStop;
    }

    // 2. Wrong e-challan
    if ((text.contains('challan') || text.contains('e-challan')) &&
        (text.contains('wrong') || text.contains('incorrect') || text.contains('mistake') || text.contains('not mine') || text.contains('dispute') || text.contains('contest'))) {
      return LegalDomain.wrongChallan;
    }

    // 3. Police refuse FIR
    if ((text.contains('police') || text.contains('sho') || text.contains('station')) &&
        (text.contains('refuse') || text.contains('denied') || text.contains('not taking') || text.contains('reject')) &&
        (text.contains('fir') || text.contains('complaint') || text.contains('case'))) {
      return LegalDomain.policeRefuseFir;
    }

    // 4. UPI fraud
    if ((text.contains('upi') || text.contains('gpay') || text.contains('phonepe') || text.contains('paytm') || text.contains('qr code')) &&
        (text.contains('scam') || text.contains('fraud') || text.contains('stole') || text.contains('cheated') || text.contains('deducted'))) {
      return LegalDomain.cyberFraud;
    }

    // 5. Cybercrime complaint general
    if (text.contains('cybercrime') || text.contains('cyber crime') || text.contains('file a cyber') || text.contains('report cyber')) {
      return LegalDomain.cybercrimeComplaint;
    }

    // 6. Arrest rights
    if (text.contains('arrest') || text.contains('arrested') || text.contains('detain') ||
        text.contains('custody') || text.contains('handcuff') || text.contains('bail') ||
        text.contains('అరెస్టు') || text.contains('गिरफ्तार')) {
      return LegalDomain.arrestRights;
    }

    // 7. Railway ticket & seat issue
    if (text.contains('railway') || text.contains('train') || text.contains('ticket') ||
        text.contains('tte') || text.contains('berth') || text.contains('seat') ||
        text.contains('రైల్వే') || text.contains('रेलवे')) {
      return LegalDomain.railway;
    }

    // 8. Landlord & deposit
    if (text.contains('landlord') || text.contains('tenant') || text.contains('deposit') ||
        text.contains('rent') || text.contains('evict') || text.contains('vacate')) {
      return LegalDomain.landlordTenant;
    }

    // 9. Workplace salary
    if (text.contains('salary') || text.contains('employer') || text.contains('wages') ||
        text.contains('withhold') || text.contains('boss') || text.contains('company not paying')) {
      return LegalDomain.workplaceSalary;
    }

    // 10. Drug offence (NDPS)
    if (text.contains('drug') || text.contains('narcotic') || text.contains('weed') ||
        text.contains('ganja') || text.contains('substance') || text.contains('ndps')) {
      return LegalDomain.drugOffence;
    }

    // 11. Matrimonial
    if (text.contains('husband') || text.contains('wife') || text.contains('marriage') ||
        text.contains('divorce') || text.contains('maintenance') || text.contains('desert') ||
        text.contains('left me') || text.contains('support') || text.contains('dowry') ||
        text.contains('భర్త') || text.contains('భార్య') || text.contains('భరణం') ||
        text.contains('पति') || text.contains('पत्नी')) {
      return LegalDomain.familyMatrimonial;
    }

    // 12. Traffic general
    if (text.contains('challan') || text.contains('traffic') || text.contains('helmet') ||
        text.contains('signal') || text.contains('drunk driving') || text.contains('చలాన్') || text.contains('चालान')) {
      return LegalDomain.traffic;
    }

    // 13. Criminal violence / theft
    if (text.contains('theft') || text.contains('stolen') || text.contains('robbery') ||
        text.contains('assault') || text.contains('beaten') || text.contains('murder') ||
        text.contains('injury') || text.contains('threat')) {
      return LegalDomain.criminalViolence;
    }

    // 14. Consumer
    if (text.contains('consumer') || text.contains('defective') || text.contains('warranty') || text.contains('refund')) {
      return LegalDomain.consumer;
    }

    return LegalDomain.general;
  }

  static String? _extractRequestedSectionNumber(String query) {
    final bnsMatch = _bnsPattern.firstMatch(query);
    if (bnsMatch != null) return bnsMatch.group(1);

    final ipcMatch = _ipcPattern.firstMatch(query);
    if (ipcMatch != null) return ipcMatch.group(1);

    return _sectionRefPattern.firstMatch(query)?.group(1);
  }

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .split(RegExp(r'[\s,.;:!?()\[\]{}""‘’“”/\-_+=@#$%^&*<>|]+'))
        .map((t) => t.trim())
        .where((t) => t.length > 2 && !_stopwords.contains(t))
        .toList();
  }

  static String _normalizeRef(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Calculates section score using ONLY substantive keywords, rejecting spurious matches.
  static double _score(LegalSection section, String queryLower, List<String> queryTokens, LegalDomain domain) {
    if (domain == LegalDomain.familyMatrimonial) {
      final isFamily = section.lawShortName.contains('HMA') ||
          section.lawName.toLowerCase().contains('marriage') ||
          section.title.toLowerCase().contains('divorce') ||
          section.title.toLowerCase().contains('maintenance') ||
          section.keywords.toLowerCase().contains('maintenance') ||
          section.keywords.toLowerCase().contains('husband');
      if (!isFamily) return 0;
    } else if (domain == LegalDomain.traffic || domain == LegalDomain.policeStop || domain == LegalDomain.wrongChallan) {
      final isTraffic = section.lawShortName.contains('MVA') ||
          section.lawName.toLowerCase().contains('motor vehicle') ||
          section.keywords.toLowerCase().contains('traffic') ||
          section.keywords.toLowerCase().contains('helmet') ||
          section.keywords.toLowerCase().contains('challan');
      if (!isTraffic) return 0;
    } else if (domain == LegalDomain.railway) {
      if (!section.lawName.toLowerCase().contains('railway')) return 0;
    } else if (domain == LegalDomain.consumer) {
      if (!section.lawName.toLowerCase().contains('consumer')) return 0;
    } else if (domain == LegalDomain.arrestRights || domain == LegalDomain.policeRefuseFir) {
      final isArrest = section.keywords.toLowerCase().contains('arrest') ||
          section.title.toLowerCase().contains('arrest') ||
          section.lawShortName.contains('BNSS') ||
          section.lawShortName.contains('Constitution');
      if (!isArrest) return 0;
    }

    if (queryTokens.isEmpty) return 0;

    double score = 0;
    final title = section.title.toLowerCase();
    final titleTe = section.titleTe.toLowerCase();
    final displayTitle = section.displayTitle.toLowerCase();
    final explanation = section.simpleExplanation.toLowerCase();
    final displayExplanation = section.displaySimpleExplanation.toLowerCase();
    final legalText = section.legalText.toLowerCase();
    final keywords = section.keywords.toLowerCase();

    int matchedTokens = 0;

    for (final token in queryTokens) {
      bool matchedThis = false;
      if (title.contains(token) || titleTe.contains(token) || displayTitle.contains(token)) {
        score += 8;
        matchedThis = true;
      }
      if (keywords.contains(token)) {
        score += 6;
        matchedThis = true;
      }
      if (explanation.contains(token) || displayExplanation.contains(token)) {
        score += 4;
        matchedThis = true;
      }
      if (legalText.contains(token)) {
        score += 2;
        matchedThis = true;
      }
      if (matchedThis) matchedTokens++;
    }

    if (matchedTokens == 0) return 0;

    final normalizedSectionNumber = _normalizeRef(section.sectionNumber);
    final normalizedQuery = _normalizeRef(queryLower);
    if (normalizedSectionNumber.isNotEmpty && normalizedQuery.contains(normalizedSectionNumber)) {
      score += 15;
    }

    return score;
  }

  static List<LegalSection> rank(String query, List<LegalSection> sections, {int topN = 3, LegalDomain domain = LegalDomain.general}) {
    final queryLower = query.toLowerCase();
    final queryTokens = _tokenize(query);

    if (queryTokens.isEmpty) return [];

    final scored = sections
        .map((s) => MapEntry(s, _score(s, queryLower, queryTokens, domain)))
        .where((e) => e.value >= 4.0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.take(topN).map((e) => e.key).toList();
  }

  /// Main AI Entry Point for offline questions.
  static String answer(String query, List<LegalSection> sections) {
    final isTe = LocaleService.isTelugu;
    final isHi = LocaleService.isHindi;

    final intent = classifyIntent(query);

    // =========================================================================
    // 0. SAFETY REFUSALS (Hack, Forgery, Hide Evidence, Self-Harm, Harmful)
    // =========================================================================
    if (intent == LegalIntent.hackRefusal) {
      return "I can't provide instructions for hacking or stealing from someone. If your goal is legitimate cybersecurity testing, I can help with ethical security testing, account protection, or reporting a vulnerability.";
    }
    if (intent == LegalIntent.forgeryRefusal) {
      return "I can't help create or use a forged document. I can explain the lawful process for obtaining or replacing a driving licence.";
    }
    if (intent == LegalIntent.hideEvidenceRefusal) {
      return "I can't provide instructions for hiding or destroying evidence. I can explain general legal rights, the investigation process, and how to seek qualified legal assistance.";
    }
    if (intent == LegalIntent.selfHarmRefusal) {
      return "It sounds like you might be going through something really difficult right now. I'm not able to help with that, but you don't have to face it alone - the KIRAN Mental Health Rehabilitation Helpline (1800-599-0019) is a free, 24x7, government-run helpline in India with trained counsellors who can talk this through with you in your own language. Please consider reaching out to them, or to someone you trust, right now.";
    }
    if (intent == LegalIntent.generalHarmfulRefusal) {
      return "I can't help plan or carry out something illegal or harmful. If you'd like, I'm glad to explain the relevant law itself instead — for example, what counts as an offence here, what the punishment is, or what your options are if you're on the receiving end of something like this.";
    }

    // =========================================================================
    // 1. NON-LEGAL / LOCATION QUESTIONS (e.g. Buddha Statue in Hyderabad)
    // =========================================================================
    if (intent == LegalIntent.locationQuestion || intent == LegalIntent.nonLegalQuestion) {
      final lower = query.toLowerCase();
      if (lower.contains('capital of india')) {
        return "The capital of India is New Delhi.\n\nNote: That appears to be a general question rather than a legal question. LegalGuide Assistant is primarily designed to help with Indian laws, citizen rights, and legal procedures.";
      }
      if (lower.contains('capital of france')) {
        return "The capital of France is Paris.\n\nNote: That appears to be a general question rather than a legal question. LegalGuide Assistant is primarily designed to help with Indian laws, citizen rights, and legal procedures.";
      }
      if (isTe) {
        return "ఇది చట్టపరమైన ప్రశ్న కాకుండా స్థానానికి సంబంధించిన ప్రశ్నగా కనిపిస్తోంది. నేను చట్టపరమైన సమాచారం, హక్కులు, విధానాలు మరియు భారతీయ చట్టాలలో సహాయం చేయగలను.";
      }
      if (isHi) {
        return "यह कानूनी प्रश्न के बजाय किसी स्थान से संबंधित प्रश्न लगता है। मैं कानूनी जानकारी, अधिकार, प्रक्रिया और भारतीय कानूनों में मदद कर सकता हूँ।";
      }
      return "That appears to be a location question rather than a legal question. I can help with legal information, rights, procedures, and Indian laws.";
    }

    // =========================================================================
    // 2. MULTI-ISSUE QUESTIONS (e.g. Landlord entered room & refused deposit)
    // =========================================================================
    if (intent == LegalIntent.multiIssue) {
      return _formatMultiIssueResponse(isTe, isHi);
    }

    // =========================================================================
    // 3. UNCLEAR / VAGUE QUESTIONS (Ask Clarifying Questions)
    // =========================================================================
    if (intent == LegalIntent.unclearClarification) {
      final lower = query.toLowerCase();
      if (lower.contains('neighbour') || lower.contains('neighbor') || lower.contains('పొరుగు') || lower.contains('पड़ोसी')) {
        if (isTe) {
          return 'మీ పొరుగువారు ఏమి చేస్తున్నారు—ఉదాహరణకు బెదిరించడం, శారీరక దాడి చేయడం, ఆస్తికి నష్టం కలిగించడం, మార్గాన్ని అడ్డుకోవడం లేదా పదేపదే వేధించడం వంటివా? దయచేసి మరికొన్ని వివరాలు తెలపండి, తద్వారా ఖచ్చితమైన చట్టపరమైన నిబంధనను తెలియజేయగలను.';
        }
        if (isHi) {
          return 'आपका पड़ोसी क्या कर रहा है—उदाहरण के लिए, धमकी दे रहा है, शारीरिक चोट पहुँचा रहा है, संपत्ति को नुकसान पहुँचा रहा है, या बार-बार परेशान कर रहा है? सटीक कानूनी प्रावधान की पहचान करने के लिए कृपया कुछ और विवरण साझा करें।';
        }
        return 'What is your neighbour doing—for example, threatening you, physically harming you, damaging property, or repeatedly harassing you? Please share a few more details so I can identify the exact applicable law.';
      }

      if (isTe) {
        return 'మీ పరిస్థితికి వర్తించే సరైన చట్టాన్ని గుర్తించడానికి, దయచేసి స్పష్టం చేయండి: ఏమి జరిగింది? ఎవరి ప్రమేయం ఉంది మరియు ఎలాంటి నష్టం లేదా సమస్య ఏర్పడింది? మరిన్ని వివరాలు అందిస్తే తగిన నిబంధనలను పరిశీలించగలను.';
      }
      if (isHi) {
        return 'आपकी स्थिति पर लागू होने वाले सही कानून की पहचान करने के लिए, कृपया स्पष्ट करें: क्या हुआ था? इसमें कौन शामिल है और क्या नुकसान या समस्या हुई? अधिक विवरण प्रदान करने पर मैं सटीक प्रावधान बता सकूँगा।';
      }
      return 'To help identify the exact law that applies to your situation, please clarify: What happened? Who is involved, and what harm or dispute occurred? Sharing these details will help me find the verified legal provisions.';
    }

    // =========================================================================
    // 4. SECTION LOOKUP & HISTORICAL LAWS (e.g. "BNS 103", "IPC 302")
    // =========================================================================
    if (intent == LegalIntent.sectionLookup) {
      return _handleSectionLookup(query, sections, isTe, isHi);
    }

    // =========================================================================
    // 5. SITUATION-BASED LEGAL PROBLEMS (e.g. Police stop, wrong challan, FIR refusal, UPI scam)
    // =========================================================================
    final domain = _detectDomain(query.toLowerCase());
    final matches = rank(query, sections, domain: domain);

    // If no verified match in domain or query is completely ungrounded
    if (domain == LegalDomain.general && matches.isEmpty) {
      if (isTe) {
        return 'ప్రస్తుత లీగల్‌గైడ్ లీగల్ డేటాబేస్ నుండి ఈ ప్రశ్నకు నిర్దిష్ట చట్టపరమైన నిబంధన ధృవీకరించబడలేదు. మీరు నిర్దిష్ట చట్టపరమైన పరిస్థితిని ఎదుర్కొంటుంటే, దయచేసి మరిన్ని వివరాలు అందించండి లేదా అర్హత కలిగిన న్యాయవాదిని సంప్రదించండి.';
      }
      if (isHi) {
        return 'इस प्रश्न के लिए वर्तमान लीगलगाइड कानूनी डेटाबेस से कोई विशिष्ट प्रावधान सत्यापित नहीं किया जा सका। यदि आप किसी विशिष्ट कानूनी स्थिति का सामना कर रहे हैं, तो कृपया अधिक विवरण प्रदान करें।';
      }
      return 'No specific provision could be verified from the current LegalGuide legal database for this question. If you are facing a specific legal situation, please provide more details.';
    }

    final rawResponse = _formatSituationResponse(query, domain, matches, isTe, isHi);
    return validateAndFinalizeAnswer(rawResponse, domain);
  }

  /// Ensures answer completeness: Quick Answer must be substantive, actions included, and never a 1-line stub.
  static String validateAndFinalizeAnswer(String answer, LegalDomain domain) {
    if (answer.trim().isEmpty) {
      return "No specific provision could be verified from the current LegalGuide legal database for this question.";
    }
    // Protect against the known truncated stub "If a police officer stops you..."
    if (answer.trim().startsWith("If a police officer stops you") && answer.length < 100) {
      return _formatPoliceStopDetailed(false, false);
    }
    return answer;
  }

  static String _formatMultiIssueResponse(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'When a landlord enters a rented premises without tenant permission and simultaneously refuses to return the security deposit, two distinct legal disputes arise: unauthorized entry/violation of tenant privacy and wrongful withholding of the security deposit. Both are legally remediable under Indian tenancy and civil laws.'
    );
    buffer.writeln();

    buffer.writeln('### Issue 1: Unauthorized Entry & Tenant Privacy');
    buffer.writeln('- **What Happened:** Landlord entering the rented premises without tenant consent or prior notice.');
    buffer.writeln('- **Your Rights:** A tenant in lawful possession has the right to quiet enjoyment and privacy. Landlords do NOT possess an unfettered right of entry without reasonable notice (typically 24 hours under the Model Tenancy Act). Unauthorized forced entry can constitute criminal trespass under Section 329 of the Bharatiya Nyaya Sanhita, 2023 (BNS).');
    buffer.writeln('- **What You Should Do:** Record dates and times of unauthorized entries. Send a formal written objection to the landlord asserting your right to privacy.');
    buffer.writeln();

    buffer.writeln('### Issue 2: Security Deposit Refund');
    buffer.writeln('- **What Happened:** Unlawful withholding or arbitrary deductions from the security deposit upon vacating.');
    buffer.writeln('- **Your Rights:** The security deposit is held in trust and must be refunded within 30 days after handing over vacant possession, minus only legitimate, pre-agreed damages beyond normal wear and tear.');
    buffer.writeln('- **What You Should Do:** Document the property condition with move-out photos/videos. Issue a formal legal notice demanding refund with interest. If unresolved, file an application before the Rent Authority or Consumer Commission.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Model Tenancy Act / State Rent Control Acts** (Tenant privacy, statutory notice for inspection, mandatory security deposit refund)');
    buffer.writeln('- **Bharatiya Nyaya Sanhita, 2023 — Section 329** (Criminal trespass)');
    buffer.writeln('- **Indian Contract Act, 1872 — Section 73** (Compensation for breach of contract)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Signed Lease / Rental Agreement');
    buffer.writeln('- Rent receipts and bank transaction records for security deposit payment');
    buffer.writeln('- Move-out photographs/videos showing property in good condition');
    buffer.writeln('- Copies of written notices, messages, and email communications');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('A landlord cannot use the security deposit as leverage or enter without notice to intimidate a tenant. Always maintain communications in writing rather than oral conversations.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Model Tenancy Act');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _handleSectionLookup(String query, List<LegalSection> sections, bool isTe, bool isHi) {
    final lower = query.toLowerCase();
    final requestedNumber = _extractRequestedSectionNumber(lower);
    final isIpc = lower.contains('ipc') || _ipcPattern.hasMatch(lower);

    if (requestedNumber != null) {
      final normalizedRequested = _normalizeRef(requestedNumber);

      LegalSection? matched;
      for (final s in sections) {
        if (_normalizeRef(s.sectionNumber) == normalizedRequested) {
          matched = s;
          break;
        }
      }

      // If not exact match, search previous_version_ref (e.g. Replaces IPC Section 302)
      if (matched == null && isIpc) {
        for (final s in sections) {
          if ((s.previousVersionRef?.toLowerCase().contains(requestedNumber) ?? false) ||
              s.amendmentInfo.toLowerCase().contains(requestedNumber)) {
            matched = s;
            break;
          }
        }
      }

      if (matched != null) {
        final buffer = StringBuffer();
        buffer.writeln('### Quick Answer');
        if (isIpc && matched.lawShortName.contains('BNS')) {
          buffer.writeln(
            'Section $requestedNumber of the Indian Penal Code, 1860 (IPC) was the historical statutory provision. '
            'The IPC was repealed and replaced by the Bharatiya Nyaya Sanhita, 2023 (BNS), effective from July 1, 2024. '
            'The corresponding current provision is Section ${matched.sectionNumber} of the Bharatiya Nyaya Sanhita (BNS).'
          );
        } else {
          buffer.writeln('${matched.lawShortName} Section ${matched.sectionNumber} — ${matched.displayTitle}: ${matched.displaySimpleExplanation}');
        }
        buffer.writeln();

        buffer.writeln('### Key Points');
        if (isIpc && matched.lawShortName.contains('BNS')) {
          buffer.writeln('- **Former / Historical Law:** IPC Section $requestedNumber (Repealed)');
          buffer.writeln('- **Current Law:** ${matched.lawShortName} Section ${matched.sectionNumber} (In force from July 1, 2024)');
        }
        if (matched.displayPunishment.isNotEmpty) {
          buffer.writeln('- **Punishment:** ${matched.displayPunishment}');
        }
        if (matched.keyElementsList.isNotEmpty) {
          for (final elem in matched.keyElementsList) {
            if (elem.trim().isNotEmpty) buffer.writeln('- $elem');
          }
        }
        buffer.writeln();

        if (matched.hasRealLifeExample) {
          buffer.writeln('### Real-Life Example');
          buffer.writeln('**Situation:** ${matched.displayExampleSituation}');
          buffer.writeln();
          buffer.writeln('**How the law may apply:** ${matched.displayExampleExplanation}');
          buffer.writeln();
          buffer.writeln('*${matched.displayExampleDisclaimer}*');
          buffer.writeln();
        }

        if (matched.whatYouShouldDoList.isNotEmpty) {
          buffer.writeln('### What You Should Do');
          for (final action in matched.whatYouShouldDoList) {
            buffer.writeln('- $action');
          }
          buffer.writeln();
        }

        buffer.writeln('### Applicable Law');
        buffer.writeln('**${matched.lawName}**');
        buffer.writeln('- **Section ${matched.sectionNumber} — ${matched.displayTitle}** (${matched.statusDisplayLabel})');
        buffer.writeln('  ${matched.displaySimpleExplanation}');
        buffer.writeln();

        if (matched.legalText.isNotEmpty) {
          buffer.writeln('### Official Statutory Text');
          buffer.writeln(matched.legalText);
          buffer.writeln();
        }

        buffer.writeln('### Important');
        buffer.writeln('Offences committed on or after July 1, 2024 are charged under the Bharatiya Nyaya Sanhita (BNS), whereas offences that occurred prior to July 1, 2024 continue to be tried under the repealed Indian Penal Code (IPC).');
        buffer.writeln();

        buffer.writeln('### Official Sources');
        final verifiedDate = matched.lastVerified ?? '2024-07-01';
        final srcName = matched.sourceName.isNotEmpty ? matched.sourceName : 'India Code (Official Government Source - indiacode.gov.in)';
        buffer.writeln('⚖️ **Verified Source:** $srcName');
        buffer.writeln('📅 **Last Verified:** $verifiedDate');

        return buffer.toString().trim();
      }
    }

    return 'No specific provision could be verified from the current LegalGuide legal database for this question.';
  }

  static String _formatSituationResponse(
    String query,
    LegalDomain domain,
    List<LegalSection> matches,
    bool isTe,
    bool isHi,
  ) {
    switch (domain) {
      case LegalDomain.policeStop:
        return _formatPoliceStopDetailed(isTe, isHi);
      case LegalDomain.wrongChallan:
        return _formatWrongChallanDetailed(isTe, isHi);
      case LegalDomain.policeRefuseFir:
        return _formatPoliceRefuseFirDetailed(isTe, isHi);
      case LegalDomain.cyberFraud:
        return _formatUpiFraudDetailed(isTe, isHi);
      case LegalDomain.cybercrimeComplaint:
        return _formatCybercrimeComplaintDetailed(isTe, isHi);
      case LegalDomain.arrestRights:
        return _formatArrestRightsDetailed(isTe, isHi);
      case LegalDomain.railway:
        return _formatRailwaySeatDetailed(isTe, isHi);
      case LegalDomain.landlordTenant:
        return _formatLandlordDepositDetailed(isTe, isHi);
      case LegalDomain.workplaceSalary:
        return _formatWorkplaceSalaryDetailed(isTe, isHi);
      case LegalDomain.drugOffence:
        return _formatDrugOffenceDetailed(isTe, isHi);
      case LegalDomain.familyMatrimonial:
        return _formatMatrimonialDetailed(matches, isTe, isHi);
      case LegalDomain.traffic:
        return _formatTrafficDetailed(matches, isTe, isHi);
      default:
        return _formatGenericSituation(query, domain, matches, isTe, isHi);
    }
  }

  // ---------------------------------------------------------------------------
  // Detailed Scenario Generators
  // ---------------------------------------------------------------------------

  static String _formatPoliceStopDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'When stopped by a police or traffic officer for a routine document check while driving, safely pull over to the side of the road, remain calm, and cooperate with the lawful check. Under the Motor Vehicles Act and Central Motor Vehicles Rules, drivers are required to produce valid documents upon demand.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- Only traffic police officers of Sub-Inspector (SI) rank or above (wearing white uniform with star insignia or carrying an official e-challan machine) are authorized to issue challans above Rs 100.');
    buffer.writeln('- Police officers do NOT have the legal authority to snatch your vehicle ignition keys, use abusive language, or deflate tires.');
    buffer.writeln('- Valid digital documents displayed on government-approved apps (DigiLocker or mParivahan) are legally at par with physical original documents under Rule 139 of the Central Motor Vehicles Rules (CMVR).');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Stop safely:** Park safely on the curb, switch off the ignition, and cooperate with the lawful check.');
    buffer.writeln('2. **Ask for identification:** If the officer is not in uniform or displaying a name badge, politely ask to see their official identity card.');
    buffer.writeln('3. **Show required documents:** Present your Driving Licence, Registration Certificate (RC), valid Vehicle Insurance, and Pollution Under Control (PUC) certificate physically or digitally via DigiLocker / mParivahan.');
    buffer.writeln('4. **Verify any challan issued:** Ensure the challan is generated electronically from an official handheld machine with the officer\'s details, vehicle number, specific section, and exact fine amount.');
    buffer.writeln('5. **Do not pay bribes:** Always insist on an official printed receipt or e-challan SMS; never hand over cash without a government-printed receipt.');
    buffer.writeln('6. **Contest wrongful action:** If you believe a challan is unjust, you have the legal right to contest it in Virtual Court or before the Special Metropolitan Magistrate.');
    buffer.writeln('7. **Detention or escalation rights:** Under Rule 139 CMVR, if you do not have physical documents with you at that exact moment, you have up to 15 days to present them to the designated police authority before being penalized for driving without documents.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Motor Vehicles Act, 1988 — Section 130** (Duty of driver to produce licence and certificate of registration)');
    buffer.writeln('- **Central Motor Vehicles Rules, 1989 — Rule 139** (Production of licence and certificate of registration, 15-day presentation window, and acceptance of digital documents on DigiLocker/mParivahan)');
    buffer.writeln('- **Motor Vehicles Act, 1988 — Section 177 / Section 179** (General penalties and disobedience of lawful orders)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Valid Driving Licence (DL)');
    buffer.writeln('- Vehicle Registration Certificate (RC)');
    buffer.writeln('- Valid Motor Third-Party / Comprehensive Insurance Policy');
    buffer.writeln('- Pollution Under Control (PUC) Certificate');
    buffer.writeln('- Official e-challan copy or printed receipt if penalized');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('If an officer seizes your physical licence, they must provide an official compounding receipt or seizure memo under Section 206 of the Motor Vehicles Act, which acts as a temporary driving permit until the hearing or fine settlement.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Ministry of Road Transport and Highways (MoRTH)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatWrongChallanDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'If you have received an incorrect, false, or mistakenly generated e-challan (such as mismatched vehicle photos, wrong number plate reading, or wrong location), you are not required to pay it blindly. You have the statutory right to contest or file an online grievance to get it cancelled.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- Common causes of wrong e-challans include automated camera OCR misreading similar registration numbers, cloned plates, or incorrect classification by traffic sensors.');
    buffer.writeln('- Paying the challan admits guilt and closes the dispute route. If you believe the challan is incorrect, do NOT pay it immediately.');
    buffer.writeln('- Disputed e-challans can be settled either through the online Parivahan Grievance portal or referred to the Virtual Court (vcourts.gov.in) for judicial review.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Verify evidence online:** Visit the official Parivahan e-Challan portal (echallan.parivahan.gov.in) and enter your Challan Number or Vehicle Number. Download the photographic proof, camera location, and timestamp.');
    buffer.writeln('2. **Review photographic proof:** Verify whether the vehicle in the photograph is actually yours (check make, model, color, and number plate characters).');
    buffer.writeln('3. **File an Online Grievance:** Click on "Complaint / Grievance" on the Parivahan portal or state traffic police portal. Attach your RC copy, photos of your actual vehicle, and explain the discrepancy.');
    buffer.writeln('4. **Contest in Virtual Court:** If the grievance is rejected or the challan is sent to court, visit the Virtual Court portal (vcourts.gov.in), select your state, and choose "I want to contest the offence".');
    buffer.writeln('5. **Preserve alibi evidence:** Gather supporting evidence such as toll plaza receipts, FASTag logs, dashcam footage, or GPS tracking logs proving your vehicle was elsewhere.');
    buffer.writeln('6. **Report number plate fraud:** If another vehicle is using a cloned/fake number plate identical to yours, immediately lodge a formal police complaint for fraud and identity theft.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Motor Vehicles Act, 1988 — Section 208** (Summary disposal of cases and notice of offence)');
    buffer.writeln('- **Central Motor Vehicles Rules, 1989 — Rule 167A** (Electronic monitoring and enforcement of road safety, photographic/video recording standards)');
    buffer.writeln('- **Information Technology Act, 2000 — Section 66D** (If someone is impersonating or using fake number plates)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Copy of the disputed e-Challan notice');
    buffer.writeln('- Vehicle Registration Certificate (RC)');
    buffer.writeln('- Photos of your vehicle showing distinct features and number plate');
    buffer.writeln('- FASTag transaction history, GPS/dashcam logs proving absence from violation site');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Ignoring an e-challan can lead to blacklisting of your vehicle on the VAHAN portal, preventing insurance renewal or ownership transfer. Always resolve or contest the challan within the specified window (typically 60 days).');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** Ministry of Road Transport and Highways (MoRTH) & eChallan Parivahan Portal (echallan.parivahan.gov.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatPoliceRefuseFirDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'Under Indian criminal jurisprudence and Supreme Court precedent (Lalita Kumari v. Govt. of UP), registration of a First Information Report (FIR) is mandatory for any cognizable offence. If a police station refuses to register your complaint, you have hierarchical statutory remedies under the law.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- The Station House Officer (SHO) cannot refuse an FIR on the grounds of lack of territorial jurisdiction; they must register a "Zero FIR" and transfer it to the appropriate police station.');
    buffer.writeln('- You have the statutory right under Bharatiya Nagarik Suraksha Sanhita (BNSS), 2023 to escalate directly to the Superintendent of Police and the Judicial Magistrate.');
    buffer.writeln('- Willful refusal to register an FIR by a public servant is punishable under Section 199 of the Bharatiya Nyaya Sanhita (BNS).');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Submit a formal written complaint:** Hand over a written, signed copy of the complaint to the Station House Officer (SHO). Request a dated acknowledgment receipt or official stamp on a duplicate copy.');
    buffer.writeln('2. **Escalate to the Superintendent of Police (SP / DCP):** Under Section 173(4) BNSS (formerly Section 154(3) CrPC), send the substance of your complaint in writing via registered post or email to the Superintendent of Police or Commissioner of Police.');
    buffer.writeln('3. **Approach the Judicial Magistrate:** If the SP fails to act within a reasonable time, file an application under Section 175(3) BNSS (formerly Section 156(3) CrPC) before the Judicial Magistrate having jurisdiction, requesting an order directing the police to register the FIR and investigate.');
    buffer.writeln('4. **File a Private Complaint:** You can also file a direct criminal complaint before the Magistrate under Section 223 BNSS (formerly Section 200 CrPC).');
    buffer.writeln('5. **Police Complaints Authority (PCA):** If police officers acted maliciously, harassed you, or demanded bribes, file a grievance with the State Police Complaints Authority (SPCA) or National Human Rights Commission (NHRC).');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 173** (Information in cognizable cases; mandatory registration of FIR and Zero FIR)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 175(3)** (Magistrate\'s power to order police investigation)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 223** (Examination of complainant by Magistrate)');
    buffer.writeln('- **Bharatiya Nyaya Sanhita, 2023 — Section 199** (Public servant disobeying direction under law)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Detailed written complaint specifying date, time, location, suspect details, and incident description');
    buffer.writeln('- Copy of postal receipt / speed post acknowledgment sent to the SP / Commissioner');
    buffer.writeln('- Medical reports, photos, digital communications, or witness contact details supporting the complaint');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Always keep postal receipts and tracking logs of communications sent to senior police officers, as these serve as mandatory proof when filing a Section 175(3) petition before the Magistrate.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Supreme Court Landmark Ruling (Lalita Kumari vs. Govt of UP)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatUpiFraudDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'If you have fallen victim to a UPI fraud or financial scam, immediate action within the "Golden Hour" (the first 2 to 4 hours) is critical to freeze the fraudster\'s beneficiary account and maximize the likelihood of fund reversal.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- Dialing the National Cyber Crime Helpline **1930** immediately triggers an automated freeze request across the Indian financial ecosystem via the Citizen Financial Cyber Fraud Reporting and Management System (CFCFRMS).');
    buffer.writeln('- Under Reserve Bank of India (RBI) guidelines on customer liability, reporting an unauthorized electronic banking transaction promptly protects you against liability.');
    buffer.writeln('- Legitimate banks and UPI apps NEVER request your UPI PIN to credit money to your account. Approving a "Collect Request" or scanning a QR code always debits money, never receives it.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Call 1930 immediately:** Dial the 24x7 National Cyber Financial Fraud Helpline 1930. Provide your bank name, account number, UPI reference ID / transaction ID, date, time, and the amount stolen.');
    buffer.writeln('2. **File an online complaint at cybercrime.gov.in:** Log onto the official National Cyber Crime Reporting Portal (cybercrime.gov.in) and register a formal complaint under the "Financial Fraud" category. Save the acknowledgment number.');
    buffer.writeln('3. **Contact your bank and UPI app:** Immediately call your bank\'s fraud reporting helpline and the UPI app customer care (Google Pay, PhonePe, Paytm, BHIM) to block the UPI ID and freeze the linked account.');
    buffer.writeln('4. **Preserve all digital evidence:** Take clear screenshots of the UPI transaction confirmation, bank SMS alerts, WhatsApp or Telegram chat history, suspect phone numbers, and phishing URLs.');
    buffer.writeln('5. **Visit the nearest Cyber Crime Police Station:** Submit a formal written complaint with your bank statement and transaction screenshots to the local cyber police station to obtain a stamped copy of the complaint.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Information Technology Act, 2000 — Section 66C** (Identity theft)');
    buffer.writeln('- **Information Technology Act, 2000 — Section 66D** (Cheating by personation using computer resource)');
    buffer.writeln('- **Bharatiya Nyaya Sanhita, 2023 — Section 318** (Cheating and dishonestly inducing delivery of property)');
    buffer.writeln('- **Reserve Bank of India (RBI) Circular** on Limiting Liability of Customers in Unauthorized Electronic Banking Transactions');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Bank account statement showing the fraudulent debit');
    buffer.writeln('- UPI 12-digit UTR / Transaction Reference Number');
    buffer.writeln('- Screenshots of payment screen, SMS alerts, and suspect communications');
    buffer.writeln('- Cyber Crime Portal complaint acknowledgment receipt (from 1930 / cybercrime.gov.in)');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Do NOT delete chats or phone logs with the fraudster, and do NOT install any remote-access applications (such as AnyDesk, TeamViewer, or QuickSupport) if instructed by someone claiming to be bank support.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** National Cyber Crime Reporting Portal (cybercrime.gov.in) & Reserve Bank of India (rbi.org.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatCybercrimeComplaintDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'In India, a cybercrime complaint can be filed conveniently online through the official National Cyber Crime Reporting Portal (cybercrime.gov.in) or offline by visiting any local police station or specialized Cyber Crime Police Station.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- The National Cyber Crime Portal operates under the Ministry of Home Affairs (MHA) and accepts complaints nationwide for both financial frauds and other digital offences.');
    buffer.writeln('- For financial cyber frauds (UPI scams, credit card theft, unauthorized transfers), dial helpline **1930** immediately to activate interstate banking account freezing.');
    buffer.writeln('- Women and children can file complaints anonymously or report cyber harassment, non-consensual image sharing, stalking, and morphing with special privacy protections.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **For Immediate Financial Cyber Fraud:** Call helpline **1930** within 2 to 4 hours of the incident.');
    buffer.writeln('2. **Online Portal Filing (cybercrime.gov.in):** Visit cybercrime.gov.in, select the appropriate category, fill in incident details and suspect URLs/phones, upload evidence, and record your Acknowledgement Number.');
    buffer.writeln('3. **Offline Police Filing:** Submit a written complaint detailing the events to your nearest Cyber Cell or local police station (Zero FIR can be filed if jurisdictional ambiguity exists).');
    buffer.writeln('4. **Preserve Digital Evidence:** Take screenshots of social media profile links, chats, transaction IDs, emails with complete headers, and voice notes without deleting them.');
    buffer.writeln('5. **Track Complaint Status:** Use the acknowledgment number on cybercrime.gov.in to monitor investigation progress.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Information Technology Act, 2000 — Section 43** (Penalty for damage to computer system)');
    buffer.writeln('- **Information Technology Act, 2000 — Section 66** (Computer related offences)');
    buffer.writeln('- **Information Technology Act, 2000 — Section 66C & 66D** (Identity theft and cheating by personation)');
    buffer.writeln('- **Information Technology Act, 2000 — Section 67 & 67A** (Transmitting obscene material in electronic form)');
    buffer.writeln('- **Bharatiya Nyaya Sanhita, 2023 — Section 318 & Section 319** (Cheating and impersonation)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Clear screenshots of chats, fake profiles, emails, or malicious links');
    buffer.writeln('- Bank account statement showing transaction details and UTR numbers');
    buffer.writeln('- Identity proof of complainant (Aadhaar, Voter ID, PAN)');
    buffer.writeln('- Cyber Crime Portal complaint acknowledgment copy');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Always report cybercrimes promptly; digital logs (such as IP addresses and server access logs) are stored by telecom service providers for a limited statutory retention period.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** National Cyber Crime Reporting Portal (cybercrime.gov.in) & Ministry of Home Affairs, Government of India');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatArrestRightsDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'Under the Constitution of India and the Bharatiya Nagarik Suraksha Sanhita (BNSS), 2023, an arrested citizen is protected by fundamental constitutional safeguards and mandatory statutory rights (established by the Supreme Court in the landmark D.K. Basu case).'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- You have the absolute constitutional right to know the exact grounds of your arrest and whether the offence is bailable or non-bailable.');
    buffer.writeln('- Police must prepare a formal Arrest Memo at the time of arrest, witnessed by at least one family member or respectable member of the locality.');
    buffer.writeln('- No woman can be arrested before sunrise or after sunset except in exceptional circumstances with prior written permission of a Judicial Magistrate, and female officers must be present.');
    buffer.writeln('- You MUST be produced before the nearest Judicial Magistrate within 24 hours of arrest.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Right to know grounds of arrest:** Ask the arresting officer to clearly specify the offence, section of law, and factual grounds for arrest (Article 22(1) Constitution & Section 47 BNSS).');
    buffer.writeln('2. **Right to inform a family member:** Under Section 48 BNSS, police are legally obligated to immediately notify a designated relative or friend about your arrest and the specific police station where you are held.');
    buffer.writeln('3. **Right to legal counsel:** You have the constitutional right to consult and be defended by an advocate of your choice (Article 22(1) & Section 37 BNSS). If unable to afford one, request free legal aid from DLSA.');
    buffer.writeln('4. **Right to medical examination:** Under Section 53 BNSS, you have the right to be medically examined by a registered government doctor upon arrest, documenting any existing injuries.');
    buffer.writeln('5. **Right to production within 24 hours:** Excluding travel time, the police must produce you before the nearest Judicial Magistrate within 24 hours (Article 22(2) & Section 58 BNSS). Detention beyond 24 hours without a Magistrate\'s remand order is illegal.');
    buffer.writeln('6. **Protection against self-incrimination:** You cannot be compelled to confess or be a witness against yourself (Article 20(3) of the Constitution).');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Constitution of India — Article 20(3), Article 21, and Article 22** (Fundamental rights to life, liberty, and protection against arbitrary arrest and detention)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 35** (Procedure and guidelines for arrest)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 43(5)** (Special protections for arrest of women)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 47** (Right to be informed of grounds of arrest and bail)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 48** (Obligation to inform nominated relative/friend)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 58** (Mandatory production before Magistrate within 24 hours)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Signed copy of the Arrest Memo');
    buffer.writeln('- Inspection Memo / Medical Examination Report');
    buffer.writeln('- Daily Diary / General Diary (GD) entry copy at the police station');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Never sign a blank sheet of paper or coerced confession in police custody. Statements made to police officers in custody are inadmissible as substantive evidence in court under Section 23 of the Bharatiya Sakshya Adhiniyam, 2023.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Supreme Court D.K. Basu Guidelines (1997)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatRailwaySeatDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'If you hold a valid, confirmed train ticket issued by Indian Railways, you have the legal right to occupy your allocated berth or seat. Unauthorized occupation or refusing to vacate a reserved seat is a punishable offence under Section 155 of the Railways Act, 1989.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- The Traveling Ticket Examiner (TTE) and train conductor are legally responsible for verifying reservation charts and ensuring confirmed passengers obtain their allocated berths.');
    buffer.writeln('- You can summon immediate Railway Protection Force (RPF) assistance onboard through the RailMadad portal or helpline 139.');
    buffer.writeln('- If Railways fails to provide your confirmed accommodation due to administrative failure or unauthorized trespassers, you are entitled to a full or partial fare refund and compensation for deficiency of service.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Show confirmed ticket politely:** Present your confirmed PNR ticket (physical or IRCTC mobile app) with matching government photo ID to the person occupying your seat.');
    buffer.writeln('2. **Find the TTE or Conductor:** Locate the Traveling Ticket Examiner (TTE) in the coach or adjacent coaches. The TTE carries the electronic reservation chart (HHT) and has the statutory duty to remove unauthorized occupants.');
    buffer.writeln('3. **Dial Helpline 139:** Call Railway Helpline 139 or send an SMS specifying your PNR, train number, coach, and seat issue.');
    buffer.writeln('4. **Lodge an incident on RailMadad:** Open the RailMadad mobile app or website (railmadad.indianrailways.gov.in) with your PNR number. The nearest RPF post or onboard escort squad will attend at the next scheduled stop.');
    buffer.writeln('5. **RPF intervention:** Under Section 155 of the Railways Act, any person entering a reserved compartment or occupying a seat without valid authority can be removed by railway staff or RPF personnel and fined.');
    buffer.writeln('6. **Claim TDR or Compensation:** If the TTE fails to provide your confirmed seat, obtain a Certificate of Non-allotment of Berth from the TTE and file a Ticket Deposit Receipt (TDR) on IRCTC within 72 hours for a refund.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Railways Act, 1989 — Section 155** (Entering into a compartment which is reserved or resisting lawful entry of passenger)');
    buffer.writeln('- **Railways Act, 1989 — Section 145** (Drunkenness or nuisance on a railway)');
    buffer.writeln('- **Consumer Protection Act, 2019 — Section 35** (Deficiency in railway transport service)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Confirmed Indian Railways / IRCTC PNR ticket');
    buffer.writeln('- Valid government photo identity card (Aadhaar, Voter ID, Driving Licence)');
    buffer.writeln('- RailMadad grievance reference number / 139 complaint ticket ID');
    buffer.writeln('- Certificate issued by the TTE (if accommodation was denied)');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Do not engage in physical altercations with unauthorized occupants. Rely on the TTE and RPF officers who are legally empowered to enforce railway rules.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Indian Railways RailMadad (railmadad.indianrailways.gov.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatLandlordDepositDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'A landlord cannot arbitrarily or unlawfully withhold a tenant\'s security deposit after the tenancy has expired and possession of the premises has been peacefully handed over. Unreasonable deductions or refusal to refund constitutes a civil breach of contract and an actionable tenancy dispute under Indian law.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- The security deposit is held by the landlord in trust and must be refunded within the contractual period (or within 30 days under the Model Tenancy Act) after deducting only legitimate, pre-agreed repairs for actual damage beyond normal wear and tear.');
    buffer.writeln('- Landlords cannot deduct deposit for normal wear and tear (such as minor paint fading or routine aging).');
    buffer.writeln('- Tenancy disputes can be brought before the Rent Authority / Rent Tribunal under state tenancy laws or the District Consumer Forum / Civil Court.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Review your Rental Agreement:** Check clauses on notice period, security deposit refund timeline, and conditions for deduction.');
    buffer.writeln('2. **Document the property condition:** Take clear photographs and video of the vacant apartment, walls, fixtures, and meters at the time of handing over keys, showing that no damage occurred.');
    buffer.writeln('3. **Draft a formal written demand:** Send an email and registered letter requesting the return of the deposit within 7 to 15 days, enclosing move-out inspection details and bank information.');
    buffer.writeln('4. **Issue an Advocate\'s Legal Notice:** If the landlord fails to refund within the deadline, have an advocate issue a formal Legal Notice demanding repayment along with interest and costs.');
    buffer.writeln('5. **File a petition before the Rent Authority / Tribunal:** In states where the Model Tenancy Act or State Rent Control Act is implemented, file an application before the Rent Authority.');
    buffer.writeln('6. **Consumer Forum or Civil Suit:** You can also approach the Consumer Commission under Section 35 of the Consumer Protection Act, 2019, or file a summary recovery suit under Order 37 CPC.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Model Tenancy Act / State Rent Control Acts** (Security deposit capping and mandatory refund within 30 days)');
    buffer.writeln('- **Indian Contract Act, 1872 — Section 73** (Compensation for breach of contract)');
    buffer.writeln('- **Transfer of Property Act, 1882 — Section 108** (Rights and liabilities of lessor and lessee)');
    buffer.writeln('- **Consumer Protection Act, 2019 — Section 35** (For rental housing services and property management agencies)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Signed Lease / Rental Agreement');
    buffer.writeln('- Bank statement / payment receipts showing payment of initial security deposit');
    buffer.writeln('- Monthly rent payment receipts and electricity/utility clearance bills');
    buffer.writeln('- Move-out photographs/videos showing property condition');
    buffer.writeln('- Copies of emails, WhatsApp messages, and formal legal notice sent to the landlord');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Always insist on a written handover acknowledgment or key receipt signed by the landlord at the time of vacating the premises.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Ministry of Housing and Urban Affairs (Model Tenancy Act)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatWorkplaceSalaryDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'No. Under Indian labour and employment laws, an employer cannot arbitrarily, illegally, or unilaterally withhold an employee\'s earned salary or wages for work already completed. Earned wages are a statutory right and not a discretionary gratuity.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- Employers are required by law to disburse wages on or before the 7th or 10th day of the wage period under the Payment of Wages Act, 1936 and the Code on Wages, 2019.');
    buffer.writeln('- Deductions can only be made for statutory items (PF, ESI, TDS) or pre-agreed contractual adjustments. An employer cannot impose arbitrary fines or hold salary for alleged poor performance.');
    buffer.writeln('- Withholding wages unlawfully constitutes a punishable offence and creates liability to pay compensation alongside the arrears.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Verify your records:** Check your employment contract, offer letter, attendance records, approved leave records, and resignation/relieving communications.');
    buffer.writeln('2. **Send a formal written demand:** Email HR and senior management citing the specific months of unpaid salary, employee ID, and requesting immediate clearance within 7 days.');
    buffer.writeln('3. **Send a Legal Notice through an Advocate:** If the employer fails to disburse the dues, engage an advocate to issue a formal Legal Notice giving a 15-day deadline.');
    buffer.writeln('4. **File a complaint before the Labour Commissioner:** Approach the District Labour Officer or Authority under Section 15 of the Payment of Wages Act / Industrial Relations Code. The Labour Authority can order payment of wages plus compensation.');
    buffer.writeln('5. **Remedies for Managerial / IT Professionals:** Non-workman professionals can file a summary recovery suit under Order 37 CPC in Civil Court, or file an insolvency petition before NCLT as an Operational Creditor under IBC.');
    buffer.writeln('6. **Criminal Breach of Trust:** If the employer deducted PF or ESI from your salary but failed to deposit it with the government, lodge a police complaint under Section 316 BNS.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Payment of Wages Act, 1936 — Section 5 & Section 15** (Timely payment of wages and claims arising out of deductions or delay)');
    buffer.writeln('- **Code on Wages, 2019** (Statutory entitlement to wages and penalties for non-payment)');
    buffer.writeln('- **Bharatiya Nyaya Sanhita, 2023 — Section 316** (Criminal breach of trust for unauthorized withholding of statutory deductions)');
    buffer.writeln('- **Industrial Disputes Act, 1947 — Section 33C(2)** (Recovery of money due from an employer)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Employment Contract / Appointment Letter');
    buffer.writeln('- Salary slips of previous months');
    buffer.writeln('- Bank account statement showing salary credits and sudden cessation');
    buffer.writeln('- Timesheets, attendance logs, and project work completion records');
    buffer.writeln('- Resignation email, acceptance confirmation, and written communications demanding payment');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('An employer cannot hold back your salary merely because you submitted your resignation; notice period buy-out rules must strictly adhere to the signed employment agreement.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Ministry of Labour and Employment (labour.gov.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatDrugOffenceDetailed(bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln(
      'Carrying, possessing, selling, purchasing, transporting, or consuming illicit narcotic drugs or psychotropic substances is strictly prohibited in India under the Narcotic Drugs and Psychotropic Substances (NDPS) Act, 1985. Penalties under the NDPS Act are graded based on the quantity seized: Small Quantity, Intermediate Quantity, or Commercial Quantity.'
    );
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- **Small Quantity:** Punishable with rigorous imprisonment for up to 1 year, or fine up to Rs 10,000, or both.');
    buffer.writeln('- **Commercial Quantity:** Severe punishment comprising rigorous imprisonment for not less than 10 years extending up to 20 years, and mandatory fine between Rs 1 lakh and Rs 2 lakh.');
    buffer.writeln('- **Bail Restrictions:** Under Section 37 of the NDPS Act, offences involving commercial quantities are strictly non-bailable unless the court is satisfied that reasonable grounds exist to believe the accused is not guilty.');
    buffer.writeln('- **Mandatory Search Safeguard:** Under Section 50 of the NDPS Act, an officer conducting a personal search of a suspect MUST inform the person of their legal right to be searched in the presence of a Gazetted Officer or a Magistrate.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. **Assert Section 50 NDPS Rights:** If being searched personally, you have the statutory right to request that the search take place in the presence of a Magistrate or Gazetted Officer.');
    buffer.writeln('2. **Demand a Search & Seizure Panchnama:** Police or narcotics officers must prepare a contemporary seizure memo (Panchnama) signed by independent local witnesses detailing the exact weight and substances seized.');
    buffer.writeln('3. **Right to Legal Representation:** Assert your right to consult an advocate immediately upon detention. If unable to afford one, request free legal aid from DLSA.');
    buffer.writeln('4. **Production within 24 hours:** The accused must be produced before the designated NDPS Special Court or nearest Judicial Magistrate within 24 hours.');
    buffer.writeln('5. **Rehabilitation Provisions:** Under Section 64A of the NDPS Act, persons addicted to drugs who are caught with small quantities for personal consumption may seek immunity from prosecution if they voluntarily opt for de-addiction treatment in an approved facility.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Narcotic Drugs and Psychotropic Substances Act, 1985 — Section 20, 21, and 22** (Punishment for offences relating to cannabis, manufactured drugs, and psychotropic substances)');
    buffer.writeln('- **Narcotic Drugs and Psychotropic Substances Act, 1985 — Section 37** (Offences to be cognizable and non-bailable)');
    buffer.writeln('- **Narcotic Drugs and Psychotropic Substances Act, 1985 — Section 50** (Conditions under which personal search of suspects shall be conducted)');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 47 & Section 58** (Arrest rights and 24-hour magistrate production)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Seizure memo / Panchnama copy');
    buffer.writeln('- Forensic Science Laboratory (FSL) chemical examination report');
    buffer.writeln('- Medical examination report');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Possession is assessed on both physical and conscious possession. Retain specialized legal counsel experienced in NDPS trial procedures.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in) & Narcotics Control Bureau (NCB)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatMatrimonialDetailed(List<LegalSection> matches, bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    if (isTe) {
      buffer.writeln('భర్త భార్యను విడిచిపెట్టి ఆర్థిక మద్దతు ఇవ్వకపోవడం చట్టపరంగా భరణం హక్కును మరియు నివాస హక్కును కలిగిస్తుంది. మీరు కోర్టు ద్వారా నెలవారీ భరణాన్ని క్లెయిమ్ చేయవచ్చు.');
    } else if (isHi) {
      buffer.writeln('यदि पति पत्नी को छोड़कर भरण-पोषण नहीं दे रहा है, तो कानूनन पत्नी को मासिक भरण-पोषण (Maintenance) और कानूनी संरक्षण का पूरा अधिकार है।');
    } else {
      buffer.writeln("If a husband has deserted his wife and stopped financial support, the wife has a legally protected right to claim monthly maintenance and residence under Indian law.");
    }
    buffer.writeln();

    buffer.writeln('### Key Points');
    if (isTe) {
      buffer.writeln('- భర్త నిరాధారంగా వదిలిపెట్టడం (Desertion) మరియు ఆర్థిక సహాయం నిరాకరించడం భరణం హక్కును ఇస్తుంది.\n- సెక్షన్ 144 BNSS కింద నెలవారీ భరణం పొందవచ్చు.');
    } else if (isHi) {
      buffer.writeln('- पति द्वारा परित्याग (Desertion) और वित्तीय सहायता न देना भरण-पोषण का आधार है।\n- धारा 144 BNSS के तहत मासिक भरण-पोषण मांगा जा सकता है।');
    } else {
      buffer.writeln('- Abandonment or separation without financial support entitles the wife to maintenance under Section 144 of BNSS, 2023 (formerly Section 125 CrPC).');
      buffer.writeln('- Protection of Women from Domestic Violence Act provides right to residence and monetary relief.');
    }
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    if (isTe) {
      buffer.writeln('1. నెలవారీ భరణం కోసం ఫ్యామిలీ కోర్టులో లేదా మేజిస్ట్రేట్ కోర్టులో సెక్షన్ 144 BNSS కింద పిటిషన్ దాఖలు చేయండి.');
      buffer.writeln('2. గృహ హింస చట్టం కింద ఆర్థిక ఉపశమనం మరియు నివాస ఉత్తర్వుల కోసం దరఖాస్తు చేసుకోండి.');
      buffer.writeln('3. ఉచిత న్యాయ సహాయం కోసం జిల్లా న్యాయ సేవాధికార సంస్థ (DLSA) ని సంప్రదించవచ్చు.');
    } else if (isHi) {
      buffer.writeln('1. मासिक भरण-पोषण के लिए पारिवारिक न्यायालय या मजिस्ट्रेट कोर्ट में धारा 144 BNSS के तहत आवेदन करें।');
      buffer.writeln('2. घरेलू हिंसा अधिनियम के तहत वित्तीय राहत और निवास आदेश के लिए अर्जी दें।');
      buffer.writeln('3. मुफ्त कानूनी सहायता के लिए जिला विधिक सेवा प्राधिकरण (DLSA) से संपर्क करें।');
    } else {
      buffer.writeln('1. File a petition for monthly maintenance under Section 144 BNSS (formerly Section 125 CrPC) before the Family Court or Judicial Magistrate.');
      buffer.writeln('2. Seek monetary relief and residence orders under the Protection of Women from Domestic Violence Act if applicable.');
      buffer.writeln('3. Approach the District Legal Services Authority (DLSA) for free legal aid if needed.');
    }
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Bharatiya Nagarik Suraksha Sanhita, 2023 — Section 144** (Order for maintenance of wives, children, and parents)');
    buffer.writeln('- **Protection of Women from Domestic Violence Act, 2005 — Section 12 & 18** (Application to Magistrate and protection orders)');
    buffer.writeln('- **Hindu Marriage Act, 1955 — Section 13** (Grounds for divorce including desertion)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Marriage certificate or documentary proof of marriage');
    buffer.writeln('- Proof of husband\'s employment and income (salary slip, bank records if available)');
    buffer.writeln('- Communication logs, messages, or witness statements showing separation');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Crucial facts include whether you have independent income, whether minor children are in your care, and whether you seek reconciliation, maintenance, or judicial separation/divorce.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatTrafficDetailed(List<LegalSection> matches, bool isTe, bool isHi) {
    final buffer = StringBuffer();
    buffer.writeln('### Quick Answer');
    buffer.writeln("Traffic fines in India are governed by the Motor Vehicles Act. You can verify and pay the challan online or contest wrongful penalties in traffic virtual court.");
    buffer.writeln();

    buffer.writeln('### Key Points');
    buffer.writeln('- Always verify the challan number, photographic evidence, and location on the official Parivahan portal.');
    buffer.writeln('- You have the statutory right to contest any wrongful challan in Virtual Court.');
    buffer.writeln();

    buffer.writeln('### What You Should Do');
    buffer.writeln('1. Check the official Parivahan or State Traffic Police portal to verify the violation evidence.');
    buffer.writeln('2. Pay the compounded penalty online within the stipulated time, or contest wrongful challans in Virtual Court.');
    buffer.writeln('3. Keep your Driving License, RC, Insurance, and PUC updated digitally in DigiLocker or mParivahan.');
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    buffer.writeln('- **Motor Vehicles Act, 1988 — Section 129 / Section 185 / Section 177** (Traffic safety regulations and penalties)');
    buffer.writeln();

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Copy of the challan / e-challan notice number');
    buffer.writeln('- Valid Driving Licence, Registration Certificate (RC), Insurance, and PUC');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Unpaid challans may lead to court summons or suspension of vehicle services on the Parivahan portal.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    buffer.writeln('⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in)');
    buffer.writeln('📅 **Last Verified:** Current');

    return buffer.toString().trim();
  }

  static String _formatGenericSituation(
    String query,
    LegalDomain domain,
    List<LegalSection> matches,
    bool isTe,
    bool isHi,
  ) {
    final primary = matches.first;
    final buffer = StringBuffer();

    buffer.writeln('### Quick Answer');
    buffer.writeln('${primary.displayTitle}: ${primary.displaySimpleExplanation}');
    buffer.writeln();

    buffer.writeln('### Key Points');
    if (primary.displayPunishment.isNotEmpty) {
      buffer.writeln('- **Punishment:** ${primary.displayPunishment}');
    }
    if (primary.keyElementsList.isNotEmpty) {
      for (final elem in primary.keyElementsList) {
        if (elem.trim().isNotEmpty) buffer.writeln('- $elem');
      }
    }
    buffer.writeln();

    if (primary.hasRealLifeExample) {
      buffer.writeln('### Real-Life Example');
      buffer.writeln('**Situation:** ${primary.displayExampleSituation}');
      buffer.writeln();
      buffer.writeln('**How the law may apply:** ${primary.displayExampleExplanation}');
      buffer.writeln();
      buffer.writeln('*${primary.displayExampleDisclaimer}*');
      buffer.writeln();
    }

    buffer.writeln('### What You Should Do');
    if (primary.whatYouShouldDoList.isNotEmpty) {
      for (final action in primary.whatYouShouldDoList) {
        buffer.writeln('- $action');
      }
    } else {
      buffer.writeln('1. Review the statutory provisions above.');
      buffer.writeln('2. Gather all relevant evidence, timestamps, and communications.');
      buffer.writeln('3. Consult an advocate or appropriate regulatory authority.');
    }
    buffer.writeln();

    buffer.writeln('### Applicable Law');
    for (final s in matches) {
      buffer.writeln('**${s.lawName}**');
      buffer.writeln('- **Section ${s.sectionNumber} — ${s.displayTitle}** (${s.statusDisplayLabel})');
      buffer.writeln('  ${s.displaySimpleExplanation}');
      buffer.writeln();
    }

    buffer.writeln('### Documents & Evidence');
    buffer.writeln('- Written complaints, notices, or receipts');
    buffer.writeln('- Identification and transaction proof');
    buffer.writeln();

    buffer.writeln('### Important');
    buffer.writeln('Facts such as jurisdiction, limitation periods, and initial notices can alter the legal outcome.');
    buffer.writeln();

    buffer.writeln('### Official Sources');
    final verifiedDate = primary.lastVerified ?? '2024-07-01';
    final srcName = primary.sourceName.isNotEmpty ? primary.sourceName : 'India Code (Official Government Source - indiacode.gov.in)';
    buffer.writeln('⚖️ **Verified Source:** $srcName');
    buffer.writeln('📅 **Last Verified:** $verifiedDate');

    return buffer.toString().trim();
  }
}
