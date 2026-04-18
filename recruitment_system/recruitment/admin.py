from django.contrib import admin
from .models import User, Candidat, Offre, Candidature

# Enregistrer le modèle User personnalisé
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('email', 'role') # Afficher l'email et le rôle dans la liste

# Enregistrement des modèles pour l'interface d'administration
@admin.register(Offre)
class OffreAdmin(admin.ModelAdmin):
    list_display = ('titre', 'experience_min', 'date_publication')

@admin.register(Candidat)
class CandidatAdmin(admin.ModelAdmin):
    list_display = ('nom', 'prenom', 'diplome')

# recruitment/admin.py
from django.contrib import admin
from .models import Candidature

@admin.register(Candidature)
class CandidatureAdmin(admin.ModelAdmin):
    # On rend le score "lecture seule" pour qu'il ne soit pas modifiable manuellement
    readonly_fields = ('score',)
    list_display = ('candidat', 'offre', 'statut', 'score')


from django.contrib import admin
from .models import Enterprise, SubscriptionPlan, SubscriptionRequest

@admin.register(Enterprise)
class EnterpriseAdmin(admin.ModelAdmin):
    # إظهار الأعمدة الهامة في القائمة بما فيها ملف الإثبات
    list_display = ('nom', 'type_entite', 'is_approved', 'current_plan')
    list_filter = ('is_approved', 'type_entite')
    search_fields = ('nom',)

# تسجيل النماذج الأخرى لتظهر أيضاً
admin.site.register(SubscriptionPlan)
admin.site.register(SubscriptionRequest)