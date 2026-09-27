from rest_framework import serializers

MAX_HISTORY_MESSAGES = 10


class ChatMessageSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=["user", "assistant"])
    content = serializers.CharField(allow_blank=False, trim_whitespace=True)


class ChatRequestSerializer(serializers.Serializer):
    message = serializers.CharField(
        allow_blank=False,
        trim_whitespace=True,
        max_length=4000,
    )
    history = ChatMessageSerializer(many=True, required=False, default=list)
    language = serializers.CharField(required=False, allow_blank=True, default="auto")

    def validate_history(self, value):
        return value[-MAX_HISTORY_MESSAGES:]
