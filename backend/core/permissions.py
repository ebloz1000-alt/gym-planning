from rest_framework.permissions import SAFE_METHODS, BasePermission


def is_admin_user(user):
    if not user or not user.is_authenticated:
        return False
    role = getattr(getattr(user, "profile", None), "role", "")
    return user.is_staff or role == "admin"


class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return is_admin_user(request.user)


class IsAdminRole(BasePermission):
    def has_permission(self, request, view):
        return is_admin_user(request.user)
