from rest_framework import permissions

class IsResponsableRH(permissions.BasePermission):
    def has_permission(self, request, view):
        # السماح فقط إذا كان المستخدم مسجلاً ودوره هو الوكيل المعتمد في نظامك
        return bool(request.user and request.user.is_authenticated and
                    (request.user.role == 'Responsable RH' or request.user.role == 'RESPONSABLE_RH'))


from rest_framework import permissions

class IsResponsableRHOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        # السماح للمدير العام (DG) والوكيل (Responsable RH)
        allowed_roles = ['DG', 'Directeur Général', 'Responsable RH', 'ADMIN']
        return request.user.role in allowed_roles