import json
import os
import re
from datetime import date
from django.core.management.base import BaseCommand
from django.utils import timezone
from laws.models import Category, Law, LegalSection, DatabaseSyncInfo


VERIFIED_DATE = date(2026, 10, 10)

# ==============================================================================
# AUDIT & METADATA ENRICHMENT FOR EXISTING LAWS (16 Laws)
# ==============================================================================
EXISTING_LAWS_METADATA = {
    2: {
        "name": "Bharatiya Nyaya Sanhita, 2023",
        "short_name": "BNS 2023",
        "category_id": 1,
        "year": 2023,
        "act_number": "Act No. 45 of 2023",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/21081",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "భారతీయ న్యాయ సంహిత, 2023",
        "short_name_te": "BNS 2023",
        "description_te": "భారత ప్రధాన క్రిమినల్ కోడ్, 1 జూలై 2024 నుండి అమలులోకి వచ్చింది, ఇండియన్ పీనల్ కోడ్, 1860 స్థానంలో వచ్చింది.",
        "name_hi": "भारतीय न्याय संहिता, 2023",
        "short_name_hi": "बीएनएस 2023",
        "description_hi": "भारत की प्रमुख आपराधिक संहिता, 1 जुलाई 2024 से लागू, भारतीय दंड संहिता, 1860 के स्थान पर।",
        "description": "India's principal criminal code, in force from 1 July 2024, replacing the Indian Penal Code, 1860.",
    },
    3: {
        "name": "Constitution of India",
        "short_name": "COI 1950",
        "category_id": 2,
        "year": 1950,
        "act_number": "Adopted 26 Nov 1949, Enforced 26 Jan 1950",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/15240",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "భారత రాజ్యాంగం",
        "short_name_te": "COI 1950",
        "description_te": "పౌరుల ప్రాథమిక హక్కులు మరియు ప్రభుత్వ చట్రాన్ని నిర్దేశించే భారతదేశ అత్యున్నత చట్టం.",
        "name_hi": "भारत का संविधान",
        "short_name_hi": "संविधान 1950",
        "description_hi": "भारत का सर्वोच्च कानून, जो नागरिकों के मौलिक अधिकारों और शासन व्यवस्था की रूपरेखा तय करता है।",
        "description": "The supreme law of India, laying down the fundamental rights of citizens and the framework of government.",
    },
    4: {
        "name": "Arrest & Detention Rights",
        "short_name": "Rights",
        "category_id": 3,
        "year": 2023,
        "act_number": "Statutory Compilation (BNSS & COI)",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/21082",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "అరెస్టు & నిర్బంధ హక్కులు",
        "short_name_te": "హక్కులు",
        "description_te": "భారతీయ నాగరిక్ సురక్ష సంహిత మరియు రాజ్యాంగం నుండి తీసుకోబడిన పౌరుల అరెస్టు హక్కులు.",
        "name_hi": "गिरफ्तारी और हिरासत अधिकार",
        "short_name_hi": "अधिकार",
        "description_hi": "भारतीय नागरिक सुरक्षा संहिता और संविधान से संकलित नागरिकों के वास्तविक गिरफ्तारी अधिकार।",
        "description": "An app-curated collection of real arrest/detention-rights provisions drawn from the Bharatiya Nagarik Suraksha Sanhita, 2023 and the Constitution of India.",
    },
    5: {
        "name": "Information Technology Act, 2000",
        "short_name": "IT Act",
        "category_id": 11,
        "year": 2000,
        "act_number": "Act No. 21 of 2000",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1999",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "సమాచార సాంకేతిక చట్టం, 2000",
        "short_name_te": "IT చట్టం",
        "description_te": "డిజిటల్ వాణిజ్యం, సైబర్ నేరాలు మరియు ఎలక్ట్రానిక్ సంతకాలను నియంత్రించే భారత ప్రధాన చట్టం.",
        "name_hi": "सूचना प्रौद्योगिकी अधिनियम, 2000",
        "short_name_hi": "आईटी एक्ट",
        "description_hi": "डिजिटल वाणिज्य, साइबर अपराधों और इलेक्ट्रॉनिक हस्ताक्षरों को नियंत्रित करने वाला भारत का प्रमुख कानून।",
        "description": "India's principal law governing digital commerce, cyber offences, and electronic signatures.",
    },
    6: {
        "name": "Motor Vehicles Act, 1988 (as amended 2019)",
        "short_name": "MV Act",
        "category_id": 7,
        "year": 1988,
        "act_number": "Act No. 59 of 1988",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1798",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "మోటారు వాహనాల చట్టం, 1988 (సవరించిన 2019)",
        "short_name_te": "MV చట్టం",
        "description_te": "లైసెన్సింగ్, వాహన భద్రత, ట్రాఫిక్ నేరాలు మరియు భారత రహదారులపై జరిమానాలను నియంత్రిస్తుంది.",
        "name_hi": "मोटर वाहन अधिनियम, 1988 (संशोधित 2019)",
        "short_name_hi": "एमवी एक्ट",
        "description_hi": "सड़क लाइसेंसिंग, वाहन सुरक्षा, यातायात अपराधों और भारतीय सड़कों पर जुर्माने को नियंत्रित करता है।",
        "description": "Governs licensing, vehicle safety, traffic offences, and penalties on Indian roads.",
    },
    7: {
        "name": "Consumer Protection Act, 2019",
        "short_name": "CPA 2019",
        "category_id": 6,
        "year": 2019,
        "act_number": "Act No. 35 of 2019",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/15256",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "వినియోగదారుల రక్షణ చట్టం, 2019",
        "short_name_te": "CPA 2019",
        "description_te": "దోషపూరిత వస్తువులు మరియు అన్యాయ వ్యాపార పద్ధతులకు వ్యతిరేకంగా వినియోగదారుల కమిషన్లను ఏర్పాటు చేస్తుంది.",
        "name_hi": "उपभोक्ता संरक्षण अधिनियम, 2019",
        "short_name_hi": "उपभोक्ता संरक्षण 2019",
        "description_hi": "दोषपूर्ण वस्तुओं और अनुचित व्यापार प्रथाओं के खिलाफ निवारण के लिए उपभोक्ता आयोग स्थापित करता है।",
        "description": "Establishes consumer commissions and procedures for redressal against defective goods and unfair trade practices.",
    },
    8: {
        "name": "Hindu Marriage Act, 1955",
        "short_name": "HMA 1955",
        "category_id": 4,
        "year": 1955,
        "act_number": "Act No. 25 of 1955",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1560",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "హిందూ వివాహ చట్టం, 1955",
        "short_name_te": "HMA 1955",
        "description_te": "హిందువులు, బౌద్ధులు, జైనులు మరియు సిక్కుల వివాహం, విడాకులు మరియు సంబంధిత విషయాలను నియంత్రిస్తుంది.",
        "name_hi": "हिन्दू विवाह अधिनियम, 1955",
        "short_name_hi": "एचएमए 1955",
        "description_hi": "हिन्दुओं, बौद्धों, जैनियों और सिखों के लिए विवाह, तलाक और संबंधित मामलों को नियंत्रित करता है।",
        "description": "Governs marriage, divorce, and related matters for Hindus, Buddhists, Jains, and Sikhs in India.",
    },
    9: {
        "name": "Protection of Women from Domestic Violence Act, 2005",
        "short_name": "DV Act 2005",
        "category_id": 4,
        "year": 2005,
        "act_number": "Act No. 43 of 2005",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2021",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "గృహ హింస నుండి మహిళల రక్షణ చట్టం, 2005",
        "short_name_te": "DV చట్టం 2005",
        "description_te": "గృహ హింసకు వ్యతిరేకంగా రక్షణ, నివాసం మరియు ద్రవ్య ఉపశమనం కోసం వేగవంతమైన సివిల్ పరిష్కారాన్ని అందిస్తుంది.",
        "name_hi": "घरेलू हिंसा से महिलाओं का संरक्षण अधिनियम, 2005",
        "short_name_hi": "घरेलू हिंसा एक्ट",
        "description_hi": "घरेलू हिंसा के खिलाफ सुरक्षा, निवास और वित्तीय राहत के लिए त्वरित दीवानी उपचार प्रदान करता है।",
        "description": "Provides a fast civil remedy — protection, residence, custody, and monetary relief orders — against domestic violence.",
    },
    10: {
        "name": "Bharatiya Nagarik Suraksha Sanhita, 2023",
        "short_name": "BNSS 2023",
        "category_id": 1,  # Primary category is Criminal Law & Procedure
        "year": 2023,
        "act_number": "Act No. 46 of 2023",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/21082",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "భారతీయ నాగరిక్ సురక్ష సంహిత, 2023",
        "short_name_te": "BNSS 2023",
        "description_te": "భారత క్రిమినల్ ప్రొసీజర్ కోడ్, 1 జూలై 2024 నుండి అమలులో ఉంది, CrPC 1973 స్థానంలో వచ్చింది.",
        "name_hi": "भारतीय नागरिक सुरक्षा संहिता, 2023",
        "short_name_hi": "बीएनएसएस 2023",
        "description_hi": "भारत की आपराधिक प्रक्रिया संहिता, 1 जुलाई 2024 से लागू, सीआरपीसी 1973 के स्थान पर।",
        "description": "India's code of criminal procedure in force from 1 July 2024, replacing the Code of Criminal Procedure, 1973.",
    },
    11: {
        "name": "Transfer of Property Act, 1882",
        "short_name": "TPA 1882",
        "category_id": 5,
        "year": 1882,
        "act_number": "Act No. 4 of 1882",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2338",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "ఆస్తి బదిలీ చట్టం, 1882",
        "short_name_te": "TPA 1882",
        "description_te": "అమ్మకం, బహుమతి మరియు లీజుతో సహా వ్యక్తుల మధ్య ఆస్తి యాజమాన్యం ఎలా బదిలీ చేయబడుతుందో నియంత్రిస్తుంది.",
        "name_hi": "संपत्ति अंतरण अधिनियम, 1882",
        "short_name_hi": "टीपीए 1882",
        "description_hi": "जीवित व्यक्तियों के बीच संपत्ति के हस्तांतरण (बिक्री, उपहार, पट्टा आदि) को नियंत्रित करता है।",
        "description": "Governs how ownership of property is transferred between living persons, including sale, gift, and lease.",
    },
    12: {
        "name": "Registration Act, 1908",
        "short_name": "Registration Act 1908",
        "category_id": 5,
        "year": 1908,
        "act_number": "Act No. 16 of 1908",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2320",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "రిజిస్ట్రేషన్ చట్టం, 1908",
        "short_name_te": "రిజిస్ట్రేషన్ చట్టం",
        "description_te": "చట్టబద్ధంగా చెల్లుబాటు కావడానికి ఏ ఆస్తి పత్రాలను సబ్-రిజిస్ట్రార్ వద్ద నమోదు చేయాలో నిర్దేశిస్తుంది.",
        "name_hi": "पंजीकरण अधिनियम, 1908",
        "short_name_hi": "पंजीकरण एक्ट",
        "description_hi": "वैध होने के लिए किन संपत्ति दस्तावेजों को सब-रजिस्ट्रार के पास पंजीकृत कराना अनिवार्य है, यह निर्दिष्ट करता है।",
        "description": "Specifies which property-related documents must be registered with the Sub-Registrar to be legally valid.",
    },
    13: {
        "name": "Sexual Harassment of Women at Workplace (Prevention, Prohibition and Redressal) Act, 2013",
        "short_name": "POSH Act 2013",
        "category_id": 8,
        "year": 2013,
        "act_number": "Act No. 14 of 2013",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2104",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "కార్యాలయాల్లో మహిళలపై లైంగిక వేధింపుల నిరోధక చట్టం, 2013",
        "short_name_te": "POSH చట్టం 2013",
        "description_te": "మహిళలు లైంగిక వేధింపులపై ఫిర్యాదు చేసి పరిష్కారం పొందేందుకు కార్యాలయాల్లో కమిటీల ఏర్పాటును తప్పనిసరి చేస్తుంది.",
        "name_hi": "कार्यस्थल पर महिलाओं का यौन उत्पीड़न (रोकथाम, निषेध और निवारण) अधिनियम, 2013",
        "short_name_hi": "पॉश एक्ट 2013",
        "description_hi": "कार्यस्थल पर यौन उत्पीड़न की रिपोर्ट करने और निवारण के लिए आंतरिक समिति तंत्र अनिवार्य करता है।",
        "description": "Requires workplaces to have a mechanism for women to report and seek redress for sexual harassment.",
    },
    14: {
        "name": "Dowry Prohibition Act, 1961",
        "short_name": "Dowry Act 1961",
        "category_id": 8,
        "year": 1961,
        "act_number": "Act No. 28 of 1961",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1518",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "వరకట్న నిషేధ చట్టం, 1961",
        "short_name_te": "వరకట్న చట్టం 1961",
        "description_te": "వరకట్నం ఇవ్వడం, తీసుకోవడం లేదా డిమాండ్ చేయడాన్ని నేరంగా పరిగణిస్తుంది.",
        "name_hi": "दहेज प्रतिषेध अधिनियम, 1961",
        "short_name_hi": "दहेज निषेध कानून",
        "description_hi": "दहेज देने, लेने या मांगने को आपराधिक अपराध घोषित करता है।",
        "description": "Criminalizes the giving, taking, or demanding of dowry.",
    },
    15: {
        "name": "Protection of Children from Sexual Offences Act, 2012",
        "short_name": "POCSO 2012",
        "category_id": 9,
        "year": 2012,
        "act_number": "Act No. 32 of 2012",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2079",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "లైంగిక నేరాల నుండి పిల్లల రక్షణ చట్టం, 2012",
        "short_name_te": "POCSO 2012",
        "description_te": "పిల్లలపై లైంగిక వేధింపులు మరియు దోపిడీని అరికట్టే ప్రత్యేక చట్టం, తప్పనిసరి రిపోర్టింగ్ బాధ్యతలతో.",
        "name_hi": "लैंगिक अपराधों से बालकों का संरक्षण अधिनियम, 2012",
        "short_name_hi": "पॉक्सो 2012",
        "description_hi": "बच्चों के यौन शोषण और उत्पीड़न से निपटने के लिए भारत का विशेष कानून, अनिवार्य रिपोर्टिंग प्रावधानों के साथ।",
        "description": "India's special law addressing sexual abuse and exploitation of children, with mandatory reporting obligations.",
    },
    16: {
        "name": "Code on Social Security, 2020",
        "short_name": "CSS 2020",
        "category_id": 10,
        "year": 2020,
        "act_number": "Act No. 36 of 2020",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/15707",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "సామాజిక భద్రతా కోడ్, 2020",
        "short_name_te": "CSS 2020",
        "description_te": "ప్రసూతి ప్రయోజనం, ప్రావిడెంట్ ఫండ్ మరియు గ్రాట్యుటీతో సహా సామాజిక భద్రతా చట్టాలను ఏకీకృతం చేస్తుంది.",
        "name_hi": "सामाजिक सुरक्षा संहिता, 2020",
        "short_name_hi": "सीएसएस 2020",
        "description_hi": "मातृत्व लाभ, भविष्य निधि (PF) और ग्रेच्युटी सहित सामाजिक सुरक्षा कानूनों को समेकित करता है।",
        "description": "Consolidates social security laws including maternity benefit, provident fund, and gratuity; in force from 21 November 2025.",
    },
    17: {
        "name": "Industrial Relations Code, 2020",
        "short_name": "IR Code 2020",
        "category_id": 10,
        "year": 2020,
        "act_number": "Act No. 35 of 2020",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/15706",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "పారిశ్రామిక సంబంధాల కోడ్, 2020",
        "short_name_te": "IR కోడ్ 2020",
        "description_te": "ట్రేడ్ యూనియన్లు, పారిశ్రామిక వివాదాలు మరియు ఉపాధి పరిస్థితులపై చట్టాలను ఏకీకృతం చేస్తుంది.",
        "name_hi": "औद्योगिक संबंध संहिता, 2020",
        "short_name_hi": "आईआर कोड 2020",
        "description_hi": "ट्रेड यूनियनों, औद्योगिक विवादों और रोजगार की शर्तों से जुड़े कानूनों को समेकित करता है।",
        "description": "Consolidates laws on trade unions, industrial disputes, and conditions of employment; in force from 21 November 2025.",
    },
}

# ==============================================================================
# MISSING IMPORTANT ACTS TO ADD (Foundational Indian Citizen Legislation)
# ==============================================================================
NEW_IMPORTANT_LAWS = [
    {
        "id": 18,
        "name": "Bharatiya Sakshya Adhiniyam, 2023",
        "short_name": "BSA 2023",
        "category_id": 1,  # Criminal Law
        "year": 2023,
        "act_number": "Act No. 47 of 2023",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/21083",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "భారతీయ సాక్ష్య అధినియం, 2023",
        "short_name_te": "BSA 2023",
        "description_te": "భారత సాక్ష్య చట్టం, 1 జూలై 2024 నుండి అమలులోకి వచ్చింది, ఇండియన్ ఎవిడెన్స్ యాక్ట్ 1872 స్థానంలో వచ్చింది.",
        "name_hi": "भारतीय साक्ष्य अधिनियम, 2023",
        "short_name_hi": "बीएसए 2023",
        "description_hi": "भारत का साक्ष्य कानून, 1 जुलाई 2024 से लागू, भारतीय साक्ष्य अधिनियम 1872 के स्थान पर।",
        "description": "India's law governing evidence and electronic records in judicial proceedings, in force from 1 July 2024, replacing the Indian Evidence Act, 1872.",
    },
    {
        "id": 19,
        "name": "Prevention of Corruption Act, 1988",
        "short_name": "PCA 1988",
        "category_id": 1,  # Criminal Law
        "year": 1988,
        "act_number": "Act No. 49 of 1988",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1922",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "అవినీతి నిరోధక చట్టం, 1988",
        "short_name_te": "PCA 1988",
        "description_te": "ప్రభుత్వ ఉద్యోగులు లంచం తీసుకోవడం, డిమాండ్ చేయడం మరియు అవినీతిని ఎదుర్కొనే చట్టం.",
        "name_hi": "भ्रष्टाचार निवारण अधिनियम, 1988",
        "short_name_hi": "पीसीए 1988",
        "description_hi": "सरकारी कर्मचारियों द्वारा रिश्वतखोरी और भ्रष्टाचार से निपटने के लिए भारत का केंद्रीय कानून।",
        "description": "Central legislation to combat bribery, abuse of public office, and criminal misconduct by public servants in India.",
    },
    {
        "id": 20,
        "name": "Narcotic Drugs and Psychotropic Substances Act, 1985",
        "short_name": "NDPS Act 1985",
        "category_id": 1,  # Criminal Law
        "year": 1985,
        "act_number": "Act No. 61 of 1985",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1791",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "మాదకద్రవ్యాల నిరోధక చట్టం, 1985",
        "short_name_te": "NDPS చట్టం",
        "description_te": "మాదకద్రవ్యాల ఉత్పత్తి, రవాణా, వినియోగం నియంత్రణ మరియు పౌరుల సోదా రక్షణలు.",
        "name_hi": "स्वापक औषधि और मनःप्रभावी पदार्थ अधिनियम, 1985",
        "short_name_hi": "एनडीपीएस एक्ट",
        "description_hi": "नशीले पदार्थों के निर्माण, परिवहन और उपभोग पर रोक तथा तलाशी के दौरान नागरिक सुरक्षा उपाय।",
        "description": "Governs offences relating to narcotic drugs and psychotropic substances, prescribing strict procedural safeguards for searches and personal liberty.",
    },
    {
        "id": 21,
        "name": "Digital Personal Data Protection Act, 2023",
        "short_name": "DPDP Act 2023",
        "category_id": 11,  # Cyber Law
        "year": 2023,
        "act_number": "Act No. 22 of 2023",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/20884",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "డిజిటల్ వ్యక్తిగత డేటా రక్షణ చట్టం, 2023",
        "short_name_te": "DPDP చట్టం 2023",
        "description_te": "డిజిటల్ వ్యక్తిగత డేటా ప్రాసెసింగ్, పౌరుల గోప్యతా హక్కులు మరియు ఫిర్యాదుల పరిష్కారం.",
        "name_hi": "डिजिटल व्यक्तिगत डेटा संरक्षण अधिनियम, 2023",
        "short_name_hi": "डीपीडीपी एक्ट 2023",
        "description_hi": "डिजिटल व्यक्तिगत डेटा के प्रसंस्करण, नागरिकों के डेटा अधिकारों और सहमति आवश्यकताओं को नियंत्रित करता है।",
        "description": "India's comprehensive personal data privacy legislation establishing rights of Data Principals and obligations of Data Fiduciaries.",
    },
    {
        "id": 22,
        "name": "Right to Information Act, 2005",
        "short_name": "RTI Act 2005",
        "category_id": 6,  # Consumer Law & Citizen Rights
        "year": 2005,
        "act_number": "Act No. 22 of 2005",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2065",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "సమాచార హక్కు చట్టం, 2005",
        "short_name_te": "RTI చట్టం 2005",
        "description_te": "ప్రభుత్వ సంస్థల నుండి పౌరులు సమాచారం పొందేందుకు వీలు కల్పించే చట్టం.",
        "name_hi": "सूचना का अधिकार अधिनियम, 2005",
        "short_name_hi": "आरटीआई एक्ट 2005",
        "description_hi": "सरकारी विभागों और लोक प्राधिकरणों से जानकारी प्राप्त करने का नागरिकों का वैधानिक अधिकार।",
        "description": "Empowers Indian citizens to secure access to information under the control of public authorities to promote transparency and accountability.",
    },
    {
        "id": 23,
        "name": "Legal Metrology Act, 2009",
        "short_name": "Legal Metrology 2009",
        "category_id": 6,  # Consumer Law
        "year": 2009,
        "act_number": "Act No. 1 of 2010",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2070",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "లీగల్ మెట్రాలజీ చట్టం, 2009",
        "short_name_te": "లీగల్ మెట్రాలజీ",
        "description_te": "తూనికలు, కొలతలు, MRP కంటే ఎక్కువ వసూలు చేయడంపై నిషేధం మరియు ప్యాకేజ్డ్ వస్తువుల నిబంధనలు.",
        "name_hi": "विधिक मापविज्ञान अधिनियम, 2009",
        "short_name_hi": "विधिक मापविज्ञान 2009",
        "description_hi": "बाजार में वजन, माप, एमआरपी से अधिक वसूली पर रोक और पैकेज्ड वस्तुओं के लिए नियम।",
        "description": "Regulates standards of weights, measures, mandatory consumer declarations on pre-packaged commodities, and prohibits charging above Maximum Retail Price (MRP).",
    },
    {
        "id": 24,
        "name": "Food Safety and Standards Act, 2006",
        "short_name": "FSSAI Act 2006",
        "category_id": 6,  # Consumer Law
        "year": 2006,
        "act_number": "Act No. 34 of 2006",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2048",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "ఆహార భద్రత మరియు ప్రమాణాల చట్టం, 2006",
        "short_name_te": "FSSAI చట్టం",
        "description_te": "కల్తీ ఆహారం, నాణ్యతా ప్రమాణాలు మరియు వినియోగదారుల ఆరోగ్య రక్షణ.",
        "name_hi": "खाद्य सुरक्षा और मानक अधिनियम, 2006",
        "short_name_hi": "एफएसएसएआई कानून",
        "description_hi": "सुरक्षित और पौष्टिक भोजन की उपलब्धता, मिलावट पर रोक और खाद्य गुणवत्ता मानक।",
        "description": "Consolidates laws relating to food safety, laying down science-based standards for articles of food and regulating manufacturing and distribution.",
    },
    {
        "id": 25,
        "name": "Juvenile Justice (Care and Protection of Children) Act, 2015",
        "short_name": "JJ Act 2015",
        "category_id": 9,  # Child Protection
        "year": 2015,
        "act_number": "Act No. 2 of 2016",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2148",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "జువెనైల్ జస్టిస్ (పిల్లల సంరక్షణ మరియు రక్షణ) చట్టం, 2015",
        "short_name_te": "JJ చట్టం 2015",
        "description_te": "సంరక్షణ అవసరమైన పిల్లల రక్షణ, గుర్తింపు గోప్యత మరియు బాలల న్యాయం.",
        "name_hi": "किशोर न्याय (बालकों की देखरेख और संरक्षण) अधिनियम, 2015",
        "short_name_hi": "जेजे एक्ट 2015",
        "description_hi": "देखरेख और संरक्षण के जरूरतमंद बच्चों की सुरक्षा, पहचान की गोपनीयता और किशोर न्याय।",
        "description": "Comprehensive law governing children in conflict with law and children in need of care and protection, mandating privacy and rehabilitation.",
    },
    {
        "id": 26,
        "name": "Child and Adolescent Labour (Prohibition and Regulation) Act, 1986",
        "short_name": "Child Labour Act 1986",
        "category_id": 9,  # Child Protection
        "year": 1986,
        "act_number": "Act No. 61 of 1986",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1806",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "బాల & కౌమార కార్మిక (నిషేధం మరియు నియంత్రణ) చట్టం, 1986",
        "short_name_te": "బాల కార్మిక చట్టం 1986",
        "description_te": "14 సంవత్సరాల లోపు పిల్లలను పనిలో పెట్టుకోవడంపై సంపూర్ణ నిషేధం.",
        "name_hi": "बाल और किशोर श्रम (प्रतिषेध और विनियमन) अधिनियम, 1986",
        "short_name_hi": "बाल श्रम निषेध अधिनियम",
        "description_hi": "14 वर्ष से कम आयु के बच्चों को किसी भी व्यवसाय में नियोजित करने पर पूर्ण प्रतिबंध।",
        "description": "Prohibits the engagement of children below 14 years in all occupations and regulates conditions of work of adolescents in non-hazardous occupations.",
    },
    {
        "id": 27,
        "name": "Right of Children to Free and Compulsory Education Act, 2009",
        "short_name": "RTE Act 2009",
        "category_id": 9,  # Child Protection
        "year": 2009,
        "act_number": "Act No. 35 of 2009",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2085",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "పిల్లల ఉచిత మరియు నిర్బంధ విద్యా హక్కు చట్టం, 2009",
        "short_name_te": "RTE చట్టం 2009",
        "description_te": "6 నుండి 14 సంవత్సరాల లోపు పిల్లలందరికీ ఉచిత మరియు నిర్బంధ ప్రాథమిక విద్య హక్కు.",
        "name_hi": "निःशुल्क और अनिवार्य बाल शिक्षा का अधिकार अधिनियम, 2009",
        "short_name_hi": "आरटीई एक्ट 2009",
        "description_hi": "6 से 14 वर्ष के प्रत्येक बच्चे के लिए निःशुल्क और अनिवार्य प्रारंभिक शिक्षा का अधिकार।",
        "description": "Gives statutory effect to Article 21A of the Constitution, guaranteeing free and compulsory elementary education to every child aged 6 to 14.",
    },
    {
        "id": 28,
        "name": "Special Marriage Act, 1954",
        "short_name": "SMA 1954",
        "category_id": 4,  # Family Law
        "year": 1954,
        "act_number": "Act No. 43 of 1954",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1547",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "ప్రత్యేక వివాహ చట్టం, 1954",
        "short_name_te": "SMA 1954",
        "description_te": "మతం మారకుండా సివిల్ వివాహం చేసుకునేందుకు భారత పౌరులకు చట్టపరమైన నిబంధనలు.",
        "name_hi": "विशेष विवाह अधिनियम, 1954",
        "short_name_hi": "एसएमए 1954",
        "description_hi": "धर्म परिवर्तन के बिना किसी भी धर्म या जाति के नागरिकों के बीच सिविल विवाह की कानूनी रूपरेखा।",
        "description": "Provides a special form of civil marriage for people of India irrespective of the religion or faith which either party may profess.",
    },
    {
        "id": 29,
        "name": "Hindu Succession Act, 1956",
        "short_name": "HSA 1956",
        "category_id": 4,  # Family Law & Succession
        "year": 1956,
        "act_number": "Act No. 30 of 1956",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1572",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "హిందూ వారసత్వ చట్టం, 1956",
        "short_name_te": "HSA 1956",
        "description_te": "ఆస్తి వారసత్వ హక్కులు మరియు కుమార్తెలకు కుమారులతో సమానంగా పూర్వీకుల ఆస్తి హక్కులు.",
        "name_hi": "हिन्दू उत्तराधिकार अधिनियम, 1956",
        "short_name_hi": "एचएसए 1956",
        "description_hi": "संपत्ति उत्तराधिकार और बेटियों को बेटों के समान पैतृक संपत्ति में जन्मजात सहदायिक अधिकार।",
        "description": "Amends and codifies the law relating to intestate succession among Hindus, establishing equal coparcenary rights for daughters by birth.",
    },
    {
        "id": 30,
        "name": "Maintenance and Welfare of Parents and Senior Citizens Act, 2007",
        "short_name": "Senior Citizens Act 2007",
        "category_id": 4,  # Family Law
        "year": 2007,
        "act_number": "Act No. 56 of 2007",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2056",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "తల్లిదండ్రులు మరియు వయోవృద్ధుల సంరక్షణ చట్టం, 2007",
        "short_name_te": "సీనియర్ సిటిజన్స్ చట్టం 2007",
        "description_te": "పిల్లల నుండి నెలవారీ భరణం మరియు ఆస్తి రక్షణ పొందేందుకు వయోవృద్ధుల చట్టపరమైన హక్కులు.",
        "name_hi": "माता-पिता और वरिष्ठ नागरिकों का भरण-पोषण एवं कल्याण अधिनियम, 2007",
        "short_name_hi": "वरिष्ठ नागरिक अधिनियम 2007",
        "description_hi": "बुजुर्ग माता-पिता के भरण-पोषण, गरिमा और संपत्ति सुरक्षा के लिए त्वरित वैधानिक अधिकार।",
        "description": "Provides effective provisions for maintenance and welfare of parents and senior citizens through fast-track Maintenance Tribunals.",
    },
    {
        "id": 31,
        "name": "Real Estate (Regulation and Development) Act, 2016",
        "short_name": "RERA 2016",
        "category_id": 5,  # Property Law
        "year": 2016,
        "act_number": "Act No. 16 of 2016",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/2158",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "రియల్ ఎస్టేట్ (నియంత్రణ మరియు అభివృద్ధి) చట్టం, 2016",
        "short_name_te": "RERA 2016",
        "description_te": "ఫ్లాట్ కొనుగోలుదారుల హక్కులు, ప్రాజెక్ట్ ఆలస్యానికి రీఫండ్, పరిహారం మరియు RERA అథారిటీ ఫిర్యాదులు.",
        "name_hi": "रियल एस्टेट (विनियमन और विकास) अधिनियम, 2016",
        "short_name_hi": "रेरा 2016",
        "description_hi": "घर खरीदारों के अधिकार, देरी पर ब्याज सहित रिफंड और रेरा प्राधिकरण में शिकायत निवारण।",
        "description": "Protects home buyers, ensures transparency and timely delivery in real estate projects, and provides fast compensation through RERA authorities.",
    },
    {
        "id": 32,
        "name": "Medical Termination of Pregnancy Act, 1971 (as amended 2021)",
        "short_name": "MTP Act 1971",
        "category_id": 8,  # Women's Rights
        "year": 1971,
        "act_number": "Act No. 34 of 1971",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1519",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "గర్భధారణ వైద్య ముగింపు చట్టం, 1971 (సవరించిన 2021)",
        "short_name_te": "MTP చట్టం",
        "description_te": "మహిళల పునరుత్పత్తి హక్కులు, సురక్షితమైన వైద్య గర్భస్రావం మరియు గుర్తింపు గోప్యత.",
        "name_hi": "गर्भ का चिकित्सीय समापन अधिनियम, 1971 (संशोधित 2021)",
        "short_name_hi": "एमटीपी एक्ट 1971",
        "description_hi": "महिलाओं के प्रजनन स्वास्थ्य अधिकार, सुरक्षित चिकित्सीय गर्भपात और पहचान की पूर्ण गोपनीयता।",
        "description": "Regulates conditions under which pregnancy may be terminated by registered medical practitioners, safeguarding reproductive autonomy and privacy.",
    },
    {
        "id": 33,
        "name": "Employees' Provident Funds and Miscellaneous Provisions Act, 1952",
        "short_name": "EPF Act 1952",
        "category_id": 10,  # Labour & Employment
        "year": 1952,
        "act_number": "Act No. 19 of 1952",
        "source_url": "https://www.indiacode.gov.in/handle/123456789/1553",
        "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
        "status": "current",
        "name_te": "ఉద్యోగుల ప్రావిడెంట్ ఫండ్ చట్టం, 1952",
        "short_name_te": "EPF చట్టం 1952",
        "description_te": "ఉద్యోగుల వేతనంలో పీఎఫ్ తగ్గింపు, యాజమాన్య వాటా మరియు సామాజిక భద్రతా పొదుపు.",
        "name_hi": "कर्मचारी भविष्य निधि और प्रकीर्ण उपबंध अधिनियम, 1952",
        "short_name_hi": "ईपीएफ एक्ट 1952",
        "description_hi": "कर्मचारियों के वेतन से पीएफ कटौती, नियोक्ता का समान अंशदान और सेवानिवृत्ति सुरक्षा।",
        "description": "Institutes compulsory provident funds, pension schemes, and deposit-linked insurance for institutional employees in India.",
    },
]


