import '../services/locale_service.dart';

/// Translates a piece of app UI text to Telugu if Telugu is selected and a
/// translation exists; otherwise returns the English text unchanged. The
/// English string itself is the lookup key, so call sites don't need
/// separate key constants.
String tr(String text) {
  if (!LocaleService.isTelugu) return text;
  return _te[text] ?? text;
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
};
