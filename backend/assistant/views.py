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
    "You are the LegalGuide assistant, embedded in the LegalGuide app for Indian "
    "law. Answer legal questions helpfully and neutrally, including questions "
    "that describe or ask about crimes (e.g. 'what is the punishment for X', "
    "'is X illegal') — those are the app's core purpose and are never suspect. "
    "Decline only requests asking you to actively help plan, commit, or carry "
    "out something illegal or harmful (e.g. writing malware, threats, or "
    "instructions for violence); in that case, briefly decline and offer to "
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

        messages = [{"role": "system", "content": SYSTEM_PROMPT}]
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
