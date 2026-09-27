from openai import (
    APIConnectionError,
    APIError,
    APITimeoutError,
    AuthenticationError,
    OpenAI,
    RateLimitError,
)
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from django.conf import settings

from accounts.models import AbuseEvent

from .safety import HARMFUL_REQUEST_RESPONSE, SELF_HARM_RESPONSE, classify_message_risk
from .serializers import ChatRequestSerializer

SYSTEM_PROMPT = (
    "You are the LegalGuide assistant, embedded in the LegalGuide mobile app for Indian "
    "law and citizen rights. Answer questions helpfully, warmly, and neutrally, including "
    "questions that describe or ask about crimes (e.g. 'what is the punishment for X', "
    "'is X illegal') — those are the app's core purpose and are never suspect.\n\n"
    "CRITICAL MULTILINGUAL & CASUAL QUERY INSTRUCTION:\n"
    "- You MUST understand and reply in WHATEVER language or dialect the user asks their question in.\n"
    "- If the user asks in Telugu script (తెలుగు) or transliterated Telugish (e.g., 'em app idhii', 'idhi emi app', 'police nannu arrest chesaru em cheyali', 'bail ela teesukovali'), understand immediately and reply in warm, helpful Telugu (either Telugu script or clear natural Telugu).\n"
    "- If the user asks in Hindi script (हिन्दी) or transliterated Hinglish (e.g., 'yeh kya app hai', 'police ne pakda to kya karein', 'chori ki saza kya hai'), understand immediately and reply in warm, helpful Hindi.\n"
    "- If the user asks in Tamil, Kannada, Malayalam, Bengali, Marathi, Gujarati, Urdu, or any other Indian or global language, reply fluently in that same language.\n"
    "- If the user asks in English, reply in English.\n"
    "- If the user asks general questions about this app (e.g., 'em app idhii' / 'what is this app' / 'yeh kaisa app hai'), warmly explain that LegalGuide (లీగల్‌గైడ్ / लीगलगाइड) is designed to help citizens understand Indian laws, police rights, railway rules, emergency protections, and court procedures in simple, everyday language.\n\n"
    "Decline only requests asking you to actively help plan, commit, or carry "
    "out something illegal or harmful (e.g. writing malware, threats, or "
    "instructions for violence); in that case, briefly decline in the user's language and offer to "
    "explain the relevant law instead."
)

UNAVAILABLE_RESPONSE = {
    "error": "assistant_unavailable",
    "message": "The AI assistant is temporarily unavailable.",
}


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

        scanned_text = " ".join([h["content"] for h in data["history"]] + [data["message"]])
        risk = classify_message_risk(scanned_text)
        if risk is not None:
            if risk == "harmful_request":
                AbuseEvent.objects.create(user=request.user, category=risk)
            reply = SELF_HARM_RESPONSE if risk == "self_harm" else HARMFUL_REQUEST_RESPONSE
            return Response({"reply": reply}, status=status.HTTP_200_OK)

        api_key = settings.OPENAI_API_KEY
        if not api_key:
            return Response(UNAVAILABLE_RESPONSE, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        user_lang = data.get("language", "auto")
        lang_hint = ""
        if user_lang and user_lang != "auto":
            lang_hint = f"\n[Context: User app interface language is '{user_lang}'.]"

        messages = [{"role": "system", "content": SYSTEM_PROMPT + lang_hint}]
        messages += [{"role": h["role"], "content": h["content"]} for h in data["history"]]
        messages.append({"role": "user", "content": data["message"]})

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
        return Response({"reply": reply}, status=status.HTTP_200_OK)
