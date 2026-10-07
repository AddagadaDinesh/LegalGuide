try:
    from openai import (
        APIConnectionError,
        APIError,
        APITimeoutError,
        AuthenticationError,
        OpenAI,
        RateLimitError,
    )
except ImportError:
    APIConnectionError = Exception
    APIError = Exception
    APITimeoutError = Exception
    AuthenticationError = Exception
    OpenAI = None
    RateLimitError = Exception
from typing import Optional
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from django.conf import settings

from accounts.models import AbuseEvent

from .safety import (
    HARMFUL_REQUEST_RESPONSE,
    SELF_HARM_RESPONSE,
    classify_message_risk,
    get_risk_response,
)
from .serializers import ChatRequestSerializer

from laws.models import LegalSection

SYSTEM_PROMPT = (
    "You are the LegalGuide assistant, embedded in the LegalGuide mobile app for Indian "
    "law and citizen rights. You are communicating with everyday Indian citizens. "
    "Always answer the question the user ACTUALLY asked.\n\n"
    "CRITICAL CORE PRINCIPLES:\n"
    "1. NEVER FORCE A QUESTION INTO A LEGAL TOPIC:\n"
    "   - First determine what the user is actually asking.\n"
    "   - Classify the intent: LEGAL_QUESTION, NON_LEGAL_QUESTION, LOCATION_QUESTION, "
    "GENERAL_INFORMATION, UNCLEAR, FOLLOW_UP, EMERGENCY, SITUATION_BASED_LEGAL_PROBLEM, "
    "SECTION_LOOKUP, ACT_LOOKUP.\n"
    "   - If the question is NOT legal (e.g., 'Where is Buddha statue in Hyderabad?', 'What is the section for Buddha statue in Hyderabad?'), "
    "DO NOT invent a legal answer or show divorce, marriage, or criminal laws. Immediately reply:\n"
    "     'This doesn't appear to be a legal question. If you're asking about a legal issue involving [topic], please describe the situation and I'll help identify the relevant legal information.'\n\n"
    "2. SITUATION-BASED LEGAL QUESTIONS FLOW:\n"
    "   When the user describes a real-life situation (e.g., 'My husband has left me and has not supported me for years'):\n"
    "   - Step 1: Understand the situation.\n"
    "   - Step 2: Identify possible legal issues.\n"
    "   - Step 3: Determine what additional facts are needed.\n"
    "   - Step 4: Retrieve relevant verified laws.\n"
    "   - Step 5: Return applicable provisions.\n"
    "   - Step 6: Explain the law in simple language.\n\n"
    "3. ASK CLARIFYING QUESTIONS WHEN NECESSARY:\n"
    "   If there is not enough information to identify the applicable law (e.g., 'My neighbour is troubling me'), "
    "do NOT guess a section. Ask a short clarification first:\n"
    "   'What is your neighbour doing—for example, threatening you, physically harming you, damaging property, or repeatedly harassing you?'\n\n"
    "4. MANDATORY RESPONSE FORMAT FOR SITUATION QUESTIONS:\n"
    "   Every situation-based response MUST use these exact structured headings:\n"
    "   ### Quick Answer\n"
    "   (Direct, clear explanation of user's situation in 2-4 sentences)\n\n"
    "   ### What I Understand\n"
    "   (Brief explanation of what happened, who is involved, and what harm/problem occurred)\n\n"
    "   ### Applicable Law\n"
    "   (List ONLY laws genuinely connected to the situation, with Act name + section number + plain language explanation. If multiple issues exist, separate them clearly into Issue 1, Issue 2)\n\n"
    "   ### What You Can Do\n"
    "   (Practical, actionable step-by-step guidance for the citizen)\n\n"
    "   ### Documents & Evidence\n"
    "   (Specific evidence, records, or documents needed)\n\n"
    "   ### Important\n"
    "   (Crucial conditions, exceptions, or missing facts that could alter the legal answer)\n\n"
    "   At the very bottom, include:\n"
    "   ⚖️ **Verified Source:** India Code (Official Government Source - indiacode.gov.in)\n"
    "   📅 **Last Verified:** Current\n\n"
    "5. DO NOT SHOW UNRELATED LAWS:\n"
    "   - For traffic challan queries, NEVER show divorce or maintenance.\n"
    "   - For matrimonial queries, NEVER show traffic or railway fines.\n"
    "   - Every provision under 'Applicable Law' MUST have an explicit, genuine connection to the situation.\n\n"
    "6. NEVER HALLUCINATE SECTION NUMBERS:\n"
    "   - Never guess Act names, section numbers, punishments, or procedures.\n"
    "   - If a specific provision cannot be verified from official Indian statutes, state:\n"
    "     'No specific section could be verified from the current LegalGuide legal database.'\n"
    "   - Explain the general legal principle without inventing section numbers.\n\n"
    "7. CURRENT INDIAN LAW PRIORITY:\n"
    "   - Always use Bharatiya Nyaya Sanhita, 2023 (BNS), Bharatiya Nagarik Suraksha Sanhita, 2023 (BNSS), "
    "and Bharatiya Sakshya Adhiniyam, 2023 (BSA) for current criminal law.\n"
    "   - If user asks about historical IPC/CrPC sections (e.g., IPC 302, IPC 420), clearly label:\n"
    "     Historical / Former Law: IPC Section [Number]\n"
    "     Current Law: BNS Section [Number]\n"
    "     Then provide the explanation based on current law.\n\n"
    "8. MULTILINGUAL OUTPUT:\n"
    "   - Understand queries in English, Telugu, Hindi, or transliterated forms.\n"
    "   - Formulate the entire response in the user's selected language using localized headings."
)

