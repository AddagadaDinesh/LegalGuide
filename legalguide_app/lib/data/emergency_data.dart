import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class EmergencyStep {
  final String title;
  final String titleTe;
  final String description;
  final String descriptionTe;
  final String legalGround;

  const EmergencyStep({
    required this.title,
    required this.titleTe,
    required this.description,
    required this.descriptionTe,
    required this.legalGround,
  });

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi) return tr(title);
    return title;
  }

  String get displayDescription {
    if (LocaleService.isTelugu && descriptionTe.isNotEmpty) return descriptionTe;
    if (LocaleService.isHindi) return tr(description);
    return description;
  }
}

class EmergencyScenario {
  final String id;
  final String title;
  final String titleTe;
  final String subtitle;
  final String subtitleTe;
  final IconData icon;
  final Color themeColor;
  final String emergencyNumber;
  final String emergencyNumberLabel;
  final List<EmergencyStep> steps;
  final List<String> doKeywords;
  final List<String> doKeywordsTe;
  final List<String> dontKeywords;
  final List<String> dontKeywordsTe;
  final String? directSearchQuery;

  const EmergencyScenario({
    required this.id,
    required this.title,
    required this.titleTe,
    required this.subtitle,
    required this.subtitleTe,
    required this.icon,
    required this.themeColor,
    required this.emergencyNumber,
    required this.emergencyNumberLabel,
    required this.steps,
    required this.doKeywords,
    required this.doKeywordsTe,
    required this.dontKeywords,
    required this.dontKeywordsTe,
    this.directSearchQuery,
  });

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi) return tr(title);
    return title;
  }

  String get displaySubtitle {
    if (LocaleService.isTelugu && subtitleTe.isNotEmpty) return subtitleTe;
    if (LocaleService.isHindi) return tr(subtitle);
    return subtitle;
  }
}

