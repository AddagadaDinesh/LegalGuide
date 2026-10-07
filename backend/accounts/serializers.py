from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

User = get_user_model()


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)
    email = serializers.EmailField(required=True, allow_blank=False)

    class Meta:
        model = User
        fields = ["username", "email", "password"]

    def validate_username(self, value):
        cleaned = value.strip()
        if len(cleaned) < 3:
            raise serializers.ValidationError("Username must be at least 3 characters long.")
        if User.objects.filter(username__iexact=cleaned).exists():
            raise serializers.ValidationError(
                "A user with this or a similar username already exists. Please choose a different username."
            )
        return cleaned

    def validate_email(self, value):
        cleaned = value.strip().lower()
        if not cleaned:
            raise serializers.ValidationError("Email is required.")
        if User.objects.filter(email__iexact=cleaned).exists():
            raise serializers.ValidationError("A user with this email address already exists.")
        return cleaned

    def validate(self, attrs):
        candidate = User(username=attrs.get("username", ""), email=attrs.get("email", ""))
        validate_password(attrs["password"], user=candidate)
        return attrs

    def create(self, validated_data):
        return User.objects.create_user(
            username=validated_data["username"].strip(),
            email=validated_data.get("email", "").strip().lower(),
            password=validated_data["password"],
        )


class LoginSerializer(serializers.Serializer):
    username = serializers.CharField()
    password = serializers.CharField(write_only=True)


class UserSerializer(serializers.ModelSerializer):
    role = serializers.SerializerMethodField()
    last_active_at = serializers.SerializerMethodField()
    last_login_at = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "username",
            "email",
            "is_staff",
            "is_superuser",
            "role",
            "date_joined",
            "last_login",
            "last_active_at",
            "last_login_at",
        ]

    def get_role(self, obj):
        if obj.is_staff or obj.is_superuser:
            return "ADMIN"
        profile = getattr(obj, "profile", None)
        if profile and profile.role == "ADMIN":
            return "ADMIN"
        return "USER"

    def get_last_active_at(self, obj):
        profile = getattr(obj, "profile", None)
        return profile.last_active_at if profile else None

    def get_last_login_at(self, obj):
        profile = getattr(obj, "profile", None)
        return profile.last_login_at if profile else obj.last_login