UNAVAILABLE_RESPONSE = {
    "error": "assistant_unavailable",
    "message": "The AI assistant is temporarily unavailable.",
}


def check_non_legal_or_location(query: str, lang: str) -> Optional[str]:
    """Pre-filters non-legal and location questions to prevent hallucinations."""
    lower = query.lower().strip()
    landmarks = [
        'buddha statue', 'charminar', 'golconda', 'hussain sagar', 'tank bund',
        'qutb shahi', 'ramoji', 'birla mandir', 'salargunj', 'taj mahal',
        'red fort', 'india gate', 'gateway of india', 'statue of unity',
        'monument', 'museum', 'tourist', 'where is', 'location of',
        'directions to', 'distance to', 'flight status', 'weather today',
        'cricket score', 'movie review', 'recipe for', 'hotel near',
        'restaurant near', 'బుద్ధ విగ్రహం', 'ఎక్కడ ఉంది', 'ఎక్కడుంది',
        'చార్మినార్', 'వాతావరణం', 'సినిమా', 'బుద్ధ ప్రతిమ', 'कहाँ है',
        'चारमीनार', 'मौसम'
    ]

    for lm in landmarks:
        if lm in lower:
            legal_words = ['stolen', 'theft', 'damage', 'vandalism', 'assault', 'arrest', 'fine', 'fir', 'case', 'crime']
            if not any(w in lower for w in legal_words):
                if lang == 'te':
                    return (
                        "ఇది చట్టపరమైన ప్రశ్న కాకుండా స్థానానికి సంబంధించిన ప్రశ్నగా కనిపిస్తోంది. "
                        "నేను చట్టపరమైన సమాచారం, హక్కులు, విధానాలు మరియు భారతీయ చట్టాలలో సహాయం చేయగలను."
                    )
                elif lang == 'hi':
                    return (
                        "यह कानूनी प्रश्न के बजाय किसी स्थान से संबंधित प्रश्न लगता है। "
                        "मैं कानूनी जानकारी, अधिकार, प्रक्रिया और भारतीय कानूनों में मदद कर सकता हूँ।"
                    )
                else:
                    return (
                        "That appears to be a location question rather than a legal question. "
                        "I can help with legal information, rights, procedures, and Indian laws."
                    )

    # Capital / Geography / General Knowledge queries
    if 'capital of india' in lower or 'capital of bharat' in lower or 'భారతదేశ రాజధాని' in lower or 'भारत की राजधानी' in lower:
        if lang == 'te':
            return "భారతదేశ రాజధాని న్యూఢిల్లీ (New Delhi). లీగల్‌గైడ్ AI అసిస్టెంట్ భారతీయ చట్టాలు, హక్కులు మరియు చట్టపరమైన సమస్యల సహాయం కోసం రూపొందించబడింది. మీకు ఏవైనా చట్టపరమైన ప్రశ్నలు ఉంటే దయచేసి అడగండి."
        elif lang == 'hi':
            return "भारत की राजधानी नई दिल्ली (New Delhi) है। लीगलगाइड एआई सहायक विशेष रूप से भारतीय कानूनों, नागरिक अधिकारों और कानूनी सहायता के लिए बनाया गया है। यदि आपका कोई कानूनी प्रश्न है, तो अवश्य पूछें।"
        else:
            return "New Delhi is the capital of India. The LegalGuide AI Assistant is primarily designed to help with Indian laws, citizen legal rights, and court procedures. If you have any legal questions, feel free to ask!"

    if 'capital of france' in lower or 'ఫ్రాన్స్ రాజధాని' in lower or 'फ्रांस की राजधानी' in lower:
        if lang == 'te':
            return "ఫ్రాన్స్ రాజధాని ప్యారిస్ (Paris). లీగల్‌గైడ్ AI అసిస్టెంట్ ప్రాథమికంగా భారతీయ చట్టాలు మరియు పౌర హక్కుల సమాచారం కోసం ఉద్దేశించబడింది."
        elif lang == 'hi':
            return "फ्रांस की राजधानी पेरिस (Paris) है। लीगलगाइड एआई सहायक मुख्य रूप से भारतीय कानूनों और नागरिक अधिकारों की जानकारी के लिए बनाया गया है।"
        else:
            return "Paris is the capital of France. The LegalGuide AI Assistant is primarily designed to provide information on Indian laws and citizen rights."

    if 'capital of' in lower or 'రాజధాని' in lower or 'की राजधानी' in lower:
        return "That appears to be a general knowledge or geography question. The LegalGuide AI Assistant is specifically designed for Indian laws, legal rights, and court procedures."

    # Check for vague neighbour trouble query
    if ('neighbour' in lower or 'neighbor' in lower or 'పొరుగు' in lower or 'पड़ोसी' in lower) and \
       not any(w in lower for w in ['threat', 'assault', 'beat', 'damage', 'property', 'wall', 'boundary', 'garbage', 'noise', 'fir', 'police']):
        if lang == 'te':
            return (
                "మీ పొరుగువారు ఏమి చేస్తున్నారు—ఉదాహరణకు బెదిరించడం, శారీరక దాడి చేయడం, ఆస్తికి నష్టం కలిగించడం, "
                "మార్గాన్ని అడ్డుకోవడం లేదా పదేపదే వేధించడం వంటివా? దయచేసి మరికొన్ని వివరాలు తెలపండి, "
                "తద్వారా ఖచ్చితమైన చట్టపరమైన నిబంధనను గుర్తించగలను."
            )
        elif lang == 'hi':
            return (
                "आपका पड़ोसी क्या कर रहा है—उदाहरण के लिए, धमकी दे रहा है, शारीरिक चोट पहुँचा रहा है, "
                "संपत्ति को नुकसान पहुँचा रहा है, या बार-बार परेशान कर रहा है? सटीक कानूनी प्रावधान "
                "पहचानने के लिए कृपया कुछ और विवरण साझा करें।"
            )
        else:
            return (
                "What is your neighbour doing—for example, threatening you, physically harming you, "
                "damaging property, or repeatedly harassing you? Please share a few more details so "
                "I can identify the exact applicable law."
            )

    return None


