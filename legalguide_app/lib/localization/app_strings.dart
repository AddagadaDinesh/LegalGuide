import '../services/locale_service.dart';

/// Translates a piece of app UI text to Telugu if Telugu is selected and a
/// translation exists; otherwise returns the English text unchanged. The
/// English string itself is the lookup key, so call sites don't need
/// separate key constants.
String tr(String text) {
  if (LocaleService.isTelugu) return _te[text] ?? text;
  if (LocaleService.isHindi) return _hi[text] ?? text;
  return text;
}

const _te = <String, String>{
  // Bottom nav / main shell
  'Home': 'హోమ్',
  'Explore': 'అన్వేషణ',
  'Saved': 'సేవ్ చేసినవి',
  'More': 'మరిన్ని',
  'Arrest & Detention': 'అరెస్టు & నిర్బంధం',
  'Documents': 'పత్రాలు',
  'Legal Help': 'న్యాయ సహాయం',
  'About': 'గురించి',
  'Account': 'ఖాతా',
  'Cancel': 'రద్దు చేయి',
  'Close': 'మూసివేయి',
  'Log out': 'లాగ్ అవుట్',
  'Logged in as': 'లాగిన్ అయ్యారు:',
  'Logged out. You can still browse offline legal content.':
      'లాగ్ అవుట్ అయ్యారు. మీరు ఇప్పటికీ ఆఫ్‌లైన్ చట్టపరమైన కంటెంట్‌ను బ్రౌజ్ చేయవచ్చు.',
  "An account is only needed for the AI Assistant's online mode. Browsing and searching legal content never requires one.":
      'AI అసిస్టెంట్ ఆన్‌లైన్ మోడ్ కోసమే ఖాతా అవసరం. చట్టపరమైన కంటెంట్‌ను బ్రౌజ్ చేయడానికి, శోధించడానికి ఖాతా అవసరం లేదు.',
  'Language': 'భాష',
  'English': 'ఇంగ్లీష్',
  'Telugu': 'తెలుగు',
  'Hindi — Coming soon': 'హిందీ — త్వరలో వస్తుంది',
  'Other languages — Coming soon': 'ఇతర భాషలు — త్వరలో వస్తుంది',
  'Online': 'ఆన్‌లైన్',
  'Offline · Using LegalGuide Knowledge': 'ఆఫ్‌లైన్ · లీగల్‌గైడ్ నాలెడ్జ్ ఉపయోగిస్తోంది',
  'Log in': 'లాగిన్',

  // Home screen
  'Welcome,': 'స్వాగతం,',
  'Simplified Legal Knowledge & Assistance': 'సరళీకృత న్యాయ పరిజ్ఞానం & సహాయం',
  'Search laws, section numbers, topics...': 'చట్టాలు, సెక్షన్ నంబర్లు, అంశాలను శోధించండి...',
  'Quick Actions': 'త్వరిత చర్యలు',
  'Search Laws': 'చట్టాలు శోధించండి',
  'Ask AI': 'AIని అడగండి',
  'Arrest &\nDetention': 'అరెస్టు &\nనిర్బంధం',
  'Legal\nDocuments': 'న్యాయ\nపత్రాలు',
  'Need Legal\nHelp': 'న్యాయ సహాయం\nకావాలా',
  "You're offline and haven't synced any legal data yet.\nConnect to the internet and pull down to refresh.":
      'మీరు ఆఫ్‌లైన్‌లో ఉన్నారు మరియు ఇంకా ఏ చట్టపరమైన డేటాను సింక్ చేయలేదు.\nఇంటర్నెట్‌కు కనెక్ట్ అయి, రిఫ్రెష్ చేయడానికి క్రిందికి లాగండి.',
  'Popular Searches': 'ప్రముఖ శోధనలు',
  'Browse Legal Categories': 'న్యాయ వర్గాలను బ్రౌజ్ చేయండి',
  'Commonly Referenced Sections': 'సాధారణంగా ప్రస్తావించే సెక్షన్లు',
  'Sections linked from multiple topics will show up here.':
      'బహుళ అంశాల నుండి లింక్ చేయబడిన సెక్షన్లు ఇక్కడ కనిపిస్తాయి.',
  'Frequently Viewed': 'తరచుగా చూసినవి',
  'Sections you open a few times will show up here.':
      'మీరు కొన్నిసార్లు తెరిచిన సెక్షన్లు ఇక్కడ కనిపిస్తాయి.',

  // Legal section card
  'IN SIMPLE WORDS': 'సాధారణ మాటల్లో',
  'Frequent': 'తరచుగా',

  // Section detail screen
  'Key Takeaway (Plain Explanation)': 'ముఖ్యాంశం (సరళ వివరణ)',
  'Purpose & Legal Context': 'ఉద్దేశ్యం & న్యాయపరమైన సందర్భం',
  'Key Elements': 'ముఖ్య అంశాలు',
  'Punishment & Penalties': 'శిక్ష & జరిమానాలు',
  'What Information May Matter': 'ఏ సమాచారం ముఖ్యం కావచ్చు',
  'Required / Relevant Documents': 'అవసరమైన / సంబంధిత పత్రాలు',
  'Official Statutory Legal Text': 'అధికారిక చట్టబద్ధమైన వచనం',
  '(Official text is kept in English to preserve its exact legal wording.)':
      '(ఖచ్చితమైన చట్టపరమైన పదాలను కాపాడటానికి అధికారిక వచనం ఆంగ్లంలోనే ఉంచబడింది.)',
  'Related Legal Provisions': 'సంబంధిత న్యాయ నిబంధనలు',
  'Verified from': 'నుండి ధృవీకరించబడింది:',
  'Official Gazette': 'అధికారిక గెజిట్',
  'Last updated': 'చివరిగా నవీకరించబడింది',

  // AI Assistant
  'LegalGuide Assistant': 'లీగల్‌గైడ్ అసిస్టెంట్',
  'Ask about Indian law, sections & your rights': 'భారత చట్టం, సెక్షన్లు & మీ హక్కుల గురించి అడగండి',
  'Log in to unlock online AI answers. Offline answers from the LegalGuide library always work.':
      'ఆన్‌లైన్ AI సమాధానాలను అన్‌లాక్ చేయడానికి లాగిన్ అవ్వండి. లీగల్‌గైడ్ లైబ్రరీ నుండి ఆఫ్‌లైన్ సమాధానాలు ఎప్పుడూ పనిచేస్తాయి.',
  'Welcome to LegalGuide!': 'లీగల్‌గైడ్‌కు స్వాగతం!',
  "When you're online I can answer anything; offline, I can only use the legal data stored in this app.":
      'మీరు ఆన్‌లైన్‌లో ఉన్నప్పుడు నేను దేనికైనా సమాధానం ఇవ్వగలను; ఆఫ్‌లైన్‌లో, ఈ యాప్‌లో నిల్వ చేయబడిన చట్టపరమైన డేటాను మాత్రమే నేను ఉపయోగించగలను.',
  'Know My Rights': 'నా హక్కులు తెలుసుకోండి',
  'Constitutional Rights': 'రాజ్యాంగ హక్కులు',
  'Explain a Legal Section': 'ఒక న్యాయ సెక్షన్‌ను వివరించండి',
  '🔒 Log in or create an account for answers beyond app content':
      '🔒 యాప్ కంటెంట్ మించిన సమాధానాల కోసం లాగిన్ అవ్వండి లేదా ఖాతా సృష్టించండి',
  '🟠 Offline – Using LegalGuide Knowledge': '🟠 ఆఫ్‌లైన్ – లీగల్‌గైడ్ నాలెడ్జ్ ఉపయోగిస్తోంది',
  '🟢 Online': '🟢 ఆన్‌లైన్',
  'Log in or create an account →': 'లాగిన్ అవ్వండి లేదా ఖాతా సృష్టించండి →',
  'Ask a question...': 'ఒక ప్రశ్న అడగండి...',

  // Login / signup
  'Enter both a username and password.': 'యూజర్‌నేమ్ మరియు పాస్‌వర్డ్ రెండూ నమోదు చేయండి.',
  'Enter a username and password.': 'యూజర్‌నేమ్ మరియు పాస్‌వర్డ్ నమోదు చేయండి.',
  'Logged in': 'లాగిన్ అయ్యారు',
  'Welcome back,': 'తిరిగి స్వాగతం,',
  'OK': 'సరే',
  "Needed only for the AI Assistant's online mode. Browsing and searching legal content never requires an account.":
      'AI అసిస్టెంట్ ఆన్‌లైన్ మోడ్ కోసమే అవసరం. చట్టపరమైన కంటెంట్‌ను బ్రౌజ్ చేయడానికి, శోధించడానికి ఖాతా ఎప్పుడూ అవసరం లేదు.',
  'Username': 'యూజర్‌నేమ్',
  'Password': 'పాస్‌వర్డ్',
  "Don't have an account? Sign up": 'ఖాతా లేదా? సైన్ అప్ చేయండి',
  'Account created': 'ఖాతా సృష్టించబడింది',
  'Create an account': 'ఖాతా సృష్టించండి',
  "Only used to unlock the AI Assistant's online mode. We don't store your search or chat history against this account.":
      'AI అసిస్టెంట్ ఆన్‌లైన్ మోడ్‌ను అన్‌లాక్ చేయడానికి మాత్రమే ఉపయోగించబడుతుంది. మేము మీ శోధన లేదా చాట్ చరిత్రను ఈ ఖాతాకు వ్యతిరేకంగా నిల్వ చేయము.',
  'Email (optional)': 'ఇమెయిల్ (ఐచ్ఛికం)',
  'Sign up': 'సైన్ అప్',
  'Already have an account? Log in': 'ఇప్పటికే ఖాతా ఉందా? లాగిన్ అవ్వండి',

  // Category overview / matter detail / explore
  'Topics': 'అంశాలు',
  'Laws & Sections': 'చట్టాలు & సెక్షన్లు',
  'Explore Laws': 'చట్టాలను అన్వేషించండి',
  'topics': 'అంశాలు',
  'with legal sections': 'న్యాయ సెక్షన్లతో',
  'content is coming soon — not yet verified.': 'కంటెంట్ త్వరలో వస్తుంది — ఇంకా ధృవీకరించబడలేదు.',
  'No topics available for this category yet.': 'ఈ వర్గానికి ఇంకా అంశాలు అందుబాటులో లేవు.',
  'Coming soon': 'త్వరలో వస్తుంది',
  'section': 'సెక్షన్',
  'sections': 'సెక్షన్లు',
  'legal section': 'న్యాయ సెక్షన్',
  'legal sections': 'న్యాయ సెక్షన్లు',
  'linked': 'లింక్ చేయబడింది',
  'Verified legal sections for this topic are not available yet.':
      'ఈ అంశం కోసం ధృవీకరించబడిన న్యాయ సెక్షన్లు ఇంకా అందుబాటులో లేవు.',
  'All': 'అన్నీ',
  'Categories': 'వర్గాలు',
  'Sections': 'సెక్షన్లు',
  'Available Provisions': 'అందుబాటులో ఉన్న నిబంధనలు',
  'View related legal sections': 'సంబంధిత న్యాయ సెక్షన్లను చూడండి',
  'Content coming soon — not yet verified': 'కంటెంట్ త్వరలో వస్తుంది — ఇంకా ధృవీకరించబడలేదు',
  'No matching legal sections found.': 'సరిపోలే న్యాయ సెక్షన్లు కనుగొనబడలేదు.',

  // Documents
  'Legal Documents & Notice Guides': 'న్యాయ పత్రాలు & నోటీసు మార్గదర్శకాలు',
  'General guide': 'సాధారణ మార్గదర్శకం',
  'What it is': 'ఇది ఏమిటి',
  "When it's used": 'ఇది ఎప్పుడు ఉపయోగించబడుతుంది',
  'Key parts': 'ముఖ్య భాగాలు',
  'Related legal sections': 'సంబంధిత న్యాయ సెక్షన్లు',

  // Legal help
  'Could not open dialer for': 'కోసం డయలర్ తెరవడం సాధ్యం కాలేదు:',
  'Calling is not supported on this device — dial': 'ఈ పరికరంలో కాల్ చేయడం మద్దతు లేదు — డయల్ చేయండి:',
  'manually.': 'మాన్యువల్‌గా.',

  // Saved screen
  'My Saved': 'నా సేవ్ చేసినవి',
  'Nothing saved yet': 'ఇంకా ఏమీ సేవ్ చేయలేదు',
  'bookmarked': 'బుక్‌మార్క్ చేయబడింది',
  'No saved sections yet — tap the bookmark icon on any section to save it here.':
      'ఇంకా సేవ్ చేసిన సెక్షన్లు లేవు — ఏదైనా సెక్షన్‌ను ఇక్కడ సేవ్ చేయడానికి బుక్‌మార్క్ చిహ్నాన్ని నొక్కండి.',

  // Law list screen
  'No laws found for': 'కోసం చట్టాలు కనుగొనబడలేదు:',
  'No sections loaded for this law.': 'ఈ చట్టానికి సెక్షన్లు లోడ్ కాలేదు.',

  // About screen
  'LegalGuide helps you look up Indian laws and legal provisions in plain '
          "language, browse offline once synced, and ask an AI assistant questions — "
          "answered either from what's actually stored in the app (offline) or from a "
          "general AI model when you're online.":
      'లీగల్‌గైడ్ భారత చట్టాలు మరియు న్యాయ నిబంధనలను సరళమైన భాషలో వెతకడానికి, '
          'సింక్ అయిన తర్వాత ఆఫ్‌లైన్‌లో బ్రౌజ్ చేయడానికి మరియు AI అసిస్టెంట్‌ను ప్రశ్నలు '
          'అడగడానికి మీకు సహాయపడుతుంది — ఇది యాప్‌లో నిజంగా నిల్వ చేయబడిన దాని నుండి '
          '(ఆఫ్‌లైన్) లేదా మీరు ఆన్‌లైన్‌లో ఉన్నప్పుడు సాధారణ AI మోడల్ నుండి సమాధానం ఇస్తుంది.',
  'Disclaimer': 'నిరాకరణ',
  'LegalGuide is an educational prototype. Information provided does not '
          'constitute certified legal advice and may not reflect the most current '
          'legal developments. Always consult a qualified legal professional for '
          'advice about your specific situation.':
      'లీగల్‌గైడ్ ఒక విద్యాపరమైన ప్రోటోటైప్. అందించిన సమాచారం ధృవీకరించబడిన న్యాయ సలహాగా '
          'పరిగణించబడదు మరియు ఇటీవలి చట్టపరమైన పరిణామాలను ప్రతిబింబించకపోవచ్చు. మీ నిర్దిష్ట '
          'పరిస్థితి గురించి సలహా కోసం ఎల్లప్పుడూ అర్హత కలిగిన న్యాయ నిపుణుడిని సంప్రదించండి.',
  'Legal content in this app is sourced from official statutes and cross-verified '
          'against multiple independent legal-reference sources, with the source and last '
          'verification date shown on each section.':
      'ఈ యాప్‌లోని న్యాయపరమైన కంటెంట్ అధికారిక శాసనాల నుండి తీసుకోబడింది మరియు బహుళ '
          'స్వతంత్ర న్యాయ-సూచన మూలాలతో క్రాస్-వెరిఫై చేయబడింది, ప్రతి సెక్షన్‌పై మూలం మరియు '
          'చివరి ధృవీకరణ తేదీ చూపబడుతుంది.',
  'Server Connection': 'సర్వర్ కనెక్షన్',
  'Address the app uses for online features (AI Assistant, syncing content). '
          "Update this if your LegalGuide server's address changes, e.g. a new tunnel URL.":
      'ఆన్‌లైన్ ఫీచర్ల కోసం (AI అసిస్టెంట్, కంటెంట్ సింకింగ్) యాప్ ఉపయోగించే చిరునామా. మీ '
          'లీగల్‌గైడ్ సర్వర్ చిరునామా మారితే దీన్ని అప్‌డేట్ చేయండి.',
  'Save': 'సేవ్ చేయి',
  'Reset to default': 'డిఫాల్ట్‌కు రీసెట్ చేయి',
  'Saved. New requests will use this address.': 'సేవ్ చేయబడింది. కొత్త అభ్యర్థనలు ఈ చిరునామాను ఉపయోగిస్తాయి.',
  'Reset to default.': 'డిఫాల్ట్‌కు రీసెట్ చేయబడింది.',

  // Emergency Guide & Audio Readout (TTS)
  'Emergency Rights Guide': 'అత్యవసర హక్కుల మార్గదర్శి',
  'Emergency\nRights': 'అత్యవసర\nహక్కులు',
  'I Need Help Right Now': 'నాకు తక్షణ సహాయం కావాలి',
  'Stay Calm & Know Your Rights': 'శాంతంగా ఉండండి & మీ హక్కులను తెలుసుకోండి',
  'Official Indian statutory protections for on-the-spot legal safety.':
      'తక్షణ చట్టపరమైన భద్రత కోసం అధికారిక భారతీయ చట్టబద్ధమైన రక్షణలు.',
  'Select Emergency Scenario:': 'అత్యవసర పరిస్థితిని ఎంచుకోండి:',
  'Immediate Rights & Steps:': 'తక్షణ హక్కులు & చర్యలు:',
  'Quick Action Rules:': 'త్వరిత చర్య నియమాలు:',
  'Dial Now': 'కాల్ చేయండి',
  'Listen': 'వినండి',
  'Stop': 'ఆపండి',
  'Listen to Section': 'సెక్షన్‌ను వినండి',
  'Stop Reading': 'చదవడం ఆపండి',
  'Listen Aloud': 'వినండి',
  'HELP NOW': 'సహాయం',
  'Police stops, traffic challans, cyber fraud & women safety rights':
      'పోలీస్ ఆపడం, ట్రాఫిక్ చలాన్లు, సైబర్ మోసం & మహిళా భద్రత హక్కులు',
  'Browse Laws Related to': 'వీటికి సంబంధించిన చట్టాలను చూడండి:',
  'Special Guides & Acts': 'ప్రత్యేక మార్గదర్శకాలు & చట్టాలు',
  'Emergency Protections': 'అత్యవసర రక్షణలు',
  'Railway Fines & Offences': 'రైల్వే జరిమానాలు & నేరాలు',
  'No matching legal sections or guides found.': 'సరిపోలే చట్టపరమైన సెక్షన్లు లేదా గైడ్‌లు ఏవీ కనుగొనబడలేదు.',
  'Indian Railway Rules & Fines': 'రైల్వే నిబంధనలు & జరిమానాలు',
  'Penalties, ticketless travel, chain pulling & passenger rights':
      'జరిమానాలు, టికెట్ లేని ప్రయాణం, చైన్ లాగడం & ప్రయాణీకుల హక్కులు',
  'Legal Documents': 'చట్టపరమైన పత్రాలు',
  'Standard legal formats, notices, affidavits & petitions':
      'ప్రామాణిక చట్టపరమైన ఫార్మాట్‌లు, నోటీసులు, అఫిడవిట్లు & పిటిషన్లు',
  // Voice Search
  'Voice Search': 'వాయిస్ శోధన',
  'Speak to search': 'మాట్లాడి శోధించండి',
  'Speak your question': 'మీ ప్రశ్నను మాట్లాడండి',
  'Use Text': 'ఈ వచనాన్ని ఉపయోగించండి',
  'Done': 'పూర్తయింది',
  'Could not start microphone. Check permissions.':
      'మైక్రోఫోన్ ప్రారంభించలేకపోయింది. అనుమతులను తనిఖీ చేయండి.',
  'Say something like "railway rules", "theft", "FIR"...':
      'ఉదాహరణకు "రైల్వే నిబంధనలు", "దొంగతనం", "FIR" అని చెప్పండి...',
  'Ask any legal question in Telugu, Hindi, or English...':
      'తెలుగు, హిందీ లేదా ఇంగ్లీషులో ఏదైనా న్యాయపరమైన ప్రశ్న అడగండి...',
  'Say law name, section number, or topic...':
      'చట్టం పేరు, సెక్షన్ నంబర్ లేదా అంశం చెప్పండి...',
  'Search fines, rules, chain, ticket...':
      'జరిమానాలు, నిబంధనలు, చైన్, టికెట్ వెతకండి...',
  'Traffic Rules & Fines': 'ట్రాఫిక్ నిబంధనలు & జరిమానాలు',
  'Traffic Rules & Driver Rights': 'ట్రాఫిక్ నిబంధనలు & డ్రైవర్ హక్కులు',
  'MV Act 2019 fines, e-challan disputes & citizen driver protections':
      'మోటార్ వాహనాల చట్టం జరిమానాలు, ఈ-చలానా మరియు పౌర హక్కులు',
  'Interactive Document Generator': 'చట్టపరమైన పత్రాల జనరేటర్',
  'Fill, customize, and export ready-to-use RTI, Police Complaints, & Legal Notices.':
      'RTI, పోలీస్ ఫిర్యాదులు, నోటీసులను సులభంగా తయారు చేసి కాపీ చేయండి.',
  'Draft Now': 'డ్రాఫ్ట్ చేయండి',
  'Legal Document Generator': 'లీగల్ డాక్యుమెంట్ జనరేటర్',
  'Instant Draft, Copy & Share': 'తక్షణ డ్రాఫ్ట్, కాపీ & షేర్',
  'Fines & Offenses': 'జరిమానాలు & నేరాలు',
  'Driver Rights': 'డ్రైవర్ హక్కులు',
  'E-Challan Guide': 'ఈ-చలానా మార్గదర్శి',
  "What's New in v1.1.0": 'v1.1.0 లో కొత్త ఫీచర్లు',
  'Traffic Rules & Fines (MV Act)': 'ట్రాఫిక్ నిబంధనలు & జరిమానాలు',
  'Full Motor Vehicles Act penalty table, driver rights, and step-by-step e-challan dispute guide.':
      'పూర్తి మోటార్ వాహనాల చట్టం జరిమానాలు, డ్రైవర్ హక్కులు మరియు ఈ-చలానా గైడ్.',
  'Draft formal Police Complaints, RTI Applications, and Legal Notices with instant copy & export.':
      'పోలీస్ ఫిర్యాదులు, RTI దరఖాస్తులు మరియు లీగల్ నోటీసులను తక్షణమే రూపొందించండి.',
  'Audio Narration (TTS) & Voice Search': 'ఆడియో రీడింగ్ (TTS) & వాయిస్ శోధన',
  'Listen aloud to legal sections, railway rules, and emergency guides in your preferred language.':
      'సెక్షన్లు, రైల్వే నిబంధనలు, ఎమర్జెన్సీ గైడ్‌లను మీ భాషలో వినండి.',
  'Cloud Bookmark Sync': 'క్లౌడ్ బుక్‌మార్క్ సమకాలీకరణ',
  'Seamlessly sync your saved laws and sections across devices when logged into your account.':
      'మీ ఖాతాలో లాగిన్ అయినప్పుడు మీ సేవ్ చేసిన సెక్షన్లను క్లౌడ్‌లో సేవ్ చేయండి.',
  'Citizen Rights & Travel': 'పౌర హక్కులు & ప్రయాణం',
  'Citizen Rights & Travel Guide': 'పౌర హక్కులు & ప్రయాణ మార్గదర్శి',
  'Emergency legal protection, police stops & Indian Railway rules':
      'అత్యవసర చట్టపరమైన రక్షణ, పోలీస్ విచారణ & రైల్వే నిబంధనలు',
  'Emergency Rights': 'అత్యవసర హక్కులు',
  'Railway Rules': 'రైల్వే నిబంధనలు',
  'SAFETY & TRANSIT': 'భద్రత & ప్రయాణం',
  'Emergency Helplines': 'అత్యవసర హెల్ప్‌లైన్లు',
  'National Emergency Number': 'జాతీయ అత్యవసర నంబర్',
  'Indian Railways (RailMadad)': 'భారతీయ రైల్వే (రైల్ మదద్)',
  'Cyber Financial Fraud': 'సైబర్ ఆర్థిక మోసాలు',
  'Women Helpline': 'మహిళా హెల్ప్‌లైన్',
  'Child Helpline': 'చైల్డ్ హెల్ప్‌లైన్',
  'National Highways Emergency': 'జాతీయ రహదారుల అత్యవసర నంబర్',
};

