import 'package:flutter/material.dart';
import '../services/locale_service.dart';

class TrafficFineItem {
  final String id;
  final String section;
  final String category; // 'Safety', 'Documents', 'Signals', 'High Severity'
  final String fineAmount;
  final String jailTerm;
  final bool isSevere;
  final IconData icon;

  final String title;
  final String titleHi;
  final String titleTe;
  final String titleTa;

  final String description;
  final String descriptionHi;
  final String descriptionTe;
  final String descriptionTa;

  const TrafficFineItem({
    required this.id,
    required this.section,
    required this.category,
    required this.fineAmount,
    required this.jailTerm,
    this.isSevere = false,
    required this.icon,
    required this.title,
    this.titleHi = '',
    this.titleTe = '',
    this.titleTa = '',
    required this.description,
    this.descriptionHi = '',
    this.descriptionTe = '',
    this.descriptionTa = '',
  });

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi && titleHi.isNotEmpty) return titleHi;
    if (LocaleService.isTamil && titleTa.isNotEmpty) return titleTa;
    return title;
  }

  String get displayDescription {
    if (LocaleService.isTelugu && descriptionTe.isNotEmpty) return descriptionTe;
    if (LocaleService.isHindi && descriptionHi.isNotEmpty) return descriptionHi;
    if (LocaleService.isTamil && descriptionTa.isNotEmpty) return descriptionTa;
    return description;
  }
}

class TrafficDriverRight {
  final String id;
  final String legalRef;
  final IconData icon;

  final String title;
  final String titleHi;
  final String titleTe;
  final String titleTa;

  final String detail;
  final String detailHi;
  final String detailTe;
  final String detailTa;

  const TrafficDriverRight({
    required this.id,
    required this.legalRef,
    required this.icon,
    required this.title,
    this.titleHi = '',
    this.titleTe = '',
    this.titleTa = '',
    required this.detail,
    this.detailHi = '',
    this.detailTe = '',
    this.detailTa = '',
  });

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi && titleHi.isNotEmpty) return titleHi;
    if (LocaleService.isTamil && titleTa.isNotEmpty) return titleTa;
    return title;
  }

  String get displayDetail {
    if (LocaleService.isTelugu && detailTe.isNotEmpty) return detailTe;
    if (LocaleService.isHindi && detailHi.isNotEmpty) return detailHi;
    if (LocaleService.isTamil && detailTa.isNotEmpty) return detailTa;
    return detail;
  }
}