class Command(BaseCommand):
    help = (
        "Audits and completes missing fields on all existing legal records, "
        "adds foundational Indian citizen laws with official statutory text, "
        "and synchronizes mobile seed assets."
    )

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Starting Legal Database Comprehensive Audit & Expansion..."))

        # 1. Update Existing Laws Metadata
        self.stdout.write("1. Auditing and enriching existing Laws...")
        for law_id, meta in EXISTING_LAWS_METADATA.items():
            law = Law.objects.filter(id=law_id).first()
            if not law:
                law = Law.objects.filter(name__iexact=meta["name"]).first()
            if law:
                law.short_name = meta["short_name"]
                law.year = meta["year"]
                law.act_number = meta["act_number"]
                law.source_url = meta["source_url"]
                law.source_name = meta["source_name"]
                law.status = meta["status"]
                law.last_verified = VERIFIED_DATE
                law.name_te = meta["name_te"]
                law.short_name_te = meta["short_name_te"]
                law.description_te = meta["description_te"]
                law.name_hi = meta["name_hi"]
                law.short_name_hi = meta["short_name_hi"]
                law.description_hi = meta["description_hi"]
                law.save()
                self.stdout.write(f"   [UPDATED LAW] ID={law.id}: {law.name} ({law.short_name}, {law.year}, {law.act_number})")

        # 2. Add New Important Laws
        self.stdout.write("\n2. Adding verified new Indian citizen Acts...")
        for item in NEW_IMPORTANT_LAWS:
            cat = Category.objects.get(id=item["category_id"])
            law, created = Law.objects.get_or_create(
                name=item["name"],
                defaults={
                    "short_name": item["short_name"],
                    "category": cat,
                    "description": item["description"],
                    "year": item["year"],
                    "act_number": item["act_number"],
                    "source_url": item["source_url"],
                    "source_name": item["source_name"],
                    "status": item["status"],
                    "last_verified": VERIFIED_DATE,
                    "name_te": item["name_te"],
                    "short_name_te": item["short_name_te"],
                    "description_te": item["description_te"],
                    "name_hi": item["name_hi"],
                    "short_name_hi": item["short_name_hi"],
                    "description_hi": item["description_hi"],
                }
            )
            if not created:
                law.year = item["year"]
                law.act_number = item["act_number"]
                law.source_url = item["source_url"]
                law.source_name = item["source_name"]
                law.status = item["status"]
                law.last_verified = VERIFIED_DATE
                law.name_te = item["name_te"]
                law.short_name_te = item["short_name_te"]
                law.description_te = item["description_te"]
                law.name_hi = item["name_hi"]
                law.short_name_hi = item["short_name_hi"]
                law.description_hi = item["description_hi"]
                law.save()
            action = "CREATED" if created else "UPDATED"
            self.stdout.write(f"   [{action} LAW] ID={law.id}: {law.name} ({law.short_name})")

        # 3. Update Existing Sections with complete statutory metadata & consequences
        self.stdout.write("\n3. Enriching existing 34 sections with verified metadata...")
        self._enrich_existing_sections()

        # 4. Add core verified sections for the new foundational Acts
        self.stdout.write("\n4. Adding foundational provisions for new Acts...")
        self._add_foundational_sections()

        # 5. Export clean JSON seeds to legalguide_app/assets/seed/
        self.stdout.write("\n5. Exporting updated canonical seeds to mobile app assets...")
        self._export_seed_assets()

        # 6. Bump DatabaseSyncInfo
        sync_info = DatabaseSyncInfo.get_info()
        sync_info.server_version += 1
        sync_info.last_source_check = timezone.now()
        sync_info.last_sync_date = timezone.now()
        sync_info.save()

        self.stdout.write(self.style.SUCCESS(
            f"\nAll operations completed successfully! Total Laws in DB: {Law.objects.count()}, "
            f"Total Sections: {LegalSection.objects.count()}, Server Version: {sync_info.server_version}"
        ))

    def _enrich_existing_sections(self):
        """Enriches missing fields in existing sections from official bare acts."""
        # 1. BNS sections: effective date is 2024-07-01
        bns = Law.objects.filter(short_name="BNS 2023").first()
        if bns:
            LegalSection.objects.filter(law=bns, effective_date__isnull=True).update(
                effective_date=date(2024, 7, 1),
                last_verified=VERIFIED_DATE,
                source="https://www.indiacode.gov.in/handle/123456789/21081",
                source_name="India Code — Ministry of Law & Justice, Govt. of India"
            )

        # 2. Update specific existing sections with accurate consequences_type and what_you_should_do
        updates = [
            ("COI 1950", "Article 14", {
                "effective_date": date(1950, 1, 26),
                "source": "https://www.indiacode.gov.in/handle/123456789/15240",
                "consequences_type": "civil",
                "what_you_should_do": "If state action or law discriminates arbitrarily without reasonable classification, file a Writ Petition under Article 226 before the High Court or Article 32 before the Supreme Court.",
                "what_you_should_do_te": "ప్రభుత్వ చర్య సహేతుక వర్గీకరణ లేకుండా ఏకపక్షంగా వివక్ష చూపితే, హైకోర్టులో ఆర్టికల్ 226 లేదా సుప్రీంకోర్టులో ఆర్టికల్ 32 కింద రిట్ పిటిషన్ దాఖలు చేయండి.",
                "what_you_should_do_hi": "यदि राज्य की कोई कार्रवाई बिना किसी उचित वर्गीकरण के मनमाने ढंग से भेदभाव करती है, तो उच्च न्यायालय में अनुच्छेद 226 या सर्वोच्च न्यायालय में अनुच्छेद 32 के तहत रिट याचिका दायर करें।",
            }),
            ("COI 1950", "Article 21", {
                "effective_date": date(1950, 1, 26),
                "source": "https://www.indiacode.gov.in/handle/123456789/15240",
                "consequences_type": "civil",
                "what_you_should_do": "Assert your fundamental right to life, dignity, legal counsel, and fair trial against any unlawful state restraint. Seek urgent Habeas Corpus or judicial remedy if liberty is infringed.",
                "what_you_should_do_te": "చట్టవిరుద్ధ నిర్బంధానికి వ్యతిరేకంగా జీవించే హక్కు, గౌరవం, న్యాయవాది సహాయం పొందే హక్కును వినియోగించండి. స్వేచ్ఛ ఉల్లంఘించబడితే హేబియస్ కార్పస్ పిటిషన్ వేయండి.",
                "what_you_should_do_hi": "किसी भी गैरकानूनी सरकारी प्रतिबंध के खिलाफ जीवन, सम्मान और निष्पक्ष सुनवाई के मौलिक अधिकार का दावा करें। स्वतंत्रता का उल्लंघन होने पर बंदी प्रत्यक्षीकरण याचिका दायर करें।",
            }),
            ("IT Act", "Section 66C", {
                "effective_date": date(2008, 10, 27),
                "source": "https://www.indiacode.gov.in/handle/123456789/1999",
                "consequences_type": "penal",
                "what_you_should_do": "Immediately freeze compromised accounts, preserve screenshots/audit logs of unauthorized password use, and lodge a cyber crime complaint at cybercrime.gov.in or local cyber police station.",
                "what_you_should_do_te": "ఖాతాలను వెంటనే బ్లాక్ చేయండి, అనధికారిక పాస్‌వర్డ్ వినియోగ స్క్రీన్‌షాట్లు మరియు లాగ్‌లను భద్రపరచండి, cybercrime.gov.in లేదా సైబర్ పోలీస్ స్టేషన్‌లో ఫిర్యాదు చేయండి.",
                "what_you_should_do_hi": "तुरंत प्रभावित खातों को फ्रीज करें, अनधिकृत पासवर्ड उपयोग के स्क्रीनशॉट और लॉग सुरक्षित रखें, और cybercrime.gov.in या साइबर पुलिस स्टेशन में शिकायत दर्ज करें।",
            }),
            ("IT Act", "Section 66D", {
                "effective_date": date(2008, 10, 27),
                "source": "https://www.indiacode.gov.in/handle/123456789/1999",
                "consequences_type": "penal",
                "what_you_should_do": "Call 1930 National Cyber Crime Helpline immediately if defrauded financially. Report fraud transaction reference numbers and lodge an FIR under Section 66D and BNS Section 318.",
                "what_you_should_do_te": "ఆర్థిక మోసానికి గురైతే వెంటనే 1930 జాతీయ సైబర్ క్రైమ్ హెల్ప్‌లైన్‌కు కాల్ చేయండి. లావాదేవీల రిఫరెన్స్ నంబర్లను అందించి సెక్షన్ 66D కింద ఎఫ్‌ఐఆర్ నమోదు చేయండి.",
                "what_you_should_do_hi": "वित्तीय धोखाधड़ी होने पर तुरंत 1930 राष्ट्रीय साइबर हेल्पलाइन पर कॉल करें। लेनदेन संदर्भ संख्या प्रदान करें और धारा 66D तथा बीएनएस धारा 318 के तहत प्राथमिकी दर्ज कराएं।",
            }),
            ("MV Act", "Section 185", {
                "effective_date": date(2019, 9, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/1798",
                "consequences_type": "penal",
                "what_you_should_do": "Never drive after consuming alcohol or drugs. If stopped, cooperate with breath analysis. You are entitled to be shown the calibrated reading on the breath analyser.",
                "what_you_should_do_te": "మద్యం లేదా మత్తుపదార్థాలు తీసుకున్న తర్వాత వాహనం నడపవద్దు. తనిఖీ చేసినప్పుడు శ్వాస పరీక్షకు సహకరించండి. బ్రీత్ ఎనలైజర్ రీడింగ్‌ను చూపమని అడిగే హక్కు మీకు ఉంది.",
                "what_you_should_do_hi": "शराब या नशीले पदार्थों के सेवन के बाद कभी वाहन न चलाएं। जांच के दौरान सांस परीक्षण में सहयोग करें। आपको ब्रीथ एनालाइजर पर रीडिंग देखने का अधिकार है।",
            }),
            ("CPA 2019", "Section 35", {
                "effective_date": date(2020, 7, 20),
                "source": "https://www.indiacode.gov.in/handle/123456789/15256",
                "consequences_type": "civil",
                "what_you_should_do": "Preserve tax invoices, warranty cards, and written dispute communications. File complaint online through e-Daakhil portal or submit in writing to District Consumer Commission.",
                "what_you_should_do_te": "పన్ను ఇన్‌వాయిస్‌లు, వారంటీ కార్డులు మరియు లిఖితపూర్వక కమ్యూనికేషన్లను భద్రపరచండి. e-Daakhil పోర్టల్ ద్వారా లేదా జిల్లా వినియోగదారుల కమిషన్‌లో నేరుగా ఫిర్యాదు చేయండి.",
                "what_you_should_do_hi": "टैक्स इनवॉइस, वारंटी कार्ड और लिखित पत्राचार सुरक्षित रखें। ई-दाखिल पोर्टल के माध्यम से ऑनलाइन या जिला उपभोक्ता आयोग में व्यक्तिगत रूप से शिकायत दर्ज करें।",
            }),
            ("HMA 1955", "Section 13", {
                "effective_date": date(1955, 5, 18),
                "source": "https://www.indiacode.gov.in/handle/123456789/1560",
                "consequences_type": "order",
                "what_you_should_do": "Consult a matrimonial lawyer. Gather corroborative documentary evidence of statutory grounds (cruelty, desertion, or mutual consent) and file petition in Family Court of competent jurisdiction.",
                "what_you_should_do_te": "వైవాహిక న్యాయవాదిని సంప్రదించండి. క్రూరత్వం, విడిచిపెట్టడం లేదా పరస్పర అంగీకారానికి సంబంధించిన ఆధారాలను సేకరించి సరైన ఫ్యామిలీ కోర్టులో పిటిషన్ దాఖలు చేయండి.",
                "what_you_should_do_hi": "पारिवारिक वकील से परामर्श लें। वैधानिक आधारों (क्रूरता, परित्याग, या आपसी सहमति) के दस्तावेजी साक्ष्य जुटाएं और अधिकार क्षेत्र वाले पारिवारिक न्यायालय में याचिका दायर करें।",
            }),
            ("DV Act 2005", "Section 12", {
                "effective_date": date(2006, 10, 26),
                "source": "https://www.indiacode.gov.in/handle/123456789/2021",
                "consequences_type": "order",
                "what_you_should_do": "Approach Protection Officer, Service Provider, or Judicial Magistrate directly. Free legal aid is available via DLSA. You can seek immediate Protection and Residence Orders.",
                "what_you_should_do_te": "ప్రొటెక్షన్ ఆఫీసర్ లేదా జ్యుడీషియల్ మేజిస్ట్రేట్‌ను నేరుగా సంప్రదించండి. DLSA ద్వారా ఉచిత న్యాయ సహాయం పొందవచ్చు. తక్షణ రక్షణ మరియు నివాస ఉత్తర్వులను కోరవచ్చు.",
                "what_you_should_do_hi": "संरक्षण अधिकारी या न्यायिक मजिस्ट्रेट से सीधे संपर्क करें। डीएलएसए के माध्यम से मुफ्त कानूनी सहायता उपलब्ध है। आप तत्काल संरक्षण और निवास आदेश मांग सकते हैं।",
            }),
            ("BNSS 2023", "BNSS Section 144", {
                "effective_date": date(2024, 7, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/21082",
                "consequences_type": "order",
                "what_you_should_do": "Submit maintenance application under BNSS Section 144 before Magistrate Court or Family Court with marriage certificate, income proof of respondent, and monthly expenditure details.",
                "what_you_should_do_te": "వివాహ ధృవీకరణ పత్రం, భర్త ఆదాయ ఆధారాలు మరియు నెలవారీ ఖర్చుల వివరాలతో మేజిస్ట్రేట్ లేదా ఫ్యామిలీ కోర్టులో సెక్షన్ 144 కింద భరణం దరఖాస్తును సమర్పించండి.",
                "what_you_should_do_hi": "विवाह प्रमाण पत्र, पति के आय प्रमाण और मासिक खर्च के विवरण के साथ मजिस्ट्रेट या पारिवारिक न्यायालय में धारा 144 के तहत भरण-पोषण आवेदन प्रस्तुत करें।",
            }),
            ("TPA 1882", "Section 54", {
                "effective_date": date(1882, 7, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/2338",
                "consequences_type": "civil",
                "what_you_should_do": "Always execute a registered Sale Deed on non-judicial stamp paper. Never rely on unregistered agreement to sell or notary stamp for transfer of title.",
                "what_you_should_do_te": "నాన్-జ్యుడీషియల్ స్టాంప్ పేపర్‌పై రిజిస్టర్డ్ సేల్ డీడ్ మాత్రమే అమలు చేయండి. యాజమాన్య బదిలీ కోసం అన్‌రిజిస్టర్డ్ అగ్రిమెంట్లు లేదా నోటరీపై ఎప్పుడూ ఆధారపడవద్దు.",
                "what_you_should_do_hi": "हमेशा नॉन-ज्यूडिशियल स्टांप पेपर पर पंजीकृत विक्रय पत्र (Sale Deed) निष्पादित करें। स्वामित्व हस्तांतरण के लिए अपंजीकृत अनुबंध या नोटरी पर कभी भरोसा न करें।",
            }),
            ("TPA 1882", "Section 58", {
                "effective_date": date(1882, 7, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/2338",
                "consequences_type": "civil",
                "what_you_should_do": "Ensure mortgage deed is registered where securing debt of ₹100 or more (except mortgage by deposit of title deeds). Demand formal discharge receipt upon loan repayment.",
                "what_you_should_do_te": "రూ. 100 లేదా అంతకంటే ఎక్కువ రుణం కోసం మార్ట్‌గేజ్ డీడ్‌ను తప్పనిసరిగా రిజిస్టర్ చేయించండి. రుణం తీర్చిన తర్వాత అసలు టైటిల్ డీడ్స్ మరియు డిశ్చార్జ్ రసీదును పొందండి.",
                "what_you_should_do_hi": "100 रुपये या उससे अधिक के ऋण के लिए बंधक विलेख को पंजीकृत कराएं। ऋण चुकाने पर मूल टाइटल डीड और औपचारिक मुक्ति रसीद अवश्य प्राप्त करें।",
            }),
            ("Registration Act 1908", "Section 17", {
                "effective_date": date(1909, 1, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/2320",
                "consequences_type": "procedural",
                "what_you_should_do": "Present documents affecting immovable property value exceeding ₹100 for registration before Sub-Registrar within 4 months of execution. Unregistered documents cannot prove title in court.",
                "what_you_should_do_te": "స్థిరాస్తికి సంబంధించిన పత్రాలను అమలు చేసిన 4 నెలల్లోపు సబ్-రిజిస్ట్రార్ వద్ద నమోదు చేయించండి. అన్‌రిజిస్టర్డ్ పత్రాలు కోర్టులో యాజమాన్యాన్ని నిరూపించలేవు.",
                "what_you_should_do_hi": "अचल संपत्ति के दस्तावेजों को निष्पादन के 4 महीने के भीतर सब-रजिस्ट्रार के समक्ष पंजीकृत कराएं। अपंजीकृत दस्तावेज न्यायालय में स्वामित्व सिद्ध नहीं कर सकते।",
            }),
            ("POSH Act 2013", "Section 9", {
                "effective_date": date(2013, 12, 9),
                "source": "https://www.indiacode.gov.in/handle/123456789/2104",
                "consequences_type": "order",
                "what_you_should_do": "Submit written complaint to Internal Committee (IC) within 3 months of incident. If workplace has fewer than 10 workers or complaint is against employer, submit to Local Committee (LC).",
                "what_you_should_do_te": "సంఘటన జరిగిన 3 నెలల్లోపు ఇంటర్నల్ కమిటీ (IC)కి లిఖితపూర్వక ఫిర్యాదును సమర్పించండి. 10 కంటే తక్కువ మంది ఉద్యోగులు ఉంటే జిల్లా లోకల్ కమిటీ (LC)కి సమర్పించండి.",
                "what_you_should_do_hi": "घटना के 3 महीने के भीतर आंतरिक समिति (IC) को लिखित शिकायत दें। यदि कार्यस्थल पर 10 से कम कर्मचारी हैं या नियोक्ता के खिलाफ शिकायत है, तो स्थानीय समिति (LC) को दें।",
            }),
            ("Dowry Act 1961", "Section 3", {
                "effective_date": date(1961, 7, 1),
                "source": "https://www.indiacode.gov.in/handle/123456789/1518",
                "consequences_type": "penal",
                "what_you_should_do": "Refuse to give or take dowry. Maintain signed list of voluntary wedding presents in accordance with Dowry Prohibition (Maintenance of Lists of Presents) Rules, 1985.",
                "what_you_should_do_te": "వరకట్నం ఇవ్వడానికి లేదా తీసుకోవడానికి నిరాకరించండి. స్వచ్ఛంద వివాహ బహుమతుల జాబితాను నిబంధనల ప్రకారం సంతకం చేయించి భద్రపరచండి.",
                "what_you_should_do_hi": "दहेज देने या लेने से सख्ती से इनकार करें। दहेज प्रतिषेध (उपहारों की सूची) नियम, 1985 के अनुसार दोनों पक्षों द्वारा हस्ताक्षरित उपहारों की सूची रखें।",
            }),
            ("POCSO 2012", "Section 4", {
                "effective_date": date(2012, 11, 14),
                "source": "https://www.indiacode.gov.in/handle/123456789/2079",
                "consequences_type": "penal",
                "what_you_should_do": "Report sexual offences against minors immediately to Special Juvenile Police Unit (SJPU), local police station, or Childline (1098). Identity of child victim is protected by law.",
                "what_you_should_do_te": "మైనర్లపై లైంగిక వేధింపులను వెంటనే స్పెషల్ జువెనైల్ పోలీస్ యూనిట్ లేదా చైల్డ్‌లైన్ (1098)కి నివేదించండి. బాధితురాలైన పిల్లల గుర్తింపు గోప్యత చట్టం ద్వారా రక్షించబడుతుంది.",
                "what_you_should_do_hi": "नाबालिगों के खिलाफ यौन अपराधों की तुरंत विशेष किशोर पुलिस इकाई या चाइल्डलाइन (1098) पर रिपोर्ट करें। पीड़ित बच्चे की पहचान कानूनन गोपनीय रखी जाती है।",
            }),
            ("POCSO 2012", "Section 19 & 21", {
                "effective_date": date(2012, 11, 14),
                "source": "https://www.indiacode.gov.in/handle/123456789/2079",
                "consequences_type": "penal",
                "what_you_should_do": "Any person (including doctor, teacher, neighbour, hospital staff) having apprehension or knowledge of child abuse MUST report it to SJPU or police. Failure is punishable with imprisonment.",
                "what_you_should_do_te": "పిల్లలపై లైంగిక దాడి జరిగిందని తెలిసిన ఏ వ్యక్తైనా (డాక్టర్, ఉపాధ్యాయుడు, పొరుగువారు) తప్పనిసరిగా పోలీసులకు తెలపాలి. నివేదించకపోవడం జైలు శిక్షార్హమైన నేరం.",
                "what_you_should_do_hi": "बाल शोषण की जानकारी या आशंका होने पर प्रत्येक व्यक्ति (डॉक्टर, शिक्षक, पड़ोसी सहित) को पुलिस या एसजेपीयू को सूचित करना अनिवार्य है। विफलता पर कारावास हो सकता है।",
            }),
            ("CSS 2020", "Section 60", {
                "effective_date": date(2025, 11, 21),
                "source": "https://www.indiacode.gov.in/handle/123456789/15707",
                "consequences_type": "order",
                "what_you_should_do": "Notify employer in writing claiming maternity benefit with expected date of delivery. Must have worked at least 80 days in the 12 months preceding delivery date.",
                "what_you_should_do_te": "ప్రసవానికి కనీసం 80 రోజులు పనిచేసిన మహిళా ఉద్యోగి ప్రసూతి ప్రయోజనాల కోసం యజమానికి లిఖితపూర్వక నోటీసు ఇవ్వాలి. 26 వారాల పూర్తి వేతనంతో కూడిన సెలవు హక్కు ఉంటుంది.",
                "what_you_should_do_hi": "प्रसव से पहले के 12 महीनों में कम से कम 80 दिन काम करने वाली महिला कर्मचारी को नियोक्ता को मातृत्व लाभ के लिए लिखित सूचना देनी चाहिए। 26 सप्ताह का सवेतन अवकाश अधिकार है।",
            }),
            ("IR Code 2020", "Section 70", {
                "effective_date": date(2025, 11, 21),
                "source": "https://www.indiacode.gov.in/handle/123456789/15706",
                "consequences_type": "procedural",
                "what_you_should_do": "If retrenched after 1 year continuous service, ensure employer pays 15 days average pay per completed year of service plus 1 month notice or pay in lieu.",
                "what_you_should_do_te": "1 సంవత్సరం నిరంతర సర్వీస్ తర్వాత తొలగించబడితే, ప్రతి సంవత్సరానికి 15 రోజుల సగటు వేతనం పరిహారంగా మరియు 1 నెల నోటీసు లేదా వేతనం చెల్లించబడిందో లేదో నిర్ధారించుకోండి.",
                "what_you_should_do_hi": "1 वर्ष की निरंतर सेवा के बाद छंटनी होने पर नियोक्ता द्वारा प्रत्येक पूरे वर्ष के लिए 15 दिन का औसत वेतन और 1 माह का नोटिस या वेतन दिया जाना अनिवार्य है।",
            }),
        ]

        for law_short, sec_num, data in updates:
            sec = LegalSection.objects.filter(section_number=sec_num).first()
            if sec:
                sec.effective_date = data.get("effective_date", sec.effective_date)
                sec.source = data.get("source", sec.source)
                sec.source_name = "India Code — Ministry of Law & Justice, Govt. of India"
                sec.last_verified = VERIFIED_DATE
                sec.consequences_type = data.get("consequences_type", sec.consequences_type or "penal")
                sec.what_you_should_do = data.get("what_you_should_do", sec.what_you_should_do)
                sec.what_you_should_do_te = data.get("what_you_should_do_te", sec.what_you_should_do_te)
                sec.what_you_should_do_hi = data.get("what_you_should_do_hi", sec.what_you_should_do_hi)
                sec.save()
                self.stdout.write(f"   [ENRICHED SECTION] ID={sec.id}: {sec.section_number} - {sec.title[:30]}")

    def _add_foundational_sections(self):
        """Adds verified foundational citizen sections for new and existing Acts."""
        new_sections_data = [
            # ------------------------------------------------------------------
            # 1. BHARATIYA NAGARIK SURAKSHA SANHITA, 2023 (BNSS) - Criminal Procedure
            # ------------------------------------------------------------------
            {
                "law_short_name": "BNSS 2023",
                "section_number": "Section 173",
                "title": "Information in Cognizable Cases (Mandatory FIR & e-FIR)",
                "title_te": "కాగ్నిజబుల్ కేసులలో సమాచారం (తప్పనిసరి ఎఫ్‌ఐఆర్ & ఇ-ఎఫ్‌ఐఆర్)",
                "title_hi": "संज्ञेय मामलों में सूचना (अनिवार्य प्राथमिकी और ई-एफआईआर)",
                "legal_text": (
                    "Every information relating to the commission of a cognizable offence, if given orally to an officer in charge of a police station, "
                    "shall be reduced to writing by him or under his direction, and be read over to the informant; and every such information, whether given "
                    "in writing or reduced to writing as aforesaid, shall be signed by the person giving it, and the substance thereof shall be entered in a book "
                    "to be kept by such officer in such form as the State Government may prescribe in this behalf: Provided that if the information is given by "
                    "the woman against whom an offence under section 64, section 65, section 66, section 67, section 68, section 69, section 70, section 71, "
                    "section 74, section 75, section 76, section 77, section 78, section 79 or section 124 of the Bharatiya Nyaya Sanhita, 2023 is alleged to have "
                    "been committed or attempted, then such information shall be recorded, by a woman police officer or any woman officer. Information may also "
                    "be given by electronic communication, which shall be taken on record on being signed within three days."
                ),
                "simple_explanation": (
                    "When a serious (cognizable) crime is reported, the police officer MUST register a First Information Report (FIR). "
                    "A free copy of the FIR must be given to you immediately. If police refuse, you can send the report to the Superintendent of Police "
                    "by post or file electronically (e-FIR), which must be formally signed within 3 days."
                ),
                "simple_explanation_te": (
                    "తీవ్రమైన (కాగ్నిజబుల్) నేరం గురించి ఫిర్యాదు చేసినప్పుడు, పోలీసు అధికారి తప్పనిసరిగా ఎఫ్‌ఐఆర్ (FIR) నమోదు చేయాలి. "
                    "ఎఫ్‌ఐఆర్ ఉచిత కాపీని ఫిర్యాదుదారునికి వెంటనే అందించాలి. పోలీసులు నిరాకరిస్తే, ఎస్పీ గారికి పోస్ట్ ద్వారా లేదా ఆన్‌లైన్‌లో ఇ-ఎఫ్‌ఐఆర్ దాఖలు చేయవచ్చు."
                ),
                "simple_explanation_hi": (
                    "जब किसी गंभीर (संज्ञेय) अपराध की सूचना दी जाती है, तो पुलिस अधिकारी को अनिवार्य रूप से एफआईआर दर्ज करनी होगी। "
                    "एफआईआर की एक निःशुल्क प्रति शिकायतकर्ता को तुरंत दी जानी चाहिए। पुलिस के इनकार करने पर पुलिस अधीक्षक को डाक द्वारा या ई-एफआईआर भेजी जा सकती है।"
                ),
                "purpose": "Guarantees citizen's fundamental access to criminal justice and mandates prompt police registration of serious crimes.",
                "purpose_te": "క్రిమినల్ న్యాయ వ్యవస్థను పౌరులు సులభంగా ఆశ్రయించేలా చేయడం మరియు తీవ్రమైన నేరాల నమోదును తప్పనిసరి చేయడం.",
                "purpose_hi": "नागरिकों को आपराधिक न्याय तक पहुंच की गारंटी देना और गंभीर अपराधों के त्वरित पंजीकरण को अनिवार्य बनाना।",
                "punishment": "A police officer who willfully disobeys direction of law to register FIR is liable under BNS Section 199 with imprisonment up to 2 years.",
                "punishment_te": "ఎఫ్‌ఐఆర్ నమోదు చేయడానికి నిరాకరించిన పోలీసు అధికారిపై BNS సెక్షన్ 199 కింద 2 సంవత్సరాల వరకు జైలు శిక్ష విధించవచ్చు.",
                "punishment_hi": "एफआईआर दर्ज करने के कानूनी निर्देश की अवहेलना करने वाले पुलिस अधिकारी पर बीएनएस धारा 199 के तहत 2 वर्ष तक का कारावास हो सकता है।",
                "effective_date": date(2024, 7, 1),
                "amendment_info": "Replaces Section 154 of the Code of Criminal Procedure, 1973 (CrPC), introducing formal statutory provision for e-FIR.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/21082",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "procedural",
                "key_elements": "Cognizable offence reported\nOral statement reduced to writing\nMandatory free copy to informant\nWoman officer records offences against women\ne-FIR signed within 3 days",
                "key_elements_te": "కాగ్నిజబుల్ నేరం నివేదిక\nమౌఖిక సమాచారాన్ని లిఖితపూర్వకంగా రాయడం\nఉచిత కాపీ అందజేత\nమహిళలపై నేరాలను మహిళా అధికారి నమోదు చేయడం\n3 రోజుల్లో ఇ-ఎఫ్‌ఐఆర్ సంతకం",
                "key_elements_hi": "संज्ञेय अपराध की सूचना\nमौखिक सूचना को लिखित रूप देना\nमुफ्त प्रति प्राप्त करने का अधिकार\nमहिला पुलिस अधिकारी द्वारा बयान दर्ज करना\n3 दिनों में ई-एफआईआर पर हस्ताक्षर",
                "relevant_documents": "Written complaint\nID proof\nEvidence of incident (photos, medical reports, transaction receipts)\nAcknowledgement slip",
                "relevant_documents_te": "లిఖితపూర్వక ఫిర్యాదు\nగుర్తింపు కార్డు\nఘటనకు సంబంధించిన ఆధారాలు (ఫోటోలు, మెడికల్ రిపోర్టులు)\nరసీదు స్లిప్",
                "relevant_documents_hi": "लिखित शिकायत\nपहचान प्रमाण\nघटना के साक्ष्य (फोटो, मेडिकल रिपोर्ट, रसीद)\nपावती पर्ची",
                "what_you_should_do": "Demand your free signed copy of the FIR on the spot. If police refuse, send complaint by registered post to Superintendent of Police under Section 173(4) or submit an application under Section 175(3) to the Magistrate.",
                "what_you_should_do_te": "ఎఫ్‌ఐఆర్ ఉచిత కాపీని అక్కడికక్కడే అడిగి పొందండి. పోలీసులు నిరాకరిస్తే, సెక్షన్ 173(4) కింద ఎస్పీకి రిజిస్టర్డ్ పోస్ట్ ద్వారా లేదా మేజిస్ట్రేట్‌కు దరఖాస్తు చేయండి.",
                "what_you_should_do_hi": "घटनास्थल पर ही एफआईआर की निःशुल्क हस्ताक्षरित प्रति मांगें। इनकार करने पर धारा 173(4) के तहत एसपी को पंजीकृत डाक से शिकायत भेजें या मजिस्ट्रेट के समक्ष आवेदन करें।",
                "quick_answer": "Yes, police must register an FIR for cognizable crimes and give you a free copy immediately.",
                "quick_answer_te": "అవును, కాగ్నిజబుల్ నేరాలకు పోలీసులు తప్పనిసరిగా ఎఫ్‌ఐఆర్ నమోదు చేసి ఉచిత కాపీని ఇవ్వాలి.",
                "quick_answer_hi": "हाँ, संज्ञेय अपराधों के लिए पुलिस को अनिवार्य रूप से एफआईआर दर्ज कर तुरंत मुफ्त प्रति देनी होगी।",
                "example_title": "Police refusal to register theft FIR",
                "example_title_te": "దొంగతనం ఎఫ్‌ఐఆర్ నమోదుకు పోలీసుల నిరాకరణ",
                "example_title_hi": "चोरी की प्राथमिकी दर्ज करने से पुलिस का इनकार",
                "example_situation": "Ramesh had his motorcycle stolen outside a shopping complex. The local police station gave him a handwritten CSR slip instead of registering an FIR.",
                "example_situation_te": "షాపింగ్ కాంప్లెక్స్ వెలుపల రమేష్ మోటార్ సైకిల్ దొంగిలించబడింది. స్థానిక పోలీసులు ఎఫ్‌ఐఆర్ నమోదు చేయకుండా సాధారణ రసీదు మాత్రమే ఇచ్చారు.",
                "example_situation_hi": "रमेश की मोटरसाइकिल शॉपिंग कॉम्प्लेक्स के बाहर से चोरी हो गई। स्थानीय पुलिस ने एफआईआर दर्ज करने के बजाय केवल अनौपचारिक पर्ची थमा दी।",
                "example_explanation": "Under Section 173, theft is cognizable and police have no discretion to deny an FIR. Ramesh sent a written complaint to the SP, who directed immediate FIR registration.",
                "example_explanation_te": "సెక్షన్ 173 ప్రకారం దొంగతనం కాగ్నిజబుల్ నేరం కాబట్టి ఎఫ్‌ఐఆర్ నిరాకరించే అధికారం పోలీసులకు లేదు. రమేష్ ఎస్పీకి ఫిర్యాదు చేయడంతో వెంటనే ఎఫ్‌ఐఆర్ నమోదైంది.",
                "example_explanation_hi": "धारा 173 के तहत चोरी संज्ञेय अपराध है और पुलिस एफआईआर से इनकार नहीं कर सकती। रमेश द्वारा एसपी को शिकायत भेजने पर तुरंत एफआईआर दर्ज की गई।",
                "example_disclaimer": "Fictional educational scenario illustrating statutory FIR procedures.",
            },
            {
                "law_short_name": "BNSS 2023",
                "section_number": "Section 479",
                "title": "Maximum Period for Which an Undertrial Prisoner Can Be Detained (Bail Rights)",
                "title_te": "విచారణ ఖైదీని నిర్బంధించగల గరిష్ట కాలం (బెయిల్ హక్కులు)",
                "title_hi": "विचाराधीन कैदी को हिरासत में रखने की अधिकतम अवधि (जमानत अधिकार)",
                "legal_text": (
                    "Where a person has, during the period of investigation, inquiry or trial under this Sanhita of an offence under any law "
                    "(not being an offence for which the punishment of death or life imprisonment has been specified as one of the punishments under that law) "
                    "undergone detention for a period extending up to one-half of the maximum period of imprisonment specified for that offence under that law, "
                    "he shall be released by the Court on bail: Provided that where such person is a first-time offender (who has never been convicted of any offence "
                    "in the past), he shall be released on bail if he has undergone detention for a period extending up to one-third of the maximum period of "
                    "imprisonment specified for such offence."
                ),
                "simple_explanation": (
                    "If a person accused of an offence (other than capital offences) has spent half the maximum sentence in jail as an undertrial, "
                    "they are entitled to statutory bail. First-time offenders are entitled to bail after completing only one-third of the maximum sentence."
                ),
                "simple_explanation_te": (
                    "మరణశిక్ష లేదా యావజ్జీవ శిక్ష లేని కేసులలో విచారణ ఖైదీ గరిష్ట శిక్షాకాలంలో సగం జైలులో గడిపితే, వారు చట్టబద్ధమైన బెయిల్‌కు అర్హులు. "
                    "మొదటిసారి నేరం చేసిన వ్యక్తులు గరిష్ట శిక్షాకాలంలో మూడో వంతు (1/3) పూర్తి చేసిన తర్వాత బెయిల్ పొందవచ్చు."
                ),
                "simple_explanation_hi": (
                    "मृत्युदंड या आजीवन कारावास से भिन्न अपराधों में यदि कोई विचाराधीन कैदी अधिकतम सजा का आधा समय जेल में काट चुका है, तो वह वैधानिक जमानत का हकदार है। "
                    "पहली बार अपराध करने वाले व्यक्ति को अधिकतम सजा का एक-तिहाई समय पूरा करने पर जमानत मिल जाती है।"
                ),
                "purpose": "Protects undertrial prisoners against indefinite incarceration and enforces right to speedy justice.",
                "purpose_te": "విచారణ ఖైదీలను అపరిమిత కాలం జైల్లో ఉంచకుండా నిరోధించడం మరియు వేగవంతమైన న్యాయం అందించడం.",
                "purpose_hi": "विचाराधीन कैदियों को अनिश्चित काल तक जेल में रहने से बचाना और त्वरित न्याय के अधिकार को लागू करना।",
                "punishment": "Judicial safeguard; illegal detention violates Article 21 of the Constitution.",
                "punishment_te": "న్యాయపరమైన రక్షణ; అక్రమ నిర్బంధం రాజ్యాంగం ఆర్టికల్ 21ని ఉల్లంఘిస్తుంది.",
                "punishment_hi": "न्यायिक सुरक्षा उपाय; अवैध हिरासत संविधान के अनुच्छेद 21 का उल्लंघन है।",
                "effective_date": date(2024, 7, 1),
                "amendment_info": "Replaces Section 436A of CrPC 1973, adding a beneficial new rule granting bail to first-time offenders after one-third period.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/21082",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "order",
                "key_elements": "Offence not punishable with death or life imprisonment\nDetention exceeds 1/2 of maximum sentence\nFirst-time offender detention exceeds 1/3 of maximum sentence\nMandatory release on bail by court",
                "key_elements_te": "మరణశిక్ష లేదా జీవిత ఖైదు లేని నేరం\nగరిష్ట శిక్షలో సగం కాలం నిర్బంధం\nమొదటిసారి నిందితులకు 1/3 వంతు కాలం నిర్బంధం\nకోర్టు తప్పనిసరిగా బెయిల్ మంజూరు చేయడం",
                "key_elements_hi": "मृत्युदंड या आजीवन कारावास रहित अपराध\nअधिकतम सजा की आधी अवधि की हिरासत\nपहली बार के अपराधी के लिए 1/3 अवधि की हिरासत\nअदालत द्वारा अनिवार्य जमानत",
                "relevant_documents": "Bail application under Section 479\nCustody certificate from jail superintendent\nNominal roll\nBail bond and surety papers",
                "relevant_documents_te": "సెక్షన్ 479 కింద బెయిల్ దరఖాస్తు\nజైలు సూపరింటెండెంట్ కస్టడీ సర్టిఫికెట్\nనామినల్ రోల్\nబెయిల్ బాండ్ మరియు షూరిటీ పత్రాలు",
                "relevant_documents_hi": "धारा 479 के तहत जमानत आवेदन\nजेल अधीक्षक से हिरासत प्रमाण पत्र\nनामिनल रोल\nजमानत बांड और मुचलका दस्तावेज",
                "what_you_should_do": "File a bail application under Section 479 accompanied by a custody certificate from the jail superintendent confirming time served.",
                "what_you_should_do_te": "జైలులో గడిపిన కాలాన్ని ధృవీకరిస్తూ జైలర్ నుండి కస్టడీ సర్టిఫికెట్‌తో సెక్షన్ 479 కింద బెయిల్ పిటిషన్ దాఖలు చేయండి.",
                "what_you_should_do_hi": "जेल में बिताई गई अवधि की पुष्टि करने वाले हिरासत प्रमाण पत्र के साथ धारा 479 के तहत जमानत याचिका दायर करें।",
                "quick_answer": "Yes, first-time offenders get bail after completing 1/3rd, and others after 1/2 of the maximum sentence.",
                "quick_answer_te": "అవును, మొదటిసారి నేరస్తులు గరిష్ట శిక్షలో మూడో వంతు పూర్తి చేసిన తర్వాత బెయిల్ పొందవచ్చు.",
                "quick_answer_hi": "हाँ, पहली बार अपराध करने वाले 1/3 और अन्य अधिकतम सजा का आधा समय काटने पर जमानत के हकदार हैं।",
                "example_title": "Statutory bail for undertrial awaiting trial for 2 years",
                "example_title_te": "2 సంవత్సరాలుగా విచారణ కోసం ఎదురుచూస్తున్న ఖైదీకి బెయిల్",
                "example_title_hi": "2 वर्षों से विचाराधीन कैदी को वैधानिक जमानत",
                "example_situation": "Sunil was charged under an offence carrying a maximum sentence of 3 years. He had spent 14 months in judicial custody as a first-time offender.",
                "example_situation_te": "సునీల్ 3 సంవత్సరాల గరిష్ట శిక్ష ఉండే కేసులో ఆరోపణలు ఎదుర్కొన్నాడు. మొదటిసారి నిందితుడైన అతను 14 నెలలు జైలులో ఉన్నాడు.",
                "example_situation_hi": "सुनील पर 3 साल की अधिकतम सजा वाले अपराध का आरोप था। पहली बार आरोपी के रूप में उसने 14 महीने जेल में बिताए।",
                "example_explanation": "One-third of 3 years is 12 months. Since Sunil had spent 14 months, the Sessions Court ordered his release under Section 479.",
                "example_explanation_te": "3 సంవత్సరాలలో మూడో వంతు అంటే 12 నెలలు. సునీల్ 14 నెలలు జైలులో ఉన్నందున సెక్షన్ 479 కింద కోర్టు అతనికి బెయిల్ మంజూరు చేసింది.",
                "example_explanation_hi": "3 साल का एक-तिहाई 12 महीने होता है। चूंकि सुनील 14 महीने काट चुका था, इसलिए सत्र न्यायालय ने धारा 479 के तहत उसकी रिहाई का आदेश दिया।",
                "example_disclaimer": "Fictional educational example explaining statutory bail thresholds under BNSS.",
            },

            # ------------------------------------------------------------------
            # 2. BHARATIYA SAKSHYA ADHINIYAM, 2023 (BSA) - Evidence & Digital Proof
            # ------------------------------------------------------------------
            {
                "law_short_name": "BSA 2023",
                "section_number": "Section 61",
                "title": "Admissibility of Electronic Records in Evidence",
                "title_te": "సాక్ష్యంలో ఎలక్ట్రానిక్ రికార్డుల ఆమోదయోగ్యత",
                "title_hi": "साक्ष्य में इलेक्ट्रॉनिक अभिलेखों की ग्राह्यता",
                "legal_text": (
                    "Nothing in this Adhiniyam shall apply to deny the admissibility of an electronic or digital record, in evidence on the ground "
                    "that it is an electronic or digital record, and such record shall have the same legal effect, validity and enforceability as other document."
                ),
                "simple_explanation": (
                    "Electronic and digital records (such as emails, WhatsApp messages, server logs, SMS, digital photos, and videos) "
                    "have the exact same legal status and evidentiary validity as physical paper documents in Indian courts."
                ),
                "simple_explanation_te": (
                    "ఈమెయిల్‌లు, వాట్సాప్ సందేశాలు, సర్వర్ లాగ్‌లు, డిజిటల్ ఫోటోలు మరియు వీడియోలు వంటి ఎలక్ట్రానిక్ రికార్డులు భారత న్యాయస్థానాలలో "
                    "సాధారణ పేపర్ పత్రాలతో సమానమైన చట్టపరమైన చెల్లుబాటును కలిగి ఉంటాయి."
                ),
                "simple_explanation_hi": (
                    "ईमेल, व्हाट्सएप संदेश, सर्वर लॉग, एसएमएस, डिजिटल फोटो और वीडियो जैसे इलेक्ट्रॉनिक रिकॉर्ड भारतीय अदालतों में "
                    "कागजी दस्तावेजों के समान ही कानूनी वैधता और साक्ष्य मूल्य रखते हैं।"
                ),
                "purpose": "Modernizes Indian evidence law by giving equal legal standing to digital records and electronic communications.",
                "purpose_te": "డిజిటల్ రికార్డులకు చట్టపరమైన గుర్తింపు ఇవ్వడం ద్వారా భారత సాక్ష్య చట్టాన్ని ఆధునీకరించడం.",
                "purpose_hi": "डिजिटल साक्ष्यों को कानूनी मान्यता देकर भारतीय साक्ष्य कानून को आधुनिक बनाना।",
                "punishment": "Fabricating false electronic evidence is punishable under BNS Section 229 with imprisonment up to 7 years.",
                "punishment_te": "తప్పుడు ఎలక్ట్రానిక్ సాక్ష్యాలను సృష్టించడం BNS సెక్షన్ 229 కింద 7 సంవత్సరాల వరకు జైలు శిక్షార్హమైన నేరం.",
                "punishment_hi": "झूठे इलेक्ट्रॉनिक साक्ष्य गढ़ना बीएनएस धारा 229 के तहत 7 साल तक के कारावास से दंडनीय है।",
                "effective_date": date(2024, 7, 1),
                "amendment_info": "Replaces Section 65A of the Indian Evidence Act, 1872, harmonizing digital proof standards.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/21083",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "procedural",
                "key_elements": "Electronic or digital record produced\nNot inadmissible merely for being digital\nEqual validity to physical document\nSubject to Section 63 certificate conditions",
                "key_elements_te": "ఎలక్ట్రానిక్ రికార్డు సమర్పణ\nడిజిటల్ అయినంత మాత్రాన తిరస్కరించలేరు\nకాగితపు పత్రంతో సమాన హోదా\nసెక్షన్ 63 సర్టిఫికెట్ నిబంధనలకు లోబడి ఉంటుంది",
                "key_elements_hi": "इलेक्ट्रॉनिक या डिजिटल रिकॉर्ड प्रस्तुत करना\nकेवल डिजिटल होने के कारण अस्वीकार्य नहीं\nकागजी दस्तावेज के समान मान्यता\nधारा 63 प्रमाण पत्र की शर्तों के अधीन",
                "relevant_documents": "Original device / storage medium\nPrintout or hash log\nCertificate under Section 63 (Schedule)\nDevice identification details",
                "relevant_documents_te": "అసలు పరికరం లేదా నిల్వ మాధ్యమం\nప్రింటౌట్ లేదా హ్యాష్ లాగ్\nసెక్షన్ 63 సర్టిఫికెట్\nడివైస్ వివరాలు",
                "relevant_documents_hi": "मूल उपकरण या स्टोरेज मीडिया\nप्रिंटआउट या हैश लॉग\nधारा 63 प्रमाण पत्र\nउपकरण विवरण",
                "what_you_should_do": "Preserve original digital files on your device with date/time stamps. To submit printouts or copied media in court, prepare a Certificate under Section 63 signed by the person in lawful control of the device.",
                "what_you_should_do_te": "మీ పరికరంలో తేదీ మరియు సమయంతో కూడిన అసలు డిజిటల్ ఫైళ్లను భద్రపరచండి. కోర్టులో సమర్పించడానికి సెక్షన్ 63 కింద సంతకం చేసిన సర్టిఫికెట్‌ను జత చేయండి.",
                "what_you_should_do_hi": "अपने उपकरण पर तारीख और समय के साथ मूल डिजिटल फाइलें सुरक्षित रखें। अदालत में प्रिंटआउट पेश करने के लिए धारा 63 के तहत हस्ताक्षरित प्रमाण पत्र संलग्न करें।",
                "quick_answer": "Yes, digital files and chat messages are fully admissible evidence under Section 61.",
                "quick_answer_te": "అవును, డిజిటల్ ఫైళ్లు మరియు చాట్ సందేశాలు కోర్టులో చట్టబద్ధమైన సాక్ష్యాలుగా ఆమోదించబడతాయి.",
                "quick_answer_hi": "हाँ, डिजिटल फाइलें और चैट संदेश धारा 61 के तहत अदालत में पूरी तरह से ग्राह्य साक्ष्य हैं।",
                "example_title": "WhatsApp payment promise used in debt recovery suit",
                "example_title_te": "అప్పు వసూలు దావాలో వాట్సాప్ సందేశం సాక్ష్యం",
                "example_title_hi": "ऋण वसूली मुकदमे में व्हाट्सएप संदेश का साक्ष्य",
                "example_situation": "Anita lent ₹50,000 to her colleague, who repeatedly acknowledged the debt and promised repayment over WhatsApp chat before defaulting.",
                "example_situation_te": "అనిత తన సహోద్యోగికి రూ. 50,000 అప్పు ఇచ్చింది. అతను వాట్సాప్‌లో అప్పును అంగీకరిస్తూ తిరిగి ఇస్తానని మెసేజ్ పెట్టి ఆ తర్వాత ఎగ్గొట్టాడు.",
                "example_situation_hi": "अनीता ने अपने सहकर्मी को 50,000 रुपये उधार दिए। सहकर्मी ने व्हाट्सएप पर ऋण स्वीकार किया लेकिन बाद में मुकर गया।",
                "example_explanation": "Anita submitted the chat printout with a Section 63 certificate. The Civil Court accepted it as valid documentary evidence under Section 61 and decreed the suit.",
                "example_explanation_te": "అనిత సెక్షన్ 63 సర్టిఫికెట్‌తో చాట్ ప్రింటౌట్‌ను సమర్పించింది. సివిల్ కోర్టు సెక్షన్ 61 కింద దానిని సరైన సాక్ష్యంగా అంగీకరించి ఆమెకు అనుకూలంగా తీర్పు ఇచ్చింది.",
                "example_explanation_hi": "अनीता ने धारा 63 प्रमाण पत्र के साथ चैट प्रस्तुत की। अदालत ने धारा 61 के तहत इसे वैध साक्ष्य मानकर फैसला सुनाया।",
                "example_disclaimer": "Fictional educational example demonstrating electronic evidence admissibility.",
            },

            # ------------------------------------------------------------------
            # 3. RIGHT TO INFORMATION ACT, 2005 (RTI) - Citizen Transparency
            # ------------------------------------------------------------------
            {
                "law_short_name": "RTI Act 2005",
                "section_number": "Section 6",
                "title": "Request for Obtaining Information from Public Authorities",
                "title_te": "ప్రభుత్వ సంస్థల నుండి సమాచారం పొందేందుకు దరఖాస్తు",
                "title_hi": "सार्वजनिक प्राधिकरणों से सूचना प्राप्त करने के लिए अनुरोध",
                "legal_text": (
                    "A person, who desires to obtain any information under this Act, shall make a request in writing or through electronic means "
                    "in English or Hindi or in the official language of the area in which the application is being made, accompanying such fee as may be prescribed, "
                    "to the Central Public Information Officer or State Public Information Officer, as the case may be. An applicant making request for information "
                    "shall not be required to give any reason for requesting the information or any other personal details except those that may be necessary "
                    "for contacting him."
                ),
                "simple_explanation": (
                    "Any Indian citizen can file a simple application in English, Hindi, or their regional language to any government department "
                    "asking for official records, status of files, funds utilization, or road works. You DO NOT need to explain why you want the information."
                ),
                "simple_explanation_te": (
                    "ఏ భారతీయ పౌరుడైనా ప్రభుత్వ శాఖ నుండి రికార్డులు, ఫైళ్ల స్థితి లేదా నిధుల ఖర్చు వివరాలను కోరుతూ దరఖాస్తు చేయవచ్చు. "
                    "సమాచారం ఎందుకు అడుగుతున్నారో కారణం చెప్పాల్సిన అవసరం లేదు."
                ),
                "simple_explanation_hi": (
                    "कोई भी भारतीय नागरिक किसी भी सरकारी विभाग से आधिकारिक रिकॉर्ड, फाइल स्थिति या विकास कार्यों की जानकारी मांग सकता है। "
                    "आवेदक को जानकारी मांगने का कोई कारण बताने की आवश्यकता नहीं है।"
                ),
                "purpose": "Empowers citizens to demand transparency and examine government records without justifying their motives.",
                "purpose_te": "ప్రభుత్వ పారదర్శకతను పెంచడం మరియు పౌరులకు సమాచార హక్కు కల్పించడం.",
                "purpose_hi": "सरकारी पारदर्शिता बढ़ाना और नागरिकों को जवाबदेही तय करने का अधिकार देना।",
                "punishment": "A Public Information Officer who delays without reasonable cause is liable to penalty up to ₹25,000 under Section 20.",
                "punishment_te": "సమాచారం ఇవ్వడంలో ఉద్దేశపూర్వకంగా ఆలస్యం చేసిన అధికారిపై సెక్షన్ 20 కింద రోజుకు రూ. 250 చొప్పున గరిష్టంగా రూ. 25,000 వరకు జరిమానా విధించవచ్చు.",
                "punishment_hi": "बिना उचित कारण के देरी करने वाले जन सूचना अधिकारी पर धारा 20 के तहत अधिकतम 25,000 रुपये तक का जुर्माना लगाया जा सकता है।",
                "effective_date": date(2005, 10, 12),
                "amendment_info": "In force since 12 October 2005 across India.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/2065",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "fine",
                "key_elements": "Citizen of India\nApplication in writing or online (rtionline.gov.in)\nNominal fee (usually ₹10)\nNo reasons required\nMandatory response within statutory time limit",
                "key_elements_te": "భారత పౌరసత్వం\nలిఖితపూర్వకంగా లేదా ఆన్‌లైన్ దరఖాస్తు\nనామమాత్రపు రుసుము (రూ. 10)\nకారణం చెప్పాల్సిన పనిలేదు\nగడువులోగా సమాధానం ఇవ్వాలి",
                "key_elements_hi": "भारतीय नागरिक\nलिखित या ऑनलाइन आवेदन\nमामूली शुल्क (10 रुपये)\nकारण बताने की आवश्यकता नहीं\nनिर्धारित समय में उत्तर अनिवार्य",
                "relevant_documents": "RTI application letter / online printout\nFee payment proof (₹10 postal order / court fee stamp / online payment receipt)\nBPL card (if claiming fee exemption)",
                "relevant_documents_te": "RTI దరఖాస్తు లేఖ\nరుసుము చెల్లింపు రసీదు (రూ. 10 పోస్టల్ ఆర్డర్)\nBPL కార్డ్ (రుసుము మినహాయింపు కోరితే)",
                "relevant_documents_hi": "आरटीआई आवेदन\nशुल्क भुगतान रसीद (10 रुपये का पोस्टल ऑर्डर)\nबीपीएल कार्ड (यदि शुल्क छूट चाहिए)",
                "what_you_should_do": "Draft clear, specific questions addressing the Public Information Officer (PIO). Pay the ₹10 fee. Do not ask for opinions; ask for certified copies of government files, orders, or attendance registers.",
                "what_you_should_do_te": "సమాచార అధికారి (PIO)కి స్పష్టమైన ప్రశ్నలతో దరఖాస్తు రాయండి. రూ. 10 రుసుము చెల్లించండి. అభిప్రాయాలు అడగకండి, ప్రభుత్వ రికార్డులు లేదా ఉత్తర్వుల సర్టిఫైడ్ కాపీలను మాత్రమే కోరండి.",
                "what_you_should_do_hi": "जन सूचना अधिकारी (PIO) को स्पष्ट प्रश्नों के साथ आवेदन भेजें। 10 रुपये का शुल्क दें। राय न मांगें, बल्कि सरकारी फाइलों या आदेशों की प्रमाणित प्रतियां मांगें।",
                "quick_answer": "Yes, you can file an RTI for ₹10 without giving any reason, and the officer must respond within 30 days.",
                "quick_answer_te": "అవును, కారణం చెప్పకుండా రూ. 10 తో RTI వేయవచ్చు, అధికారి 30 రోజుల్లో సమాధానం ఇవ్వాలి.",
                "quick_answer_hi": "हाँ, बिना कोई कारण बताए मात्र 10 रुपये में आरटीआई दायर की जा सकती है, और 30 दिनों में उत्तर देना अनिवार्य है।",
                "example_title": "Citizen checking delayed municipal road repair work",
                "example_title_te": "మున్సిపల్ రోడ్డు మరమ్మతుల ఆలస్యంపై RTI దరఖాస్తు",
                "example_title_hi": "सड़क मरम्मत में देरी पर नागरिक द्वारा आरटीआई",
                "example_situation": "A residential colony road was sanctioned 6 months ago but no work began. Colony resident Priya filed an RTI application asking for the sanctioned tender copy and completion deadline.",
                "example_situation_te": "కాలనీ రోడ్డు మంజూరై 6 నెలలు గడిచినా పనులు ప్రారంభం కాలేదు. కాలనీవాసి ప్రియ టెండర్ కాపీ మరియు గడువు వివరాలు కోరుతూ RTI వేసింది.",
                "example_situation_hi": "कॉलोनी की सड़क 6 महीने पहले स्वीकृत हुई थी लेकिन काम शुरू नहीं हुआ। प्रिया ने स्वीकृत टेंडर और कार्य समाप्ति तिथि की जानकारी के लिए आरटीआई लगाई।",
                "example_explanation": "Under Section 6, the municipality was compelled to provide the contractor name and penalty clauses within 30 days, causing the contractor to resume work immediately.",
                "example_explanation_te": "సెక్షన్ 6 ప్రకారం మున్సిపాలిటీ 30 రోజుల్లో టెండర్ వివరాలను అందించడంతో కాంట్రాక్టర్ వెంటనే పనులు ప్రారంభించాడు.",
                "example_explanation_hi": "धारा 6 के तहत नगर पालिका को 30 दिनों में टेंडर विवरण देना पड़ा, जिससे ठेकेदार ने तुरंत काम शुरू कर दिया।",
                "example_disclaimer": "Fictional educational scenario illustrating citizen use of the RTI Act.",
            },

            # ------------------------------------------------------------------
            # 4. LEGAL METROLOGY ACT, 2009 - Consumer Protection on MRP
            # ------------------------------------------------------------------
            {
                "law_short_name": "Legal Metrology 2009",
                "section_number": "Section 18 & 36",
                "title": "Mandatory Declarations on Pre-Packaged Goods and Penalty for Selling Above MRP",
                "title_te": "ప్యాక్ చేసిన వస్తువులపై తప్పనిసరి వివరాలు మరియు MRP కంటే ఎక్కువ అమ్మినందుకు జరిమానా",
                "title_hi": "पैकेज्ड वस्तुओं पर अनिवार्य घोषणाएं और एमआरपी से अधिक पर बेचने पर जुर्माना",
                "legal_text": (
                    "No person shall manufacture, pack, sell, import, distribute, deliver, offer, expose or possess for sale any pre-packaged commodity "
                    "unless such package is in such standard quantities or number and bears thereon such declarations and particulars in such manner as may be prescribed. "
                    "Whoever manufactures, packs, imports, sells, distributes, delivers, offers, exposes or possesses for sale any pre-packaged commodity which does not "
                    "conform to the declarations on the package shall be punished with fine which may extend to twenty-five thousand rupees, for the second offence, "
                    "to fifty thousand rupees and for the subsequent offence, with fine which shall not be less than fifty thousand rupees but which may extend to one lakh "
                    "rupees or with imprisonment for a term which may extend to one year or with both."
                ),
                "simple_explanation": (
                    "No shopkeeper, cinema hall, mall, restaurant, or airport vendor can charge even 1 rupee more than the printed Maximum Retail Price (MRP) "
                    "on any packaged product (like bottled water, soft drinks, or snacks). Dual MRP pricing for the same product is strictly prohibited."
                ),
                "simple_explanation_te": (
                    "ఏ దుకాణదారుడైనా, సినిమా హాల్, మాల్ లేదా విమానాశ్రయంలో ప్యాక్ చేసిన వస్తువులపై (నీళ్ల బాటిల్స్, కూల్‌డ్రింక్స్) ముద్రించిన MRP కంటే ఒక్క రూపాయి కూడా ఎక్కువ వసూలు చేయకూడదు. "
                    "ఒకే వస్తువుకు రెండు వేర్వేరు MRP ధరలు పెట్టడం చట్టవిరుద్ధం."
                ),
                "simple_explanation_hi": (
                    "कोई भी दुकानदार, मॉल, सिनेमा हॉल या हवाई अड्डा विक्रेता पैकेज्ड वस्तु (जैसे पानी की बोतल, स्नैक्स) पर छपे अधिकतम खुदरा मूल्य (MRP) से एक रुपया भी अधिक नहीं ले सकता। "
                    "एक ही उत्पाद पर दोहरे एमआरपी का उपयोग पूर्णतः प्रतिबंधित है।"
                ),
                "purpose": "Protects consumers from extortionate overcharging and ensures mandatory product information (net quantity, expiry date, customer care).",
                "purpose_te": "వినియోగదారులను అదనపు ధరల నుండి రక్షించడం మరియు ప్యాకెట్లపై సరైన వివరాలు ఉండేలా చూడడం.",
                "purpose_hi": "उपभोक्ताओं को अधिक मूल्य वसूली से बचाना और पैकेज पर सही जानकारी सुनिश्चित करना।",
                "punishment": "Fine up to ₹25,000 for first offence, ₹50,000 for second offence, and up to ₹1,00,000 or imprisonment up to 1 year for subsequent offences.",
                "punishment_te": "మొదటి తప్పుకు రూ. 25,000 వరకు జరిమానా, రెండోసారికి రూ. 50,000, ఆ తర్వాత రూ. 1,00,000 వరకు లేదా 1 సంవత్సరం జైలు శిక్ష.",
                "punishment_hi": "पहले अपराध पर 25,000 रुपये तक जुर्माना, दूसरे पर 50,000 रुपये, और बाद के अपराधों पर 1 लाख रुपये तक जुर्माना या 1 वर्ष का कारावास।",
                "effective_date": date(2011, 4, 1),
                "amendment_info": "In force from 1 April 2011; Legal Metrology (Packaged Commodities) Rules amended in 2017 to prohibit dual MRP.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/2070",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "fine",
                "key_elements": "Pre-packaged commodity\nMandatory printed MRP (inclusive of all taxes)\nNet quantity, expiry date, manufacturer address\nSelling above printed MRP is prohibited\nRepeat offence attracts imprisonment",
                "key_elements_te": "ప్యాక్ చేసిన వస్తువు\nఅన్ని పన్నులతో కూడిన MRP ముద్రణ తప్పనిసరి\nనికర పరిమాణం, గడువు తేదీ\nMRP కంటే ఎక్కువ అమ్మడం నిషేధం",
                "key_elements_hi": "पैकेज्ड वस्तु\nसभी करों सहित मुद्रित एमआरपी\nमात्रा, निर्माण व समाप्ति तिथि\nएमआरपी से अधिक बिक्री पर प्रतिबंध",
                "relevant_documents": "Purchase bill / invoice\nPhotograph of product packaging showing printed MRP\nStore receipt showing excess charge",
                "relevant_documents_te": "కొనుగోలు రసీదు / బిల్లు\nప్యాకెట్‌పై ముద్రించిన MRP ఫోటో\nఎక్కువ వసూలు చేసినట్లు చూపించే బిల్లు",
                "relevant_documents_hi": "खरीद रसीद / बिल\nपैकेट पर छपे एमआरपी की फोटो\nअतिरिक्त वसूली दर्शाने वाला बिल",
                "what_you_should_do": "Refuse to pay above printed MRP. Take a photo of the printed MRP and the cash receipt. File a complaint with the National Consumer Helpline (1915) or the State Legal Metrology Department.",
                "what_you_should_do_te": "MRP కంటే ఎక్కువ చెల్లించడానికి నిరాకరించండి. ప్యాకెట్ పై ఉన్న MRP మరియు బిల్లును ఫోటో తీయండి. జాతీయ వినియోగదారుల హెల్ప్‌లైన్ (1915) లేదా లీగల్ మెట్రాలజీ విభాగానికి ఫిర్యాదు చేయండి.",
                "what_you_should_do_hi": "एमआरपी से अधिक भुगतान करने से इनकार करें। छपे मूल्य और बिल की फोटो लें। राष्ट्रीय उपभोक्ता हेल्पलाइन (1915) या विधिक मापविज्ञान विभाग में शिकायत दर्ज करें।",
                "quick_answer": "No, nobody can legally charge above the printed MRP on packaged goods anywhere in India.",
                "quick_answer_te": "లేదు, భారతదేశంలో ఎక్కడా ప్యాక్ చేసిన వస్తువులపై MRP కంటే ఎక్కువ వసూలు చేయడం చట్టవిరుద్ధం.",
                "quick_answer_hi": "नहीं, भारत में कहीं भी पैकेज्ड सामान पर छपे एमआरपी से अधिक वसूलना गैरकानूनी है।",
                "example_title": "Multiplex charging ₹50 for ₹20 water bottle",
                "example_title_te": "రూ. 20 వాటర్ బాటిల్‌కు మల్టీప్లెక్స్ రూ. 50 వసూలు చేయడం",
                "example_title_hi": "मल्टीप्लेक्स द्वारा 20 रुपये की पानी की बोतल पर 50 रुपये की वसूली",
                "example_situation": "A cinema theatre sold a branded sealed water bottle with printed MRP ₹20 for ₹50, claiming 'cooling and service charges'.",
                "example_situation_te": "సినిమా థియేటర్‌లో రూ. 20 MRP ఉన్న వాటర్ బాటిల్‌కు కూలింగ్ ఛార్జీలు అంటూ రూ. 50 వసూలు చేశారు.",
                "example_situation_hi": "एक सिनेमा हॉल ने 20 रुपये एमआरपी वाली पानी की बोतल के लिए 'कूलिंग चार्ज' के नाम पर 50 रुपये वसूले।",
                "example_explanation": "Under Section 36 and the Supreme Court rulings on packaged commodities, charging above printed MRP is an offence. The consumer department fined the theatre management.",
                "example_explanation_te": "సెక్షన్ 36 మరియు సుప్రీంకోర్టు తీర్పుల ప్రకారం MRP కంటే ఎక్కువ తీసుకోవడం నేరం. లీగల్ మెట్రాలజీ అధికారులు థియేటర్‌కు జరిమానా విధించారు.",
                "example_explanation_hi": "धारा 36 और सर्वोच्च न्यायालय के आदेशानुसार एमआरपी से अधिक वसूली अपराध है। उपभोक्ता विभाग ने सिनेमा प्रबंधन पर जुर्माना लगाया।",
                "example_disclaimer": "Fictional educational scenario illustrating anti-profiteering Legal Metrology rules.",
            },

            # ------------------------------------------------------------------
            # 5. HINDU SUCCESSION ACT, 1956 - Equal Rights for Daughters
            # ------------------------------------------------------------------
            {
                "law_short_name": "HSA 1956",
                "section_number": "Section 6",
                "title": "Devolution of Interest in Coparcenary Property (Equal Property Rights for Daughters)",
                "title_te": "ఉమ్మడి కుటుంబ ఆస్తిలో సమాన హక్కులు (కుమార్తెలకు సమాన ఆస్తి హక్కు)",
                "title_hi": "सहदायिकी संपत्ति में बेटियों के समान अधिकार",
                "legal_text": (
                    "On and from the commencement of the Hindu Succession (Amendment) Act, 2005, in a Joint Hindu family governed by the Mitakshara law, "
                    "the daughter of a coparcener shall: (a) by birth become a coparcener in her own right the same manner as the son; "
                    "(b) have the same rights in the coparcenary property as she would have had if she had been a son; "
                    "(c) be subject to the same liabilities in respect of the said coparcenary property as that of a son."
                ),
                "simple_explanation": (
                    "Every daughter has an equal birthright in ancestral (coparcenary) family property, exactly like a son. "
                    "A daughter cannot be denied her share in ancestral property, whether she is married or unmarried, and whether her father was alive "
                    "or deceased in 2005 (confirmed by the Supreme Court in Vineeta Sharma v. Rakesh Sharma).",
                ),
                "simple_explanation_te": (
                    "కుమారులతో సమానంగా ప్రతి కుమార్తెకు ఉమ్మడి పూర్వీకుల ఆస్తిలో పుట్టుకతోనే సమాన హక్కు ఉంటుంది. "
                    "కుమార్తెకు వివాహం అయినా కాకపోయినా పూర్వీకుల ఆస్తిలో సమాన వాటాను నిరాకరించలేరు.",
                ),
                "simple_explanation_hi": (
                    "प्रत्येक बेटी का अपने पिता की पैतृक (सहदायिकी) संपत्ति में बेटे के समान ही जन्म से बराबर का अधिकार है। "
                    "विवाहित या अविवाहित होने पर भी पैतृक संपत्ति में बेटी के समान हिस्से से इनकार नहीं किया जा सकता।",
                ),
                "purpose": "Abolishes gender discrimination in Hindu ancestral property inheritance and guarantees equal coparcenary rights for women.",
                "purpose_te": "హిందూ పూర్వీకుల ఆస్తిలో లింగ వివక్షను తొలగించి మహిళలకు సమాన హక్కులను కల్పించడం.",
                "purpose_hi": "पैतृक संपत्ति में लैंगिक भेदभाव समाप्त करना और महिलाओं को जन्मजात समान अधिकार देना।",
                "punishment": "Civil partition decree enforceable by court; fraudulent exclusion of daughters from partition is void.",
                "punishment_te": "సివిల్ కోర్టు ద్వారా ఆస్తి విభజన ఉత్తర్వులు అమలు చేయబడతాయి; కుమార్తెలను మినహాయించి చేసిన విభజన చెల్లదు.",
                "punishment_hi": "अदालत द्वारा विभाजन डिक्री लागू कराई जाती है; बेटियों को वंचित कर किया गया संपत्ति विभाजन अवैध है।",
                "effective_date": date(2005, 9, 9),
                "amendment_info": "Substituted by the Hindu Succession (Amendment) Act, 2005 (Act 39 of 2005), in force from 9 September 2005.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1572",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "civil",
                "key_elements": "Hindu coparcenary property\nDaughter becomes coparcener by birth\nSame rights and liabilities as a son\nApplies whether married or unmarried",
                "key_elements_te": "హిందూ పూర్వీకుల ఉమ్మడి ఆస్తి\nపుట్టుకతోనే కుమార్తెకు హక్కు\nకుమారుడితో సమాన హక్కులు మరియు బాధ్యతలు\nవివాహంతో సంబంధం లేదు",
                "key_elements_hi": "हिन्दू पैतृक संपत्ति\nजन्म से बेटी का सहदायिक अधिकार\nबेटे के समान अधिकार व दायित्व\nविवाहित या अविवाहित दोनों पर लागू",
                "relevant_documents": "Family pedigree chart (Genealogy / Vamshavruksham)\nRevenue records (Pahani, Jamabandi, RoR)\nTitle deeds of ancestral property\nBirth certificate / Proof of parentage",
                "relevant_documents_te": "కుటుంబ వంశవృక్షం పత్రం\nరెవెన్యూ రికార్డులు (పహాణీ, పట్టాదారు పాస్ పుస్తకం)\nపూర్వీకుల ఆస్తి దస్తావేజులు\nజనన ధృవీకరణ పత్రం",
                "relevant_documents_hi": "पारिवारिक वंशावली\nराजस्व रिकॉर्ड (खतौनी, जमाबंदी)\nपैतृक संपत्ति के दस्तावेज\nजन्म प्रमाण पत्र / वल्दियत प्रमाण",
                "what_you_should_do": "Obtain certified copies of ancestral property revenue records and family genealogy. If brothers or relatives refuse partition, send a legal notice demanding your 1/nth share and file a Suit for Partition in the competent Civil Court.",
                "what_you_should_do_te": "పూర్వీకుల ఆస్తి రెవెన్యూ రికార్డులు మరియు వంశవృక్షం పత్రాలను పొందండి. కుటుంబ సభ్యులు వాటా ఇవ్వడానికి నిరాకరిస్తే, లీగల్ నోటీసు పంపి సివిల్ కోర్టులో విభజన దావా (Partition Suit) వేయండి.",
                "what_you_should_do_hi": "पैतृक संपत्ति के राजस्व रिकॉर्ड और वंशावली की प्रमाणित प्रतियां प्राप्त करें। हिस्सा न मिलने पर कानूनी नोटिस भेजें और सिविल कोर्ट में बंटवारे का मुकदमा (Partition Suit) दायर करें।",
                "quick_answer": "Yes, daughters have 100% equal legal rights in ancestral property as sons by birth.",
                "quick_answer_te": "అవును, పూర్వీకుల ఆస్తిలో కుమారులతో సమానంగా కుమార్తెలకు పుట్టుకతోనే పూర్తి సమాన హక్కులు ఉంటాయి.",
                "quick_answer_hi": "हाँ, बेटियों को पैतृक संपत्ति में बेटों के बिल्कुल बराबर जन्मजात कानूनी अधिकार प्राप्त हैं।",
                "example_title": "Daughter claiming ancestral agricultural land share",
                "example_title_te": "పూర్వీకుల వ్యవసాయ భూమిలో కుమార్తె వాటా దావా",
                "example_title_hi": "पैतृक कृषि भूमि में बेटी द्वारा हिस्से का दावा",
                "example_situation": "Sunita's two brothers divided 6 acres of ancestral agricultural land between themselves after their father passed away, giving Sunita nothing because she was married.",
                "example_situation_te": "తండ్రి మరణించిన తర్వాత సునీత ఇద్దరు సోదరులు 6 ఎకరాల పూర్వీకుల భూమిని పంచుకున్నారు. ఆమెకు వివాహం అయిందనే కారణంతో ఏమీ ఇవ్వలేదు.",
                "example_situation_hi": "सुनीता के दो भाइयों ने पिता की मृत्यु के बाद 6 एकड़ पैतृक भूमि आपस में बांट ली और सुनीता को विवाहित बताकर हिस्सा देने से मना कर दिया।",
                "example_explanation": "Under Section 6, Sunita is an equal coparcener by birth entitled to 2 acres (1/3rd share). The Civil Court set aside the brothers' private partition and granted Sunita her 2 acres.",
                "example_explanation_te": "సెక్షన్ 6 ప్రకారం సునీతకు పుట్టుకతోనే సమానంగా 2 ఎకరాల (1/3 వాటా) హక్కు ఉంది. సివిల్ కోర్టు సోదరుల ప్రైవేట్ విభజనను రద్దు చేసి సునీతకు 2 ఎకరాల వాటాను మంజూరు చేసింది.",
                "example_explanation_hi": "धारा 6 के तहत सुनीता को 2 एकड़ (एक-तिहाई हिस्सा) पाने का समान अधिकार है। अदालत ने भाइयों के निजी बंटवारे को खारिज कर सुनीता को उसका हिस्सा दिया।",
                "example_disclaimer": "Fictional educational scenario explaining Section 6 coparcenary succession.",
            },

            # ------------------------------------------------------------------
            # 6. SENIOR CITIZENS ACT, 2007 - Maintenance and Property Protection
            # ------------------------------------------------------------------
            {
                "law_short_name": "Senior Citizens Act 2007",
                "section_number": "Section 4 & 23",
                "title": "Maintenance of Parents and Transfer of Property Void in Certain Circumstances",
                "title_te": "తల్లిదండ్రుల భరణం మరియు కొన్ని సందర్భాలలో ఆస్తి బదిలీ రద్దు",
                "title_hi": "वरिष्ठ नागरिकों का भरण-पोषण और संपत्ति अंतरण का शून्य होना",
                "legal_text": (
                    "A senior citizen including parent who is unable to maintain himself from his own earning or out of property owned by him, "
                    "shall be entitled to make an application under section 5 against children or relatives for monthly maintenance. "
                    "Where any senior citizen who, after the commencement of this Act, has transferred by way of gift or otherwise, his property, "
                    "subject to the condition that the transferee shall provide the basic amenities and basic physical needs to the transferor and such transferee "
                    "refuses or fails to provide such amenities and physical needs, the said transfer of property shall be deemed to have been made by fraud "
                    "or coercion or under undue influence and shall at the option of the transferor be declared void by the Tribunal."
                ),
                "simple_explanation": (
                    "Senior citizens (60+) can claim monthly maintenance (up to ₹10,000) from their children or legal heirs through a fast Maintenance Tribunal. "
                    "Crucially, if an elderly parent gifted their home to a child on condition of care, and the child later neglects or abuses them, "
                    "the Maintenance Tribunal can declare the gift deed VOID and restore ownership back to the parent.",
                ),
                "simple_explanation_te": (
                    "60 ఏళ్లు పైబడిన సీనియర్ సిటిజన్లు లేదా తల్లిదండ్రులు తమ పిల్లల నుండి మెయింటెనెన్స్ ట్రిబ్యునల్ ద్వారా నెలవారీ భరణం పొందవచ్చు. "
                    "పిల్లలకు సంరక్షణ షరతుతో ఇల్లు లేదా ఆస్తిని గిఫ్ట్ ఇచ్చిన తర్వాత వారు సరిగ్గా చూసుకోకపోతే, ఆ గిఫ్ట్ డీడ్‌ను రద్దు చేసి ఆస్తిని తిరిగి తల్లిదండ్రులకే ఇప్పించవచ్చు.",
                ),
                "simple_explanation_hi": (
                    "60 वर्ष से अधिक आयु के बुजुर्ग माता-पिता भरण-पोषण न्यायाधिकरण के माध्यम से अपने बच्चों से मासिक गुजारा भत्ता प्राप्त कर सकते हैं। "
                    "यदि किसी बुजुर्ग ने देखभाल की शर्त पर अपनी संपत्ति बच्चे को दान (Gift) की है और बच्चा उपेक्षा करता है, तो न्यायाधिकरण उस दान विलेख को रद्द कर सकता है।",
                ),
                "purpose": "Provides rapid summary redress for elderly parents to secure dignified maintenance and recover property gifted to neglectful children.",
                "purpose_te": "వృద్ధుల ఆత్మగౌరవాన్ని కాపాడటం మరియు సంరక్షణ చేయని పిల్లలకు ఇచ్చిన ఆస్తిని సులభంగా తిరిగి పొందేలా చేయడం.",
                "purpose_hi": "बुजुर्गों के सम्मानजनक भरण-पोषण की व्यवस्था करना और उपेक्षा करने वाले बच्चों से संपत्ति वापस दिलाना।",
                "punishment": "Tribunal order enforceable as a judicial order; non-payment attracts warrant and imprisonment up to 1 month under Section 5(8).",
                "punishment_te": "ట్రిబ్యునల్ ఆదేశాలు పాటించకపోతే సెక్షన్ 5(8) కింద జైలు శిక్ష లేదా వారెంట్ జారీ చేయవచ్చు.",
                "punishment_hi": "आदेश का पालन न करने पर धारा 5(8) के तहत वारंट और 1 महीने तक की कैद हो सकती है।",
                "effective_date": date(2007, 12, 29),
                "amendment_info": "Enacted in December 2007; tribunals established at Sub-Divisional (RDO/SDM) level across all states.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/2056",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "order",
                "key_elements": "Senior citizen (aged 60+) or parent\nUnable to maintain self from own earnings\nChildren / relatives with sufficient means\nTransferred property conditional on care\nTribunal has power to cancel transfer under Section 23",
                "key_elements_te": "60 ఏళ్లు పైబడిన వ్యక్తి లేదా తల్లిదండ్రులు\nస్వతంత్ర ఆదాయం లేకపోవడం\nఆదాయం ఉన్న పిల్లలు\nసంరక్షణ షరతుతో ఆస్తి బదిలీ\nసెక్షన్ 23 కింద ఆస్తి బదిలీని రద్దు చేసే అధికారం",
                "key_elements_hi": "60 वर्ष से अधिक आयु\nस्वयं का भरण-पोषण करने में असमर्थ\nसक्षम बच्चे या रिश्तेदार\nदेखभाल की शर्त पर संपत्ति का अंतरण\nधारा 23 के तहत रजिस्ट्री रद्द करने का अधिकार",
                "relevant_documents": "Age proof (Aadhaar / Voter ID)\nGift Deed / Settlement Deed copy\nMedical bills and monthly expense details\nComplaint petition before Sub-Divisional Magistrate (SDM/RDO)",
                "relevant_documents_te": "వయస్సు ధృవీకరణ (ఆధార్ కార్డు)\nగిఫ్ట్ డీడ్ / సెటిల్‌మెంట్ డీడ్ కాపీ\nవైద్య ఖర్చుల వివరాలు\nRDO/సబ్-కలెక్టర్ ట్రిబ్యునల్ వద్ద దరఖాస్తు",
                "relevant_documents_hi": "आयु प्रमाण (आधार कार्ड)\nगिफ्ट डीड की प्रति\nमासिक खर्च व मेडिकल बिल\nएसडीएम / आरडीओ ट्रिब्यूनल में आवेदन",
                "what_you_should_do": "File a direct application before the Sub-Divisional Magistrate (SDM/RDO Maintenance Tribunal). No advocate is required. Request monthly maintenance and cancellation of property settlement under Section 23.",
                "what_you_should_do_te": "సబ్-డివిజనల్ మేజిస్ట్రేట్ (RDO మెయింటెనెన్స్ ట్రిబ్యునల్) వద్ద నేరుగా దరఖాస్తు చేయండి. న్యాయవాది అవసరం లేదు. సెక్షన్ 23 కింద ఆస్తి రద్దు మరియు భరణం కోరండి.",
                "what_you_should_do_hi": "एसडीएम (रखरखाव न्यायाधिकरण) के समक्ष सीधे आवेदन करें। वकील की जरूरत नहीं है। धारा 23 के तहत संपत्ति रद्दीकरण और मासिक भरण-पोषण की मांग करें।",
                "quick_answer": "Yes, elderly parents can cancel a property gift deed and get maintenance if their child neglects them.",
                "quick_answer_te": "అవును, పిల్లలు పట్టించుకోకపోతే తల్లిదండ్రులు గిఫ్ట్ డీడ్‌ను రద్దు చేసి ఆస్తిని తిరిగి పొందవచ్చు.",
                "quick_answer_hi": "हाँ, बच्चे द्वारा उपेक्षा किए जाने पर बुजुर्ग माता-पिता गिफ्ट डीड रद्द कराकर संपत्ति वापस ले सकते हैं।",
                "example_title": "Elderly father recovering gifted house from abusive son",
                "example_title_te": "కుమారుడికి ఇచ్చిన ఇంటిని తిరిగి పొందిన వృద్ధ తండ్రి",
                "example_title_hi": "पुत्र को दी गई संपत्ति वापस प्राप्त करने वाले बुजुर्ग पिता",
                "example_situation": "72-year-old Gopal gifted his ancestral house to his son on the express promise that he would be cared for. Within months, the son locked Gopal out and refused food and medicines.",
                "example_situation_te": "72 ఏళ్ల గోపాల్ తన ఇంటిని కొడుకు పేరిట రాసిచ్చాడు. ఆ తర్వాత కొడుకు అతనికి ఆహారం, మందులు ఇవ్వకుండా ఇంటి నుంచి గెంటివేశాడు.",
                "example_situation_hi": "72 वर्षीय गोपाल ने देखभाल के वादे पर अपना मकान बेटे के नाम कर दिया। बाद में बेटे ने गोपाल को घर से निकाल दिया।",
                "example_explanation": "Gopal petitioned the Maintenance Tribunal under Section 23. The Tribunal declared the gift deed void, restored possession to Gopal, and ordered ₹6,000 monthly maintenance.",
                "example_explanation_te": "గోపాల్ సెక్షన్ 23 కింద ట్రిబ్యునల్‌ను ఆశ్రయించాడు. ట్రిబ్యునల్ గిఫ్ట్ డీడ్‌ను రద్దు చేసి, ఇంటిని గోపాల్‌కు ఇప్పించడంతో పాటు నెలకు రూ. 6,000 భరణం ఇప్పించింది.",
                "example_explanation_hi": "गोपाल ने न्यायाधिकरण में धारा 23 के तहत याचिका दायर की। न्यायाधिकरण ने गिफ्ट डीड को शून्य घोषित कर गोपाल को मकान का कब्जा और भरण-पोषण दिलाया।",
                "example_disclaimer": "Fictional educational example demonstrating Section 23 property restoration.",
            },

            # ------------------------------------------------------------------
            # 7. REAL ESTATE (REGULATION AND DEVELOPMENT) ACT, 2016 (RERA)
            # ------------------------------------------------------------------
            {
                "law_short_name": "RERA 2016",
                "section_number": "Section 18",
                "title": "Return of Amount and Compensation for Delay in Real Estate Possession",
                "title_te": "రియల్ ఎస్టేట్ స్వాధీనంలో ఆలస్యానికి మొత్తం వాపసు మరియు పరిహారం",
                "title_hi": "फ्लैट पजेशन में देरी पर ब्याज सहित रिफंड और मुआवजा",
                "legal_text": (
                    "If the promoter fails to complete or is unable to give possession of an apartment, plot or building, in accordance with the terms "
                    "of the agreement for sale or, as the case may be, duly completed by the date specified therein, he shall be liable on demand to the allottees, "
                    "in case the allottee wishes to withdraw from the project, without prejudice to any other remedy available, to return the amount received by him "
                    "in respect of that apartment, plot, building, as the case may be, with interest at such rate as may be prescribed in this behalf including compensation: "
                    "Provided that where an allottee does not intend to withdraw from the project, he shall be paid, by the promoter, interest for every month of delay, "
                    "till the handing over of the possession."
                ),
                "simple_explanation": (
                    "If a builder fails to hand over possession of your flat or plot by the promised date in the agreement, you have two clear legal choices under RERA: "
                    "1. Withdraw from the project and demand a FULL REFUND of all money paid plus prescribed bank interest (SBI MCLR + 2%) and compensation; OR "
                    "2. Stay in the project and receive monthly interest from the builder for every single month of delay until possession is given.",
                ),
                "simple_explanation_te": (
                    "బిల్డర్ ఒప్పందంలో పేర్కొన్న గడువులోగా ఫ్లాట్ లేదా ప్లాట్ అప్పగించడంలో విఫలమైతే, కొనుగోలుదారునికి RERA కింద రెండు స్పష్టమైన హక్కులు ఉన్నాయి: "
                    "1. ప్రాజెక్ట్ నుండి వైదొలగి చెల్లించిన మొత్తం డబ్బును వడ్డీతో (SBI రేటు + 2%) సహా వాపసు తీసుకోవడం; లేదా "
                    "2. ప్రాజెక్ట్‌లో కొనసాగుతూ ఫ్లాట్ ఇచ్చే వరకు ప్రతి నెలా ఆలస్యానికి వడ్డీ పరిహారం పొందడం.",
                ),
                "simple_explanation_hi": (
                    "यदि बिल्डर अनुबंध में तय समय पर फ्लैट या प्लॉट का कब्जा देने में विफल रहता है, तो रेरा के तहत खरीदार के पास दो अधिकार हैं: "
                    "1. प्रोजेक्ट से बाहर निकलकर अपनी पूरी जमा राशि ब्याज सहित वापस मांगना; या "
                    "2. प्रोजेक्ट में बने रहकर कब्जा मिलने तक हर महीने का ब्याज प्राप्त करना।",
                ),
                "purpose": "Shields home buyers against predatory builder delays and establishes statutory right to interest and refunds.",
                "purpose_te": "బిల్డర్ల ప్రాజెక్ట్ ఆలస్యం నుండి ఇళ్ల కొనుగోలుదారులను రక్షించడం మరియు వడ్డీతో కూడిన వాపసు హక్కు కల్పించడం.",
                "purpose_hi": "बिल्डरों की मनमानी और देरी से घर खरीदारों को बचाना और समयबद्ध पजेशन या रिफंड सुनिश्चित करना।",
                "punishment": "Non-compliance with RERA orders attracts penalty up to 5% of project cost or imprisonment up to 3 years under Section 63/64.",
                "punishment_te": "RERA ఆదేశాలను పాటించని బిల్డర్‌పై ప్రాజెక్ట్ వ్యయంలో 5% వరకు జరిమానా లేదా 3 సంవత్సరాల వరకు జైలు శిక్ష విధించవచ్చు.",
                "punishment_hi": "रेरा आदेशों का उल्लंघन करने पर बिल्डर को प्रोजेक्ट लागत का 5% जुर्माना या 3 साल तक की कैद हो सकती है।",
                "effective_date": date(2017, 5, 1),
                "amendment_info": "In force nationwide since 1 May 2017 across all states and Union Territories.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/2158",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "civil",
                "key_elements": "Registered RERA project\nAgreement for Sale with agreed possession date\nPromoter fails to deliver possession on time\nAllottee option: Complete refund with interest OR monthly delay interest\nAdjudicating Officer awards compensation",
                "key_elements_te": "RERA రిజిస్టర్డ్ ప్రాజెక్ట్\nస్వాధీన గడువుతో కూడిన సేల్ అగ్రిమెంట్\nసకాలంలో ఫ్లాట్ ఇవ్వడంలో బిల్డర్ వైఫల్యం\nవడ్డీతో కూడిన పూర్తి వాపసు లేదా నెలవారీ ఆలస్య వడ్డీ",
                "key_elements_hi": "रेरा पंजीकृत प्रोजेक्ट\nपजेशन तिथि वाला बिल्डर-बायर एग्रीमेंट\nसमय पर फ्लैट देने में विफलता\nब्याज सहित पूरा रिफंड या मासिक देरी ब्याज",
                "relevant_documents": "Agreement for Sale (Builder-Buyer Agreement)\nBank payment receipts / account statement showing disbursements\nBuilder delay communication letters / emails\nRERA project registration number",
                "relevant_documents_te": "సేల్ అగ్రిమెంట్ (బిల్డర్-బయర్ ఒప్పందం)\nచెల్లింపు రసీదులు మరియు బ్యాంక్ స్టేట్‌మెంట్\nఆలస్యంపై ఈమెయిళ్లు\nRERA ప్రాజెక్ట్ రిజిస్ట్రేషన్ నంబర్",
                "relevant_documents_hi": "बिल्डर-बायर एग्रीमेंट\nभुगतान की रसीदें व बैंक स्टेटमेंट\nईमेल पत्राचार\nरेरा प्रोजेक्ट रजिस्ट्रेशन नंबर",
                "what_you_should_do": "Check your RERA project number online. File an online complaint under Section 31 before the State Real Estate Regulatory Authority (RERA) portal specifying whether you demand refund with interest or monthly delay interest.",
                "what_you_should_do_te": "ఆన్‌లైన్‌లో RERA పోర్టల్‌లో ప్రాజెక్ట్ నంబర్ తనిఖీ చేయండి. సెక్షన్ 31 కింద రాష్ట్ర RERA పోర్టల్‌లో ఫిర్యాదు దాఖలు చేసి రీఫండ్ లేదా నెలవారీ వడ్డీని క్లెయిమ్ చేయండి.",
                "what_you_should_do_hi": "राज्य के रेरा पोर्टल पर धारा 31 के तहत ऑनलाइन शिकायत दर्ज करें और स्पष्ट करें कि आप ब्याज सहित रिफंड चाहते हैं या मासिक देरी का ब्याज।",
                "quick_answer": "Yes, under RERA Section 18 you can demand a 100% refund with interest or monthly delay penalty.",
                "quick_answer_te": "అవును, RERA సెక్షన్ 18 కింద మీరు పూర్తి డబ్బును వడ్డీతో వాపసు పొందవచ్చు లేదా నెలవారీ ఆలస్య వడ్డీని పొందవచ్చు.",
                "quick_answer_hi": "हाँ, रेरा धारा 18 के तहत आप ब्याज सहित पूरा रिफंड या मासिक देरी का ब्याज मांग सकते हैं।",
                "example_title": "Home buyer delayed by 2 years demanding full refund",
                "example_title_te": "2 ఏళ్ల పాటు ఆలస్యమైన ఫ్లాట్ కోసం కొనుగోలుదారు రీఫండ్ క్లెయిమ్",
                "example_title_hi": "2 साल की देरी पर घर खरीदार द्वारा पूरे रिफंड की मांग",
                "example_situation": "Vikram booked an apartment in an under-construction project in 2021 with promised delivery by June 2024. In late 2024, the structure was barely half-complete.",
                "example_situation_te": "విక్రమ్ జూన్ 2024 గడువుతో ఫ్లాట్ బుక్ చేసుకున్నాడు. గడువు ముగిసినా ప్రాజెక్ట్ సగం కూడా పూర్తి కాలేదు.",
                "example_situation_hi": "विक्रम ने जून 2024 तक पजेशन के वादे पर फ्लैट बुक किया। 2024 के अंत तक भी प्रोजेक्ट आधा-अधूरा था।",
                "example_explanation": "Vikram filed a complaint under Section 18 before RERA. The Authority directed the builder to refund Vikram's entire ₹45 lakhs along with 10.75% annual interest within 60 days.",
                "example_explanation_te": "విక్రమ్ RERAలో ఫిర్యాదు చేశాడు. అథారిటీ బిల్డర్‌ను 60 రోజుల్లో విక్రమ్ చెల్లించిన మొత్తం ₹45 లక్షలను 10.75% వడ్డీతో తిరిగి చెల్లించాలని ఆదేశించింది.",
                "example_explanation_hi": "विक्रम ने रेरा में धारा 18 के तहत शिकायत दर्ज की। प्राधिकरण ने बिल्डर को 60 दिनों में 10.75% ब्याज सहित पूरे 45 लाख रुपये लौटाने का आदेश दिया।",
                "example_disclaimer": "Fictional educational example illustrating RERA Section 18 relief.",
            },

            # ------------------------------------------------------------------
            # 8. CONSTITUTION OF INDIA - Fundamental Freedoms & Writs
            # ------------------------------------------------------------------
            {
                "law_short_name": "COI 1950",
                "section_number": "Article 19(1)(a)",
                "title": "Protection of Certain Rights Regarding Freedom of Speech and Expression",
                "title_te": "వాక్ మరియు భావ ప్రకటన స్వేచ్ఛ హక్కు రక్షణ",
                "title_hi": "वाक्-स्वातंत्र्य और अभिव्यक्ति की स्वतंत्रता का अधिकार",
                "legal_text": (
                    "All citizens shall have the right to freedom of speech and expression. "
                    "Nothing in sub-clause (a) of clause (1) shall affect the operation of any existing law, or prevent the State from making any law, "
                    "in so far as such law imposes reasonable restrictions on the exercise of the right conferred by the said sub-clause in the interests of "
                    "the sovereignty and integrity of India, the security of the State, friendly relations with foreign States, public order, decency or morality "
                    "or in relation to contempt of court, defamation or incitement to an offence."
                ),
                "simple_explanation": (
                    "Every citizen has the constitutional freedom to express opinions, speak, write, publish news, and criticize government policies peacefully. "
                    "The State can only restrict this right on strict, narrow grounds specified in Article 19(2) (such as national security, sovereignty, public order, or decency).",
                ),
                "simple_explanation_te": (
                    "ప్రతి పౌరుడికి మాట్లాడే, రాసే, అభిప్రాయాలను వ్యక్తం చేసే మరియు శాంతియుతంగా ప్రభుత్వాన్ని ప్రశ్నించే ప్రాథమిక రాజ్యాంగ హక్కు ఉంది. "
                    "దేశ భద్రత, సార్వభౌమాధికారం మరియు శాంతిభద్రతల వంటి పరిమిత కారణాలపై మాత్రమే సహేతుకమైన ఆంక్షలు విధించవచ్చు.",
                ),
                "simple_explanation_hi": (
                    "प्रत्येक नागरिक को अपने विचार व्यक्त करने, बोलने, लिखने और शांतिपूर्ण ढंग से सरकारी नीतियों की आलोचना करने की संवैधानिक स्वतंत्रता है। "
                    "राज्य केवल अनुच्छेद 19(2) में दिए गए सीमित आधारों (जैसे राष्ट्रीय सुरक्षा, लोक व्यवस्था) पर ही उचित प्रतिबंध लगा सकता है।",
                ),
                "purpose": "Foundational pillar of Indian democracy ensuring free dissemination of ideas and press freedom.",
                "purpose_te": "భారత ప్రజాస్వామ్యానికి పునాది అయిన భావ వ్యక్తీకరణ మరియు పత్రికా స్వేచ్ఛను పరిరక్షించడం.",
                "purpose_hi": "भारतीय लोकतंत्र के मूल स्तंभ के रूप में विचार अभिव्यक्ति और प्रेस की स्वतंत्रता सुनिश्चित करना।",
                "punishment": "Unconstitutional censorship or unlawful arrest violates Fundamental Rights; damages/writs grantable by Constitutional Courts.",
                "punishment_te": "చట్టవిరుద్ధమైన సెన్సార్‌షిప్ లేదా అరెస్టు ప్రాథమిక హక్కులను ఉల్లంఘిస్తుంది; కోర్టులు రక్షణ కల్పిస్తాయి.",
                "punishment_hi": "असंवैधानिक रोक या अवैध गिरफ्तारी मौलिक अधिकारों का उल्लंघन है; संवैधानिक अदालतें राहत प्रदान करती हैं।",
                "effective_date": date(1950, 1, 26),
                "amendment_info": "Amended by the Constitution (First Amendment) Act, 1951 and Sixteenth Amendment Act, 1963.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/15240",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "civil",
                "key_elements": "Citizen of India\nRight to express thoughts by words, writing, printing, or media\nIncludes freedom of press and right to circulate\nSubject only to reasonable restrictions under Article 19(2)",
                "key_elements_te": "భారత పౌరసత్వం\nమాటలు, రచనలు, ప్రింటింగ్ ద్వారా భావ వ్యక్తీకరణ\nపత్రికా స్వేచ్ఛను కలిగి ఉంటుంది\nఆర్టికల్ 19(2) పరిమితులకు లోబడి ఉంటుంది",
                "key_elements_hi": "भारतीय नागरिक\nशब्दों, लेखन या मीडिया द्वारा अभिव्यक्ति\nप्रेस की स्वतंत्रता शामिल\nअनुच्छेद 19(2) के उचित प्रतिबंधों के अधीन",
                "relevant_documents": "Published text / video / speech transcript\nImpugned government order or notice\nWrit petition under Article 226/32",
                "relevant_documents_te": "ప్రచురించిన వ్యాసం లేదా వీడియో కాపీ\nప్రభుత్వ నిషేధ ఉత్తర్వు\nరిట్ పిటిషన్ పత్రాలు",
                "relevant_documents_hi": "प्रकाशित लेख या वीडियो\nसरकारी रोक आदेश की प्रति\nरिट याचिका दस्तावेज",
                "what_you_should_do": "Exercise speech responsibly without inciting violence or hate speech. If a police complaint or gag order is issued without lawful grounds, approach High Court under Article 226 to quash the order.",
                "what_you_should_do_te": "బాధ్యతాయుతంగా భావ ప్రకటనా స్వేచ్ఛను వినియోగించండి. చట్టవిరుద్ధంగా నోటీసులు లేదా ఆంక్షలు విధిస్తే హైకోర్టులో ఆర్టికల్ 226 కింద సవాలు చేయండి.",
                "what_you_should_do_hi": "हिंसा या घृणा भाषण को बढ़ावा दिए बिना जिम्मेदारी से अपने विचार व्यक्त करें। अनुचित प्रतिबंध लगने पर उच्च न्यायालय में अनुच्छेद 226 के तहत चुनौती दें।",
                "quick_answer": "Yes, Article 19(1)(a) protects freedom of speech and expression, subject only to reasonable restrictions.",
                "quick_answer_te": "అవును, ఆర్టికల్ 19(1)(a) వాక్ మరియు భావ ప్రకటన స్వేచ్ఛకు రాజ్యాంగ రక్షణ కల్పిస్తుంది.",
                "quick_answer_hi": "हाँ, अनुच्छेद 19(1)(a) वाक् और अभिव्यक्ति की स्वतंत्रता की गारंटी देता है।",
                "example_title": "Citizen blogging peaceful criticism of local road infrastructure",
                "example_title_te": "రోడ్ల పరిస్థితిపై పౌరుడి శాంతియుత విమర్శల బ్లాగ్",
                "example_title_hi": "खराब सड़कों पर नागरिक द्वारा शांतिपूर्ण ब्लॉग लेखन",
                "example_situation": "An engineer wrote a well-researched blog showing substandard road construction by the local municipality. A local officer threatened him with a criminal complaint for defaming the department.",
                "example_situation_te": "ఒక ఇంజనీర్ స్థానిక మున్సిపల్ రోడ్ల నాణ్యత లోపంపై బ్లాగ్‌లో రాశాడు. డిపార్ట్‌మెంట్‌పై దుష్ప్రచారం చేశాడని అధికారి కేసు పెడతానని బెదిరించాడు.",
                "example_situation_hi": "एक नागरिक ने नगर पालिका द्वारा बनाई गई घटिया सड़क का फोटो सहित ब्लॉग लिखा। अधिकारी ने मानहानि का मुकदमा दर्ज करने की धमकी दी।",
                "example_explanation": "Under Article 19(1)(a), peaceful, truthful critique of public works is protected speech in the public interest. The High Court protects citizens against frivolous intimidation.",
                "example_explanation_te": "ఆర్టికల్ 19(1)(a) ప్రకారం ప్రభుత్వ పనులపై ప్రజా ప్రయోజనార్థం చేసే నిజమైన విమర్శ రక్షించబడుతుంది. తప్పుడు కేసులను కోర్టులు కొట్టివేస్తాయి.",
                "example_explanation_hi": "अनुच्छेद 19(1)(a) के तहत जनहित में की गई तथ्यात्मक आलोचना पूरी तरह संरक्षित है। अधिकारी की धमकी गैरकानूनी है।",
                "example_disclaimer": "Fictional educational example illustrating Article 19(1)(a) protections.",
            },
            {
                "law_short_name": "COI 1950",
                "section_number": "Article 32",
                "title": "Remedies for Enforcement of Fundamental Rights (Constitutional Writs)",
                "title_te": "ప్రాథమిక హక్కుల అమలు కోసం పరిహారాలు (రాజ్యాంగ రిట్లు)",
                "title_hi": "मौलिक अधिकारों को प्रवर्तित कराने के लिए उपचार (संवैधानिक रिट)",
                "legal_text": (
                    "The right to move the Supreme Court by appropriate proceedings for the enforcement of the rights conferred by this Part is guaranteed. "
                    "The Supreme Court shall have power to issue directions or orders or writs, including writs in the nature of habeas corpus, mandamus, "
                    "prohibition, quo warranto and certiorari, whichever may be appropriate, for the enforcement of any of the rights conferred by this Part."
                ),
                "simple_explanation": (
                    "Article 32 is called the 'Heart and Soul of the Constitution' (Dr. B.R. Ambedkar). It gives every citizen the direct right to approach "
                    "the Supreme Court of India if any of their Fundamental Rights are violated. The Court can issue 5 powerful Writs: Habeas Corpus (release illegal detainee), "
                    "Mandamus (order public official to perform duty), Certiorari (quash unlawful order), Prohibition, and Quo Warranto.",
                ),
                "simple_explanation_te": (
                    "ఆర్టికల్ 32 భారత రాజ్యాంగానికి 'హృదయం మరియు ఆత్మ' వంటిది. పౌరుల ప్రాథమిక హక్కులు ఉల్లంఘించబడినప్పుడు నేరుగా సుప్రీంకోర్టును ఆశ్రయించే హక్కును ఇది కల్పిస్తుంది. "
                    "సుప్రీంకోర్టు 5 రకాల రిట్లను జారీ చేయగలదు: హేబియస్ కార్పస్, మాండమస్, సెర్టియోరారి, ప్రొహిబిషన్, కో-వారంటో.",
                ),
                "simple_explanation_hi": (
                    "अनुच्छेद 32 को डॉ. बी.आर. आंबेडकर ने 'संविधान की आत्मा और हृदय' कहा था। यह नागरिकों को अपने मौलिक अधिकारों के हनन पर सीधे सर्वोच्च न्यायालय जाने का अधिकार देता है। "
                    "न्यायालय 5 प्रकार की रिट जारी कर सकता है: बंदी प्रत्यक्षीकरण, परमादेश, प्रतिषेध, उत्प्रेषण और अधिकार-पृच्छा।",
                ),
                "purpose": "Guarantees direct constitutional remedies from the highest court of the land against fundamental rights violations.",
                "purpose_te": "ప్రాథమిక హక్కుల రక్షణ కోసం దేశ అత్యున్నత న్యాయస్థానం నుండి ప్రత్యక్ష పరిహారాన్ని అందించడం.",
                "purpose_hi": "मौलिक अधिकारों की सुरक्षा के लिए देश की सर्वोच्च अदालत से सीधे संवैधानिक उपचार सुनिश्चित करना।",
                "punishment": "Contempt of Supreme Court for disobedience of writ orders is punishable with fine and imprisonment under Article 129.",
                "punishment_te": "సుప్రీంకోర్టు రిట్ ఉత్తర్వులను ఉల్లంఘిస్తే ఆర్టికల్ 129 కింద కోర్టు ధిక్కార నేరంగా పరిగణించి జైలు శిక్ష విధించవచ్చు.",
                "punishment_hi": "सर्वोच्च न्यायालय के रिट आदेशों की अवहेलना करने पर अनुच्छेद 129 के तहत अवमानना की सजा हो सकती है।",
                "effective_date": date(1950, 1, 26),
                "amendment_info": "Basic structure of the Constitution; cannot be curtailed even by constitutional amendment.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/15240",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "order",
                "key_elements": "Direct remedy before Supreme Court\nEnforcement of Fundamental Rights (Part III)\nFive prerogative writs\nCannot be suspended except under emergency",
                "key_elements_te": "సుప్రీంకోర్టులో ప్రత్యక్ష విచారణ\nప్రాథమిక హక్కుల అమలు\n5 రకాల రాజ్యాంగ రిట్లు\nఎమర్జెన్సీలో తప్ప రద్దు చేయలేరు",
                "key_elements_hi": "सर्वोच्च न्यायालय में सीधा उपचार\nमौलिक अधिकारों का प्रवर्तन\n5 संवैधानिक रिट\nआपातकाल के अलावा निलंबित नहीं किया जा सकता",
                "relevant_documents": "Writ Petition under Article 32\nAffidavit verifying facts\nCopies of unlawful orders / proof of rights infringement",
                "relevant_documents_te": "ఆర్టికల్ 32 కింద రిట్ పిటిషన్\nఅఫిడవిట్\nచట్టవిరుద్ధ ఉత్తర్వులు లేదా హక్కుల ఉల్లంఘన ఆధారాలు",
                "relevant_documents_hi": "अनुच्छेद 32 के तहत रिट याचिका\nशपथ पत्र\nअवैध आदेश या अधिकार हनन के साक्ष्य",
                "what_you_should_do": "If a government authority violates your Fundamental Rights (life, speech, equality, freedom from arbitrary arrest), engage an Advocate-on-Record to file a Writ Petition directly before the Supreme Court under Article 32.",
                "what_you_should_do_te": "ప్రభుత్వ అధికారులు మీ ప్రాథమిక హక్కులను ఉల్లంఘిస్తే, అడ్వకేట్-ఆన్-రికార్డ్ ద్వారా సుప్రీంకోర్టులో ఆర్టికల్ 32 కింద రిట్ పిటిషన్ దాఖలు చేయండి.",
                "what_you_should_do_hi": "यदि कोई सरकारी प्राधिकरण आपके मौलिक अधिकारों का हनन करता है, तो सर्वोच्च न्यायालय में सीधे अनुच्छेद 32 के तहत रिट याचिका दायर करें।",
                "quick_answer": "Yes, Article 32 gives you the direct right to approach the Supreme Court to enforce your Fundamental Rights.",
                "quick_answer_te": "అవును, ప్రాథమిక హక్కుల పరిరక్షణ కోసం నేరుగా సుప్రీంకోర్టును ఆశ్రయించే హక్కును ఆర్టికల్ 32 కల్పిస్తుంది.",
                "quick_answer_hi": "हाँ, अनुच्छेद 32 मौलिक अधिकारों के प्रवर्तन के लिए सीधे सर्वोच्च न्यायालय जाने का अधिकार देता है।",
                "example_title": "Writ of Habeas Corpus filed for citizen detained in secret custody",
                "example_title_te": "రహస్య నిర్బంధంలో ఉన్న పౌరుడి కోసం హేబియస్ కార్పస్ రిట్",
                "example_title_hi": "अवैध हिरासत में रखे गए नागरिक के लिए बंदी प्रत्यक्षीकरण रिट",
                "example_situation": "A young man was picked up by plainclothes police officers without a warrant and held in an undisclosed interrogation room for 4 days without production before a Magistrate.",
                "example_situation_te": "వారెంట్ లేకుండా ఒక యువకుడిని పోలీసులు తీసుకెళ్లి 4 రోజుల పాటు మేజిస్ట్రేట్ ముందు హాజరుపరచకుండా రహస్య నిర్బంధంలో ఉంచారు.",
                "example_situation_hi": "एक युवक को पुलिस ने बिना वारंट उठाया और 4 दिनों तक बिना मजिस्ट्रेट के समक्ष पेश किए गुप्त हिरासत में रखा।",
                "example_explanation": "His father moved the Court under Article 32 / 226 for a Writ of Habeas Corpus. The Court directed police to produce him immediately, found the detention illegal, and ordered his release with compensation.",
                "example_explanation_te": "అతని తండ్రి హేబియస్ కార్పస్ రిట్ దాఖలు చేశాడు. కోర్టు ఆ యువకుడిని వెంటనే హాజరుపరచాలని ఆదేశించి, నిర్బంధం చట్టవిరుద్ధమని తేల్చి పరిహారంతో విడుదల చేసింది.",
                "example_explanation_hi": "पिता ने बंदी प्रत्यक्षीकरण याचिका दायर की। न्यायालय ने तुरंत पेश करने का आदेश दिया और हिरासत को अवैध मानते हुए मुआवजे के साथ रिहा कराया।",
                "example_disclaimer": "Fictional educational example illustrating Habeas Corpus writ proceedings.",
            },

            # ------------------------------------------------------------------
            # 9. MOTOR VEHICLES ACT, 1988 (as amended 2019)
            # ------------------------------------------------------------------
            {
                "law_short_name": "MV Act",
                "section_number": "Section 181",
                "title": "Driving Vehicles in Contravention of Section 3 or Section 4 (Driving Without Driving Licence)",
                "title_te": "డ్రైవింగ్ లైసెన్స్ లేకుండా వాహనం నడపడంపై శిక్ష",
                "title_hi": "ड्राइविंग लाइसेंस के बिना वाहन चलाने पर दंड",
                "legal_text": (
                    "Whoever drives a motor vehicle in contravention of section 3 or section 4 shall be punishable with imprisonment for a term "
                    "which may extend to three months, or with fine which may extend to five thousand rupees, or with both."
                ),
                "simple_explanation": (
                    "Driving any motor vehicle without a valid driving license (or allowing an underage person without a license to drive) "
                    "is a serious offence under the 2019 amendment punishable with a heavy fine up to ₹5,000, imprisonment up to 3 months, or both.",
                ),
                "simple_explanation_te": (
                    "చెల్లుబాటు అయ్యే డ్రైవింగ్ లైసెన్స్ లేకుండా వాహనం నడపడం చట్టరీత్యా నేరం. సవరించిన చట్టం ప్రకారం రూ. 5,000 వరకు భారీ జరిమానా లేదా 3 నెలల వరకు జైలు శిక్ష విధించవచ్చు.",
                ),
                "simple_explanation_hi": (
                    "वैध ड्राइविंग लाइसेंस के बिना वाहन चलाना गंभीर अपराध है। 2019 के संशोधन के तहत 5,000 रुपये तक का जुर्माना या 3 महीने तक की कैद हो सकती है।",
                ),
                "purpose": "Ensures road safety and prevents unqualified, unlicensed drivers from endangering public life.",
                "purpose_te": "రహదారి భద్రతను నిర్ధారించడం మరియు అర్హత లేని వ్యక్తులు వాహనాలు నడపకుండా నిరోధించడం.",
                "purpose_hi": "सड़क सुरक्षा सुनिश्चित करना और अयोग्य व्यक्तियों द्वारा वाहन चलाने पर रोक लगाना।",
                "punishment": "Fine up to ₹5,000, imprisonment up to 3 months, or both.",
                "punishment_te": "రూ. 5,000 వరకు జరిమానా, 3 నెలల వరకు జైలు శిక్ష లేదా రెండూ.",
                "punishment_hi": "5,000 रुपये तक का जुर्माना, 3 महीने तक की कैद, या दोनों।",
                "effective_date": date(2019, 9, 1),
                "amendment_info": "Fine increased tenfold from ₹500 to ₹5,000 by the Motor Vehicles (Amendment) Act, 2019.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1798",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "penal",
                "key_elements": "Driving motor vehicle on public road\nNo valid driving licence held\nOffence is compoundable by traffic police\nVehicle impoundment possible under Section 207",
                "key_elements_te": "బహిరంగ రహదారిపై వాహనం నడపడం\nచెల్లుబాటు అయ్యే డ్రైవింగ్ లైసెన్స్ లేకపోవడం\nరూ. 5,000 జరిమానా\nవాహనాన్ని సీజ్ చేసే అవకాశం",
                "key_elements_hi": "सार्वजनिक सड़क पर वाहन चलाना\nवैध ड्राइविंग लाइसेंस का न होना\n5,000 रुपये तक जुर्माना\nवाहन जब्ती संभव",
                "relevant_documents": "Physical Driving Licence or digital copy on DigiLocker / mParivahan app\nVehicle RC\nInsurance policy certificate",
                "relevant_documents_te": "డ్రైవింగ్ లైసెన్స్ లేదా డిజిలాకర్/mParivahan యాప్‌లో డిజిటల్ కాపీ\nవాహన RC\nఇన్సూరెన్స్ పత్రం",
                "relevant_documents_hi": "ड्राइविंग लाइसेंस (डिजीलॉकर/एमपरिवहन मान्य)\nवाहन आरसी\nबीमा प्रमाण पत्र",
                "what_you_should_do": "Always carry your driving licence or keep it stored on government DigiLocker or mParivahan app (statutorily valid under IT Act Section 4). Never drive on an expired licence.",
                "what_you_should_do_te": "ఎల్లప్పుడూ మీ డ్రైవింగ్ లైసెన్స్‌ను తీసుకెళ్లండి లేదా DigiLocker/mParivahan యాప్‌లో ఉంచండి (చట్టబద్ధంగా చెల్లుబాటు అవుతుంది). గడువు ముగిసిన లైసెన్స్‌తో నడపవద్దు.",
                "what_you_should_do_hi": "हमेशा ड्राइविंग लाइसेंस साथ रखें या डिजीलॉकर/एमपरिवहन ऐप पर रखें (जो कानूनी रूप से मान्य है)। एक्सपायर हो चुके लाइसेंस पर वाहन न चलाएं।",
                "quick_answer": "Yes, driving without a license carries a fine of up to ₹5,000 or up to 3 months jail.",
                "quick_answer_te": "అవును, లైసెన్స్ లేకుండా డ్రైవింగ్ చేస్తే రూ. 5,000 వరకు జరిమానా లేదా 3 నెలల వరకు జైలు శిక్ష ఉంటుంది.",
                "quick_answer_hi": "हाँ, बिना लाइसेंस वाहन चलाने पर 5,000 रुपये तक का जुर्माना या 3 महीने तक की जेल हो सकती है।",
                "example_title": "Student caught riding friend's bike without driving licence",
                "example_title_te": "డ్రైవింగ్ లైసెన్స్ లేకుండా స్నేహితుడి బైక్ నడుపుతూ పట్టుబడ్డ విద్యార్థి",
                "example_title_hi": "बिना लाइसेंस मित्र की बाइक चलाते पकड़ा गया छात्र",
                "example_situation": "College student Kiran borrowed his friend's bike to buy groceries. He was stopped at a police checkpoint and could not produce a driving licence.",
                "example_situation_te": "కిరణ్ తన స్నేహితుడి బైక్‌పై బయలుదేరాడు. ట్రాఫిక్ తనిఖీలో డ్రైవింగ్ లైసెన్స్ చూపించలేకపోయాడు.",
                "example_situation_hi": "किरण अपने दोस्त की बाइक चला रहा था। ट्रैफिक पुलिस चेकिंग में वह ड्राइविंग लाइसेंस प्रस्तुत नहीं कर सका।",
                "example_explanation": "Traffic police issued a challan for ₹5,000 under Section 181. Under Section 180, his friend who permitted an unlicensed driver to ride was also penalized.",
                "example_explanation_te": "ట్రాఫిక్ పోలీసులు సెక్షన్ 181 కింద కిరణ్‌కు రూ. 5,000 చలాన్ విధించారు. లైసెన్స్ లేని వ్యక్తికి బైక్ ఇచ్చిన స్నేహితుడికి కూడా సెక్షన్ 180 కింద జరిమానా విధించారు.",
                "example_explanation_hi": "पुलिस ने धारा 181 के तहत 5,000 रुपये का चालान काटा। बिना लाइसेंस वाले को बाइक देने पर उसके दोस्त पर भी धारा 180 में जुर्माना लगाया गया।",
                "example_disclaimer": "Fictional educational scenario illustrating Section 181 MV Act penalties.",
            },

            # ------------------------------------------------------------------
            # 10. DIGITAL PERSONAL DATA PROTECTION ACT, 2023 (DPDP)
            # ------------------------------------------------------------------
            {
                "law_short_name": "DPDP Act 2023",
                "section_number": "Section 6 & 11",
                "title": "Consent Requirements and Rights of the Data Principal (Data Privacy)",
                "title_te": "సమ్మతి నిబంధనలు మరియు పౌరుల డేటా గోప్యతా హక్కులు",
                "title_hi": "डेटा गोपनीयता: सहमति की आवश्यकताएं और नागरिकों के अधिकार",
                "legal_text": (
                    "Consent given by the Data Principal shall be free, specific, informed, unconditional and unambiguous with a clear affirmative action, "
                    "and shall signify an agreement for processing of her personal data for the specified purpose, and shall be limited to such personal data "
                    "as is necessary for such specified purpose. The Data Principal shall have the right to obtain from the Data Fiduciary confirmation whether the "
                    "Data Fiduciary is processing or has processed personal data of the Data Principal; a summary of the personal data of the Data Principal being processed; "
                    "and the right of correction, completion, updating and erasure of her personal data."
                ),
                "simple_explanation": (
                    "No app, website, telecom company, or bank can harvest or process your personal data without clear, upfront consent for a specific purpose. "
                    "You have the statutory right to demand what personal data they hold about you, correct inaccuracies, withdraw your consent at any time, "
                    "and request complete deletion (erasure) of your data.",
                ),
                "simple_explanation_te": (
                    "ఏ యాప్, వెబ్‌సైట్ లేదా బ్యాంక్ కూడా నిర్దిష్ట ప్రయోజనం కోసం స్పష్టమైన ముందస్తు అనుమతి లేకుండా మీ వ్యక్తిగత డేటాను సేకరించకూడదు. "
                    "వారు మీ గురించి ఏ సమాచారాన్ని భద్రపరిచారో తెలుసుకునే హక్కు, తప్పులను సరిదిద్దే హక్కు, సమ్మతిని ఉపసంహరించుకునే హక్కు మరియు డేటాను తొలగించాలని కోరే హక్కు మీకు ఉంది.",
                ),
                "simple_explanation_hi": (
                    "कोई भी ऐप, वेबसाइट या कंपनी आपकी स्पष्ट सहमति के बिना व्यक्तिगत डेटा एकत्र या प्रोसेस नहीं कर सकती। "
                    "नागरिकों को यह जानने का अधिकार है कि उनके बारे में क्या डेटा रखा गया है, गलतियों को सुधारने, सहमति वापस लेने और डेटा मिटाने (Erasure) की मांग करने का अधिकार है।",
                ),
                "purpose": "Protects digital privacy and establishes comprehensive statutory rights for citizens over their personal data.",
                "purpose_te": "డిజిటల్ గోప్యతను పరిరక్షించడం మరియు పౌరుల వ్యక్తిగత సమాచారంపై వారికి సంపూర్ణ నియంత్రణ కల్పించడం.",
                "purpose_hi": "डिजिटल गोपनीयता की रक्षा करना और नागरिकों को उनके व्यक्तिगत डेटा पर पूर्ण नियंत्रण प्रदान करना।",
                "punishment": "Data Protection Board can levy significant monetary penalties up to ₹250 crore on companies for significant data breaches or non-compliance under Schedule.",
                "punishment_te": "డేటా ఉల్లంఘనలకు పాల్పడే సంస్థలపై డేటా ప్రొటెక్షన్ బోర్డ్ రూ. 250 కోట్ల వరకు భారీ జరిమానాలు విధించవచ్చు.",
                "punishment_hi": "डेटा सुरक्षा बोर्ड कंपनियों पर गंभीर उल्लंघन के लिए 250 करोड़ रुपये तक का भारी जुर्माना लगा सकता है।",
                "effective_date": date(2023, 8, 11),
                "amendment_info": "Enacted as Act No. 22 of 2023 on 11 August 2023; operational framework governed by pending commencement of central rules.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/20884",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "fine",
                "key_elements": "Data Principal (Citizen) and Data Fiduciary (Company)\nFree, specific, informed consent\nNotice in English or 22 Scheduled Indian languages\nRight to access summary of data\nRight to correction and erasure\nRight to grievance redressal",
                "key_elements_te": "పౌరుడు (డేటా ప్రిన్సిపాల్) మరియు సంస్థ (డేటా ఫిడ్యూషియరీ)\nస్వేచ్ఛాయుత ముందస్తు సమ్మతి\nతెలుగు మరియు ఇతర భారతీయ భాషలలో నోటీసు\nడేటా వివరాలను తెలుసుకునే హక్కు\nసరిదిద్దే మరియు తొలగించే హక్కు",
                "key_elements_hi": "नागरिक (डेटा प्रिंसिपल) और कंपनी (डेटा फिड्यूशरी)\nस्पष्ट व पूर्व सहमति\nभारतीय भाषाओं में नोटिस\nडेटा तक पहुंच और सुधार का अधिकार\nडेटा मिटाने का अधिकार",
                "relevant_documents": "Consent notice given by company\nData access / erasure request email\nProof of identity\nGrievance redressal ticket number",
                "relevant_documents_te": "కంపెనీ ఇచ్చిన సమ్మతి నోటీసు\nడేటా తొలగింపు అభ్యర్థన ఈమెయిల్\nగుర్తింపు కార్డు\nఫిర్యాదు టికెట్ నంబర్",
                "relevant_documents_hi": "कंपनी द्वारा दिया गया नोटिस\nडेटा मिटाने के अनुरोध का ईमेल\nपहचान पत्र\nशिकायत निवारण संदर्भ संख्या",
                "what_you_should_do": "Send a formal written or email request to the Data Protection Officer (DPO) of the company demanding erasure of your personal data and withdrawal of marketing consent.",
                "what_you_should_do_te": "సంబంధిత కంపెనీ డేటా ప్రొటెక్షన్ ఆఫీసర్ (DPO)కి మీ డేటాను తొలగించాలని మరియు మార్కెటింగ్ సమ్మతిని ఉపసంహరించుకుంటున్నట్లు ఈమెయిల్ పంపండి.",
                "what_you_should_do_hi": "कंपनी के डेटा सुरक्षा अधिकारी (DPO) को ईमेल भेजकर अपने डेटा को मिटाने और मार्केटिंग सहमति वापस लेने का औपचारिक अनुरोध करें।",
                "quick_answer": "Yes, you have the statutory right under the DPDP Act to access, correct, or demand deletion of your personal data.",
                "quick_answer_te": "అవును, కంపెనీల వద్ద ఉన్న మీ వ్యక్తిగత డేటాను తనిఖీ చేసే, సరిదిద్దే లేదా తొలగించాలని కోరే హక్కు మీకు ఉంది.",
                "quick_answer_hi": "हाँ, डीपीडीपी अधिनियम के तहत आपको अपने व्यक्तिगत डेटा तक पहुँचने, उसे सुधारने या मिटाने की मांग करने का कानूनी अधिकार है।",
                "example_title": "Loan app continuing to spam user after account closure",
                "example_title_te": "ఖాతా మూసివేసిన తర్వాత కూడా డేటాను తొలగించని లోన్ యాప్",
                "example_title_hi": "खाता बंद करने के बाद भी लोन ऐप द्वारा डेटा का दुरुपयोग",
                "example_situation": "Neha repaid her online loan and closed her account, but the lending app kept retaining her phone contacts and sending promotional calls daily.",
                "example_situation_te": "నేహా లోన్ పూర్తిగా తీర్చి ఖాతా మూసివేసినా, లోన్ యాప్ ఆమె కాంటాక్టులను తొలగించకుండా ప్రతిరోజూ ప్రమోషనల్ కాల్స్ చేస్తూ వేధించింది.",
                "example_situation_hi": "नेहा ने लोन चुकाकर अपना खाता बंद कर दिया, लेकिन ऐप ने उसके संपर्कों को नहीं हटाया और लगातार कॉल करता रहा।",
                "example_explanation": "Under Section 11 and 12 of the DPDP Act, Neha exercised her right to erasure and withdrawal of consent. The company was obligated to delete her contact records and stop promotional communications.",
                "example_explanation_te": "DPDP చట్టం సెక్షన్ 11 & 12 ప్రకారం నేహా తన డేటాను తొలగించాలని డిమాండ్ చేసింది. కంపెనీ ఆమె వివరాలను పూర్తిగా తొలగించాల్సి వచ్చింది.",
                "example_explanation_hi": "डीपीडीपी अधिनियम की धारा 11 और 12 के तहत नेहा ने सहमति वापस लेते हुए डेटा हटाने की मांग की। कंपनी को उसका डेटा डिलीट करना पड़ा।",
                "example_disclaimer": "Fictional educational scenario demonstrating DPDP Act privacy rights.",
            },

            # ------------------------------------------------------------------
            # 11. PREVENTION OF CORRUPTION ACT, 1988 (PCA)
            # ------------------------------------------------------------------
            {
                "law_short_name": "PCA 1988",
                "section_number": "Section 7",
                "title": "Offence Relating to Public Servant Being Bribed",
                "title_te": "ప్రభుత్వ ఉద్యోగి లంచం డిమాండ్ చేయడం లేదా తీసుకోవడంపై నేరం",
                "title_hi": "लोक सेवक द्वारा रिश्वत लेने या मांगने से संबंधित अपराध",
                "legal_text": (
                    "Any public servant who: (a) obtains or accepts or attempts to obtain from any person, an undue advantage, "
                    "with the intention to perform or cause performance of public duty improperly or dishonestly; or "
                    "(b) obtains or accepts or attempts to obtain, an undue advantage as a reward for the improper or dishonest "
                    "performance of a public duty, shall be punishable with imprisonment for a term which shall not be less than "
                    "three years but which may extend to seven years and shall also be liable to fine."
                ),
                "simple_explanation": (
                    "Any government employee, police officer, or municipal official who demands or accepts a bribe (undue advantage) "
                    "to do their duty, process a file, issue a certificate, or overlook a violation is guilty of a grave criminal offence "
                    "carrying mandatory imprisonment of 3 to 7 years plus a heavy fine."
                ),
                "simple_explanation_te": (
                    "ఏ ప్రభుత్వ ఉద్యోగి అయినా, పోలీసు లేదా మున్సిపల్ అధికారి సర్టిఫికెట్ ఇవ్వడానికి, ఫైల్ కదల్చడానికి లంచం డిమాండ్ చేసినా "
                    "లేదా తీసుకున్నా 3 నుండి 7 సంవత్సరాల వరకు తప్పనిసరి జైలు శిక్ష మరియు జరిమానా విధించబడుతుంది."
                ),
                "simple_explanation_hi": (
                    "कोई भी सरकारी कर्मचारी या पुलिस अधिकारी जो अपना काम करने, फाइल आगे बढ़ाने या प्रमाण पत्र जारी करने के लिए "
                    "रिश्वत (अनुचित लाभ) मांगता या लेता है, उसे कम से कम 3 वर्ष और अधिकतम 7 वर्ष तक के अनिवार्य कारावास और जुर्माने की सजा होगी।"
                ),
                "purpose": "Eradicates corruption in public administration and holds public servants accountable for integrity and honesty.",
                "purpose_te": "ప్రజా పాలనలో అవినీతిని అంతమొందించడం మరియు ప్రభుత్వ ఉద్యోగుల జవాబుదారీతనాన్ని నిర్ధారించడం.",
                "purpose_hi": "लोक प्रशासन में भ्रष्टाचार को समाप्त करना और सरकारी कर्मचारियों की ईमानदारी सुनिश्चित करना।",
                "punishment": "Mandatory imprisonment of not less than 3 years, extendable up to 7 years, and fine.",
                "punishment_te": "కనీసం 3 సంవత్సరాల నుండి గరిష్టంగా 7 సంవత్సరాల వరకు తప్పనిసరి జైలు శిక్ష మరియు జరిమానా.",
                "punishment_hi": "कम से कम 3 साल से 7 साल तक का अनिवार्य कारावास और जुर्माना।",
                "effective_date": date(2018, 7, 26),
                "amendment_info": "Substituted by the Prevention of Corruption (Amendment) Act, 2018 (Act 16 of 2018).",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1922",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "penal",
                "key_elements": "Public servant\nDemands, accepts or attempts to obtain undue advantage\nImproper or dishonest performance of duty\nMinimum 3 years mandatory imprisonment",
                "key_elements_te": "ప్రభుత్వ ఉద్యోగి\nఅనధికారిక లబ్ధి/లంచం డిమాండ్ చేయడం లేదా తీసుకోవడం\nవిధుల దుర్వినియోగం\nకనీసం 3 సంవత్సరాల జైలు శిక్ష",
                "key_elements_hi": "सरकारी कर्मचारी\nअनुचित लाभ/रिश्वत मांगना या स्वीकार करना\nकर्तव्य का बेईमानी से निर्वहन\nन्यूनतम 3 वर्ष का कारावास",
                "relevant_documents": "ACB / CBI complaint letter\nTainted currency serial number sheet (phenolphthalein trap memo)\nAudio/video recording of bribe demand",
                "relevant_documents_te": "ACB లేదా CBI ఫిర్యాదు లేఖ\nట్రాప్ మెమో మరియు కరెన్సీ నోట్ల నంబర్లు\nలంచం డిమాండ్ ఆడియో/వీడియో రికార్డింగ్",
                "relevant_documents_hi": "एसीबी या सीबीआई शिकायत पत्र\nट्रैप मेमो और नोटों के सीरियल नंबर\nरिश्वत मांगने की ऑडियो/वीडियो रिकॉर्डिंग",
                "what_you_should_do": "Never pay a bribe. Note details of the demand. Contact the Anti-Corruption Bureau (ACB / State Vigilance Helpline 1064) or CBI. They will organize a statutory trap using phenolphthalein powder to catch the officer red-handed.",
                "what_you_should_do_te": "ఎప్పుడూ లంచం ఇవ్వకండి. వివరాలను నమోదు చేయండి. వెంటనే అవినీతి నిరోధక శాఖ (ACB హెల్ప్‌లైన్ 1064) లేదా CBI ని సంప్రదించండి. వారు ట్రాప్ వేసి అధికారిని రెడ్ హ్యాండెడ్‌గా పట్టుకుంటారు.",
                "what_you_should_do_hi": "रिश्वत कभी न दें। मांग के विवरण नोट करें। तुरंत भ्रष्टाचार निरोधक ब्यूरो (ACB हेल्पलाइन 1064) या सीबीआई से संपर्क करें। वे अधिकारी को रंगे हाथों पकड़ने के लिए वैधानिक ट्रैप आयोजित करेंगे।",
                "quick_answer": "Demanding or taking a bribe is a non-bailable offence carrying 3 to 7 years mandatory jail.",
                "quick_answer_te": "లంచం డిమాండ్ చేయడం లేదా తీసుకోవడం 3 నుండి 7 సంవత్సరాల జైలు శిక్ష పడే నాన్-బెయిలబుల్ నేరం.",
                "quick_answer_hi": "रिश्वत मांगना या लेना गैर-जमानती अपराध है जिसमें 3 से 7 साल की अनिवार्य जेल की सजा है।",
                "example_title": "Municipal clerk demanding ₹10,000 for trade license renewal",
                "example_title_te": "ట్రేడ్ లైసెన్స్ రెన్యూవల్ కోసం మున్సిపల్ క్లర్క్ రూ. 10,000 డిమాండ్ చేయడం",
                "example_title_hi": "ट्रेड लाइसेंस नवीनीकरण के लिए नगर पालिका क्लर्क द्वारा 10,000 रुपये की मांग",
                "example_situation": "Anil applied for renewal of his grocery shop license. The municipal clerk stalled the file for 2 months and demanded ₹10,000 cash to sign the approval.",
                "example_situation_te": "అనిల్ తన కిరాణా దుకాణం లైసెన్స్ రెన్యూవల్ కోసం దరఖాస్తు చేశాడు. మున్సిపల్ క్లర్క్ ఫైల్ ఆపి రూ. 10,000 లంచం డిమాండ్ చేశాడు.",
                "example_situation_hi": "अनिल ने दुकान के लाइसेंस नवीनीकरण का आवेदन किया। क्लर्क ने 2 महीने तक फाइल रोकी और 10,000 रुपये रिश्वत मांगी।",
                "example_explanation": "Anil approached the Anti-Corruption Bureau (ACB). An ACB trap was laid; the clerk was caught accepting chemically marked currency, arrested under Section 7, and remanded to judicial custody.",
                "example_explanation_te": "అనిల్ ACBని ఆశ్రయించాడు. ACB అధికారులు ట్రాప్ చేసి క్లర్క్‌ను లంచం తీసుకుంటుండగా రెడ్ హ్యాండెడ్‌గా పట్టుకుని సెక్షన్ 7 కింద అరెస్టు చేశారు.",
                "example_explanation_hi": "अनिल ने एसीबी से संपर्क किया। एसीबी ने ट्रैप लगाकर क्लर्क को रंगे हाथों पकड़ा और धारा 7 के तहत गिरफ्तार कर जेल भेजा।",
                "example_disclaimer": "Fictional educational example illustrating Section 7 PCA anti-bribery trap.",
            },

            # ------------------------------------------------------------------
            # 12. NDPS ACT, 1985 - Procedural Safeguards on Search
            # ------------------------------------------------------------------
            {
                "law_short_name": "NDPS Act 1985",
                "section_number": "Section 50",
                "title": "Conditions Under Which Search of Persons Shall Be Conducted (Search Safeguard)",
                "title_te": "వ్యక్తుల సోదా నిర్వహించాల్సిన నిబంధనలు (సోదా రక్షణ హక్కు)",
                "title_hi": "व्यक्तियों की तलाशी लिए जाने की शर्तें (नागरिक तलाशी सुरक्षा)",
                "legal_text": (
                    "When any officer duly authorised is about to search any person under the provisions of section 41, section 42 or section 43, "
                    "he shall, if such person so requires, take such person without unnecessary delay to the nearest Gazetted Officer of any of the "
                    "departments mentioned in section 42 or to the nearest Magistrate. The Magistrate or the Gazetted Officer before whom such person is "
                    "brought shall, if he sees no reasonable ground for search, forthwith discharge the person but otherwise shall direct that search be made. "
                    "No female shall be searched by anyone excepting a female."
                ),
                "simple_explanation": (
                    "If an enforcement officer or police stops you suspecting possession of prohibited drugs and wants to conduct a body search, "
                    "they MUST inform you of your statutory right to be searched in the presence of a Gazetted Officer or an independent Magistrate. "
                    "Furthermore, a woman can ONLY be searched by a female officer. Non-compliance vitiates the trial (Supreme Court Constitution Bench).",
                ),
                "simple_explanation_te": (
                    "మాదకద్రవ్యాల అనుమానంతో అధికారులు మీ శరీరాన్ని సోదా చేయాలనుకున్నప్పుడు, గెజిటెడ్ ఆఫీసర్ లేదా మేజిస్ట్రేట్ సమక్షంలో సోదా చేయించుకునే "
                    "చట్టపరమైన హక్కు మీకున్న విషయాన్ని వారు మీకు తప్పనిసరిగా తెలియజేయాలి. అలాగే మహిళను కేవలం మహిళా అధికారి మాత్రమే సోదా చేయాలి.",
                ),
                "simple_explanation_hi": (
                    "यदि कोई अधिकारी नशीले पदार्थों के संदेह में आपकी व्यक्तिगत तलाशी लेना चाहता है, तो उसे आपको यह सूचित करना अनिवार्य है कि "
                    "आपको किसी राजपत्रित अधिकारी (Gazetted Officer) या मजिस्ट्रेट के समक्ष तलाशी कराने का कानूनी अधिकार है। महिला की तलाशी केवल महिला अधिकारी ले सकती है।",
                ),
                "purpose": "Prevents planting of contraband and ensures strict constitutional fairness during police bodily searches.",
                "purpose_te": "తప్పుడు కేసులు బనాయించకుండా నిరోధించడం మరియు పౌరుల వ్యక్తిగత స్వేచ్ఛను పరిరక్షించడం.",
                "purpose_hi": "झूठे आरोप लगाने से रोकना और व्यक्तिगत तलाशी के दौरान नागरिक अधिकारों की रक्षा करना।",
                "punishment": "Violation of Section 50 renders any alleged recovery illegal, leading to acquittal of the accused.",
                "punishment_te": "సెక్షన్ 50 నిబంధనలను పాటించకపోతే ఆ సోదా చట్టవిరుద్ధమవుతుంది మరియు నిందితుడు నిర్దోషిగా విడుదలవుతాడు.",
                "punishment_hi": "धारा 50 का उल्लंघन करने पर बरामदगी अवैध मानी जाती है और आरोपी बरी हो जाता है।",
                "effective_date": date(1985, 11, 14),
                "amendment_info": "Sub-section (5) and (6) added by NDPS (Amendment) Act, 2001 (Act 9 of 2001).",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1791",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "procedural",
                "key_elements": "Personal (bodily) search under NDPS\nMandatory duty to inform suspect of right\nOption to be searched before Gazetted Officer or Magistrate\nFemale searched only by female officer\nPanchnama / search memo recorded",
                "key_elements_te": "వ్యక్తిగత శరీర సోదా\nహక్కు గురించి నిందితుడికి తెలియజేయడం తప్పనిసరి\nగెజిటెడ్ ఆఫీసర్ లేదా మేజిస్ట్రేట్ సమక్షంలో సోదా ఎంపిక\nమహిళలకు మహిళా అధికారి మాత్రమే సోదా\nపంచనామా నమోదు",
                "key_elements_hi": "व्यक्तिगत शारीरिक तलाशी\nअधिकार के बारे में सूचित करना अनिवार्य\nमजिस्ट्रेट या राजपत्रित अधिकारी के समक्ष तलाशी का विकल्प\nमहिला की तलाशी केवल महिला द्वारा\nपंचनामा तैयार करना",
                "relevant_documents": "Search memo / notice under Section 50\nPanchnama (Seizure list signed by independent witnesses)\nGazetted Officer endorsement memo",
                "relevant_documents_te": "సెక్షన్ 50 నోటీసు కాపీ\nపంచనామా (స్వతంత్ర సాక్షుల సంతకాలతో కూడిన సీజర్ లిస్ట్)\nగెజిటెడ్ ఆఫీసర్ ధృవీకరణ",
                "relevant_documents_hi": "धारा 50 के तहत नोटिस\nपंचनामा (स्वतंत्र गवाहों के हस्ताक्षर सहित)\nराजपत्रित अधिकारी का ज्ञापन",
                "what_you_should_do": "If an officer asks to search your person for narcotics, insist on exercising your Section 50 right to be searched before the nearest Magistrate or Gazetted Officer. Ensure independent witnesses sign the search memo.",
                "what_you_should_do_te": "అధికారులు మిమ్మల్ని సోదా చేయాలనుకుంటే, మేజిస్ట్రేట్ లేదా గెజిటెడ్ ఆఫీసర్ సమక్షంలోనే సోదా చేయాలని సెక్షన్ 50 హక్కును ఉపయోగించండి. స్వతంత్ర సాక్షులు ఉన్నారని నిర్ధారించుకోండి.",
                "what_you_should_do_hi": "यदि अधिकारी आपकी तलाशी लेना चाहें, तो धारा 50 के तहत निकटतम मजिस्ट्रेट या राजपत्रित अधिकारी के समक्ष तलाशी कराने के अधिकार का प्रयोग करें। स्वतंत्र गवाहों की उपस्थिति सुनिश्चित करें।",
                "quick_answer": "Yes, you have the statutory right under Section 50 to be searched only before a Magistrate or Gazetted Officer.",
                "quick_answer_te": "అవును, మేజిస్ట్రేట్ లేదా గెజిటెడ్ ఆఫీసర్ సమక్షంలో మాత్రమే సోదా చేయించుకునే హక్కు మీకు ఉంది.",
                "quick_answer_hi": "हाँ, धारा 50 के तहत आपको केवल मजिस्ट्रेट या राजपत्रित अधिकारी के समक्ष तलाशी कराने का कानूनी अधिकार है।",
                "example_title": "Police conducting pat-down search without offering Magistrate option",
                "example_title_te": "మేజిస్ట్రేట్ ఎంపిక ఇవ్వకుండా పోలీసులు నిర్వహించిన శరీర సోదా",
                "example_title_hi": "बिना मजिस्ट्रेट विकल्प दिए पुलिस द्वारा तलाशी",
                "example_situation": "Police stopped a traveller at a bus stand, searched his pockets directly without informing him of Section 50 rights, and claimed contraband recovery.",
                "example_situation_te": "బస్ స్టాండ్ వద్ద ఒక ప్రయాణికుడిని ఆపి, సెక్షన్ 50 హక్కులను తెలపకుండానే జేబులను తనిఖీ చేసి డ్రగ్స్ దొరికాయని పోలీసులు పేర్కొన్నారు.",
                "example_situation_hi": "बस स्टैंड पर एक यात्री को रोककर पुलिस ने धारा 50 की सूचना दिए बिना उसकी जेबों की तलाशी ली और प्रतिबंधित पदार्थ बरामदगी का दावा किया।",
                "example_explanation": "Because police failed to inform him of his mandatory right to be searched before a Gazetted Officer or Magistrate, the Special Court ruled the search void and acquitted him.",
                "example_explanation_te": "గెజిటెడ్ ఆఫీసర్ లేదా మేజిస్ట్రేట్ ముందు సోదా చేయించుకునే హక్కును తెలపనందున, సెక్షన్ 50 ఉల్లంఘనగా పరిగణించి కోర్టు అతన్ని నిర్దోషిగా విడుదల చేసింది.",
                "example_explanation_hi": "मजिस्ट्रेट के समक्ष तलाशी के अधिकार की सूचना न देने के कारण विशेष अदालत ने तलाशी को अवैध ठहराया और आरोपी को बरी कर दिया।",
                "example_disclaimer": "Fictional educational example illustrating mandatory compliance with Section 50 NDPS Act.",
            },

            # ------------------------------------------------------------------
            # 13. INFORMATION TECHNOLOGY ACT, 2000 - Violation of Privacy
            # ------------------------------------------------------------------
            {
                "law_short_name": "IT Act",
                "section_number": "Section 66E",
                "title": "Punishment for Violation of Bodily Privacy (Voyeurism & Hidden Cameras)",
                "title_te": "శరీర గోప్యత ఉల్లంఘనకు శిక్ష (దాచిన కెమెరాలు & అసభ్య ఫోటోలు)",
                "title_hi": "निजता के उल्लंघन के लिए दंड (हिडन कैमरा और अश्लील तस्वीरें)",
                "legal_text": (
                    "Whoever, intentionally or knowingly captures, publishes or transmits the image of a private area of any person "
                    "without his or her consent, under circumstances violating the privacy of that person, shall be punished with imprisonment "
                    "which may extend to three years or with fine not exceeding two lakh rupees, or with both."
                ),
                "simple_explanation": (
                    "Capturing, recording, transmitting, or publishing photos or videos of anyone's private body parts, changing rooms, "
                    "bathrooms, or intimate moments without their explicit consent (such as hidden cameras in hotel rooms or trial rooms) "
                    "is a non-bailable cyber offence carrying up to 3 years imprisonment and ₹2,00,000 fine.",
                ),
                "simple_explanation_te": (
                    "హోటల్ గదులు, ట్రయల్ రూమ్‌లలో దాచిన కెమెరాల ద్వారా లేదా అనుమతి లేకుండా ఎవరి శరీర గోప్యతను ఫోటోలు తీసినా, ప్రసారం చేసినా "
                    "3 సంవత్సరాల వరకు జైలు శిక్ష మరియు రూ. 2,00,000 వరకు జరిమానా విధించబడుతుంది.",
                ),
                "simple_explanation_hi": (
                    "किसी भी व्यक्ति की सहमति के बिना उसके निजी अंगों, चेंजिंग रूम, बाथरूम या होटल के कमरे में छिपे कैमरे से फोटो/वीडियो लेना, "
                    "प्रसारित या प्रकाशित करना गंभीर साइबर अपराध है, जिसमें 3 वर्ष तक की कैद और 2 लाख रुपये तक का जुर्माना हो सकता है।",
                ),
                "purpose": "Shields citizens against digital voyeurism, spy-cams, and intimate privacy infringements.",
                "purpose_te": "డిజిటల్ కెమెరా వేధింపులు మరియు వ్యక్తుల శరీర గోప్యత ఉల్లంఘనల నుండి రక్షణ కల్పించడం.",
                "purpose_hi": "डिजिटल ताक-झांक, जासूसी कैमरों और व्यक्तिगत निजता के हनन से नागरिकों की रक्षा करना।",
                "punishment": "Imprisonment up to 3 years, fine up to ₹2,00,000, or both.",
                "punishment_te": "3 సంవత్సరాల వరకు జైలు శిక్ష, రూ. 2,00,000 వరకు జరిమానా లేదా రెండూ.",
                "punishment_hi": "3 साल तक की जेल, 2 लाख रुपये तक का जुर्माना, या दोनों।",
                "effective_date": date(2008, 10, 27),
                "amendment_info": "Inserted by the Information Technology (Amendment) Act, 2008 (Act 10 of 2009).",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1999",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "penal",
                "key_elements": "Captures, publishes, or transmits image of private area\nWithout consent of person\nCircumstances violating privacy\nImprisonment up to 3 years and fine up to 2 lakhs",
                "key_elements_te": "అనుమతి లేకుండా ప్రైవేట్ భాగాల ఫోటోలు/వీడియోలు తీయడం లేదా పంపడం\nగోప్యతా ఉల్లంఘన\n3 సంవత్సరాల వరకు జైలు\nరూ. 2 లక్షల వరకు జరిమానా",
                "key_elements_hi": "बिना सहमति निजी अंगों की तस्वीर/वीडियो लेना या भेजना\nनिजता का उल्लंघन\n3 साल तक की कैद\n2 लाख रुपये तक जुर्माना",
                "relevant_documents": "Device / camera evidence\nDigital URL / file link\nComplaint copy to Cyber Crime portal (cybercrime.gov.in)\nWitness statements",
                "relevant_documents_te": "కెమెరా లేదా డివైస్ ఆధారాలు\nడిజిటల్ లింక్ లేదా ఫైల్ కాపీ\nసైబర్ క్రైమ్ పోర్టల్ ఫిర్యాదు కాపీ\nసాక్షుల వాంగ్మూలాలు",
                "relevant_documents_hi": "कैमरा या उपकरण का साक्ष्य\nडिजिटल लिंक या फाइल\nसाइबर क्राइम पोर्टल की शिकायत प्रति\nगवाहों के बयान",
                "what_you_should_do": "Do not tamper with the device if you discover a hidden camera in a trial room or hotel. Immediately call 112/police. Take photos of the camera setup and file a complaint under Section 66E IT Act and BNS Section 77.",
                "what_you_should_do_te": "ట్రయల్ రూమ్ లేదా హోటల్‌లో రహస్య కెమెరా కనిపిస్తే వెంటనే 112 పోలీసులకు కాల్ చేయండి. కెమెరాను ఫోటో తీసి సెక్షన్ 66E మరియు BNS సెక్షన్ 77 కింద ఎఫ్‌ఐఆర్ నమోదు చేయించండి.",
                "what_you_should_do_hi": "ट्रायल रूम या होटल में हिडन कैमरा मिलने पर तुरंत 112/पुलिस को कॉल करें। कैमरे की फोटो लें और धारा 66E आईटी एक्ट तथा बीएनएस धारा 77 के तहत प्राथमिकी दर्ज कराएं।",
                "quick_answer": "Yes, planting hidden cameras or capturing private images without consent carries up to 3 years jail and 2 lakh fine.",
                "quick_answer_te": "అవును, అనుమతి లేకుండా ప్రైవేట్ ఫోటోలు తీయడం లేదా దాచిన కెమెరాలు పెట్టడం 3 ఏళ్ల జైలు శిక్ష పడే నేరం.",
                "quick_answer_hi": "हाँ, हिडन कैमरा लगाना या बिना सहमति निजी तस्वीरें लेना 3 साल तक की जेल और 2 लाख जुर्माने का अपराध है।",
                "example_title": "Hidden pinhole camera found in clothing store trial room",
                "example_title_te": "బట్టల దుకాణం ట్రయల్ రూమ్‌లో కనిపించిన దాచిన కెమెరా",
                "example_title_hi": "कपड़ों की दुकान के ट्रायल रूम में मिला हिडन कैमरा",
                "example_situation": "A customer in a clothing boutique noticed a suspicious blinking wire above the trial room mirror and discovered a mini-camera connected to a laptop in the staff room.",
                "example_situation_te": "బట్టల దుకాణం ట్రయల్ రూమ్ అద్దం పైన అనుమానాస్పద వైర్ కనిపించడంతో సిబ్బంది గదిలోని ల్యాప్‌టాప్‌కు కనెక్ట్ చేసిన చిన్న కెమెరా బయటపడింది.",
                "example_situation_hi": "एक ग्राहक ने ट्रायल रूम के शीशे के पास एक संदिग्ध कैमरा देखा जो स्टाफ रूम के लैपटॉप से जुड़ा था।",
                "example_explanation": "Police seized the devices and arrested the store manager under Section 66E of the IT Act. The court denied bail given the gross infringement of privacy.",
                "example_explanation_te": "పోలీసులు పరికరాలను స్వాధీనం చేసుకుని ఐటీ చట్టం సెక్షన్ 66E కింద స్టోర్ మేనేజర్‌ను అరెస్టు చేశారు. గోప్యత ఉల్లంఘన కారణంగా కోర్టు బెయిల్ నిరాకరించింది.",
                "example_explanation_hi": "पुलिस ने उपकरण जब्त कर स्टोर मैनेजर को धारा 66E के तहत गिरफ्तार किया। अदालत ने निजता के गंभीर हनन को देखते हुए जमानत खारिज कर दी।",
                "example_disclaimer": "Fictional educational scenario demonstrating enforcement of Section 66E IT Act.",
            },

            # ------------------------------------------------------------------
            # 14. JUVENILE JUSTICE ACT, 2015 - Protection of Identity of Child
            # ------------------------------------------------------------------
            {
                "law_short_name": "JJ Act 2015",
                "section_number": "Section 74",
                "title": "Prohibition on Disclosure of Identity of Children in Need of Care or Conflict with Law",
                "title_te": "పిల్లల గుర్తింపు బహిర్గతం చేయడంపై నిషేధం (గోప్యతా రక్షణ)",
                "title_hi": "बालकों की पहचान उजागर करने पर पूर्ण प्रतिबंध",
                "legal_text": (
                    "No report in any newspaper, magazine, news-sheet or audio-visual media or other form of communication "
                    "regarding any inquiry or investigation or judicial procedure, shall disclose the name, address or school or any other "
                    "particular, which may lead to the identification of a child in conflict with law or a child in need of care and protection "
                    "or a child victim or witness of a crime, involved in such matter, nor shall the picture of any such child be published: "
                    "Whoever contravenes the provisions shall be punishable with imprisonment for a term which may extend to six months or fine "
                    "which may extend to two lakh rupees or with both."
                ),
                "simple_explanation": (
                    "No newspaper, news channel, website, or social media user can publish the name, photo, school, parents' name, address, "
                    "or any detail that reveals the identity of a child victim of a crime, child witness, or child in conflict with law. "
                    "Violating a child's privacy carries up to 6 months imprisonment and ₹2,00,000 fine.",
                ),
                "simple_explanation_te": (
                    "నేర బాధితులైన పిల్లలు, సాక్షులు లేదా నేరారోపణలు ఎదుర్కొంటున్న పిల్లల పేరు, ఫోటో, స్కూలు, చిరునామాను ఏ వార్తాపత్రిక, టీవీ ఛానెల్ "
                    "లేదా సోషల్ మీడియాలో ప్రచురించడం చట్టరీత్యా నేరం. ఉల్లంఘిస్తే 6 నెలల జైలు మరియు రూ. 2 లక్షల జరిమానా ఉంటుంది.",
                ),
                "simple_explanation_hi": (
                    "किसी भी समाचार पत्र, टीवी चैनल या सोशल मीडिया पर किसी पीड़ित बच्चे, गवाह या कानून का उल्लंघन करने वाले बच्चे का नाम, "
                    "फोटो, स्कूल या पहचान उजागर करने वाली कोई भी जानकारी प्रकाशित करना पूरी तरह प्रतिबंधित है। उल्लंघन पर 6 महीने की कैद और 2 लाख रुपये जुर्माना हो सकता है।",
                ),
                "purpose": "Shields children from lifelong social stigma and preserves their rehabilitation and dignity.",
                "purpose_te": "పిల్లలను సామాజిక వివక్ష నుండి కాపాడటం మరియు వారి పునరావాసాన్ని పరిరక్షించడం.",
                "purpose_hi": "बच्चों को आजीवन सामाजिक कलंक से बचाना और उनका पुनर्वास व गरिमा सुनिश्चित करना।",
                "punishment": "Imprisonment up to 6 months, fine up to ₹2,00,000, or both.",
                "punishment_te": "6 నెలల వరకు జైలు శిక్ష, రూ. 2,00,000 వరకు జరిమానా లేదా రెండూ.",
                "punishment_hi": "6 महीने तक की कैद, 2 लाख रुपये तक का जुर्माना, या दोनों।",
                "effective_date": date(2016, 1, 15),
                "amendment_info": "In force from 15 January 2016; stringent media reporting guidelines enforced by Supreme Court.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/2148",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "penal",
                "key_elements": "Child victim, witness, or child in conflict with law\nMedia or digital disclosure of name, photo, school, or address\nStrict liability for publishers and editors\nImprisonment up to 6 months and fine up to 2 lakhs",
                "key_elements_te": "బాధిత పిల్లలు, సాక్షులు లేదా చట్టాన్ని ఉల్లంఘించిన పిల్లలు\nపేరు, ఫోటో లేదా స్కూల్ వివరాల ప్రచురణ నిషేధం\nపత్రికలు, వెబ్‌సైట్లకు కఠిన బాధ్యత\n6 నెలల జైలు మరియు 2 లక్షల జరిమానా",
                "key_elements_hi": "पीड़ित बालक, गवाह या विधि विवादी बालक\nपहचान उजागर करने वाली कोई भी सामग्री प्रकाशित करना\nप्रकाशकों और संपादकों पर सख्त दायित्व\n6 महीने तक कैद व 2 लाख जुर्माना",
                "relevant_documents": "Published newspaper clipping / web link / social media screenshot\nComplaint before Juvenile Justice Board (JJB) or Child Welfare Committee (CWC)\nFIR under Section 74 JJ Act",
                "relevant_documents_te": "ప్రచురించిన పేపర్ క్లిప్పింగ్ లేదా స్క్రీన్‌షాట్\nచైల్డ్ వెల్ఫేర్ కమిటీ (CWC) వద్ద ఫిర్యాదు\nJJ చట్టం సెక్షన్ 74 కింద ఎఫ్‌ఐఆర్ కాపీ",
                "relevant_documents_hi": "प्रकाशित समाचार की प्रति / स्क्रीनशॉट\nबाल कल्याण समिति (CWC) के समक्ष शिकायत\nधारा 74 के तहत प्राथमिकी प्रति",
                "what_you_should_do": "Never share or forward posts disclosing photos or names of minor victims on social media. If you see media leaking child details, report to Child Welfare Committee (CWC) or National Commission for Protection of Child Rights (NCPCR).",
                "what_you_should_do_te": "సోషల్ మీడియాలో మైనర్ బాధితుల పేర్లు లేదా ఫోటోలను ఎప్పుడూ షేర్ చేయవద్దు. మీడియా లీక్ చేస్తే చైల్డ్ వెల్ఫేర్ కమిటీ (CWC) లేదా NCPCR కి ఫిర్యాదు చేయండి.",
                "what_you_should_do_hi": "सोशल मीडिया पर नाबालिग पीड़ितों के नाम या फोटो कभी शेयर न करें। उल्लंघन दिखने पर बाल कल्याण समिति (CWC) या एनसीपीसीआर में शिकायत करें।",
                "quick_answer": "No, revealing a child victim's name or photo is illegal, punishable with up to 6 months jail and ₹2 lakh fine.",
                "quick_answer_te": "లేదు, బాధిత పిల్లల పేరు లేదా ఫోటోను ప్రచురించడం చట్టవిరుద్ధం, 6 నెలల జైలు మరియు రూ. 2 లక్షల జరిమానా ఉంటుంది.",
                "quick_answer_hi": "नहीं, किसी पीड़ित बच्चे की पहचान या फोटो उजागर करना गैरकानूनी है और 6 महीने की जेल व 2 लाख जुर्माने से दंडनीय है।",
                "example_title": "YouTube channel publishing photo of missing kidnapped child after recovery",
                "example_title_te": "కిడ్నాప్ నుండి రక్షించిన పిల్లల ఫోటోను ప్రసారం చేసిన యూట్యూబ్ ఛానెల్",
                "example_title_hi": "अपहरण से बचाए गए बच्चे की फोटो प्रसारित करने वाला यूट्यूब चैनल",
                "example_situation": "A local news portal uploaded an unblurred video showing the face and school uniform of an 8-year-old rescued from kidnapping.",
                "example_situation_te": "కిడ్నాప్ నుండి కాపాడిన 8 ఏళ్ల బాలుడి ముఖం మరియు స్కూల్ యూనిఫాం స్పష్టంగా కనిపించే వీడియోను ఒక యూట్యూబ్ న్యూస్ పోర్టల్ అప్‌లోడ్ చేసింది.",
                "example_situation_hi": "एक वेब पोर्टल ने अपहरण से बचाए गए 8 वर्षीय बच्चे का चेहरा और स्कूल यूनिफॉर्म दिखाते हुए वीडियो अपलोड कर दिया।",
                "example_explanation": "Under Section 74, disclosing the face or school of any child victim is prohibited. CWC initiated action, resulting in an FIR against the channel editor and immediate takedown.",
                "example_explanation_te": "సెక్షన్ 74 ప్రకారం పిల్లల ముఖం చూపించడం నేరం. CWC ఆదేశాలతో ఛానెల్ ఎడిటర్‌పై ఎఫ్‌ఐఆర్ నమోదు చేసి వీడియోను తొలగించారు.",
                "example_explanation_hi": "धारा 74 के तहत बच्चे का चेहरा दिखाना अपराध है। बाल कल्याण समिति की पहल पर चैनल संपादक पर प्राथमिकी दर्ज हुई और वीडियो हटवाया गया।",
                "example_disclaimer": "Fictional educational scenario illustrating privacy safeguards under Section 74 JJ Act.",
            },

            # ------------------------------------------------------------------
            # 15. SPECIAL MARRIAGE ACT, 1954 - Interfaith & Civil Marriage
            # ------------------------------------------------------------------
            {
                "law_short_name": "SMA 1954",
                "section_number": "Section 4 & 5",
                "title": "Conditions Relating to Solemnization of Special Civil Marriage and Notice",
                "title_te": "ప్రత్యేక సివిల్ వివాహ నిబంధనలు మరియు వివాహ నోటీసు",
                "title_hi": "विशेष नागरिक विवाह की शर्तें और विवाह की सूचना",
                "legal_text": (
                    "A marriage between any two persons may be solemnized under this Act, if at the time of the marriage the following conditions are fulfilled, "
                    "namely: (a) neither party has a spouse living; (b) neither party is incapable of giving a valid consent to it in consequence of unsoundness of mind; "
                    "(c) the male has completed the age of twenty-one years and the female the age of eighteen years; (d) the parties are not within the degrees "
                    "of prohibited relationship: Provided that where a custom permits, such custom shall prevail. When a marriage is intended to be solemnized under this Act, "
                    "the parties to the marriage shall give notice thereof in writing in the form specified to the Marriage Officer of the district in which at least "
                    "one of the parties to the marriage has resided for a period of not less than thirty days immediately preceding the date on which such notice is given."
                ),
                "simple_explanation": (
                    "Any two consenting Indian citizens (regardless of different religions, castes, or nationalities) can legally marry through a secular civil ceremony "
                    "WITHOUT any religious conversion or ceremony. Groom must be at least 21 and bride at least 18. A 30-day notice must be submitted to the District Marriage Officer.",
                ),
                "simple_explanation_te": (
                    "భారతదేశంలో ఏ ఇద్దరు పౌరులైనా తమ మతం మార్చుకోకుండా, ఏ మతపరమైన ఆచారాలు లేకుండా లౌకిక పద్ధతిలో రిజిస్ట్రార్ ముందు వివాహం చేసుకోవచ్చు. "
                    "వరుడికి 21, వధువుకు 18 ఏళ్లు నిండి ఉండాలి. జిల్లా మ్యారేజ్ ఆఫీసర్‌కు 30 రోజుల ముందస్తు నోటీసు ఇవ్వాలి.",
                ),
                "simple_explanation_hi": (
                    "कोई भी दो वयस्क भारतीय नागरिक (चाहे उनका धर्म या जाति कुछ भी हो) बिना धर्म परिवर्तन किए धर्मनिरपेक्ष तरीके से विशेष विवाह कर सकते हैं। "
                    "वर की आयु 21 वर्ष और वधू की 18 वर्ष पूरी होनी चाहिए। जिले के विवाह अधिकारी को 30 दिन का नोटिस देना होता है।",
                ),
                "purpose": "Provides a statutory civil marriage framework protecting interfaith and intercaste couples without religious conversion.",
                "purpose_te": "మతం మారాల్సిన అవసరం లేకుండా భిన్న మతాలు లేదా కులాల జంటలకు చట్టబద్ధమైన వివాహ రక్షణ కల్పించడం.",
                "purpose_hi": "धर्म परिवर्तन की आवश्यकता के बिना अंतरधार्मिक और अंतरजातीय जोड़ों को कानूनी विवाह सुरक्षा प्रदान करना।",
                "punishment": "A Marriage Certificate issued under Section 13 is conclusive evidence of valid marriage, enforceable nationwide.",
                "punishment_te": "సెక్షన్ 13 కింద జారీ చేసిన వివాహ ధృవీకరణ పత్రం దేశవ్యాప్తంగా చెల్లుబాటు అయ్యే తిరుగులేని సాక్ష్యం.",
                "punishment_hi": "धारा 13 के तहत जारी विवाह प्रमाण पत्र पूरे देश में वैध विवाह का निर्णायक साक्ष्य है।",
                "effective_date": date(1955, 1, 1),
                "amendment_info": "High Courts have held that mandatory public display of couple's addresses in notice violates privacy.",
                "status": "current",
                "source": "https://www.indiacode.gov.in/handle/123456789/1547",
                "source_name": "India Code — Ministry of Law & Justice, Govt. of India",
                "consequences_type": "civil",
                "key_elements": "Consenting adults (male 21+, female 18+)\nNeither party has a living spouse\nNo religious conversion required\n30-day notice in district of residence\nSolemnization before Marriage Officer with 3 witnesses",
                "key_elements_te": "మేజర్లు (వరుడు 21+, వధువు 18+)\nజీవించి ఉన్న భార్య/భర్త లేకపోవడం\nమతం మారాల్సిన అవసరం లేదు\n30 రోజుల ముందస్తు నోటీసు\n3 మంది సాక్షుల సమక్షంలో నమోదు",
                "key_elements_hi": "वयस्क नागरिक (वर 21+, वधू 18+)\nपहले से जीवित जीवनसाथी न हो\nधर्म परिवर्तन की आवश्यकता नहीं\n30 दिन का नोटिस\n3 गवाहों के समक्ष पंजीकरण",
                "relevant_documents": "Age proof (10th marks card / Birth certificate / Passport)\nAddress proof showing 30 days residence in district\nPassport size photographs\nAffidavit of marital status and non-prohibited relationship\nID proofs of 3 witnesses",
                "relevant_documents_te": "వయస్సు ధృవీకరణ (పాస్‌పోర్ట్ / SSC మెమో)\nచిరునామా ధృవీకరణ పత్రం\nఫోటోలు\nఅఫిడవిట్\n3 మంది సాక్షుల ఆధార్ కార్డులు",
                "relevant_documents_hi": "आयु प्रमाण पत्र\n30 दिनों के निवास का पता प्रमाण\nपासपोर्ट फोटो\nशपथ पत्र\n3 गवाहों के पहचान पत्र",
                "what_you_should_do": "Submit the Notice of Intended Marriage to the Sub-Registrar / Marriage Officer. Bring 3 adult witnesses with valid ID cards on the designated solemnization date after the 30-day period.",
                "what_you_should_do_te": "జిల్లా మ్యారేజ్ ఆఫీసర్‌కు 30 రోజుల ముందస్తు నోటీసును సమర్పించండి. గడువు ముగిసిన తర్వాత ముగ్గురు సాక్షులతో వెళ్లి వివాహాన్ని రిజిస్టర్ చేయించుకోండి.",
                "what_you_should_do_hi": "विवाह अधिकारी को निर्धारित प्रारूप में 30 दिन का नोटिस दें। अवधि पूरी होने पर 3 वयस्क गवाहों के साथ उपस्थित होकर विवाह संपन्न कराएं।",
                "quick_answer": "Yes, interfaith couples can marry under the Special Marriage Act without changing their religion.",
                "quick_answer_te": "అవును, మతం మారకుండా స్పెషల్ మ్యారేజ్ యాక్ట్ కింద భిన్న మతాల వారు చట్టబద్ధంగా వివాహం చేసుకోవచ్చు.",
                "quick_answer_hi": "हाँ, अंतरधार्मिक जोड़े बिना धर्म परिवर्तन किए विशेष विवाह अधिनियम के तहत कानूनी विवाह कर सकते हैं।",
                "example_title": "Interfaith couple solemnizing civil marriage without religious conversion",
                "example_title_te": "మతం మారకుండా సివిల్ వివాహం చేసుకున్న జంట",
                "example_title_hi": "बिना धर्म परिवर्तन किए विशेष विवाह करने वाला जोड़ा",
                "example_situation": "Farhan and Ananya wanted to marry while retaining their respective personal faiths. Ananya's relatives threatened to stop them.",
                "example_situation_te": "ఫర్హాన్ మరియు అనన్య తమ మతాలను మార్చుకోకుండా వివాహం చేసుకోవాలనుకున్నారు. బంధువులు అడ్డుకుంటామని బెదిరించారు.",
                "example_situation_hi": "फरहान और अनन्या अपने-अपने धर्म को बनाए रखते हुए शादी करना चाहते थे। रिश्तेदारों ने विरोध किया।",
                "example_explanation": "They submitted notice under Section 5 of SMA. After 30 days, they appeared with 3 witnesses and were issued an official Marriage Certificate under Section 13, giving them full legal protection as husband and wife.",
                "example_explanation_te": "వారు SMA సెక్షన్ 5 కింద దరఖాస్తు చేసుకున్నారు. 30 రోజుల తర్వాత ముగ్గురు సాక్షులతో రిజిస్ట్రార్ ముందు వివాహం చేసుకుని అధికారిక ధృవీకరణ పత్రం పొందారు.",
                "example_explanation_hi": "उन्होंने धारा 5 के तहत नोटिस दिया। 30 दिन बाद 3 गवाहों के साथ उपस्थित होकर धारा 13 के तहत विवाह प्रमाण पत्र प्राप्त किया, जिसे पूर्ण कानूनी सुरक्षा प्राप्त है।",
                "example_disclaimer": "Fictional educational example illustrating civil marriage procedures under SMA 1954.",
            },
        ]

        for s_data in new_sections_data:
            law = Law.objects.filter(short_name=s_data["law_short_name"]).first()
            if not law:
                prefix = s_data["law_short_name"].split()[0]
                law = Law.objects.filter(short_name__icontains=prefix).first()
            if not law:
                kw = "Bharatiya Nagarik Suraksha" if "BNSS" in s_data["law_short_name"] else s_data["law_short_name"]
                law = Law.objects.filter(name__icontains=kw).first()
            if not law:
                self.stdout.write(self.style.ERROR(f"Law not found for {s_data['law_short_name']}"))
                continue

            sec, created = LegalSection.objects.get_or_create(
                law=law,
                section_number=s_data["section_number"],
                defaults={
                    "title": s_data["title"],
                    "legal_text": s_data["legal_text"],
                    "simple_explanation": s_data["simple_explanation"],
                    "purpose": s_data["purpose"],
                    "punishment": s_data.get("punishment", ""),
                    "effective_date": s_data.get("effective_date"),
                    "amendment_info": s_data.get("amendment_info", ""),
                    "status": s_data.get("status", "current"),
                    "source": s_data.get("source", "https://www.indiacode.gov.in/"),
                    "source_name": s_data.get("source_name", "India Code — Ministry of Law & Justice, Govt. of India"),
                    "last_verified": VERIFIED_DATE,
                    "consequences_type": s_data.get("consequences_type", "penal"),
                    "key_elements": s_data.get("key_elements", ""),
                    "key_elements_te": s_data.get("key_elements_te", ""),
                    "key_elements_hi": s_data.get("key_elements_hi", ""),
                    "relevant_documents": s_data.get("relevant_documents", ""),
                    "relevant_documents_te": s_data.get("relevant_documents_te", ""),
                    "relevant_documents_hi": s_data.get("relevant_documents_hi", ""),
                    "what_you_should_do": s_data.get("what_you_should_do", ""),
                    "what_you_should_do_te": s_data.get("what_you_should_do_te", ""),
                    "what_you_should_do_hi": s_data.get("what_you_should_do_hi", ""),
                    "title_te": s_data.get("title_te", ""),
                    "simple_explanation_te": s_data.get("simple_explanation_te", ""),
                    "purpose_te": s_data.get("purpose_te", ""),
                    "punishment_te": s_data.get("punishment_te", ""),
                    "title_hi": s_data.get("title_hi", ""),
                    "simple_explanation_hi": s_data.get("simple_explanation_hi", ""),
                    "purpose_hi": s_data.get("purpose_hi", ""),
                    "punishment_hi": s_data.get("punishment_hi", ""),
                    "quick_answer": s_data.get("quick_answer", ""),
                    "quick_answer_te": s_data.get("quick_answer_te", ""),
                    "quick_answer_hi": s_data.get("quick_answer_hi", ""),
                    "example_title": s_data.get("example_title", ""),
                    "example_title_te": s_data.get("example_title_te", ""),
                    "example_title_hi": s_data.get("example_title_hi", ""),
                    "example_situation": s_data.get("example_situation", ""),
                    "example_situation_te": s_data.get("example_situation_te", ""),
                    "example_situation_hi": s_data.get("example_situation_hi", ""),
                    "example_explanation": s_data.get("example_explanation", ""),
                    "example_explanation_te": s_data.get("example_explanation_te", ""),
                    "example_explanation_hi": s_data.get("example_explanation_hi", ""),
                    "example_disclaimer": s_data.get("example_disclaimer", ""),
                }
            )
            if not created:
                sec.title = s_data["title"]
                sec.legal_text = s_data["legal_text"]
                sec.simple_explanation = s_data["simple_explanation"]
                sec.purpose = s_data["purpose"]
                sec.punishment = s_data.get("punishment", sec.punishment)
                sec.effective_date = s_data.get("effective_date", sec.effective_date)
                sec.amendment_info = s_data.get("amendment_info", sec.amendment_info)
                sec.source = s_data.get("source", sec.source)
                sec.last_verified = VERIFIED_DATE
                sec.consequences_type = s_data.get("consequences_type", sec.consequences_type)
                sec.key_elements = s_data.get("key_elements", sec.key_elements)
                sec.key_elements_te = s_data.get("key_elements_te", sec.key_elements_te)
                sec.key_elements_hi = s_data.get("key_elements_hi", sec.key_elements_hi)
                sec.relevant_documents = s_data.get("relevant_documents", sec.relevant_documents)
                sec.relevant_documents_te = s_data.get("relevant_documents_te", sec.relevant_documents_te)
                sec.relevant_documents_hi = s_data.get("relevant_documents_hi", sec.relevant_documents_hi)
                sec.what_you_should_do = s_data.get("what_you_should_do", sec.what_you_should_do)
                sec.what_you_should_do_te = s_data.get("what_you_should_do_te", sec.what_you_should_do_te)
                sec.what_you_should_do_hi = s_data.get("what_you_should_do_hi", sec.what_you_should_do_hi)
                sec.title_te = s_data.get("title_te", sec.title_te)
                sec.simple_explanation_te = s_data.get("simple_explanation_te", sec.simple_explanation_te)
                sec.purpose_te = s_data.get("purpose_te", sec.purpose_te)
                sec.title_hi = s_data.get("title_hi", sec.title_hi)
                sec.simple_explanation_hi = s_data.get("simple_explanation_hi", sec.simple_explanation_hi)
                sec.purpose_hi = s_data.get("purpose_hi", sec.purpose_hi)
                sec.quick_answer = s_data.get("quick_answer", sec.quick_answer)
                sec.quick_answer_te = s_data.get("quick_answer_te", sec.quick_answer_te)
                sec.quick_answer_hi = s_data.get("quick_answer_hi", sec.quick_answer_hi)
                sec.example_title = s_data.get("example_title", sec.example_title)
                sec.example_title_te = s_data.get("example_title_te", sec.example_title_te)
                sec.example_title_hi = s_data.get("example_title_hi", sec.example_title_hi)
                sec.example_situation = s_data.get("example_situation", sec.example_situation)
                sec.example_situation_te = s_data.get("example_situation_te", sec.example_situation_te)
                sec.example_situation_hi = s_data.get("example_situation_hi", sec.example_situation_hi)
                sec.example_explanation = s_data.get("example_explanation", sec.example_explanation)
                sec.example_explanation_te = s_data.get("example_explanation_te", sec.example_explanation_te)
                sec.example_explanation_hi = s_data.get("example_explanation_hi", sec.example_explanation_hi)
                sec.save()
            act = "CREATED" if created else "UPDATED"
            self.stdout.write(f"   [{act} PROVISION] ID={sec.id}: {law.short_name} {sec.section_number} - {sec.title[:35]}")

    def _export_seed_assets(self):
        """Dumps canonical database records to JSON files in legalguide_app/assets/seed/."""
        from laws.serializers import CategorySerializer, LawSerializer, LegalSectionSerializer

        base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
        seed_dir = os.path.join(base_dir, "..", "legalguide_app", "assets", "seed")
        seed_dir = os.path.normpath(seed_dir)

        if not os.path.exists(seed_dir):
            self.stdout.write(self.style.ERROR(f"Seed dir not found: {seed_dir}"))
            return

        # Categories
        cats = Category.objects.all().order_by("id")
        cats_data = CategorySerializer(cats, many=True).data
        cat_file = os.path.join(seed_dir, "categories.json")
        with open(cat_file, "w", encoding="utf-8") as f:
            json.dump(cats_data, f, ensure_ascii=False, indent=2)
        self.stdout.write(f"   Exported {len(cats_data)} categories to {cat_file}")

        # Laws
        laws = Law.objects.all().order_by("id")
        laws_data = LawSerializer(laws, many=True).data
        law_file = os.path.join(seed_dir, "laws.json")
        with open(law_file, "w", encoding="utf-8") as f:
            json.dump(laws_data, f, ensure_ascii=False, indent=2)
        self.stdout.write(f"   Exported {len(laws_data)} laws to {law_file}")

        # Sections
        secs = LegalSection.objects.all().order_by("law_id", "id")
        secs_data = LegalSectionSerializer(secs, many=True).data
        sec_file = os.path.join(seed_dir, "sections.json")
        with open(sec_file, "w", encoding="utf-8") as f:
            json.dump(secs_data, f, ensure_ascii=False, indent=2)
        self.stdout.write(f"   Exported {len(secs_data)} sections to {sec_file}")
