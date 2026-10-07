import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legalguide_app/models/legal_section.dart';
import 'package:legalguide_app/screens/section_detail_screen.dart';
import 'package:legalguide_app/services/analytics_service.dart';
import 'package:legalguide_app/services/locale_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    AnalyticsService.cancelDebounceTimer();
  });

  group('LegalSection Model & Real-Life Example System Tests', () {
    test('LegalSection serializes and deserializes all example and progressive disclosure fields', () {
      final json = {
        'id': 26,
        'law': 10,
        'section_number': 'BNSS Section 144',
        'title': 'Order for Maintenance of Wives, Children and Parents',
        'legal_text': 'If any person having sufficient means neglects or refuses to maintain...',
        'simple_explanation': 'Provides a legal mechanism through which wives, children, and parents can claim maintenance.',
        'purpose': 'Prevents destitution and vagrancy by enforcing familial maintenance obligations.',
        'punishment': 'Monthly allowance determined by the Magistrate; failure to comply without sufficient cause can lead to warrant of enforcement.',
        'relevant_documents': 'Proof of relationship, income proof of respondent, medical expenses records.',
        'key_elements': 'Person having sufficient means.\nNeglect or refusal to maintain.\nInability of dependent to maintain themselves.',
        'status': 'current',
        'source_name': 'India Code — Ministry of Law & Justice, Govt. of India',
        'source_type': 'Official Bare Act Gazette (India Code)',
        'source': 'https://www.indiacode.gov.in/',
        'version': 1,
        'last_verified': '2024-07-01',
        'quick_answer': 'Section 144 empowers a Magistrate to order maintenance for dependent wives, children, and elderly parents.',
        'quick_answer_te': 'సెక్షన్ 144 ఆధారపడిన భార్య, పిల్లలు మరియు వృద్ధ తల్లిదండ్రులకు భరణం చెల్లించాలని ఆదేశించే అధికారాన్ని మేజిస్ట్రేట్‌కు కల్పిస్తుంది.',
        'quick_answer_hi': 'धारा 144 मजिस्ट्रेट को भरण-पोषण देने का आदेश देने की शक्ति देती है।',
        'example_title': 'Scenario: Maintenance Claim for Elderly Dependent Parents',
        'example_situation': 'Suppose an earning adult son with steady income neglects his elderly ailing mother who has no pension or property.',
        'example_situation_te': 'ఆదాయం ఉన్న కుమారుడు ఎటువంటి ఆస్తి లేని తన వృద్ధ తల్లిని పట్టించుకోకుండా వదిలేశాడని అనుకుందాం.',
        'example_situation_hi': 'मान लीजिए एक कमाने वाला बेटा अपनी बुजुर्ग माँ की अनदेखी करता है।',
        'example_explanation': 'Under BNSS Section 144, the mother can file a petition before the Magistrate, who can order monthly maintenance allowance.',
        'example_explanation_te': 'BNSS సెక్షన్ 144 కింద తల్లి మేజిస్ట్రేట్ కోర్టులో పిటిషన్ దాఖలు చేయవచ్చు.',
        'example_explanation_hi': 'बीएनएसएस धारा 144 के तहत अदालत मासिक गुजारा भत्ता देने का आदेश दे सकती है।',
        'example_disclaimer': 'Fictional educational example. This scenario is provided only to help explain the legal concept and does not represent an actual case.',
        'what_you_should_do': '1. Collate medical expense records.\n2. Collect evidence of respondent income.\n3. File application under Section 144.',
        'what_you_should_do_te': '1. వైద్య ఖర్చుల రసీదులను సిద్ధం చేసుకోండి.\n2. ఎదుటి వ్యక్తి ఆదాయ ఆధారాలను సేకరించండి.',
        'what_you_should_do_hi': '1. चिकित्सा खर्च के बिल तैयार रखें।\n2. प्रतिवादी की आय का प्रमाण जुटाएं।',
        'consequences_type': 'order',
        'example_steps': [
          {'order': 1, 'title': 'Neglect Occurs', 'description': 'Person with means neglects maintenance.', 'icon': 'person_off'},
          {'order': 2, 'title': 'Petition Filed', 'description': 'Application filed before Magistrate.', 'icon': 'description'},
          {'order': 3, 'title': 'Monthly Order', 'description': 'Court passes maintenance order.', 'icon': 'gavel'}
        ],
      };

      final section = LegalSection.fromJson(json);

      expect(section.id, 26);
      expect(section.sectionNumber, 'BNSS Section 144');
      expect(section.consequencesType, 'order');
      expect(section.hasRealLifeExample, isTrue);
      expect(section.hasSteps, isTrue);
      expect(section.hasVisualExample, isFalse);
      expect(section.hasVideoExample, isFalse);
      expect(section.exampleStepsList.length, 3);
      expect(section.exampleStepsList[0].title, 'Neglect Occurs');
      expect(section.whatYouShouldDoList.length, 3);
      expect(section.consequencesHeaderTitle, 'Court Orders & Enforcement');
      expect(section.documentsHeaderTitle, 'Documents That May Be Relevant');

      // Test serialization round-trip
      final exportedJson = section.toJson();
      expect(exportedJson['consequences_type'], 'order');
      expect(exportedJson['quick_answer'], contains('Section 144 empowers'));
      expect(exportedJson['example_situation'], contains('earning adult son'));
    });

    test('Localized accessors return language-specific text and fallback cleanly', () {
      final section = LegalSection(
        id: 1,
        lawId: 10,
        sectionNumber: 'Section 144',
        title: 'Maintenance',
        titleTe: 'భరణం',
        titleHi: 'भरण-पोषण',
        legalText: 'Official text...',
        simpleExplanation: 'Plain English',
        simpleExplanationTe: 'తెలుగు వివరణ',
        simpleExplanationHi: 'हिन्दी व्याख्या',
        purpose: 'Purpose',
        punishment: 'Monthly order',
        relevantDocuments: 'Docs',
        source: 'https://indiacode.nic.in',
        quickAnswer: 'English Quick Answer',
        quickAnswerTe: 'తెలుగు త్వరిత సమాధానం',
        quickAnswerHi: 'हिन्दी त्वरित उत्तर',
        exampleSituation: 'English Situation',
        exampleSituationTe: 'తెలుగు పరిస్థితి',
        exampleSituationHi: 'हिन्दी परिस्थिति',
        exampleExplanation: 'English Law Application',
        exampleExplanationTe: 'తెలుగు చట్టం వర్తింపు',
        exampleExplanationHi: 'हिन्दी कानून लागू',
        consequencesType: 'order',
      );

      // 1. English
      LocaleService.language.value = 'en';
      expect(section.displayTitle, 'Maintenance');
      expect(section.displayQuickAnswer, 'English Quick Answer');
      expect(section.displayExampleSituation, 'English Situation');
      expect(section.displayExampleExplanation, 'English Law Application');
      expect(section.consequencesHeaderTitle, 'Court Orders & Enforcement');

      // 2. Telugu
      LocaleService.language.value = 'te';
      expect(section.displayTitle, 'భరణం');
      expect(section.displayQuickAnswer, 'తెలుగు త్వరిత సమాధానం');
      expect(section.displayExampleSituation, 'తెలుగు పరిస్థితి');
      expect(section.displayExampleExplanation, 'తెలుగు చట్టం వర్తింపు');
      expect(section.consequencesHeaderTitle, 'కోర్టు ఉత్తర్వులు & అమలు');

      // 3. Hindi
      LocaleService.language.value = 'hi';
      expect(section.displayTitle, 'भरण-पोषण');
      expect(section.displayQuickAnswer, 'हिन्दी त्वरित उत्तर');
      expect(section.displayExampleSituation, 'हिन्दी परिस्थिति');
      expect(section.displayExampleExplanation, 'हिन्दी कानून लागू');
      expect(section.consequencesHeaderTitle, 'अदालती आदेश और निष्पादन');

      // Reset
      LocaleService.language.value = 'en';
    });
  });

  group('SectionDetailScreen Progressive Disclosure & Layout Tests', () {
    Widget buildScreen(LegalSection section, {Size size = const Size(360, 640)}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SectionDetailScreen(section: section),
        ),
      );
    }

    testWidgets('BNSS 144 renders progressive disclosure hierarchy with example, steps, and court order', (tester) async {
      LocaleService.language.value = 'en';

      final bnss144 = LegalSection(
        id: 26,
        lawId: 10,
        sectionNumber: 'BNSS Section 144',
        title: 'Order for Maintenance of Wives, Children and Parents',
        legalText: 'If any person having sufficient means neglects or refuses to maintain his wife, children or parents...',
        simpleExplanation: 'Provides a legal mechanism through which dependent wives, children, and elderly parents can claim monthly maintenance.',
        purpose: 'Prevents destitution and vagrancy by enforcing familial maintenance obligations.',
        punishment: 'Monthly allowance determined by Magistrate.',
        relevantDocuments: 'Proof of relationship, income proof, medical expenses records.',
        keyElements: 'Person having sufficient means.\nNeglect or refusal to maintain.',
        source: 'https://www.indiacode.gov.in/',
        sourceName: 'India Code — Ministry of Law & Justice, Govt. of India',
        version: 1,
        lastVerified: '2024-07-01',
        quickAnswer: 'Section 144 empowers a Magistrate to order monthly maintenance for dependent wives, children, and elderly parents.',
        exampleTitle: 'Scenario: Maintenance Claim for Elderly Dependent Parents',
        exampleSituation: 'Suppose an earning adult son with steady income neglects his elderly ailing mother who has no pension or property.',
        exampleExplanation: 'Under BNSS Section 144, the mother can file a petition before the Magistrate, who can order monthly maintenance allowance.',
        exampleDisclaimer: 'Fictional educational example. This scenario is provided only to help explain the legal concept and does not represent an actual case.',
        whatYouShouldDo: '1. Collate medical expense records.\n2. Collect evidence of respondent income.\n3. File application under Section 144.',
        consequencesType: 'order',
        exampleSteps: '[{"order":1,"title":"Neglect Occurs","description":"Person with means refuses support.","icon":"person_off"},{"order":2,"title":"Petition Filed","description":"Application filed before Magistrate.","icon":"description"},{"order":3,"title":"Maintenance Order","description":"Court awards binding monthly allowance.","icon":"gavel"}]',
      );

      await tester.pumpWidget(buildScreen(bnss144));
      await tester.pumpAndSettle();

      // Header checks
      expect(find.text('BNSS Section 144'), findsWidgets);
      expect(find.text('Order for Maintenance of Wives, Children and Parents'), findsOneWidget);
      expect(find.text('LegalGuide Content Version: v1'), findsOneWidget);
      expect(find.text('Current Law'), findsOneWidget);

      // Quick Answer
      expect(find.text('Quick Answer'), findsOneWidget);
      expect(find.textContaining('Section 144 empowers a Magistrate'), findsOneWidget);

      // In Simple Words
      expect(find.text('In Simple Words'), findsOneWidget);

      // Real-Life Example
      expect(find.text('💡 Understand With an Example'), findsOneWidget);
      expect(find.textContaining('earning adult son with steady income'), findsOneWidget);
      expect(find.textContaining('mother can file a petition before the Magistrate'), findsOneWidget);
      expect(find.textContaining('Fictional educational example'), findsOneWidget);

      // Steps flow
      expect(find.text('Step-by-Step Procedure Flow'), findsOneWidget);
      expect(find.text('Neglect Occurs'), findsOneWidget);
      expect(find.text('Maintenance Order'), findsOneWidget);

      // What You Should Do
      expect(find.text('📋 What You Should Do'), findsOneWidget);
      expect(find.textContaining('Collate medical expense records.'), findsOneWidget);

      // Collapsible sections titles
      expect(find.text('Key Elements'), findsOneWidget);
      expect(find.text('Documents That May Be Relevant'), findsOneWidget);
      expect(find.text('Court Orders & Enforcement'), findsOneWidget);
      expect(find.text('Official Statutory Legal Text'), findsOneWidget);

      // Official Source Card
      expect(find.text('Official Source'), findsOneWidget);
      expect(find.text('View Official Source'), findsOneWidget);

      // Media cards when empty are cleanly hidden
      expect(find.text('🎬 See It in Action'), findsNothing);
      expect(find.text('Visual Example'), findsNothing);

      // Test expanding a collapsible section
      expect(find.text('Person having sufficient means.'), findsNothing);
      await tester.ensureVisible(find.text('Key Elements'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Key Elements'));
      await tester.pumpAndSettle();
      expect(find.text('Person having sufficient means.'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Criminal provision BNS 103 displays Punishment & Penalties and penal consequence', (tester) async {
      final bns103 = LegalSection(
        id: 2,
        lawId: 2,
        sectionNumber: 'Section 103(1)',
        title: 'Punishment for Murder',
        legalText: 'Whoever commits murder shall be punished with death or imprisonment for life...',
        simpleExplanation: 'Unlawfully killing another with the intent to kill.',
        purpose: 'Protects the right to life.',
        punishment: 'Death or imprisonment for life, and fine.',
        relevantDocuments: 'FIR copy, post-mortem report.',
        source: 'https://indiacode.gov.in',
        quickAnswer: 'Section 103(1) of BNS 2023 defines the punishment for murder.',
        exampleSituation: 'Suppose Person A deliberately plans and attacks Person B resulting in death.',
        exampleExplanation: 'The act constitutes murder under Section 103(1).',
        consequencesType: 'penal',
      );

      await tester.pumpWidget(buildScreen(bns103));
      await tester.pumpAndSettle();

      expect(find.text('Punishment & Penalties'), findsOneWidget);
      expect(find.text('Court Orders & Enforcement'), findsNothing);
      expect(find.text('💡 Understand With an Example'), findsOneWidget);
      expect(find.textContaining('Person A deliberately plans and attacks'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Motor Vehicles Act 185 renders breath analyser checkpoint flow on small Android screen without overflow', (tester) async {
      final mv185 = LegalSection(
        id: 22,
        lawId: 6,
        sectionNumber: 'Section 185',
        title: 'Driving by a Drunken Person or by a Person Under the Influence of Drugs',
        legalText: 'Whoever, while driving, or attempting to drive, a motor vehicle has in his blood alcohol exceeding 30 mg per 100 ml...',
        simpleExplanation: 'Driving with blood alcohol content over 30 mg per 100 ml is illegal.',
        purpose: 'Prevents road accidents caused by impaired driving.',
        punishment: 'Imprisonment up to 6 months and/or fine up to ₹10,000 for first offence.',
        relevantDocuments: 'Breath analyser printout, driving licence, RC book.',
        source: 'https://indiacode.gov.in',
        quickAnswer: 'Section 185 penalizes driving with blood alcohol content over 30 mg per 100 ml.',
        exampleSituation: 'Suppose a driver consumes alcohol and is stopped at a traffic checkpoint with 55 mg/100 ml reading.',
        exampleExplanation: 'Because the reading exceeds 30 mg, Section 185 penalties apply.',
        whatYouShouldDo: '1. Never drink and drive.\n2. Cooperate with lawful breath analyser testing.',
        exampleSteps: '[{"order":1,"title":"Vehicle Stopped","description":"Traffic checkpoint stop.","icon":"traffic"},{"order":2,"title":"Breath Test","description":"Breathing into analyser.","icon":"speed"},{"order":3,"title":"Challan Issued","description":"Fine or summons recorded.","icon":"receipt"}]',
        consequencesType: 'penal',
      );

      // Test on small 320x480 screen to verify zero overflow
      await tester.pumpWidget(buildScreen(mv185, size: const Size(320, 480)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Section 185'), findsWidgets);
      expect(find.text('Driving by a Drunken Person or by a Person Under the Influence of Drugs'), findsOneWidget);
      expect(find.text('Step-by-Step Procedure Flow'), findsOneWidget);
      expect(find.text('Vehicle Stopped'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Consumer Protection Act 35 and IT Act 66D render with appropriate consequence labels', (tester) async {
      final cpa35 = LegalSection(
        id: 23,
        lawId: 7,
        sectionNumber: 'Section 35',
        title: 'Manner in Which Complaint Shall Be Made',
        legalText: 'A complaint, in relation to any goods sold or delivered or agreed to be sold or delivered...',
        simpleExplanation: 'Explains how consumers can file complaints before the District Consumer Commission.',
        purpose: 'Ensures accessible consumer grievance redressal.',
        punishment: 'Commission can order refund, replacement, and compensation.',
        relevantDocuments: 'Purchase invoice, warranty card, legal notice copy.',
        source: 'https://indiacode.gov.in',
        quickAnswer: 'Section 35 sets out the complaint filing process for defective goods and deficient services.',
        exampleSituation: 'Suppose a consumer purchases a brand-new television that fails in 2 days and the seller refuses refund.',
        exampleExplanation: 'Under CPA Section 35, the consumer can file a complaint before the District Commission.',
        consequencesType: 'civil',
      );

      await tester.pumpWidget(buildScreen(cpa35));
      await tester.pumpAndSettle();

      expect(find.text('Civil Consequences & Remedies'), findsOneWidget);
      expect(find.text('Court Orders & Enforcement'), findsNothing);
      expect(find.text('Punishment & Penalties'), findsNothing);
      expect(find.textContaining('consumer purchases a brand-new television'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Telugu localization updates Real-Life Example, Quick Answer, and Section Headers dynamically', (tester) async {
      LocaleService.language.value = 'te';

      final bnss144 = LegalSection(
        id: 26,
        lawId: 10,
        sectionNumber: 'BNSS Section 144',
        title: 'Order for Maintenance of Wives, Children and Parents',
        titleTe: 'భార్య, పిల్లలు మరియు తల్లిదండ్రుల భరణం కొరకు ఉత్తర్వులు',
        legalText: 'Statutory legal text...',
        simpleExplanation: 'Explanation',
        simpleExplanationTe: 'భరణం కోరడానికి చట్టబద్ధమైన మార్గాన్ని అందిస్తుంది.',
        purpose: 'Purpose',
        purposeTe: 'పేదరికం మరియు నిరాశ్రయతను నిరోధించడానికి.',
        punishment: 'Punishment',
        relevantDocuments: 'Docs',
        source: 'https://indiacode.gov.in',
        quickAnswerTe: 'సెక్షన్ 144 ఆధారపడిన భార్య, పిల్లలు మరియు వృద్ధ తల్లిదండ్రులకు భరణం చెల్లించాలని ఆదేశించే అధికారాన్ని మేజిస్ట్రేట్‌కు కల్పిస్తుంది.',
        exampleSituationTe: 'ఆదాయం ఉన్న ఒక కుమారుడు తన వృద్ధ తల్లిని పట్టించుకోకుండా వదిలేశాడని అనుకుందాం.',
        exampleExplanationTe: 'BNSS సెక్షన్ 144 కింద తల్లి మేజిస్ట్రేట్ కోర్టులో పిటిషన్ దాఖలు చేయవచ్చు.',
        whatYouShouldDoTe: '1. వైద్య ఖర్చుల రసీదులను సిద్ధం చేసుకోండి.\n2. ఎదుటి వ్యక్తి ఆదాయ ఆధారాలను సేకరించండి.',
        consequencesType: 'order',
      );

      await tester.pumpWidget(buildScreen(bnss144));
      await tester.pumpAndSettle();

      expect(find.text('భార్య, పిల్లలు మరియు తల్లిదండ్రుల భరణం కొరకు ఉత్తర్వులు'), findsOneWidget);
      expect(find.text('త్వరిత సమాధానం'), findsOneWidget);
      expect(find.textContaining('ఆధారపడిన భార్య, పిల్లలు మరియు వృద్ధ తల్లిదండ్రులకు'), findsOneWidget);
      expect(find.text('💡 ఉదాహరణతో అర్థం చేసుకోండి'), findsOneWidget);
      expect(find.textContaining('ఆదాయం ఉన్న ఒక కుమారుడు తన వృద్ధ తల్లిని'), findsOneWidget);
      expect(find.text('కోర్టు ఉత్తర్వులు & అమలు'), findsOneWidget);
      expect(find.text('అధికారిక మూలం'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
      LocaleService.language.value = 'en';
    });

    testWidgets('BNS 318 correctly differentiates Section 318(4) aggravated fraud and separates legal concepts from victim actions', (tester) async {
      final bns318 = LegalSection(
        id: 3,
        lawId: 2,
        sectionNumber: 'Section 318',
        title: 'Cheating',
        legalText: 'Section 318 defines cheating and prescribes penalties across its subsections. Under subsection 318(4), cheating dishonestly inducing delivery of property carries imprisonment up to 7 years and fine.',
        simpleExplanation: 'Section 318 deals with cheating across multiple sub-sections. Sub-section 318(4) specifically applies where cheating dishonestly induces delivery of property or valuable security.',
        purpose: 'Protects citizens and businesses against dishonest deception, fraudulent inducement, and wrongful property loss.',
        punishment: 'General cheating under 318(2): imprisonment up to 3 years or fine; Aggravated cheating with dishonest delivery of property under 318(4): imprisonment up to 7 years and fine.',
        relevantDocuments: 'Payment receipts, bank transaction statements, communication transcripts, appointment letters.',
        source: 'https://indiacode.gov.in',
        sourceName: 'India Code — Ministry of Law & Justice, Govt. of India',
        quickAnswer: 'Section 318 governs cheating with differentiated penalties. Subsection 318(4) specifically penalizes dishonest inducement to deliver property.',
        exampleTitle: 'Scenario: Fabricated Appointment Letter Job Fraud',
        exampleSituation: 'A person poses as a senior government recruitment officer, displays fabricated appointment letters, and convinces a job seeker to transfer ₹3,00,000.',
        exampleExplanation: 'Depending on the evidence, conduct involving intentional deception and dishonest inducement to deliver money may satisfy Section 318(4) because property (₹3,00,000) was delivered.',
        exampleDisclaimer: 'Fictional educational example. This scenario is provided only to help explain the legal concept and does not represent an actual case.',
        visualImageUrl: 'assets/illustrations/bns_318_cheating.png',
        visualCaption: 'Illustration of false job promise leading to financial transfer and cybercrime complaint reporting.',
        visualAltText: 'Diagram showing cheating progression and reporting process',
        videoUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        videoTitle: 'Understanding BNS 318: How Cheating & Delivery of Property is Treated Under New Criminal Law',
        videoDuration: '45 seconds',
        videoTranscript: 'This educational video explains the elements of cheating under Section 318.',
        whatYouShouldDo: '1. Preserve relevant evidence immediately (screenshots, transaction receipts, messages).\n2. Alert your bank or payment provider promptly if financial transfer occurred.\n3. Report the incident to the appropriate cybercrime portal or police authority.\n4. Seek legal assistance where necessary.',
        exampleSteps: '[{"order":1,"title":"Deceptive Representation","description":"Accused makes fraudulent claim.","icon":"warning"},{"order":2,"title":"Dishonest Inducement","description":"Victim deceived into acting.","icon":"swap_horiz"},{"order":3,"title":"Delivery of Property","description":"Money transferred to fraudster.","icon":"currency_rupee"},{"order":4,"title":"Applicable Subsection","description":"Section 318(4) considered based on facts.","icon":"gavel"}]',
        consequencesType: 'penal',
      );

      await tester.pumpWidget(buildScreen(bns318));
      await tester.pumpAndSettle();

      // Verify BNS 318 content
      expect(find.text('Section 318'), findsWidgets);
      expect(find.text('Cheating'), findsOneWidget);
      expect(find.text('💡 Understand With an Example'), findsOneWidget);

      // Verify 318(4) distinction is present
      expect(find.textContaining('Sub-section 318(4) specifically applies where cheating dishonestly induces delivery of property'), findsOneWidget);

      // Verify visual illustration inside example card
      expect(find.text('🖼️ Visual Example'), findsOneWidget);
      expect(find.text('Zoom'), findsOneWidget);
      expect(find.textContaining('Illustrative example for educational purposes'), findsOneWidget);

      // Verify layout order: Situation is above Visual Example, which is above How the law may apply
      final situationFinder = find.text('Situation:');
      final visualFinder = find.text('🖼️ Visual Example');
      final howLawAppliesFinder = find.text('How the law may apply:');
      final videoFinder = find.text('🎬 Watch the Example');

      expect(situationFinder, findsOneWidget);
      expect(visualFinder, findsOneWidget);
      expect(howLawAppliesFinder, findsOneWidget);
      expect(videoFinder, findsOneWidget);

      final situationTop = tester.getTopLeft(situationFinder).dy;
      final visualTop = tester.getTopLeft(visualFinder).dy;
      final howLawAppliesTop = tester.getTopLeft(howLawAppliesFinder).dy;
      final videoTop = tester.getTopLeft(videoFinder).dy;

      expect(situationTop, lessThan(visualTop));
      expect(visualTop, lessThan(howLawAppliesTop));
      expect(howLawAppliesTop, lessThan(videoTop));

      // Verify video inside example card
      expect(find.text('45 seconds'), findsOneWidget);
      expect(find.text('Watch Educational Video'), findsOneWidget);

      // Verify separated steps: A. Legal concept steps
      expect(find.text('Step-by-Step Procedure Flow'), findsOneWidget);
      expect(find.text('Deceptive Representation'), findsOneWidget);
      expect(find.text('Delivery of Property'), findsOneWidget);
      expect(find.text('Applicable Subsection'), findsOneWidget);

      // Verify separated steps: B. Victim action checklist
      expect(find.text('📋 What You Should Do'), findsOneWidget);
      expect(find.textContaining('Preserve relevant evidence immediately'), findsOneWidget);
      expect(find.textContaining('Alert your bank or payment provider promptly'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('Absence of media cleanly hides media components without showing "Photo unavailable"', (tester) async {
      final noMediaSection = LegalSection(
        id: 99,
        lawId: 2,
        sectionNumber: 'Section 999',
        title: 'Sample Provision Without Media',
        legalText: 'Sample text...',
        simpleExplanation: 'Sample explanation without photo or video.',
        purpose: 'Sample purpose.',
        punishment: 'Sample penalty.',
        relevantDocuments: 'Sample docs.',
        source: 'https://indiacode.gov.in',
        quickAnswer: 'Sample quick answer.',
        exampleSituation: 'Sample scenario situation text.',
        exampleExplanation: 'Sample law application explanation.',
        visualImageUrl: '', // Empty image
        videoUrl: '', // Empty video
      );

      await tester.pumpWidget(buildScreen(noMediaSection));
      await tester.pumpAndSettle();

      // Text example should be visible
      expect(find.text('💡 Understand With an Example'), findsOneWidget);
      expect(find.text('Sample scenario situation text.'), findsOneWidget);

      // Media elements should NOT be shown
      expect(find.text('🖼️ Visual Example'), findsNothing);
      expect(find.text('🎬 Watch the Example'), findsNothing);
      expect(find.textContaining('Photo unavailable'), findsNothing);
      expect(find.textContaining('Video unavailable'), findsNothing);

      AnalyticsService.cancelTimersForTesting();
    });

    testWidgets('BNSS Section 47 verifies arrest grounds, bail notification, and educational illustration', (tester) async {
      final bnss47 = LegalSection(
        id: 6,
        lawId: 4,
        sectionNumber: 'BNSS Section 47',
        title: 'Person Arrested to be Informed of Grounds of Arrest and of Right to Bail',
        legalText: 'Every police officer or other person arresting any person without warrant shall forthwith communicate to him full particulars of the offence for which he is arrested or other grounds for such arrest...',
        simpleExplanation: 'Police must forthwith inform an arrested person of the grounds of arrest, and for bailable offences, of the entitlement to bail.',
        purpose: 'Prevents arbitrary arrest by requiring the reason to be stated immediately, upholding Article 22.',
        punishment: 'Procedural safeguard; non-compliance may affect procedural validity.',
        relevantDocuments: 'Arrest memo, bail application, surety documents.',
        source: 'Bharatiya Nagarik Suraksha Sanhita, 2023, Section 47',
        quickAnswer: 'BNSS Section 47 mandates forthwith disclosure of grounds of arrest and notification of right to bail for bailable offences.',
        exampleSituation: 'Suppose a citizen is detained without warrant by police during a public gathering for an alleged bailable infraction, but the arresting officer does not inform the citizen of the specific grounds of arrest or whether the alleged offence is bailable.',
        exampleExplanation: 'Under Section 47 of BNSS 2023, the arresting officer is statutorily required to forthwith communicate full particulars of the offence or grounds of arrest. Where the alleged offence is bailable, the officer must also inform the person of their entitlement to bail so they may arrange sureties. In this scenario, failure to inform the arrestee of these statutory particulars raises a procedural non-compliance issue under Section 47.',
        visualImageUrl: 'assets/illustrations/bnss_47_arrest_grounds.jpg',
        visualCaption: 'Arresting officer communicating statutory grounds of arrest and notification of right to bail.',
        visualAltText: 'Fictional educational illustration of police officer communicating grounds of arrest.',
        isVisualIllustrative: true,
        whatYouShouldDo: '1. Politely ask: Under what section and grounds am I being arrested?\n2. Inquire whether the alleged offence is bailable.\n3. Request the preparation of an arrest memo (BNSS Section 46).\n4. Request to inform a relative or friend (BNSS Section 48).',
      );

      // Verify model getters
      expect(bnss47.exampleImageUrl, 'assets/illustrations/bnss_47_arrest_grounds.jpg');
      expect(bnss47.exampleImageCaption, contains('Arresting officer communicating'));
      expect(bnss47.exampleImageAltText, contains('Fictional educational illustration'));
      expect(bnss47.exampleImageEnabled, isTrue);

      await tester.pumpWidget(buildScreen(bnss47));
      await tester.pumpAndSettle();

      // Verify BNSS 47 title and example card
      expect(find.text('BNSS Section 47'), findsWidgets);
      expect(find.text('💡 Understand With an Example'), findsOneWidget);

      // Verify layout order: Situation is above Visual Example, which is above How the law may apply
      final situationTop = tester.getTopLeft(find.text('Situation:')).dy;
      final visualTop = tester.getTopLeft(find.text('🖼️ Visual Example')).dy;
      final howLawAppliesTop = tester.getTopLeft(find.text('How the law may apply:')).dy;

      expect(situationTop, lessThan(visualTop));
      expect(visualTop, lessThan(howLawAppliesTop));

      // Verify educational label is displayed
      expect(find.textContaining('Illustrative example for educational purposes — not an actual case.'), findsOneWidget);
      expect(find.textContaining('Arresting officer communicating'), findsOneWidget);

      AnalyticsService.cancelTimersForTesting();
    });

    test('Provision Key generates stable, case-insensitive, and unique identifiers across Acts', () {
      // 1. Same Act and Section with different cases or spacing produce same key
      final key1 = LegalSection.computeProvisionKey(2, 'Section 103(1)');
      final key2 = LegalSection.computeProvisionKey(2, 'section 103(1)');
      final key3 = LegalSection.computeProvisionKey(2, ' Section 103(1) ');
      expect(key1, '2_section_103_1');
      expect(key1, key2);
      expect(key1, key3);

      // 2. Different Acts with same section number produce distinct keys
      final bns103Key = LegalSection.computeProvisionKey(2, 'Section 103');
      final bnss103Key = LegalSection.computeProvisionKey(10, 'Section 103');
      final bsa103Key = LegalSection.computeProvisionKey(1, 'Section 103');

      expect(bns103Key, '2_section_103');
      expect(bnss103Key, '10_section_103');
      expect(bsa103Key, '1_section_103');
      expect(bns103Key, isNot(equals(bnss103Key)));
      expect(bns103Key, isNot(equals(bsa103Key)));
      expect(bnss103Key, isNot(equals(bsa103Key)));

      // 3. Subsections are differentiated
      final sec318Key = LegalSection.computeProvisionKey(2, 'Section 318');
      final sec318_4Key = LegalSection.computeProvisionKey(2, 'Section 318(4)');
      expect(sec318Key, isNot(equals(sec318_4Key)));
    });
  });
}

