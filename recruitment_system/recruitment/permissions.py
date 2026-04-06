from rest_framework import permissions

class IsResponsableRH(permissions.BasePermission):
    def has_permission(self, request, view):
        # السماح فقط إذا كان المستخدم مسجلاً ودوره هو الوكيل المعتمد في نظامك
        return bool(request.user and request.user.is_authenticated and
                    (request.user.role == 'Responsable RH' or request.user.role == 'RESPONSABLE_RH'))