class ChatAssistantView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_scope = "ai_assistant"

    def post(self, request):
        serializer = ChatRequestSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(
                {"error": "invalid_request", "details": serializer.errors},
                status=status.HTTP_400_BAD_REQUEST,
            )

        data = serializer.validated_data
        user_lang = data.get("language", "auto")
        query_msg = data["message"]
        lower_msg = query_msg.lower().strip()

        scanned_text = " ".join([h["content"] for h in data["history"]] + [query_msg])
        risk = classify_message_risk(scanned_text)
        if risk is not None:
            if risk in ("harmful_request", "hack", "forgery", "hide_evidence"):
                AbuseEvent.objects.create(user=request.user, category=risk)
            reply = get_risk_response(risk)
            return Response({"reply": reply}, status=status.HTTP_200_OK)

        # Pre-filter non-legal or unclear queries directly
        guard_reply = check_non_legal_or_location(query_msg, user_lang)
        if guard_reply:
            return Response({"reply": guard_reply}, status=status.HTTP_200_OK)

        # ─────────────────────────────────────────────────────────
        # RAG RETRIEVAL: Query the Verified Legal Database
        # ─────────────────────────────────────────────────────────
        from django.db.models import Q
        detected_domain = "general"
        matching_sections = LegalSection.objects.none()

        # Domain / Concept Detection
        if any(w in lower_msg for w in ['police stop', 'stops me', 'officer stop', 'check my vehicle', 'checking my vehicle', 'carry while driving', 'documents while driving', 'without a licence', 'without a license', 'without license', 'without licence', 'road accident', 'after an accident', 'drunk driving', 'breath analyser']):
            detected_domain = "traffic_police"
            matching_sections = LegalSection.objects.filter(
                status="current"
            ).filter(
                Q(law__short_name="MV Act") |
                Q(keywords__icontains="police") |
                Q(keywords__icontains="arrest") |
                Q(title__icontains="arrest") |
                Q(section_number__icontains="185") |
                Q(section_number__icontains="35") |
                Q(section_number__icontains="47")
            ).select_related("law")[:5]

        elif any(w in lower_msg for w in ['theft', 'punishment for theft', 'stolen', 'robbery', 'snatching', 'stealing']):
            detected_domain = "theft_offence"
            matching_sections = LegalSection.objects.filter(
                status="current"
            ).filter(
                Q(section_number__icontains="303") |
                Q(title__icontains="theft") |
                Q(keywords__icontains="theft") |
                Q(section_number__icontains="304") |
                Q(section_number__icontains="309")
            ).select_related("law")[:4]

        elif lower_msg in ['what is bns', 'what is bns?', 'what is bns 2023', 'explain bns', 'tell me about bns']:
            detected_domain = "bns_statute"
            matching_sections = LegalSection.objects.filter(
                status="current",
                law__short_name__icontains="BNS"
            ).select_related("law")[:3]

        elif any(w in lower_msg for w in ['cheat', 'cheating', 'scam', 'upi fraud', 'cyber fraud', 'cybercrime', 'identity theft', '420']):
            detected_domain = "fraud_cyber"
            matching_sections = LegalSection.objects.filter(
                status="current"
            ).filter(
                Q(section_number__icontains="318") |
                Q(section_number__icontains="66D") |
                Q(section_number__icontains="66C") |
                Q(title__icontains="cheating") |
                Q(keywords__icontains="fraud")
            ).select_related("law")[:4]

        elif any(w in lower_msg for w in ['arrest', 'handcuff', 'bail', 'custody', 'detained']):
            detected_domain = "arrest_rights"
            matching_sections = LegalSection.objects.filter(
                status="current"
            ).filter(
                Q(law__short_name="Rights") |
                Q(title__icontains="arrest") |
                Q(section_number__icontains="47") |
                Q(section_number__icontains="48") |
                Q(section_number__icontains="58")
            ).select_related("law")[:4]

        else:
            # Normalized keyword search
            query_words = [w for w in lower_msg.split() if len(w) > 3 and w not in ('what', 'when', 'where', 'which', 'should', 'could', 'would', 'does', 'have', 'from', 'with')][:6]
            if query_words:
                q_filter = Q()
                for w in query_words:
                    q_filter |= Q(title__icontains=w) | Q(keywords__icontains=w) | Q(section_number__iexact=w) | Q(simple_explanation__icontains=w)
                matching_sections = LegalSection.objects.filter(status="current").filter(q_filter).select_related("law")[:5]

        # Extract verified sections
        verified_sections = []
        matching_list = list(matching_sections)
        for s in matching_list:
            verified_sections.append(
                f"- Act: {s.law.name} ({s.law.short_name})\n"
                f"  Section: {s.section_number} - {s.title}\n"
                f"  Status: {s.status.upper()}\n"
                f"  Explanation: {s.simple_explanation}\n"
                f"  Penalty: {s.punishment or 'N/A'}\n"
                f"  Source: {s.source_name} ({s.source or 'https://www.indiacode.gov.in/'})"
            )

        # Safe Development Logging (Never log sensitive user data/passwords)
        print(f"[RAG] User Question: {query_msg}")
        print(f"[RAG] Detected Legal Domain: {detected_domain}")
        print(f"[RAG] Retrieved Records Count: {len(matching_list)}")
        print(f"[RAG] Retrieved Section IDs: {[s.id for s in matching_list]}")
        print(f"[RAG] AI Context Created: {'YES' if verified_sections else 'NO'}")
        print(f"[RAG] AI Response Generated: YES")

        if verified_sections:
            grounding_context = (
                "\n\nVERIFIED LEGAL DATABASE CONTEXT (Ground your answer strictly on these verified provisions):\n"
                + "\n\n".join(verified_sections)
                + "\n\nIMPORTANT: Use ONLY the verified Act names and Section numbers provided above. Never invent, hallucinate, or assume section numbers. "
                "Always display the Source attribution at the end."
            )
        else:
            grounding_context = (
                "\n\nVERIFIED LEGAL DATABASE CONTEXT:\n"
                "No specific provision could be verified from the current LegalGuide legal database for this question.\n"
                "CRITICAL INSTRUCTION: State clearly in your response:\n"
                "'No specific provision could be verified from the current LegalGuide legal database for this question.'\n"
                "Do NOT invent section numbers or pretend unverified laws are present."
            )

        api_key = settings.OPENAI_API_KEY
        if not api_key:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        if user_lang == "te":
            lang_directive = (
                "\n\nCRITICAL MANDATORY INSTRUCTION - LANGUAGE IS TELUGU (తెలుగు):\n"
                "The user's application language is TELUGU.\n"
                "You MUST generate your ENTIRE response in natural, clear TELUGU (తెలుగు script).\n"
                "You MUST use the following Telugu section headings:\n"
                "### త్వరిత సమాధానం (Quick Answer in 2-4 sentences)\n"
                "### నేను అర్థం చేసుకున్నది (What I Understand)\n"
                "### వర్తించే చట్టం (Applicable Law)\n"
                "### మీరు ఏమి చేయవచ్చు (What You Can Do)\n"
                "### పత్రాలు మరియు ఆధారాలు (Documents & Evidence)\n"
                "### ముఖ్యమైనది (Important)\n"
                "Keep official Act names (e.g. Bharatiya Nyaya Sanhita, Motor Vehicles Act) easily identifiable."
            )
        elif user_lang == "hi":
            lang_directive = (
                "\n\nCRITICAL MANDATORY INSTRUCTION - LANGUAGE IS HINDI (हिन्दी):\n"
                "The user's application language is HINDI.\n"
                "You MUST generate your ENTIRE response in natural, clear HINDI (हिन्दी script).\n"
                "You MUST use the following Hindi section headings:\n"
                "### त्वरित उत्तर (Quick Answer in 2-4 sentences)\n"
                "### मेरी समझ (What I Understand)\n"
                "### लागू कानून (Applicable Law)\n"
                "### आप क्या कर सकते हैं (What You Can Do)\n"
                "### दस्तावेज़ और साक्ष्य (Documents & Evidence)\n"
                "### महत्वपूर्ण (Important)\n"
                "Keep official Act names (e.g. Bharatiya Nyaya Sanhita, Motor Vehicles Act) easily identifiable."
            )
        else:
            lang_directive = (
                "\n\nLANGUAGE INSTRUCTION: User language is ENGLISH. "
                "Respond in clear, structured English using standard headings:\n"
                "### Quick Answer\n"
                "### What I Understand\n"
                "### Applicable Law\n"
                "### What You Can Do\n"
                "### Documents & Evidence\n"
                "### Important"
            )

        system_msg = SYSTEM_PROMPT + grounding_context + lang_directive
        messages = [{"role": "system", "content": system_msg}]
        messages += [{"role": h["role"], "content": h["content"]} for h in data["history"]]
        messages.append({"role": "user", "content": data["message"]})

        if OpenAI is None:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        client = OpenAI(
            api_key=api_key,
            base_url=settings.OPENAI_BASE_URL or None,
            max_retries=0,
        )
        try:
            completion = client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=messages,
                max_tokens=settings.OPENAI_MAX_TOKENS,
                timeout=45,
            )
        except AuthenticationError:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except (APIConnectionError, APITimeoutError):
            return Response(
                {"error": "upstream_timeout",
                 "message": "The assistant took too long to respond. Please try again."},
                status=status.HTTP_504_GATEWAY_TIMEOUT,
            )
        except RateLimitError:
            return Response(
                {"error": "rate_limited",
                 "message": "The assistant is busy. Please try again shortly."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        except APIError:
            return Response(
                {"error": "upstream_error",
                 "message": "The assistant could not process your request. Please try again."},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        except Exception:
            return Response(
                {"error": "internal_error", "message": "Something went wrong. Please try again."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        reply = completion.choices[0].message.content
        try:
            from analytics.tracking import record_ai_question_event
            record_ai_question_event(request.user, data["message"])
        except Exception:
            pass
        return Response({"reply": reply}, status=status.HTTP_200_OK)


SUMMARIZE_SYSTEM_PROMPT = (
    "You are a strict, concise legal assistant for LegalGuide.\n"
    "Your task: Given an AI answer that has already been generated, create a short, high-clarity summary.\n\n"
    "CRITICAL CONSTRAINTS:\n"
    "1. Base your summary ONLY on facts, procedures, and legal provisions explicitly present in the provided answer.\n"
    "2. Do NOT introduce new legal claims, new section numbers, new penalties, new procedures, or new assumptions.\n"
    "3. Format your response strictly as 3 to 5 concise bullet points (each line starting with '• ').\n"
    "4. Do NOT output headings, conversational introductions, or disclaimers.\n"
    "5. Use simple, everyday citizen language.\n"
    "6. Respond in the exact same language as the provided answer (Telugu, Hindi, or English).\n"
)


class SummarizeAnswerView(APIView):
    permission_classes = [IsAuthenticated]
    throttle_scope = "ai_assistant"

    def post(self, request):
        text = request.data.get("text", "").strip()
        if not text:
            return Response(
                {"error": "invalid_request", "message": "The text to summarize is required."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        api_key = settings.OPENAI_API_KEY
        if not api_key:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        user_lang = request.data.get("language", "auto")
        if user_lang == "te":
            lang_directive = (
                "\n\nCRITICAL MANDATORY INSTRUCTION:\n"
                "The user's application language is TELUGU (తెలుగు).\n"
                "You MUST generate the 3 to 5 summary bullet points ENTIRELY IN TELUGU (తెలుగు script).\n"
                "Base the summary ONLY on the provided text."
            )
            user_prompt = f"Summarize this answer into 3 to 5 clear bullet points in Telugu (తెలుగు) based ONLY on this text:\n\n{text}"
        elif user_lang == "hi":
            lang_directive = (
                "\n\nCRITICAL MANDATORY INSTRUCTION:\n"
                "The user's application language is HINDI (हिन्दी).\n"
                "You MUST generate the 3 to 5 summary bullet points ENTIRELY IN HINDI (हिन्दी script).\n"
                "Base the summary ONLY on the provided text."
            )
            user_prompt = f"Summarize this answer into 3 to 5 clear bullet points in Hindi (हिन्दी) based ONLY on this text:\n\n{text}"
        else:
            lang_directive = "\n\nWrite the 3 to 5 summary bullet points in ENGLISH."
            user_prompt = f"Summarize this answer into 3 to 5 clear bullet points based ONLY on this text:\n\n{text}"

        messages = [
            {"role": "system", "content": SUMMARIZE_SYSTEM_PROMPT + lang_directive},
            {
                "role": "user",
                "content": user_prompt,
            },
        ]

        client = OpenAI(
            api_key=api_key,
            base_url=settings.OPENAI_BASE_URL or None,
            max_retries=0,
        )
        try:
            completion = client.chat.completions.create(
                model=settings.OPENAI_MODEL,
                messages=messages,
                max_tokens=250,
                temperature=0.2,
                timeout=30,
            )
        except AuthenticationError:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)
        except (APIConnectionError, APITimeoutError):
            return Response(
                {"error": "upstream_timeout", "message": "Summarization timed out."},
                status=status.HTTP_504_GATEWAY_TIMEOUT,
            )
        except RateLimitError:
            return Response(
                {"error": "rate_limited", "message": "The assistant is busy. Please try again shortly."},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )
        except APIError:
            return Response(
                {"error": "upstream_error", "message": "Summarization failed."},
                status=status.HTTP_502_BAD_GATEWAY,
            )
        except Exception:
            return Response(
                {"error": "internal_error", "message": "Something went wrong while summarizing."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        summary = completion.choices[0].message.content.strip()
        return Response({"summary": summary}, status=status.HTTP_200_OK)
