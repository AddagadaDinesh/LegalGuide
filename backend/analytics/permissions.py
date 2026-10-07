from rest_framework.permissions import BasePermission


class IsAdminUserRole(BasePermission):
    """
    Allows access only to authenticated users who possess the ADMIN role.
    Checks:
      - user.is_staff
      - user.is_superuser
      - user.profile.role == 'ADMIN'
    
    Rejects all normal users and unauthenticated requests with HTTP 403 Forbidden.
    Never relies on client-provided headers or query parameters.
    """
    message = "You do not have permission to access the Admin Analytics Dashboard. Administrator privileges are required."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False
        if user.is_staff or user.is_superuser:
            return True
        profile = getattr(user, "profile", None)
        if profile and (profile.role == "ADMIN" or profile.is_admin):
            return True
        return False
