from django.contrib import admin
from .models import Candidat, Offre, Candidature

# Enregistrement des modèles pour l'interface d'administration
@admin.register(Offre)
class OffreAdmin(admin.ModelAdmin):
    list_display = ('titre', 'experience_min', 'date_publication')

@admin.register(Candidat)
class CandidatAdmin(admin.ModelAdmin):
    list_display = ('nom', 'prenom', 'diplome')

@admin.register(Candidature)
class CandidatureAdmin(admin.ModelAdmin):
    list_display = ('candidat', 'offre', 'statut', 'score')
    list_filter = ('statut',)