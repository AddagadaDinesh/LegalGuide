from rest_framework.permissions import BasePermission


class IsLegalAdministrator(BasePermission):
    """
    Allows access only to authenticated users who possess administrator privileges.
    Checks:
      - user.is_staff
      - user.is_superuser
      - user.profile.role == 'ADMIN'
      - user.profile.is_admin is True

    Rejects normal users and unauthenticated requests with HTTP 403 Forbidden.
    """
    message = "You do not have permission to manage statutory legal updates. Legal Administrator privileges are required."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff or user.is_superuser:
            return True
        profile = getattr(user, "profile", None)
        if profile and (getattr(profile, "role", "") == "ADMIN" or getattr(profile, "is_admin", False)):
            return True
        return False