class TrafficData {
  static const List<TrafficFineItem> fines = [
    TrafficFineItem(
      id: 'drunk_driving',
      section: 'Section 185 MV Act',
      category: 'High Severity',
      fineAmount: '₹10,000 (1st) / ₹15,000 (2nd)',
      jailTerm: 'Up to 6 Months (1st) / 2 Years (2nd)',
      isSevere: true,
      icon: Icons.no_drinks_rounded,
      title: 'Drunk Driving (Alcohol > 30mg per 100ml)',
      titleHi: 'शराब पीकर गाड़ी चलाना (Section 185)',
      titleTe: 'మద్యం సేవించి వాహనం నడపడం (Section 185)',
      titleTa: 'மது அருந்தி வாகனம் ஓட்டுதல் (Section 185)',
      description: 'Driving under the influence of alcohol exceeding 30mg per 100ml blood detected via breathalyzer. Police can detain vehicle until a sober driver takes custody.',
      descriptionHi: 'ब्रेथ एनालाइजर में 30mg/100ml से ज्यादा शराब पाए जाने पर कोर्ट चालान और वाहन जब्त हो सकता है।',
      descriptionTe: 'రక్తంలో 100 మి.లీకి 30 మి.గ్రా కంటే ఎక్కువ ఆల్కహాల్ ఉంటే వాహనాన్ని పోలీసులు సీజ్ చేయవచ్చు, కోర్టు ద్వారా రూ.10,000 జరిమానా పడుతుంది.',
      descriptionTa: '100 மில்லி இரத்தத்தில் 30 மிகிக்கு மேல் மதுபானம் இருந்தால் நீதிமன்ற அபராதம் மற்றும் சிறை தண்டனை உண்டு.',
    ),
    TrafficFineItem(
      id: 'minor_driving',
      section: 'Section 199A MV Act',
      category: 'High Severity',
      fineAmount: '₹25,000 on Parents / Owner',
      jailTerm: 'Up to 3 Years for Guardian / Owner',
      isSevere: true,
      icon: Icons.family_restroom_rounded,
      title: 'Juvenile / Minor Driving Offense',
      titleHi: 'नाबालिग द्वारा वाहन चलाना (Section 199A)',
      titleTe: 'మైనర్ వాహనం నడపడం (తల్లిదండ్రులపై నేరం)',
      titleTa: 'மைனர் வாகனம் ஓட்டுதல் (பெற்றோர் பொறுப்பு)',
      description: 'Vehicle registration cancelled for 1 year. The minor is tried under Juvenile Justice Act and ineligible for Driving License until age 25. Guardian/Owner held criminally liable.',
      descriptionHi: 'माता-पिता/वाहन मालिक पर ₹25,000 जुर्माना और 3 साल तक की जेल। वाहन का रजिस्ट्रेशन 1 साल के लिए रद्द।',
      descriptionTe: 'మైనర్ పిల్లలు వాహనం నడిపితే తల్లిదండ్రులకు రూ.25,000 జరిమానా మరియు 3 ఏళ్ల జైలు శిక్ష. మైనర్‌కు 25 ఏళ్లు వచ్చేవరకు లైసెన్స్ రాదు.',
      descriptionTa: 'வாகன உரிமையாளருக்கு ₹25,000 அபராதம் மற்றும் 3 ஆண்டுகள் சிறை. வாகனப் பதிவு 1 ஆண்டு ரத்து செய்யப்படும்.',
    ),
    TrafficFineItem(
      id: 'blocking_ambulance',
      section: 'Section 194E MV Act',
      category: 'High Severity',
      fineAmount: '₹10,000',
      jailTerm: 'Up to 6 Months Jail',
      isSevere: true,
      icon: Icons.emergency_rounded,
      title: 'Blocking Ambulance or Emergency Vehicle',
      titleHi: 'एंबुलेंस/इमरजेंसी वाहन का रास्ता रोकना',
      titleTe: 'అంబులెన్స్ లేదా అత్యవసర వాహనానికి దారి ఇవ్వకపోవడం',
      titleTa: 'ஆம்புலன்ஸ் அல்லது அவசர வாகனத்தை தடுப்பது',
      description: 'Failure to give free passage to fire brigade, ambulance, or other emergency vehicles. It is a cognizable traffic violation recorded by dashcam or e-challan cameras.',
      descriptionHi: 'एंबुलेंस या फायर ब्रिगेड को रास्ता न देने पर ₹10,000 का भारी जुर्माना या 6 महीने की जेल का प्रावधान है।',
      descriptionTe: 'అంబులెన్స్ లేదా ఫైర్ ఇంజిన్‌కు దారి ఇవ్వకపోతే రూ.10,000 జరిమానా లేదా 6 నెలల జైలు శిక్ష విధించబడుతుంది.',
      descriptionTa: 'ஆம்புலன்ஸ் அல்லது தீயணைப்பு வாகனத்திற்கு வழிவிடாவிட்டால் ₹10,000 அபராதம் விதிக்கப்படும்.',
    ),
    TrafficFineItem(
      id: 'no_helmet',
      section: 'Section 129 / 194D MV Act',
      category: 'Safety',
      fineAmount: '₹1,000 + 3 Months DL Suspension',
      jailTerm: 'None',
      icon: Icons.sports_motorsports_rounded,
      title: 'Riding Without Helmet (Rider or Pillion)',
      titleHi: 'बिना हेलमेट दोपहिया वाहन चलाना (Section 194D)',
      titleTe: 'హెల్మెట్ లేకుండా బైక్ నడపడం (Section 194D)',
      titleTa: 'ஹெல்மெட் இல்லாமல் இருசக்கர வாகனம் ஓட்டுதல்',
      description: 'Both rider and pillion passenger must wear BIS-certified helmets with chinstraps fastened. Exemption only for turban-wearing Sikhs.',
      descriptionHi: 'चालक और पीछे बैठे यात्री दोनों के लिए बीआईएस प्रमाणित हेलमेट अनिवार्य है। ₹1,000 जुर्माना और 3 महीने के लिए लाइसेंस सस्पेंड।',
      descriptionTe: 'రైడర్ మరియు వెనుక కూర్చున్న వ్యక్తి ఇద్దరూ ఖచ్చితంగా హెల్మెట్ ధరించాలి. రూ.1,000 జరిమానా మరియు 3 నెలల లైసెన్స్ సస్పెన్షన్.',
      descriptionTa: 'இருசக்கர வாகன ஓட்டுநர் மற்றும் பின்னால் இருப்பவர் இருவருக்கும் ஹெல்மெட் கட்டாயம். ₹1,000 அபராதம்.',
    ),
    TrafficFineItem(
      id: 'no_seatbelt',
      section: 'Section 194B MV Act',
      category: 'Safety',
      fineAmount: '₹1,000',
      jailTerm: 'None',
      icon: Icons.airline_seat_recline_normal_rounded,
      title: 'Driving Without Seatbelt (Front or Rear)',
      titleHi: 'सीट बेल्ट न लगाना (Section 194B)',
      titleTe: 'సీట్ బెల్ట్ ధరించకపోవడం (Section 194B)',
      titleTa: 'சீட் பெல்ட் அணியாமல் வாகனம் ஓட்டுதல்',
      description: 'Mandatory for the driver and all occupants, including front passenger and rear seat passengers where belts are fitted.',
      descriptionHi: 'कार चालक और आगे/पीछे बैठे यात्रियों द्वारा सीट बेल्ट न लगाने पर ₹1,000 का जुर्माना।',
      descriptionTe: 'కారు డ్రైవర్ మరియు ప్రయాణికులు సీట్ బెల్ట్ ధరించకపోతే రూ.1,000 జరిమానా విధించబడుతుంది.',
      descriptionTa: 'காரில் சீட் பெல்ட் அணியாமல் பயணம் செய்தால் ₹1,000 அபராதம்.',
    ),
    TrafficFineItem(
      id: 'no_license',
      section: 'Section 181 MV Act',
      category: 'Documents',
      fineAmount: '₹5,000',
      jailTerm: 'Up to 3 Months',
      icon: Icons.badge_rounded,
      title: 'Driving Without Valid Driving License',
      titleHi: 'बिना ड्राइविंग लाइसेंस वाहन चलाना (Section 181)',
      titleTe: 'డ్రైవింగ్ లైసెన్స్ లేకుండా వాహనం నడపడం',
      titleTa: 'செல்லுபடியாகும் ஓட்டுநர் உரிமம் இன்றி ஓட்டுதல்',
      description: 'Operating a motor vehicle without possessing an active, authorized driving license for that specific class of vehicle.',
      descriptionHi: 'ड्राइविंग लाइसेंस न होने पर ₹5,000 का जुर्माना लगता है।',
      descriptionTe: 'చెల్లుబాటు అయ్యే డ్రైవింగ్ లైసెన్స్ లేకుండా వాహనం నడిపితే రూ.5,000 జరిమానా విధించబడుతుంది.',
      descriptionTa: 'உரிமம் இல்லாமல் வாகனம் ஓட்டினால் ₹5,000 அபராதம்.',
    ),
    TrafficFineItem(
      id: 'red_light',
      section: 'Section 184 / 119 MV Act',
      category: 'Signals',
      fineAmount: '₹1,000 to ₹5,000',
      jailTerm: '6 Months to 1 Year (Repeat)',
      icon: Icons.traffic_rounded,
      title: 'Jumping Red Light / Signal Violation',
      titleHi: 'रेड लाइट जंप करना / सिग्नल तोड़ना',
      titleTe: 'ట్రాఫిక్ రెడ్ లైట్ జంప్ చేయడం / సిగ్నల్ ఉల్లంఘన',
      titleTa: 'சிவப்பு விளக்கை தாண்டுதல் / சிக்னல் மீறல்',
      description: 'Passing a red signal or stop sign. Often captured by automated traffic enforcement cameras with direct e-challan sent via SMS.',
      descriptionHi: 'लाल बत्ती पार करने पर ₹1,000 से ₹5,000 तक का जुर्माना और दोहराने पर लाइसेंस निलंबन।',
      descriptionTe: 'రెడ్ సిగ్నల్ దాటితే ఆటోమేటిక్ కెమెరా ద్వారా రూ.1,000 నుండి రూ.5,000 వరకు ఈ-చలానా వస్తుంది.',
      descriptionTa: 'சிக்னல் மீறினால் ₹1,000 முதல் ₹5,000 வரை அபராதம்.',
    ),
    TrafficFineItem(
      id: 'phone_driving',
      section: 'Section 184(c) MV Act',
      category: 'Safety',
      fineAmount: '₹1,000 to ₹5,000',
      jailTerm: 'Up to 1 Year (Repeat)',
      icon: Icons.phone_disabled_rounded,
      title: 'Using Mobile Phone While Driving',
      titleHi: 'ड्राइविंग के दौरान मोबाइल फोन का उपयोग',
      titleTe: 'డ్రైవింగ్ చేస్తూ మొబైల్ ఫోన్ మాట్లాడటం',
      titleTa: 'வாகனம் ஓட்டும்போது செல்போன் பேசுதல்',
      description: 'Holding or talking on a handheld mobile phone while operating a vehicle. Navigation is permitted only via hands-free mount without driver distraction.',
      descriptionHi: 'गाड़ी चलाते समय हाथ में फोन पकड़कर बात करने पर ₹1,000 से ₹5,000 जुर्माना। केवल नेविगेशन हेतु हैंड-फ्री अनुमति है।',
      descriptionTe: 'వాహనం నడుపుతూ ఫోన్ మాట్లాడితే రూ.1,000 నుండి రూ.5,000 జరిమానా. నావిగేషన్ కోసం మాత్రమే స్టాండ్‌లో పెట్టుకోవచ్చు.',
      descriptionTa: 'செல்போனில் பேசிக்கொண்டு வாகனம் ஓட்டினால் ₹1,000 முதல் ₹5,000 வரை அபராதம்.',
    ),
    TrafficFineItem(
      id: 'over_speeding',
      section: 'Section 183 MV Act',
      category: 'Speed & Signals',
      fineAmount: '₹1,000 - ₹2,000 (LMV) / ₹2,000 - ₹4,000 (Commercial)',
      jailTerm: 'Impound on Repeat',
      icon: Icons.speed_rounded,
      title: 'Over-Speeding Beyond Posted Speed Limit',
      titleHi: 'निर्धारित गति सीमा से तेज गाड़ी चलाना (Section 183)',
      titleTe: 'నిర్ణీత వేగ పరిమితి దాటి వేగంగా నడపడం (ఓవర్‌స్పీడింగ్)',
      titleTa: 'அதிவேகமாக வாகனம் ஓட்டுதல் (Section 183)',
      description: 'Exceeding the speed limit detected by radar guns or speed cameras. Subsequent offenses can lead to impounding of the driver license.',
      descriptionHi: 'कार के लिए ₹1,000 - ₹2,000 और कमर्शियल वाहनों के लिए ₹2,000 - ₹4,000 तक का जुर्माना।',
      descriptionTe: 'కార్లు/బైక్‌లకు రూ.1,000 నుండి రూ.2,000 వరకు స్పీడ్ గన్ల ద్వారా నేరుగా చలానా జనరేట్ అవుతుంది.',
      descriptionTa: 'வேக வரம்பை மீறினால் ₹1,000 முதல் ₹2,000 வரை அபராதம்.',
    ),
    TrafficFineItem(
      id: 'no_insurance',
      section: 'Section 196 MV Act',
      category: 'Documents',
      fineAmount: '₹2,000 (1st) / ₹4,000 (2nd)',
      jailTerm: 'Up to 3 Months Jail',
      icon: Icons.policy_rounded,
      title: 'Driving Uninsured Vehicle (No Third Party)',
      titleHi: 'बिना थर्ड पार्टी इंश्योरेंस के गाड़ी चलाना (Section 196)',
      titleTe: 'ఇన్సూరెన్స్ లేకుండా వాహనం నడపడం (Section 196)',
      titleTa: 'காப்பீடு இல்லாத வாகனம் ஓட்டுதல் (Section 196)',
      description: 'Mandatory to maintain at least third-party insurance at all times to compensate victims of road accidents.',
      descriptionHi: 'थर्ड पार्टी बीमा न होने पर पहली बार ₹2,000 और दूसरी बार ₹4,000 का जुर्माना अथवा 3 महीने की जेल।',
      descriptionTe: 'థర్డ్ పార్టీ ఇన్సూరెన్స్ లేకుండా నడిపితే మొదటిసారి రూ.2,000, రెండోసారి రూ.4,000 లేదా 3 నెలల జైలు.',
      descriptionTa: 'மூன்றாம் நபர் காப்பீடு இல்லாமல் ஓட்டினால் ₹2,000 அபராதம் அல்லது 3 மாத சிறை.',
    ),
    TrafficFineItem(
      id: 'puc_violation',
      section: 'Section 190(2) MV Act',
      category: 'Documents',
      fineAmount: '₹10,000 + 3 Months DL Disqualification',
      jailTerm: 'Up to 3 Months',
      icon: Icons.eco_rounded,
      title: 'No Valid Pollution Certificate (PUCC)',
      titleHi: 'प्रदूषण प्रमाण पत्र (PUC) न होना (Section 190(2))',
      titleTe: 'పొల్యూషన్ సర్టిఫికేట్ (PUC) లేకపోవడం',
      titleTa: 'புகை பரிசோதனை சான்றிதழ் (PUC) இல்லாமை',
      description: 'Vehicles older than 1 year must carry a valid digital PUC certificate registered on the national Parivahan portal.',
      descriptionHi: 'वैध पीयूसी न होने पर ₹10,000 का जुर्माना और लाइसेंस 3 महीने के लिए निलंबित हो सकता है।',
      descriptionTe: 'చెల్లుబాటు అయ్యే PUC సర్టిఫికేట్ లేకపోతే రవాణా శాఖ రూ.10,000 వరకు భారీ జరిమానా విధిస్తుంది.',
      descriptionTa: 'செல்லுபடியாகும் PUC இல்லாவிட்டால் ₹10,000 வரை அபராதம் விதிக்கப்படலாம்.',
    ),
    TrafficFineItem(
      id: 'triple_riding',
      section: 'Section 128 / 194C MV Act',
      category: 'Safety',
      fineAmount: '₹1,000 + 3 Months DL Suspension',
      jailTerm: 'None',
      icon: Icons.two_wheeler_rounded,
      title: 'Triple Riding on Two-Wheeler',
      titleHi: 'दोपहिया पर तीन सवारी बैठाना (Section 194C)',
      titleTe: 'టూ-వీలర్‌పై ముగ్గురు ప్రయాణించడం (ట్రిపుల్ రైడింగ్)',
      titleTa: 'இருசக்கர வாகனத்தில் மூவர் பயணம் செய்தல்',
      description: 'No driver of a two-wheeled motorcycle shall carry more than one person in addition to himself on the vehicle.',
      descriptionHi: 'दोपहिया पर एक से अधिक सवारी बैठाने पर ₹1,000 जुर्माना और 3 महीने के लिए लाइसेंस रद्द।',
      descriptionTe: 'బైక్ పై ముగ్గురు ప్రయాణిస్తే రూ.1,000 జరిమానాతో పాటు 3 నెలల డ్రైవింగ్ లైసెన్స్ సస్పెన్షన్.',
      descriptionTa: 'இருசக்கர வாகனத்தில் 3 பேர் பயணம் செய்தால் ₹1,000 அபராதம்.',
    ),
  ];

