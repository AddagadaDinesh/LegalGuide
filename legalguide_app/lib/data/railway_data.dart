import '../localization/app_strings.dart';
import '../services/locale_service.dart';

class RailwayFineItem {
  final String title;
  final String titleTe;
  final String section;
  final String fineAmount;
  final String jailTerm;
  final String severity; // High, Medium, Standard
  final String description;
  final String descriptionTe;
  final bool isBailable;
  final bool isCognizable;

  const RailwayFineItem({
    required this.title,
    required this.titleTe,
    required this.section,
    required this.fineAmount,
    required this.jailTerm,
    required this.severity,
    required this.description,
    required this.descriptionTe,
    required this.isBailable,
    required this.isCognizable,
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

class RailwayRuleItem {
  final String title;
  final String titleTe;
  final String category; // Allowed vs Prohibited
  final bool isAllowed;
  final String detail;
  final String detailTe;
  final String legalRef;

  const RailwayRuleItem({
    required this.title,
    required this.titleTe,
    required this.category,
    required this.isAllowed,
    required this.detail,
    required this.detailTe,
    required this.legalRef,
  });

  String get displayTitle {
    if (LocaleService.isTelugu && titleTe.isNotEmpty) return titleTe;
    if (LocaleService.isHindi) return tr(title);
    return title;
  }

  String get displayDetail {
    if (LocaleService.isTelugu && detailTe.isNotEmpty) return detailTe;
    if (LocaleService.isHindi) return tr(detail);
    return detail;
  }
}

class RailwaySectionData {
  final String sectionNumber;
  final String title;
  final String simpleExplanation;
  final String legalText;
  final String punishment;
  final String bailability;
  final String practicalExample;

  const RailwaySectionData({
    required this.sectionNumber,
    required this.title,
    required this.simpleExplanation,
    required this.legalText,
    required this.punishment,
    required this.bailability,
    required this.practicalExample,
  });
}

class RailwayData {
  static const List<RailwayFineItem> fines = [
    RailwayFineItem(
      title: 'Ticketless Travel / Without Valid Pass',
      titleTe: 'టికెట్ లేకుండా లేదా చెల్లని పాస్‌తో ప్రయాణం',
      section: 'Section 138, Railways Act 1989',
      fineAmount: '₹250 minimum penalty + full fare from starting station',
      jailTerm: 'Up to 1 month (if penalty not paid)',
      severity: 'Medium',
      description:
          'Traveling in a train without an authentic ticket, or traveling beyond authorized destination, or in a higher class than permitted.',
      descriptionTe:
          'సరైన టికెట్ లేకుండా లేదా ప్రయాణ పరిమితి దాటి లేదా అనుమతించిన తరగతి కంటే ఎక్కువ తరగతిలో ప్రయాణించడం.',
      isBailable: true,
      isCognizable: false,
    ),
    RailwayFineItem(
      title: 'Fraudulent Ticketless Travel (Intent to Defraud)',
      titleTe: 'మోసపూరిత ఉద్దేశంతో టికెట్ లేకుండా ప్రయాణించడం',
      section: 'Section 137, Railways Act 1989',
      fineAmount: 'Up to ₹1,000 (minimum ₹500) + excess fare',
      jailTerm: 'Imprisonment up to 6 months',
      severity: 'High',
      description:
          'Intentionally defrauding railways by evading ticket payment, using forged tickets, altered identity, or counterfeit passes.',
      descriptionTe:
          'నకిలీ టికెట్ ఉపయోగించి లేదా టికెట్ చెల్లింపును తప్పించుకోవాలనే ఉద్దేశంతో ప్రయాణించడం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Alarm Chain Pulling without Reasonable Cause',
      titleTe: 'తగిన కారణం లేకుండా అత్యవసర చైన్ లాగడం',
      section: 'Section 141, Railways Act 1989',
      fineAmount: 'Up to ₹1,000 (minimum ₹500 for first offence)',
      jailTerm: 'Imprisonment up to 1 year',
      severity: 'High',
      description:
          'Pulling the emergency communication chain without genuine emergency (such as medical crisis, fire, or severe threat). Pulling to board late or for convenience is an offence.',
      descriptionTe:
          'సరైన అత్యవసర కారణం (వైద్య సమస్య, అగ్నిప్రమాదం) లేకుండా రైలు చైన్ లాగడం చట్టరీత్యా నేరం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Trespassing on Railway Tracks / Restricted Area',
      titleTe: 'రైల్వే ట్రాక్‌లపై నడవడం లేదా ఆక్రమించడం',
      section: 'Section 147, Railways Act 1989',
      fineAmount: 'Up to ₹1,000',
      jailTerm: 'Imprisonment up to 6 months',
      severity: 'High',
      description:
          'Walking across railway tracks instead of using foot-over-bridges, crossing closed level crossings, or unauthorized entry into railway yards.',
      descriptionTe:
          'ఫుట్ ఓవర్ బ్రిడ్జి ఉపయోగించకుండా ట్రాక్‌లు దాటడం, గేటు మూసి ఉన్నప్పుడు పట్టాలు దాటడం నేరం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Men Entering Women-Reserved Coach',
      titleTe: 'మహిళా కోచ్‌లో పురుషులు ప్రవేశించడం',
      section: 'Section 162, Railways Act 1989',
      fineAmount: 'Up to ₹500 + immediate removal from train',
      jailTerm: 'Detention until next station / up to 1 month',
      severity: 'High',
      description:
          'Any male passenger unlawfully entering or refusing to leave a compartment, berth, or coach designated exclusively for female passengers.',
      descriptionTe:
          'మహిళల కోసం కేటాయించిన బోగీలోకి పురుషులు ప్రవేశించడం లేదా దిగడానికి నిరాకరించడం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Traveling on Footboard, Roof, or Engine',
      titleTe: 'ఫుట్‌బోర్డ్, పైకప్పు లేదా ఇంజిన్‌పై ప్రయాణించడం',
      section: 'Section 156, Railways Act 1989',
      fineAmount: 'Up to ₹500',
      jailTerm: 'Imprisonment up to 3 months',
      severity: 'High',
      description:
          'Hanging from doors, riding footboards, climbing on roofs of coaches, or riding in engine cabins despite warnings by railway servants.',
      descriptionTe:
          'రైలు తలుపుల వద్ద వేలాడడం, ఫుట్‌బోర్డుపై లేదా రైలు పైకప్పుపై ప్రయాణించడం ప్రమాదకరం మరియు నేరం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Smoking in Trains or Railway Premises',
      titleTe: 'రైళ్లు లేదా రైల్వే ప్రాంగణంలో ధూమపానం',
      section: 'Section 167, Railways Act 1989',
      fineAmount: '₹100 to ₹200 spot fine',
      jailTerm: 'Removal from train on refusal to desist',
      severity: 'Standard',
      description:
          'Smoking tobacco or e-cigarettes in any compartment, toilet, station platform, or railway waiting area.',
      descriptionTe:
          'రైలు బోగీలు, టాయిలెట్లు లేదా ప్లాట్‌ఫారమ్‌లపై ధూమపానం చేయడం నిషేధం.',
      isBailable: true,
      isCognizable: false,
    ),
    RailwayFineItem(
      title: 'Drunkenness, Obscenity, or Public Nuisance',
      titleTe: 'మద్యపానం, అసభ్య ప్రవర్తన లేదా ప్రయాణికులను వేధించడం',
      section: 'Section 145, Railways Act 1989',
      fineAmount: '₹100 to ₹500 + forfeiture of ticket and fare',
      jailTerm: 'Up to 6 months imprisonment',
      severity: 'High',
      description:
          'Consuming alcohol, being intoxicated, using abusive/obscene language, or creating nuisance for co-passengers on railway premises.',
      descriptionTe:
          'రైలులో మద్యం సేవించడం, అసభ్యకరంగా ప్రవర్తించడం లేదా ఇతరులకు భంగం కలిగించడం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Carrying Dangerous / Inflammable / Explosive Goods',
      titleTe: 'ప్రమాదకరమైన లేదా పేలుడు పదార్థాలను తీసుకెళ్లడం',
      section: 'Section 164, Railways Act 1989',
      fineAmount: 'Up to ₹1,000 + liability for all damages caused',
      jailTerm: 'Imprisonment up to 3 years',
      severity: 'High',
      description:
          'Carrying firecrackers, petrol, kerosene, gas cylinders, acids, or other hazardous inflammable chemicals inside train coaches.',
      descriptionTe:
          'టపాసులు, పెట్రోల్, గ్యాస్ సిలిండర్లు లేదా ప్రమాదకరమైన రసాయనాలను రైలులో తీసుకెళ్లడం తీవ్ర నేరం.',
      isBailable: false,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Unauthorized Hawking, Vending, or Begging',
      titleTe: 'అనధికారిక వ్యాపారం, అమ్మకాలు లేదా యాచించడం',
      section: 'Section 144, Railways Act 1989',
      fineAmount: '₹1,000 to ₹2,000',
      jailTerm: 'Imprisonment up to 1 year',
      severity: 'Medium',
      description:
          'Selling food, water, or articles inside coaches or stations without valid IRCTC/Railway permit, or begging on trains.',
      descriptionTe:
          'రైల్వే అనుమతి లేకుండా వస్తువులు విక్రయించడం లేదా రైలులో యాచించడం.',
      isBailable: true,
      isCognizable: true,
    ),
    RailwayFineItem(
      title: 'Littering or Spitting on Railway Premises',
      titleTe: 'రైల్వే ప్రాంగణంలో చెత్త వేయడం లేదా ఉమ్మివేయడం',
      section: 'Indian Railways (Cleanliness) Rules, 2012',
      fineAmount: 'Up to ₹500 spot fine',
      jailTerm: 'None',
      severity: 'Standard',
      description:
          'Throwing plastic, food waste, bottles from train windows or on platforms, or spitting tobacco in railway premises.',
      descriptionTe:
          'ప్లాస్టిక్, ఆహార వ్యర్థాలు లేదా కిటికీల నుండి చెత్త విసరడం, ఉమ్మివేయడం.',
      isBailable: true,
      isCognizable: false,
    ),
  ];

  static const List<RailwayRuleItem> rules = [
    RailwayRuleItem(
      title: 'Middle Berth Sleeping Hours',
      titleTe: 'మిడిల్ బెర్త్ నిద్రించే సమయాలు',
      category: 'Allowed',
      isAllowed: true,
      detail:
          'Passengers with middle berths are permitted to sleep and raise their berth between 10:00 PM and 6:00 AM. During other hours (6:00 AM to 10:00 PM), it must be folded to allow lower berth passengers to sit.',
      detailTe:
          'మిడిల్ బెర్త్‌ను రాత్రి 10:00 నుండి ఉదయం 6:00 వరకు మాత్రమే వేసుకోవాలి. మిగిలిన సమయంలో కింద కూర్చునే వారికి అనుకూలంగా మడవాలి.',
      legalRef: 'Railway Passenger Commercial Rules',
    ),
    RailwayRuleItem(
      title: 'Night Travel Etiquette (After 10:00 PM)',
      titleTe: 'రాత్రి ప్రయాణ నిబంధనలు (రాత్రి 10 గంటల తర్వాత)',
      category: 'Allowed',
      isAllowed: true,
      detail:
          'After 10:00 PM, main coach lights must be turned off (only night lights allowed). Playing loud music on loudspeakers without earphones and speaking loudly on phone is prohibited to ensure passenger rest.',
      detailTe:
          'రాత్రి 10 గంటల తర్వాత పెద్ద లైట్లు ఆపివేయాలి. ఇయర్ ఫోన్స్ లేకుండా పెద్ద శబ్దంతో సంగీతం వినడం నిషేధం.',
      legalRef: 'Railway Board Circular on Night Travel',
    ),
    RailwayRuleItem(
      title: 'Luggage Allowance per Passenger',
      titleTe: 'ప్రయాణికుడి లగేజీ పరిమితి',
      category: 'Allowed',
      isAllowed: true,
      detail:
          'Permitted free allowance: AC First Class: 70 kg, AC 2-Tier: 50 kg, AC 3-Tier & Sleeper: 40 kg, Second Class: 35 kg. Excess luggage must be booked in brake van / luggage office.',
      detailTe:
          'ఉచిత లగేజీ పరిమితి: AC ఫస్ట్: 70 కిలోలు, 2-టైర్: 50 కిలోలు, 3-టైర్ & స్లీపర్: 40 కిలోలు, సెకండ్ క్లాస్: 35 కిలోలు.',
      legalRef: 'Railways Luggage Rules',
    ),
    RailwayRuleItem(
      title: 'Emergency Alarm Chain Usage',
      titleTe: 'అత్యవసర చైన్ వాడే పరిస్థితులు',
      category: 'Allowed',
      isAllowed: true,
      detail:
          'Valid emergencies include: A companion/child falling from moving train, sudden severe medical crisis, fire inside coach, elderly/disabled person boarding attempt with train starting, or security emergency.',
      detailTe:
          'కదిలే రైలు నుండి ఎవరైనా పడిపోయినప్పుడు, ఆకస్మిక తీవ్ర గుండెపోటు/వైద్య సమస్య, లేదా అగ్నిప్రమాదం జరిగినప్పుడు మాత్రమే చైన్ లాగాలి.',
      legalRef: 'Section 141, Railways Act 1989',
    ),
    RailwayRuleItem(
      title: 'Identity Proof for E-Tickets',
      titleTe: 'ఈ-టికెట్‌తో గుర్తింపు కార్డు నిబంధన',
      category: 'Allowed',
      isAllowed: true,
      detail:
          'At least one passenger in a PNR must carry an original government ID (Aadhaar, Voter ID, PAN, Driving License, Passport, or Student ID). Failure to show original ID results in being treated as ticketless.',
      detailTe:
          'ఆన్‌లైన్ టికెట్ ఉన్నప్పుడు అసలైన ప్రభుత్వ గుర్తింపు కార్డు (ఆధార్, పాన్, ఓటర్ ఐడీ మొదలైనవి) తప్పనిసరిగా చూపించాలి.',
      legalRef: 'IRCTC E-ticketing Rules',
    ),
    RailwayRuleItem(
      title: 'Playing Loud Music Without Headphones',
      titleTe: 'స్పీకర్లలో పెద్ద శబ్దంతో పాటలు పెట్టడం',
      category: 'Prohibited',
      isAllowed: false,
      detail:
          'Playing music or videos on speaker mode inside passenger coaches, particularly after 10:00 PM, is strictly prohibited and can invite RPF action under public nuisance rules.',
      detailTe:
          'రైలు బోగీల్లో లౌడ్‌స్పీకర్లతో పాటలు వినడం నిషిద్ధం. ఇతరులకు ఇబ్బంది కలగకుండా హెడ్‌ఫోన్లు మాత్రమే వాడాలి.',
      legalRef: 'Section 145, Railways Act 1989',
    ),
    RailwayRuleItem(
      title: 'Boarding Train with Waiting List (WL) E-Ticket',
      titleTe: 'వెయిటింగ్ లిస్ట్ (WL) ఈ-టికెట్‌తో ఎక్కడం',
      category: 'Prohibited',
      isAllowed: false,
      detail:
          'Fully waitlisted e-tickets are automatically cancelled and refunded after chart preparation. Boarding any reserved or unreserved coach on an auto-cancelled WL e-ticket is treated as ticketless travel.',
      detailTe:
          'చార్ట్ తయారైన తర్వాత కూడా వెయిటింగ్ లిస్ట్‌లోనే ఉన్న ఆన్‌లైన్ టికెట్ రద్దవుతుంది. దాంతో ప్రయాణిస్తే టికెట్ లేనట్లే భావిస్తారు.',
      legalRef: 'IRCTC Commercial Rules',
    ),
    RailwayRuleItem(
      title: 'Carrying Gas Stove / Cooking on Train',
      titleTe: 'రైలులో గ్యాస్ స్టవ్ లేదా వంట చేయడం',
      category: 'Prohibited',
      isAllowed: false,
      detail:
          'Carrying flammable gas cylinders, kerosene stoves, or lighting open fire inside train compartments or vestibules is a non-bailable criminal offense punishable with up to 3 years imprisonment.',
      detailTe:
          'రైలులో గ్యాస్ సిలిండర్లు తీసుకెళ్లడం లేదా నిప్పు వెలిగించడం చట్టరీత్యా తీవ్రమైన నేరం.',
      legalRef: 'Section 164, Railways Act 1989',
    ),
    RailwayRuleItem(
      title: 'Crossing Closed Railway Level Crossings',
      titleTe: 'మూసి ఉన్న గేటు కింద నుండి వెళ్లడం',
      category: 'Prohibited',
      isAllowed: false,
      detail:
          'Crossing or crawling under a closed railway level crossing gate on foot, bicycle, or motorcycle is an offense under Section 147 and 160, punishable with heavy fines and jail.',
      detailTe:
          'రైల్వే గేటు మూసి ఉన్నప్పుడు పట్టాలు దాటడానికి ప్రయత్నించడం చట్టవిరుద్ధం మరియు ప్రాణాంతకం.',
      legalRef: 'Section 160 & 147, Railways Act 1989',
    ),
  ];

  static const List<RailwaySectionData> sections = [
    RailwaySectionData(
      sectionNumber: 'Section 137',
      title: 'Fraudulently Traveling or Attempting to Travel Without Pass/Ticket',
      simpleExplanation:
          'Punishes anyone who enters or travels in a train with the deliberate intent to cheat the railways and avoid paying the ticket fare, or using fake/forged passes.',
      legalText:
          'If any person, with intent to defraud a railway administration, enters or remains in any carriage on a railway, or travels in a train, without having a proper pass or ticket... he shall be punishable with imprisonment for a term which may extend to six months, or with fine which may extend to one thousand rupees, or with both.',
      punishment: 'Imprisonment up to 6 months, or fine up to ₹1,000 (minimum ₹500), or both.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'Ramesh alters an expired general ticket date with a pen to board an express train to avoid paying. He is liable under Section 137.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 138',
      title: 'Levy of Excess Charge for Traveling Without Proper Pass or Ticket',
      simpleExplanation:
          'Applies when a passenger boards a train without proper ticket, travels beyond the authorized station, or travels in a higher coach class without malafide fraudulent intent.',
      legalText:
          'If any passenger travels in a train without having a proper pass or ticket with him, or in a carriage of a higher class... he shall be liable to pay, on the demand of any railway servant, the excess charge together with the ordinary fare for the distance which he has traveled.',
      punishment: 'Single ordinary fare from starting station + Excess penalty charge (minimum ₹250).',
      bailability: 'Bailable | Non-Cognizable',
      practicalExample:
          'Suresh buys a Sleeper ticket but sits in 3rd AC coach due to rush. The TTE charges difference of fare plus ₹250 penalty under Section 138.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 141',
      title: 'Needlessly Interfering with Communication (Alarm Chain Pulling)',
      simpleExplanation:
          'Makes it a criminal offense to pull the alarm chain or tamper with the train brake system without a genuine, reasonable, or sufficient emergency cause.',
      legalText:
          'If any passenger, or any other person, without reasonable and sufficient cause, makes use of, or interferes with, any means of communication provided by a railway administration in a train for passengers and the railway servants... he shall be punishable with imprisonment for a term which may extend to one year, or with fine which may extend to one thousand rupees, or with both.',
      punishment: 'Imprisonment up to 1 year, or fine up to ₹1,000 (minimum ₹500 for first offence), or both.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'Kiran pulls the train chain because his friend was late reaching the platform and missed the train. This is illegal and punishable under Section 141.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 144',
      title: 'Prohibition on Canvassing, Hawking, and Begging',
      simpleExplanation:
          'Prohibits any unauthorized selling of goods, soliciting orders, or begging inside train compartments and on railway station platforms.',
      legalText:
          'If any person canvasses for any custom or hawks or exposes for sale any article whatsoever in any carriage or upon any part of a railway, except under and in accordance with the terms and conditions of a licence granted by the railway administration... he shall be punishable with imprisonment for a term which may extend to one year, or with fine which may extend to two thousand rupees, or with both.',
      punishment: 'Imprisonment up to 1 year, or fine from ₹1,000 up to ₹2,000, or both.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'An unauthorized vendor boards a train at night without IRCTC license to sell snacks. RPF can arrest and confiscate goods under Section 144.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 145',
      title: 'Drunkenness or Nuisance on Railway Premises',
      simpleExplanation:
          'Penalizes being drunk, committing nuisance, using obscene language, or endangering comfort of fellow passengers anywhere on railway property.',
      legalText:
          'If any person in any railway carriage or upon any part of a railway is in a state of intoxication, or commits any nuisance or act of indecency, or uses abusive or obscene language... he may be removed from the railway by any railway servant and shall be punishable with fine and forfeiture of his pass or ticket.',
      punishment: 'Fine ₹100 for 1st offense; repeat offense up to ₹500 and up to 6 months imprisonment.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'A passenger consumes alcohol inside a sleeper coach, behaves loudly, and abuses co-passengers. TTE and RPF remove him at next station under Section 145.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 147',
      title: 'Trespassing on Railway Tracks and Railway Property',
      simpleExplanation:
          'Penalizes unauthorized entry or walking across railway tracks, platforms, workshops, yards, or refusal to leave when ordered.',
      legalText:
          'If any person enters upon or into any part of a railway without lawful authority, or having lawfully entered upon or into such part misuses such part or refuses to leave... he shall be punishable with imprisonment for a term which may extend to six months, or with fine which may extend to one thousand rupees, or with both.',
      punishment: 'Imprisonment up to 6 months, or fine up to ₹1,000, or both.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'Passengers climb down onto the tracks to cross to Platform 2 instead of using the foot-over-bridge. RPF can detain them under Section 147.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 156',
      title: 'Traveling on Roof, Steps, Footboard, or Engine',
      simpleExplanation:
          'Prohibits any person from traveling on the exterior parts of a train, including coach roof, footboard, or engine, due to grave safety risk from electric wires and fall.',
      legalText:
          'If any passenger or other person persists in traveling on the roof, step or footboard of any carriage or other part of a train not intended for the use of passengers... he shall be punishable with imprisonment for a term which may extend to three months, or with fine which may extend to five hundred rupees, or with both.',
      punishment: 'Imprisonment up to 3 months, or fine up to ₹500, or both, plus removal from train.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'Students stand hanging from the door footboard on a suburban local train refusing to step inside. Liable under Section 156.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 162',
      title: 'Entering Carriage or Other Place Reserved for Females',
      simpleExplanation:
          'Protects female passengers by punishing any male passenger who enters a coach, compartment, or waiting room reserved exclusively for women.',
      legalText:
          'If a male person enters a carriage, compartment, room or other place reserved for females, or remains therein after having been requested by any railway servant to leave it... he shall be removed from the carriage, compartment, room or other place and shall also be punishable with fine which may extend to five hundred rupees.',
      punishment: 'Fine up to ₹500, forfeiture of ticket, and immediate physical removal from train.',
      bailability: 'Bailable | Cognizable',
      practicalExample:
          'A male passenger boards the dedicated ladies compartment of an express or suburban train. RPF can immediately evict him and impose ₹500 fine.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 164',
      title: 'Unlawfully Bringing Dangerous or Offensive Goods',
      simpleExplanation:
          'Strictly prohibits carrying explosives, fireworks, petrol, gas cylinders, or highly inflammable chemicals on trains without special authorization.',
      legalText:
          'If any person, in contravention of section 67, takes with him any dangerous goods upon a railway... he shall be punishable with imprisonment for a term which may extend to three years, or with fine which may extend to one thousand rupees, or with both, and shall also be liable to pay compensation for any loss or damage caused.',
      punishment: 'Imprisonment up to 3 years, or fine up to ₹1,000, or both + full damages for any fire/loss.',
      bailability: 'Non-Bailable | Cognizable',
      practicalExample:
          'Carrying a box of Diwali firecrackers or a commercial LPG cylinder in luggage. This is a severe non-bailable offense under Section 164.',
    ),
    RailwaySectionData(
      sectionNumber: 'Section 167',
      title: 'Smoking on Railway Premises or Passenger Compartments',
      simpleExplanation:
          'Prohibits smoking of cigarettes, beedis, or electronic cigarettes anywhere in train carriages, toilets, or station premises.',
      legalText:
          'No person in any compartment of a train shall, if objected to by any other passenger in that compartment, smoke therein. If any person smokes in contravention of sub-section (1), he shall be punishable with fine which may extend to one hundred rupees.',
      punishment: 'Spot fine up to ₹200 (under amended Cleanliness/Anti-Smoking orders).',
      bailability: 'Bailable | Non-Cognizable',
      practicalExample:
          'A passenger smokes inside the train bathroom. The smoke detector or co-passengers alert TTE, who imposes fine under Section 167.',
    ),
  ];
}