const emergencyScenarios = <EmergencyScenario>[
  EmergencyScenario(
    id: 'police_stop',
    title: 'Police Stop & Detention',
    titleTe: 'పోలీస్ ఆపడం & నిర్బంధం',
    subtitle: 'Immediate legal protections against wrongful arrest, harassment, or unlawful detention.',
    subtitleTe: 'అక్రమ అరెస్టు, వేధింపులు లేదా చట్టవిరుద్ధమైన నిర్బంధం నుండి తక్షణ చట్టపరమైన రక్షణలు.',
    icon: Icons.shield_outlined,
    themeColor: Color(0xFFE53935),
    emergencyNumber: '112',
    emergencyNumberLabel: 'Police Control Room: 112',
    directSearchQuery: 'Arrest',
    steps: [
      EmergencyStep(
        title: 'Right to Know Grounds of Arrest',
        titleTe: 'అరెస్టు కారణాలు తెలుసుకునే హక్కు',
        description: 'You have an absolute right to ask why you are being stopped or arrested, and to inspect the officer\'s official name tag and badge.',
        descriptionTe: 'మిమ్మల్ని ఎందుకు ఆపారో లేదా అరెస్టు చేస్తున్నారో అడిగే పూర్తి హక్కు మీకు ఉంది. అధికారి నేమ్ ట్యాగ్‌ను చూడవచ్చు.',
        legalGround: 'Article 22(1) Constitution & DK Basu Guidelines',
      ),
      EmergencyStep(
        title: 'Right to Inform Family or Lawyer',
        titleTe: 'కుటుంబానికి లేదా న్యాయవాదికి సమాచారం ఇచ్చే హక్కు',
        description: 'Police must allow you to make one phone call to notify a family member, friend, or your advocate of your detention location within 8-12 hours.',
        descriptionTe: 'పోలీసులు మీ కుటుంబసభ్యులకు లేదా న్యాయవాదికి మీరు ఎక్కడ ఉన్నారో తెలపడానికి ఫోన్ కాల్ చేసుకోవడానికి అనుమతించాలి.',
        legalGround: 'DK Basu Guidelines / BNSS / CrPC Sec 50A',
      ),
      EmergencyStep(
        title: 'Women Arrest Protections',
        titleTe: 'మహిళల అరెస్టు రక్షణలు',
        description: 'A woman cannot be arrested between sunset and sunrise (except in exceptional circumstances with prior Magistrate permission) and must be arrested only by a female officer.',
        descriptionTe: 'మహిళలను సూర్యాస్తమయం మరియు సూర్యోదయం మధ్య మేజిస్ట్రేట్ ముందస్తు అనుమతి లేకుండా అరెస్టు చేయకూడదు. మహిళా అధికారి మాత్రమే అరెస్టు చేయాలి.',
        legalGround: 'Section 46(4) CrPC / Section 43 BNSS',
      ),
      EmergencyStep(
        title: '24-Hour Magistrate Production',
        titleTe: '24 గంటల్లో మేజిస్ట్రేట్ ముందు హాజరుపరచడం',
        description: 'Detaining anyone in police custody for more than 24 hours without producing them before a judicial magistrate is illegal detention.',
        descriptionTe: 'న్యాయ మేజిస్ట్రేట్ ముందు హాజరుపరచకుండా ఎవరినీ 24 గంటలకు మించి పోలీస్ కస్టడీలో ఉంచడం చట్టవిరుద్ధం.',
        legalGround: 'Article 22(2) Constitution of India',
      ),
    ],
    doKeywords: [
      'Politely request the officer\'s name and designation',
      'Ask for a formal Arrest Memo with time & date',
      'Demand a routine medical check-up upon arrest',
    ],
    doKeywordsTe: [
      'అధికారి పేరు మరియు హోదాను మర్యాదగా అడగండి',
      'సమయం & తేదీతో కూడిన అధికారిక అరెస్ట్ మెమోను అడగండి',
      'అరెస్టు సమయంలో సాధారణ వైద్య పరీక్షను కోరండి',
    ],
    dontKeywords: [
      'Do not physically resist or use offensive language',
      'Do not sign blank papers or unsigned confession notes',
      'Do not unlock your smartphone without a lawful warrant',
    ],
    dontKeywordsTe: [
      'శారీరకంగా ప్రతిఘటించవద్దు లేదా అసభ్యంగా మాట్లాడవద్దు',
      'ఖాళీ కాగితాలు లేదా సంతకం లేని ఒప్పుకోలు నోట్లపై సంతకం చేయవద్దు',
      'చట్టబద్ధమైన వారెంట్ లేకుండా మీ ఫోన్ లాక్ తీయవద్దు',
    ],
  ),
  EmergencyScenario(
    id: 'traffic_stop',
    title: 'Traffic Stop & Vehicle Inspection',
    titleTe: 'ట్రాఫిక్ తనిఖీ & వాహన తనిఖీ',
    subtitle: 'Know what traffic police can and cannot demand on the road.',
    subtitleTe: 'రోడ్డుపై ట్రాఫిక్ పోలీసులు ఏమి అడగవచ్చు మరియు ఏమి అడగకూడదో తెలుసుకోండి.',
    icon: Icons.traffic_outlined,
    themeColor: Color(0xFFF57C00),
    emergencyNumber: '112',
    emergencyNumberLabel: 'Emergency Police Helpline: 112',
    directSearchQuery: 'Motor Vehicles',
    steps: [
      EmergencyStep(
        title: 'Only ASI or Above Can Issue Challans',
        titleTe: 'ASI లేదా అంతకంటే ఎక్కువ హోదా గలవారే చలాన్ ఇవ్వగలరు',
        description: 'A traffic constable or head constable cannot issue spot fines or compoundable challans unless accompanied by an officer of Assistant Sub-Inspector (ASI) or higher rank.',
        descriptionTe: 'ట్రాఫిక్ కానిస్టేబుల్ లేదా హెడ్ కానిస్టేబుల్ స్పాట్ చలాన్ జారీ చేయలేరు. ASI లేదా అంతకంటే ఎక్కువ స్థాయి అధికారి సమక్షంలో మాత్రమే జారీ చేయవచ్చు.',
        legalGround: 'Motor Vehicles Act, 1988',
      ),
      EmergencyStep(
        title: 'Snatching Vehicle Keys is Illegal',
        titleTe: 'వాహనం కీలు లాక్కోవడం చట్టవిరుద్ధం',
        description: 'Police officers have no statutory right to snatch keys from the ignition or deflate your vehicle tires. You have the right to film such misconduct peacefully.',
        descriptionTe: 'వాహనం నుండి కీలను లాక్కోవడం లేదా టైర్ల గాలి తీయడం పోలీసులకు చట్టపరంగా హక్కు లేదు.',
        legalGround: 'Central Motor Vehicles Rules / Police Conduct Manuals',
      ),
      EmergencyStep(
        title: 'Digital Documents are Legally Valid',
        titleTe: 'డిజిటల్ పత్రాలు చట్టబద్ధమైనవి',
        description: 'Showing your Driving License, RC, and Insurance on DigiLocker or mParivahan is 100% legally recognized. Officers cannot demand physical original cards if shown digitally.',
        descriptionTe: 'డిజిలాకర్ లేదా mParivahan యాప్‌లో డ్రైవింగ్ లైసెన్స్, RC చూపించడం చట్టబద్ధం. ఒరిజినల్ కార్డులు ఇవ్వాలని బలవంతం చేయలేరు.',
        legalGround: 'MoRTH Notification RT-11036/64/2017',
      ),
    ],
    doKeywords: [
      'Keep DigiLocker / mParivahan ready on your phone',
      'Insist on an official e-challan or printed government receipt',
      'Note down the officer\'s buckle number if harassed',
    ],
    doKeywordsTe: [
      'మీ ఫోన్‌లో డిజిలాకర్ / mParivahan సిద్ధంగా ఉంచుకోండి',
      'అధికారిక ఈ-చలాన్ లేదా ప్రింటెడ్ ప్రభుత్వ రసీదును మాత్రమే అడగండి',
      'వేధింపులు ఎదురైతే అధికారి బ్యాడ్జ్ నంబర్‌ను రాసుకోండి',
    ],
    dontKeywords: [
      'Do not pay cash without receiving an instant verified receipt',
      'Do not leave your vehicle unattended in active traffic',
    ],
    dontKeywordsTe: [
      'ధృవీకరించిన రసీదు తీసుకోకుండా నగదు చెల్లించవద్దు',
      'రద్దీగా ఉండే ట్రాఫిక్‌లో వాహనాన్ని ఒంటరిగా వదిలి వెళ్లవద్దు',
    ],
  ),
  EmergencyScenario(
    id: 'cyber_fraud',
    title: 'UPI & Cyber Banking Fraud',
    titleTe: 'UPI & సైబర్ బ్యాంకింగ్ మోసం',
    subtitle: 'Golden-hour steps to freeze stolen funds and preserve digital evidence.',
    subtitleTe: 'దోచుకున్న డబ్బును ఫ్రీజ్ చేయడానికి మరియు డిజిటల్ ఆధారాలను భద్రపరచడానికి గోల్డెన్-అవర్ చర్యలు.',
    icon: Icons.phonelink_lock_outlined,
    themeColor: Color(0xFF0288D1),
    emergencyNumber: '1930',
    emergencyNumberLabel: 'National Cyber Crime Helpline: 1930',
    directSearchQuery: 'Fraud',
    steps: [
      EmergencyStep(
        title: 'Dial 1930 Within the Golden Hour',
        titleTe: 'మొదటి గంటలోనే 1930 కి కాల్ చేయండి',
        description: 'Calling 1930 immediately alerts the Citizen Financial Cyber Fraud Reporting System (CFCFRMS), allowing law enforcement to block the beneficiary bank accounts before cash is withdrawn.',
        descriptionTe: 'మోసం జరిగిన వెంటనే 1930 కి కాల్ చేస్తే సైబర్ క్రైమ్ విభాగం ఆ డబ్బు వేరే ఖాతాలకు వెళ్లకుండా లేదా విత్‌డ్రా కాకుండా వెంటనే ఫ్రీజ్ చేస్తుంది.',
        legalGround: 'MHA National Cyber Crime Reporting Portal (NCRP)',
      ),
      EmergencyStep(
        title: 'Block Card & Net Banking Instantly',
        titleTe: 'కార్డు & నెట్ బ్యాంకింగ్‌ను వెంటనే బ్లాక్ చేయండి',
        description: 'Notify your bank\'s fraud division immediately to freeze debit/credit cards, UPI IDs, and net banking logins to prevent repeat deductions.',
        descriptionTe: 'మరింత నష్టం జరగకుండా మీ బ్యాంక్ హెల్ప్‌లైన్‌కు కాల్ చేసి కార్డ్ మరియు నెట్ బ్యాంకింగ్ లాగిన్‌లను తక్షణమే బ్లాక్ చేయండి.',
        legalGround: 'RBI Circular on Customer Protection in Unauthorised Transactions',
      ),
      EmergencyStep(
        title: 'Preserve All Digital Evidence',
        titleTe: 'అన్ని డిజిటల్ ఆధారాలను భద్రపరచండి',
        description: 'Take screenshots of transaction SMS, UPI UTR numbers, caller ID numbers, chat messages, and fake URLs. Do not delete transaction messages.',
        descriptionTe: 'లావాదేవీ SMS, UPI UTR నంబర్లు, కాలర్ ID, చాట్‌ల స్క్రీన్‌షాట్‌లు తీసుకోండి. మెసేజ్‌లను తొలగించవద్దు.',
        legalGround: 'Section 65B Indian Evidence Act / BSA',
      ),
    ],
    doKeywords: [
      'Call 1930 immediately with transaction UTR number',
      'File formal report at cybercrime.gov.in',
      'Inform bank branch manager in writing within 3 days for zero liability',
    ],
    doKeywordsTe: [
      'లావాదేవీ UTR నంబర్‌తో వెంటనే 1930 కి కాల్ చేయండి',
      'cybercrime.gov.in లో అధికారిక ఫిర్యాదు నమోదు చేయండి',
      'జీరో లయబిలిటీ కోసం 3 రోజుల్లోగా బ్యాంక్ మేనేజర్‌కు లిఖితపూర్వకంగా తెలియజేయండి',
    ],
    dontKeywords: [
      'Never share OTP, PIN, or CVV with anyone pretending to be a bank officer',
      'Do not click remote access app links (AnyDesk, TeamViewer, RustDesk)',
    ],
    dontKeywordsTe: [
      'బ్యాంక్ అధికారి అని చెప్పుకునే ఎవరితోనూ OTP, PIN, లేదా CVV పంచుకోవద్దు',
      'రిమోట్ యాక్సెస్ యాప్ లింక్‌లను (AnyDesk, TeamViewer) ఎప్పుడూ ఇన్‌స్టాల్ చేయవద్దు',
    ],
  ),
  EmergencyScenario(
    id: 'railway_dispute',
    title: 'Train TTE & Berthing Disputes',
    titleTe: 'రైలు TTE & బెర్త్ సమస్యలు',
    subtitle: 'Rules for middle berth sleeping hours, night ticket checking, and passenger safety.',
    subtitleTe: 'మిడిల్ బెర్త్ నిద్ర సమయాలు, రాత్రి టికెట్ తనిఖీ మరియు ప్రయాణీకుల భద్రత నిబంధనలు.',
    icon: Icons.train_outlined,
    themeColor: Color(0xFF388E3C),
    emergencyNumber: '139',
    emergencyNumberLabel: 'RailMadad & Railway Police: 139',
    directSearchQuery: 'Railway',
    steps: [
      EmergencyStep(
        title: 'Middle Berth Hours: 10:00 PM to 06:00 AM',
        titleTe: 'మిడిల్ బెర్త్ సమయం: రాత్రి 10:00 నుండి ఉదయం 06:00 వరకు',
        description: 'Passengers assigned the middle berth can keep it folded up only between 10:00 PM and 6:00 AM. Lower berth passengers cannot refuse this during these hours.',
        descriptionTe: 'మిడిల్ బెర్త్ ప్రయాణీకులు రాత్రి 10:00 నుండి ఉదయం 6:00 వరకు మాత్రమే బెర్త్‌ను వేసుకోవచ్చు. మిగతా సమయంలో ఇతరులు కూర్చోవడానికి ఇవ్వాలి.',
        legalGround: 'Indian Railways Commercial Manual Rule 4.5',
      ),
      EmergencyStep(
        title: 'No Ticket Checking Between 10 PM and 6 AM',
        titleTe: 'రాత్రి 10 నుండి ఉదయం 6 వరకు టికెట్ తనిఖీ లేదు',
        description: 'TTEs are strictly instructed not to disturb sleeping passengers for ticket verification between 10:00 PM and 6:00 AM, unless you board the train after 10:00 PM.',
        descriptionTe: 'రాత్రి 10 గంటల తర్వాత బోర్డింగ్ చేసిన వారు మినహా, నిద్రపోతున్న ప్రయాణీకులను రాత్రి 10 నుండి ఉదయం 6 మధ్య టికెట్ తనిఖీ కోసం లేపకూడదు.',
        legalGround: 'Railway Board Circular on Night Ticket Checking',
      ),
      EmergencyStep(
        title: 'Instant RailMadad Grievance',
        titleTe: 'తక్షణ RailMadad ఫిర్యాదు',
        description: 'If a TTE harasses you or if unauthorized people occupy reserved berths, dialing 139 or tweeting @RailMinIndia mobilizes RPF officers at the next stopping station.',
        descriptionTe: 'TTE వేధించినా లేదా రిజర్వ్డ్ సీట్లలో ఇతరులు ప్రవేశించినా 139 కి కాల్ చేస్తే తర్వాతి స్టేషన్‌లో RPF రక్షణ బృందం వస్తుంది.',
        legalGround: 'RailMadad Passenger Redressal System',
      ),
    ],
    doKeywords: [
      'Call or SMS 139 with your PNR number for immediate assistance',
      'Demand to see the TTE\'s electronic charting device (HHT)',
      'Politely invoke Rule 4.5 regarding middle berth hours',
    ],
    doKeywordsTe: [
      'తక్షణ సహాయం కోసం మీ PNR నంబర్‌తో 139 కి కాల్ లేదా SMS చేయండి',
      'TTE యొక్క ఎలక్ట్రానిక్ ఛార్టింగ్ పరికరాన్ని (HHT) చూపించమని కోరండి',
      'మిడిల్ బెర్త్ సమయాల గురించి రూల్ 4.5 ను మర్యాదగా ప్రస్తావించండి',
    ],
    dontKeywords: [
      'Do not engage in physical altercations with unauthorized occupants',
      'Do not pull the alarm chain without a genuine emergency (Section 141)',
    ],
    dontKeywordsTe: [
      'అనధికారిక వ్యక్తులతో శారీరక గొడవలకు దిగవద్దు',
      'నిజమైన అత్యవసర పరిస్థితి లేకుండా అలారం చైన్ లాగవద్దు (సెక్షన్ 141)',
    ],
  ),
  EmergencyScenario(
    id: 'women_safety',
    title: 'Women Safety & Zero FIR',
    titleTe: 'మహిళల భద్రత & జీరో FIR',
    subtitle: 'Jurisdiction-free FIR filing, virtual complaints, and medical aid guarantees.',
    subtitleTe: 'ఏ పోలీస్ స్టేషన్‌లోనైనా జీరో FIR నమోదు, వర్చువల్ ఫిర్యాదులు మరియు వైద్య సహాయం.',
    icon: Icons.health_and_safety_outlined,
    themeColor: Color(0xFFC2185B),
    emergencyNumber: '1091',
    emergencyNumberLabel: 'Women Police Helpline: 1091 / 181',
    directSearchQuery: 'Women',
    steps: [
      EmergencyStep(
        title: 'Right to File "Zero FIR" Anywhere',
        titleTe: 'ఎక్కడైనా "జీరో FIR" నమోదు చేసే హక్కు',
        description: 'Any police station in India is legally obligated to register an FIR for a crime against a woman, regardless of where the incident occurred, before transferring it to the jurisdictional station.',
        descriptionTe: 'సంఘటన ఎక్కడ జరిగినా సరే, భారతదేశంలోని ఏ పోలీస్ స్టేషన్ అయినా మహిళలపై జరిగే నేరాలపై జీరో FIR నమోదు చేయాల్సిందే. అధికార పరిధి లేదని తిరస్కరించలేరు.',
        legalGround: 'Section 173 BNSS / Ministry of Home Affairs Advisory',
      ),
      EmergencyStep(
        title: 'E-FIR and Registered Post Complaints',
        titleTe: 'ఈ-FIR మరియు పోస్ట్ ద్వారా ఫిర్యాదులు',
        description: 'If unable to visit a station physically, women can submit complaints via email, official state police cyber portals, or registered speed post to the Commissioner of Police.',
        descriptionTe: 'స్టేషన్‌కు స్వయంగా వెళ్లలేకపోతే, ఈమెయిల్ ద్వారా లేదా స్పీడ్ పోస్ట్ ద్వారా పోలీస్ కమిషనర్‌కు ఫిర్యాదును పంపవచ్చు.',
        legalGround: 'Delhi High Court Guidelines & State Police Standing Orders',
      ),
      EmergencyStep(
        title: 'Statement Recording in Presence of Female Officer',
        titleTe: 'మహిళా అధికారి సమక్షంలో వాంగ్మూలం నమోదు',
        description: 'A woman victim has the right to have her statement recorded at her own residence or choice of place in the presence of a woman police officer and her parents/guardian.',
        descriptionTe: 'మహిళా బాధితురాలి వాంగ్మూలాన్ని ఆమె స్వగృహంలో లేదా ఆమె ఎంచుకున్న ప్రదేశంలో మహిళా పోలీస్ అధికారి సమక్షంలో మాత్రమే నమోదు చేయాలి.',
        legalGround: 'Section 157 BNSS / Section 160 CrPC',
      ),
    ],
    doKeywords: [
      'Dial 112, 1091, or 181 for immediate police dispatch',
      'Demand a written copy of the Zero FIR completely free of charge',
      'Ask for examination at an authorized government or private hospital',
    ],
    doKeywordsTe: [
      'తక్షణ పోలీసు సహాయం కోసం 112, 1091, లేదా 181 కి కాల్ చేయండి',
      'జీరో FIR యొక్క ఉచిత కాపీని లిఖితపూర్వకంగా అడగండి',
      'ప్రభుత్వ లేదా ప్రైవేట్ ఆసుపత్రిలో ఉచిత వైద్య పరీక్షను కోరండి',
    ],
    dontKeywords: [
      'Do not wash or change clothes after physical assault before medical exam',
      'Do not accept informal settlements without formal police recording',
    ],
    dontKeywordsTe: [
      'వైద్య పరీక్షకు ముందు దుస్తులను ఉతకడం లేదా మార్చడం చేయవద్దు',
      'పోలీస్ రికార్డు లేకుండా అనధికారిక రాజీలను అంగీకరించవద్దు',
    ],
  ),
];