  static const List<TrafficDriverRight> driverRights = [
    TrafficDriverRight(
      id: 'digilocker_validity',
      legalRef: 'MoRTH Notification RT-11036/64/2017 & Rule 139 CMVR',
      icon: Icons.smartphone_rounded,
      title: 'DigiLocker & mParivahan are 100% Legally Valid',
      titleHi: 'डिजिलॉकर और एम-परिवहन पूरी तरह वैध हैं',
      titleTe: 'డిజిలాకర్ & ఎం-పరివాహన్ పత్రాలు చట్టబద్ధంగా పూర్తిగా చెల్లుతాయి',
      titleTa: 'டிஜிலாக்கர் ஆவணங்கள் 100% சட்டப்பூர்வமாக செல்லுபடியாகும்',
      detail: 'Traffic police cannot insist on physical copies of your Driving License, RC, Insurance, or PUC if you show them via DigiLocker or the official mParivahan app. It is legally binding across all Indian states.',
      detailHi: 'यदि आप डिजिलॉकर या एम-परिवहन ऐप में डिजिटल दस्तावेज दिखाते हैं, तो पुलिस फिजिकल कॉपी की मांग नहीं कर सकती और इसके लिए चालान नहीं काट सकती।',
      detailTe: 'ట్రాఫిక్ పోలీసులు ఒరిజినల్ ఫిజికల్ కాపీల కోసం పట్టుబట్టలేరు. డిజిలాకర్ లేదా అధికారిక mParivahan యాప్‌లో చూపించిన పత్రాలను చట్టబద్ధంగా అంగీకరించాల్సిందే.',
      detailTa: 'டிஜிலாக்கர் அல்லது mParivahan செயலியில் டிஜிட்டல் ஆவணங்களை காட்டினால் அசல் ஆவணங்களை கேட்க போலீசுக்கு உரிமை இல்லை.',
    ),
    TrafficDriverRight(
      id: 'key_snatching_illegal',
      legalRef: 'Supreme Court & Police Manual Guidelines',
      icon: Icons.key_off_rounded,
      title: 'Snatching Vehicle Keys from Ignition is Illegal',
      titleHi: 'गाड़ी की चाबी छीनना या टायर की हवा निकालना गैरकानूनी है',
      titleTe: 'వాహనం కీ లాక్కోవడం లేదా టైర్లలో గాలి తీయడం చట్టవిరుద్ధం',
      titleTa: 'வாகன சாவியை பிடுங்குவது சட்டவிரோதமானது',
      detail: 'No police officer, regardless of rank, has the legal right to forcibly pull the key out of your vehicle ignition or deflate tires. If an officer attempts this, you can politely object and record the incident.',
      detailHi: 'कोई भी पुलिसकर्मी चलती गाड़ी की चाबी नहीं निकाल सकता और न ही टायर की हवा निकाल सकता है। ऐसा करना पुलिस आचार संहिता का उल्लंघन है।',
      detailTe: 'పోలీస్ అధికారికి మీ బైక్ లేదా కార్ ఇగ్నిషన్ నుండి కీ లాక్కొనే లేదా టైర్ల గాలి తీసే అధికారం చట్టంలో లేదు. ఇది నిబంధనలకు విరుద్ధం.',
      detailTa: 'வாகனத்தின் சாவியைப் பிடுங்குவதற்கோ, டயரில் காற்றைப் பிடுங்குவதற்கோ எந்த காவல்துறைக்கும் சட்டப்பூர்வ அதிகாரம் இல்லை.',
    ),
    TrafficDriverRight(
      id: 'officer_rank_spot_fine',
      legalRef: 'Motor Vehicles Act Section 130 / State Police Rules',
      icon: Icons.military_tech_rounded,
      title: 'Only Sub-Inspector (SI) or Above Can Fine Over ₹100',
      titleHi: 'केवल सब-इंस्पेक्टर या उससे ऊपर के अधिकारी ही स्पॉट चालान काट सकते हैं',
      titleTe: 'కేవలం ఎస్సై (SI) లేదా పై స్థాయి అధికారికే స్పాట్ చలానా వేసే అధికారం ఉంది',
      titleTa: 'சப்-இன்ஸ்பெக்டர் அல்லது அதற்கு மேற்பட்ட அதிகாரிகள் மட்டுமே அபராதம் விதிக்க முடியும்',
      detail: 'Constables and Head Constables cannot issue arbitrary spot cash fines over ₹100 or confiscate documents. Only an officer of the rank of Sub-Inspector (wearing at least one star) with an official e-challan machine can issue a spot penalty.',
      detailHi: 'कांस्टेबल केवल ट्रैफिक नियंत्रित कर सकते हैं। ₹100 से अधिक का ऑन-द-स्पॉट चालान केवल सब-इंस्पेक्टर (SI) या उच्च अधिकारी ही काट सकते हैं।',
      detailTe: 'హెడ్ కానిస్టేబుల్ లేదా కానిస్టేబుల్‌కు స్పాట్ చలానా రాసే అధికారం లేదు. కనీసం ఒక స్టార్ ఉన్న సబ్-ఇన్‌స్పెక్టర్ (SI) లేదా పై అధికారి మాత్రమే చలానా విధించగలరు.',
      detailTa: 'காவலர்கள் நேரடியாக அபராதம் வசூலிக்க முடியாது. சப்-இன்ஸ்பெக்டர் பதவிக்கு மேல் உள்ளவர்களே இ-சலான் போட முடியும்.',
    ),
    TrafficDriverRight(
      id: 'receipt_mandate',
      legalRef: 'Rule 139 Central Motor Vehicles Rules',
      icon: Icons.receipt_long_rounded,
      title: 'Official Printed E-Challan Receipt is Mandatory',
      titleHi: 'आधिकारिक ई-चालान रसीद प्राप्त करना आपका अधिकार है',
      titleTe: 'అధికారిక ప్రింటెడ్ ఈ-చలానా రసీదు పొందడం మీ హక్కు',
      titleTa: 'அதிகாரப்பூர்வ ரசீது பெறுவது உங்கள் உரிமை',
      detail: 'Never pay cash without an official printed receipt or digital SMS confirmation generated by the handheld government POS machine. If no receipt is provided, the money is considered unauthorized.',
      detailHi: 'बिना सरकारी ई-चालान रसीद या मैसेज के कभी भी नकद भुगतान न करें। हर जुर्माने की सरकारी रसीद अनिवार्य है।',
      detailTe: 'మిషన్ ద్వారా జనరేట్ అయిన ప్రింటెడ్ రసీదు లేదా SMS లేకుండా పోలీసులకు నగదు ఇవ్వకండి. రసీదు అడగడం మీ చట్టబద్ధమైన హక్కు.',
      detailTa: 'அரசு இ-சலான் ரசீது இல்லாமல் எந்தவொரு ரொக்க அபராதத்தையும் செலுத்த வேண்டாம்.',
    ),
    TrafficDriverRight(
      id: 'towing_rules',
      legalRef: 'Urban Traffic Regulations & High Court Directives',
      icon: Icons.car_crash_rounded,
      title: 'Vehicle Cannot be Towed if Occupant is Inside',
      titleHi: 'यदि गाड़ी के अंदर कोई बैठा है तो उसे टो (tow) नहीं किया जा सकता',
      titleTe: 'వాహనంలో మనుషులు కూర్చుని ఉంటే వాహనాన్ని టోయింగ్ చేయకూడదు',
      titleTa: 'உள்ளே ஆள் இருக்கும்போது வாகனத்தை இழுத்துச் செல்ல முடியாது',
      detail: 'If you or any passenger is sitting inside the vehicle, towing cranes cannot legally tow the vehicle away. You can pay the wrong-parking fine on the spot and immediately clear the lane.',
      detailHi: 'यदि चालक या कोई व्यक्ति वाहन में बैठा है, तो क्रेन से गाड़ी को टो नहीं किया जा सकता। आप नो-पार्किंग चालान भरकर तुरंत गाड़ी हटा सकते हैं।',
      detailTe: 'కారు లేదా వాహనంలో ఎవరైనా కూర్చుని ఉంటే టోయింగ్ క్రేన్ వాహనాన్ని లాగడం చట్టవిరుద్ధం. రాంగ్ పార్కింగ్ ఫైన్ కట్టి వాహనాన్ని పక్కకు తీయవచ్చు.',
      detailTa: 'வாகனத்திற்குள் யாராவது அமர்ந்திருந்தால் டோயிங் வாகனம் அதை இழுத்துச் செல்ல முடியாது.',
    ),
    TrafficDriverRight(
      id: 'breathalyzer_blood_test',
      legalRef: 'Section 203 & 204 Motor Vehicles Act',
      icon: Icons.medical_services_rounded,
      title: 'Right to Medical Blood Test for Alcohol Verification',
      titleHi: 'शराब जांच के लिए अस्पताल में ब्लड टेस्ट की मांग का अधिकार',
      titleTe: 'ఆల్కహాల్ టెస్ట్ తప్పుగా వస్తే బ్లడ్ టెస్ట్ కోరే హక్కు',
      titleTa: 'இரத்த பரிசோதனை கோரும் உரிமை',
      detail: 'If you believe the breathalyzer reading is faulty or false, you have the legal right to request a clinical blood test at a government hospital within 2 hours to prove sobriety.',
      detailHi: 'यदि आपको लगता है कि ब्रेथ-एनालाइजर खराब है, तो आप 2 घंटे के भीतर सरकारी अस्पताल में ब्लड टेस्ट कराने की मांग कर सकते हैं।',
      detailTe: 'బ్రీత్ అనలైజర్ మెషిన్ రీడింగ్‌పై మీకు అనుమానం ఉంటే, 2 గంటల లోపు సమీప ప్రభుత్వ ఆసుపత్రిలో బ్లడ్ టెస్ట్ చేయించాలని కోరవచ్చు.',
      detailTa: 'ப்ரீத் அனலைசர் தவறான முடிவு காட்டினால் 2 மணி நேரத்திற்குள் அரசு மருத்துவமனையில் ரத்தப் பரிசோதனை கோரலாம்.',
    ),
    TrafficDriverRight(
      id: 'women_motorist_safety',
      legalRef: 'Section 46(4) CrPC / Section 35 BNSS',
      icon: Icons.shield_rounded,
      title: 'Protections for Women Drivers at Night',
      titleHi: 'रात में महिला चालकों के लिए विशेष कानूनी सुरक्षा',
      titleTe: 'రాత్రి సమయాల్లో మహిళా డ్రైవర్లకు ప్రత్యేక రక్షణలు',
      titleTa: 'இரவு நேரங்களில் பெண் ஓட்டுநர்களுக்கான சிறப்பு பாதுகாப்பு',
      detail: 'A woman driver cannot be detained or physically questioned on the road between sunset (6 PM) and sunrise (6 AM) without the active presence of a woman police officer.',
      detailHi: 'सूर्यास्त के बाद और सूर्योदय से पहले महिला पुलिसकर्मी की गैर-मौजूदगी में किसी भी महिला चालक को रोका या हिरासत में नहीं लिया जा सकता।',
      detailTe: 'సూర్యాస్తమయం తర్వాత మరియు సూర్యోదయానికి ముందు మహిళా పోలీస్ అధికారి లేనిదే మహిళా డ్రైవర్లను అదుపులోకి తీసుకోవడం చట్టవిరుద్ధం.',
      detailTa: 'சூரிய அஸ்தமனத்திற்குப் பிறகு பெண் காவலர் இல்லாமல் பெண் ஓட்டுநர்களை தடுத்து நிறுத்த முடியாது.',
    ),
  ];
}