const _hi = <String, String>{
  // Bottom nav / main shell
  'Home': 'होम',
  'Explore': 'एक्सप्लोर',
  'Saved': 'सहेजे गए',
  'More': 'अन्य',
  'Arrest & Detention': 'गिरफ़्तारी और हिरासत',
  'Documents': 'दस्तावेज़',
  'Legal Help': 'कानूनी सहायता',
  'About': 'ऐप के बारे में',
  'Account': 'खाता',
  'Cancel': 'रद्द करें',
  'Close': 'बंद करें',
  'Log out': 'लॉग आउट',
  'Logged in as': 'लॉग इन हैं:',
  'Logged out. You can still browse offline legal content.':
      'लॉग आउट हो गए। आप अभी भी ऑफ़लाइन कानूनी सामग्री ब्राउज़ कर सकते हैं।',
  "An account is only needed for the AI Assistant's online mode. Browsing and searching legal content never requires one.":
      'केवल AI सहायक के ऑनलाइन मोड के लिए खाते की आवश्यकता होती है। ब्राउज़ और सर्च करने के लिए कभी खाते की आवश्यकता नहीं होती।',
  'Language': 'भाषा',
  'English': 'English',
  'Telugu': 'తెలుగు (Telugu)',
  'Hindi': 'हिन्दी (Hindi)',
  'Hindi — Coming soon': 'हिन्दी (Hindi)',
  'Other languages — Coming soon': 'अन्य भाषाएं — जल्द ही',
  'Online': 'ऑनलाइन',
  'Offline · Using LegalGuide Knowledge': 'ऑफ़लाइन · लीगलगाइड ज्ञान का उपयोग',
  'Log in': 'लॉग इन',

  // Home screen
  'Welcome,': 'स्वागत है,',
  'Simplified Legal Knowledge & Assistance': 'सरल कानूनी ज्ञान और सहायता',
  'Search laws, section numbers, topics...': 'कानून, धारा नंबर, विषय खोजें...',
  'Quick Actions': 'त्वरित कार्रवाई',
  'Search Laws': 'कानून खोजें',
  'Ask AI': 'AI से पूछें',
  'Arrest &\nDetention': 'गिरफ़्तारी &\nहिरासत',
  'Legal\nDocuments': 'कानूनी\nदस्तावेज़',
  'Need Legal\nHelp': 'कानूनी मदद\nचाहिए',
  "You're offline and haven't synced any legal data yet.\nConnect to the internet and pull down to refresh.":
      'आप ऑफ़लाइन हैं और अभी तक कोई कानूनी डेटा सिंक नहीं हुआ है।\nइंटरनेट से जुड़ें और रीफ्रेश करने के लिए नीचे खींचें।',
  'Popular Searches': 'लोकप्रिय खोजें',
  'Browse Legal Categories': 'कानूनी श्रेणियां ब्राउज़ करें',
  'Commonly Referenced Sections': 'अक्सर संदर्भित धाराएं',
  'Sections linked from multiple topics will show up here.':
      'कई विषयों से जुड़ी धाराएं यहां दिखाई देंगी।',
  'Frequently Viewed': 'अक्सर देखी गई',
  'Sections you open a few times will show up here.':
      'जिन्हें आप कई बार खोलते हैं वे धाराएं यहां दिखाई देंगी।',

  // Legal section card
  'IN SIMPLE WORDS': 'सरल शब्दों में',
  'Frequent': 'अक्सर',

  // Section detail screen
  'Key Takeaway (Plain Explanation)': 'मुख्य निष्कर्ष (सरल व्याख्या)',
  'Purpose & Legal Context': 'उद्देश्य और कानूनी संदर्भ',
  'Key Elements': 'प्रमुख तत्व',
  'Punishment & Penalties': 'सज़ा और दंड',
  'What Information May Matter': 'क्या जानकारी महत्वपूर्ण हो सकती है',
  'Required / Relevant Documents': 'आवश्यक / प्रासंगिक दस्तावेज़',
  'Official Statutory Legal Text': 'आधिकारिक वैधानिक कानूनी पाठ',
  '(Official text is kept in English to preserve its exact legal wording.)':
      '(सटीक कानूनी शब्दावली बनाए रखने के लिए आधिकारिक पाठ अंग्रेजी में रखा गया है।)',
  'Related Legal Provisions': 'संबंधित कानूनी प्रावधान',
  'Verified from': 'सत्यापित स्रोत:',
  'Official Gazette': 'आधिकारिक राजपत्र',
  'Last updated': 'अंतिम अपडेट',

  // AI Assistant
  'LegalGuide Assistant': 'लीगलगाइड सहायक',
  'Ask about Indian law, sections & your rights': 'भारतीय कानून, धाराओं और अपने अधिकारों के बारे में पूछें',
  'Log in to unlock online AI answers. Offline answers from the LegalGuide library always work.':
      'ऑनलाइन AI उत्तर अनलॉक करने के लिए लॉग इन करें। ऑफ़लाइन उत्तर हमेशा काम करते हैं।',
  'Welcome to LegalGuide!': 'लीगलगाइड में आपका स्वागत है!',
  "When you're online I can answer anything; offline, I can only use the legal data stored in this app.":
      'जब आप ऑनलाइन होते हैं तो मैं कुछ भी उत्तर दे सकता हूँ; ऑफ़लाइन केवल इस ऐप में संग्रहीत डेटा का उपयोग करता हूँ।',
  'Know My Rights': 'अपने अधिकार जानें',
  'Constitutional Rights': 'संवैधानिक अधिकार',
  'Explain a Legal Section': 'कानूनी धारा की व्याख्या करें',
  '🔒 Log in or create an account for answers beyond app content':
      '🔒 ऐप सामग्री से परे उत्तरों के लिए लॉग इन करें या खाता बनाएं',
  '🟠 Offline – Using LegalGuide Knowledge': '🟠 ऑफ़लाइन – लीगलगाइड ज्ञान',
  '🟢 Online': '🟢 ऑनलाइन',
  'Log in or create an account →': 'लॉग इन करें या खाता बनाएं →',
  'Ask a question...': 'प्रश्न पूछें...',

  // Login / signup
  'Enter both a username and password.': 'उपयोगकर्ता नाम और पासवर्ड दोनों दर्ज करें।',
  'Enter a username and password.': 'उपयोगकर्ता नाम और पासवर्ड दर्ज करें।',
  'Logged in': 'लॉग इन हो गया',
  'Welcome back,': 'वापसी पर स्वागत है,',
  'OK': 'ठीक है',
  "Needed only for the AI Assistant's online mode. Browsing and searching legal content never requires an account.":
      'केवल AI सहायक के ऑनलाइन मोड के लिए आवश्यक। ब्राउज़िंग और खोज के लिए खाते की आवश्यकता कभी नहीं होती।',
  'Username': 'यूज़रनेम',
  'Password': 'पासवर्ड',
  "Don't have an account? Sign up": 'खाता नहीं है? साइन अप करें',
  'Account created': 'खाता बनाया गया',
  'Create an account': 'खाता बनाएं',
  "Only used to unlock the AI Assistant's online mode. We don't store your search or chat history against this account.":
      'केवल AI सहायक के ऑनलाइन मोड को अनलॉक करने के लिए उपयोग किया जाता है।',
  'Email (optional)': 'ईमेल (वैकल्पिक)',
  'Sign up': 'साइन अप करें',
  'Already have an account? Log in': 'पहले से खाता है? लॉग इन करें',

  // Category overview / matter detail / explore
  'Topics': 'विषय',
  'Laws & Sections': 'कानून और धाराएं',
  'Explore Laws': 'कानून खोजें',
  'topics': 'विषय',
  'with legal sections': 'कानूनी धाराओं के साथ',
  'content is coming soon — not yet verified.': 'सामग्री जल्द आ रही है — अभी सत्यापित नहीं।',
  'No topics available for this category yet.': 'इस श्रेणी के लिए अभी कोई विषय उपलब्ध नहीं है।',
  'Coming soon': 'जल्द आ रहा है',
  'section': 'धारा',
  'sections': 'धाराएं',
  'legal section': 'कानूनी धारा',
  'legal sections': 'कानूनी धाराएं',
  'linked': 'संबद्ध',
  'Verified legal sections for this topic are not available yet.':
      'इस विषय के लिए सत्यापित कानूनी धाराएं अभी उपलब्ध नहीं हैं।',
  'All': 'सभी',
  'Categories': 'श्रेणियां',
  'Sections': 'धाराएं',
  'Available Provisions': 'उपलब्ध प्रावधान',
  'View related legal sections': 'संबंधित कानूनी धाराएं देखें',
  'Content coming soon — not yet verified': 'सामग्री जल्द आ रही है — अभी सत्यापित नहीं',
  'No matching legal sections found.': 'कोई संबंधित कानूनी धारा नहीं मिली।',

  // Documents
  'Legal Documents & Notice Guides': 'कानूनी दस्तावेज़ और नोटिस गाइड',
  'General guide': 'सामान्य गाइड',
  'What it is': 'यह क्या है',
  "When it's used": 'इसका उपयोग कब होता है',
  'Key parts': 'प्रमुख भाग',
  'Related legal sections': 'संबंधित कानूनी धाराएं',

  // Legal help
  'Could not open dialer for': 'इसके लिए डायलर नहीं खोला जा सका:',
  'Calling is not supported on this device — dial': 'इस डिवाइस पर कॉलिंग समर्थित नहीं है — मैन्युअल रूप से डायल करें:',
  'manually.': 'मैन्युअल रूप से।',

  // Saved screen
  'My Saved': 'सहेजी गई धाराएं',
  'Nothing saved yet': 'अभी कुछ भी सहेजा नहीं गया है',
  'bookmarked': 'बुकमार्क किया गया',
  'No saved sections yet — tap the bookmark icon on any section to save it here.':
      'अभी कोई धारा सहेजी नहीं गई — किसी भी धारा पर बुकमार्क आइकन दबाकर यहाँ सहेजें।',

  // Law list screen
  'No laws found for': 'इसके लिए कोई कानून नहीं मिला:',
  'No sections loaded for this law.': 'इस कानून के लिए कोई धारा लोड नहीं हुई।',

  // About screen
  'LegalGuide helps you look up Indian laws and legal provisions in plain '
          "language, browse offline once synced, and ask an AI assistant questions — "
          "answered either from what's actually stored in the app (offline) or from a "
          "general AI model when you're online.":
      'लीगलगाइड भारतीय कानूनों और कानूनी प्रावधानों को सरल भाषा में देखने, सिंक होने पर ऑफ़लाइन ब्राउज़ करने और AI सहायक से प्रश्न पूछने में आपकी सहायता करता है।',
  'Disclaimer': 'अस्वीकरण',
  'LegalGuide is an educational prototype. Information provided does not '
          'constitute certified legal advice and may not reflect the most current '
          'legal developments. Always consult a qualified legal professional for '
          'advice about your specific situation.':
      'लीगलगाइड एक शैक्षिक प्रोटोटाइप है। प्रदान की गई जानकारी प्रमाणित कानूनी सलाह नहीं है। हमेशा योग्य कानूनी विशेषज्ञ से सलाह लें।',
  'Legal content in this app is sourced from official statutes and cross-verified '
          'against multiple independent legal-reference sources, with the source and last '
          'verification date shown on each section.':
      'इस ऐप की कानूनी सामग्री आधिकारिक कानूनों से ली गई है और एकाधिक कानूनी संदर्भ स्रोतों से सत्यापित है।',
  'Server Connection': 'सर्वर कनेक्शन',
  'Address the app uses for online features (AI Assistant, syncing content). '
          "Update this if your LegalGuide server's address changes, e.g. a new tunnel URL.":
      'ऑनलाइन सुविधाओं (AI सहायक, सामग्री सिंकिंग) के लिए ऐप द्वारा उपयोग किया जाने वाला सर्वर पता।',
  'Save': 'सहेजें',
  'Reset to default': 'डिफ़ॉल्ट पर रीसेट करें',
  'Saved. New requests will use this address.': 'सहेज लिया गया। नए अनुरोध इस पते का उपयोग करेंगे।',
  'Reset to default.': 'डिफ़ॉल्ट पर रीसेट किया गया।',

  // Emergency Guide & Audio Readout (TTS)
  'Emergency Rights Guide': 'आपातकालीन अधिकार गाइड',
  'Emergency\nRights': 'आपातकालीन\nअधिकार',
  'I Need Help Right Now': 'मुझे तुरंत मदद चाहिए',
  'Stay Calm & Know Your Rights': 'शांत रहें और अपने अधिकार जानें',
  'Official Indian statutory protections for on-the-spot legal safety.':
      'मौके पर कानूनी सुरक्षा के लिए आधिकारिक भारतीय वैधानिक संरक्षण।',
  'Select Emergency Scenario:': 'आपातकालीन स्थिति चुनें:',
  'Immediate Rights & Steps:': 'तत्काल अधिकार और कदम:',
  'Quick Action Rules:': 'त्वरित कार्रवाई नियम:',
  'Dial Now': 'कॉल करें',
  'Listen': 'सुनें',
  'Stop': 'रोकें',
  'Listen to Section': 'धारा सुनें',
  'Stop Reading': 'पढ़ना रोकें',
  'Listen Aloud': 'बोलकर सुनें',
  'HELP NOW': 'मदद',
  'Police stops, traffic challans, cyber fraud & women safety rights':
      'पुलिस पूछताछ, ट्रैफिक चालान, साइबर अपराध और महिला सुरक्षा अधिकार',
  'Browse Laws Related to': 'इससे संबंधित कानून देखें:',
  'Special Guides & Acts': 'विशेष गाइड और कानून',
  'Emergency Protections': 'आपातकालीन संरक्षण',
  'Railway Fines & Offences': 'रेलवे जुर्माने और अपराध',
  'No matching legal sections or guides found.': 'कोई कानूनी धारा या गाइड नहीं मिली।',
  'Indian Railway Rules & Fines': 'भारतीय रेलवे नियम और जुर्माने',
  'Penalties, ticketless travel, chain pulling & passenger rights':
      'जुर्माना, बिना टिकट यात्रा, चेन खींचना और यात्री अधिकार',
  'Legal Documents': 'कानूनी दस्तावेज़',
  'Standard legal formats, notices, affidavits & petitions':
      'मानक कानूनी प्रारूप, नोटिस, हलफनामे और याचिकाएं',
  'Need Legal Help': 'कानूनी मदद चाहिए',
  'Free legal aid, emergency helplines & court assistance':
      'मुफ़्त कानूनी सहायता, आपातकालीन हेल्पलाइन और अदालती सहायता',

  // Scenario titles & summaries
  'Police Stop & Detention': 'पुलिस पूछताछ और हिरासत',
  'Immediate legal protections against wrongful arrest, harassment, or unlawful detention.':
      'गलत गिरफ्तारी, उत्पीड़न या अवैध हिरासत के खिलाफ तत्काल कानूनी सुरक्षा।',
  'Traffic Police Stops & Vehicle Check': 'ट्रैफिक पुलिस पूछताछ और वाहन चेकिंग',
  'Know your rights on spot fines, physical document checking, key confiscation, and towing.':
      'मौके पर चालान, भौतिक दस्तावेज़ जांच, चाबी छीनने और टोइंग पर अपने अधिकार जानें।',
  'Cyber Crime & Financial Fraud': 'साइबर अपराध और वित्तीय धोखाधड़ी',
  'Urgent steps for UPI scams, unauthorized transactions, identity theft, and fake FIR threats.':
      'UPI धोखाधड़ी, अनधिकृत लेनदेन, पहचान चोरी और फर्जी FIR धमकियों के लिए तत्काल कदम।',
  'Women Safety & Harassment Protection': 'महिला सुरक्षा और उत्पीड़न से सुरक्षा',
  'Critical legal shields for women: Zero FIR, arrest restrictions, night detention ban, and dignity rights.':
      'महिलाओं के लिए महत्वपूर्ण कानूनी सुरक्षा: ज़ीरो FIR, गिरफ़्तारी प्रतिबंध और गरिमा के अधिकार।',

  // Categories
  'Criminal Law': 'आपराधिक कानून',
  'Constitutional Law': 'संवैधानिक कानून',
  'Family Law': 'पारिवारिक कानून',
  'Property Law': 'संपत्ति कानून',
  'Consumer Law': 'उपभोक्ता कानून',
  'Motor Vehicle Law': 'मोटर वाहन कानून',
  "Women's Rights": 'महिला अधिकार',
  'Child Protection': 'बाल संरक्षण',
  'Labour & Employment': 'श्रम और रोजगार',
  'Cyber Law': 'साइबर कानून',
  'Environment Law': 'पर्यावरण कानून',
  'Right to Information': 'सूचना का अधिकार (RTI)',

  // Matters
  'Arrest': 'गिरफ्तारी',
  'Theft & Snatching': 'चोरी और छिनैती',
  'Cheating & Fraud': 'धोखाधड़ी और कपट',
  'Robbery': 'डकैती और लूट',
  'Assault & Hurt': 'हमला और चोट',
  'Criminal Intimidation': 'आपराधिक धमकी',
  'Defamation': 'मानहानि',
  'Murder': 'हत्या',
  'Bail': 'जमानत',
  'FIR': 'एफआईआर (FIR)',
  'Criminal complaint': 'आपराधिक शिकायत',
  'Search and seizure': 'तलाशी और जब्ती',
  'Investigation': 'जांच-पड़ताल',
  'Evidence': 'सबूत',
  'Summons': 'समन',
  'Warrant': 'वारंट',
  'Trial': 'मुकदमा',
  'Anticipatory bail': 'अग्रिम जमानत',
  'Bailable vs non-bailable offences': 'जमानती बनाम गैर-जमानती अपराध',
  'Cognizable vs non-cognizable offences': 'संज्ञेय बनाम असंज्ञेय अपराध',
  'Appeal against conviction': 'दोषसिद्धि के खिलाफ अपील',
  'Compounding of offences': 'अपराधों का समझौता',
  'Right to Life & Liberty': 'जीवन और स्वतंत्रता का अधिकार',
  'Right to Legal Counsel': 'वकील पाने का अधिकार',

  // Railway UI & Fines
  'Railway Rules & Fines': 'रेलवे नियम और जुर्माना',
  'Search fines, chain, ticket, rules...': 'जुर्माना, चेन, टिकट, नियम खोजें...',
  'Fines & Penalties': 'जुर्माना और दंड',
  "Do's & Don'ts": 'क्या करें और क्या न करें',
  'Bare Act Sections': 'कानून की धाराएं',
  'Helplines & Rights': 'हेल्पलाइन और अधिकार',
  'No matching penalties found': 'कोई मेल खाता जुर्माना नहीं मिला',
  'Travelling Without Valid Ticket': 'बिना वैध टिकट यात्रा',
  'Alarm Chain Pulling Without Reasonable Cause': 'बिना उचित कारण चेन खींचना',
  'Smoking in Railway Compartments': 'रेलवे डिब्बों में धूम्रपान',
  'Drunkenness or Creating Nuisance': 'शराब पीना या उपद्रव मचाना',
  'Trespassing Railway Track': 'रेलवे ट्रैक पार करना/अनाधिकृत प्रवेश',
  'Roof / Footboard Travelling': 'छत या पायदान पर यात्रा',
  'Carrying Dangerous / Explosive Goods': 'खतरनाक या विस्फोटक सामग्री ले जाना',
  'Unauthorized Hawking or Vending': 'अनाधिकृत फेरी या सामान बेचना',
  'Defacing / Damaging Railway Property': 'रेलवे संपत्ति को नुकसान पहुंचाना',
  'Obstructing Railway Servant on Duty': 'रेलवे कर्मचारी के काम में बाधा डालना',
  'Step': 'कदम',
  // Voice Search
  'Voice Search': 'वॉयस सर्च',
  'Speak to search': 'बोलकर खोजें',
  'Speak your question': 'अपना प्रश्न बोलें',
  'Use Text': 'इस टेक्स्ट का उपयोग करें',
  'Done': 'हो गया',
  'Could not start microphone. Check permissions.':
      'माइक्रोफ़ोन प्रारंभ नहीं हो सका। अनुमतियाँ जांचें।',
  'Say something like "railway rules", "theft", "FIR"...':
      'जैसे "रेलवे नियम", "चोरी", "एफआईआर" बोलिए...',
  'Ask any legal question in Telugu, Hindi, or English...':
      'तेलुगु, हिन्दी या अंग्रेज़ी में कोई भी कानूनी सवाल पूछें...',
  'Say law name, section number, or topic...':
      'कानून का नाम, धारा संख्या या विषय बोलें...',
  'Search fines, rules, chain, ticket...':
      'जुर्माना, नियम, चेन, टिकट खोजें...',
  'Traffic Rules & Fines': 'ट्रैफिक नियम एवं चालान',
  'Traffic Rules & Driver Rights': 'ट्रैफिक नियम एवं नागरिक अधिकार',
  'MV Act 2019 fines, e-challan disputes & citizen driver protections':
      'मोटर वाहन अधिनियम 2019 चालान, ई-चालान और ड्राइवर अधिकार',
  'Interactive Document Generator': 'इंटरएक्टिव दस्तावेज़ जनरेटर',
  'Fill, customize, and export ready-to-use RTI, Police Complaints, & Legal Notices.':
      'RTI, पुलिस शिकायतें और कानूनी नोटिस तुरंत तैयार व कॉपी करें।',
  'Draft Now': 'तैयार करें',
  'Legal Document Generator': 'कानूनी दस्तावेज़ जनरेटर',
  'Instant Draft, Copy & Share': 'तुरंत ड्राफ्ट, कॉपी और साझा करें',
  'Fines & Offenses': 'जुर्माना और अपराध',
  'Driver Rights': 'ड्राइवर के अधिकार',
  'E-Challan Guide': 'ई-चालान गाइड',
  "What's New in v1.1.0": 'v1.1.0 में क्या नया है',
  'Traffic Rules & Fines (MV Act)': 'ट्रैफिक नियम एवं चालान (MV Act)',
  'Full Motor Vehicles Act penalty table, driver rights, and step-by-step e-challan dispute guide.':
      'मोटर वाहन अधिनियम जुर्माना तालिका, नागरिक अधिकार और ई-चालान विवाद गाइड।',
  'Draft formal Police Complaints, RTI Applications, and Legal Notices with instant copy & export.':
      'पुलिस शिकायत, आरटीआई आवेदन और कानूनी नोटिस आसानी से तैयार करें।',
  'Audio Narration (TTS) & Voice Search': 'ऑडियो वाचन (TTS) और वॉइस सर्च',
  'Listen aloud to legal sections, railway rules, and emergency guides in your preferred language.':
      'कानूनी धाराओं और नियमों को अपनी भाषा में सुनें।',
  'Cloud Bookmark Sync': 'क्लाउड बुकमार्क सिंक',
  'Seamlessly sync your saved laws and sections across devices when logged into your account.':
      'लॉगिन करने पर अपने सहेजे गए अनुभागों को सभी डिवाइसों में सिंक करें।',
  'Citizen Rights & Travel': 'नागरिक अधिकार और यात्रा',
  'Citizen Rights & Travel Guide': 'नागरिक अधिकार और यात्रा गाइड',
  'Emergency legal protection, police stops & Indian Railway rules':
      'आपातकालीन कानूनी सुरक्षा, पुलिस पूछताछ और रेलवे नियम',
  'Emergency Rights': 'आपातकालीन अधिकार',
  'Railway Rules': 'रेलवे नियम',
  'SAFETY & TRANSIT': 'सुरक्षा और यात्रा',
  'Emergency Helplines': 'आपातकालीन हेल्पलाइन',
  'National Emergency Number': 'राष्ट्रीय आपातकालीन नंबर',
  'Indian Railways (RailMadad)': 'भारतीय रेलवे (रेल मदद)',
  'Cyber Financial Fraud': 'साइबर वित्तीय धोखाधड़ी',
  'Women Helpline': 'महिला हेल्पलाइन',
  'Child Helpline': 'चाइल्ड हेल्पलाइन',
  'National Highways Emergency': 'राष्ट्रीय राजमार्ग आपातकालीन नंबर',
};
