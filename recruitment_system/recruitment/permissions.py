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
        allowed_roles = ['DG', 'Directeur Général', 'Responsable RH', 'ADMIN', 'DG_GOV', 'DG_COMPANY', 'DG_BUSINESS']
        return request.user.role in allowed_roles


from rest_framework import permissions


class IsCanPostOffre(permissions.BasePermission):
    def has_permission(self, request, view):
        # 1. التأكد من أن المستخدم مسجل دخول
        if not (request.user and request.user.is_authenticated):
            return False

        # 2. جلب الدور وتحويله لأحرف كبيرة لتجنب أخطاء الكتابة
        user_role = str(request.user.role).upper()

        # 3. قائمة الأدوار المسموح لها بالنشر
        allowed_roles = [
            'DG', 'DIRECTEUR GÉNÉRAL', 'DIRECTEUR GENERAL',
            'RESPONSABLE RH', 'RESPONSABLE_RH',
            'ADMIN', 'DG_GOV', 'DG_COMPANY', 'DG_BUSINESS'
        ]

        return user_role in allowed_roles