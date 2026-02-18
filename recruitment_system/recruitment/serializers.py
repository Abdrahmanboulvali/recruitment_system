from rest_framework import serializers
from .models import Candidat, Offre, Candidature

# Convertir le modèle Offre en JSON
class OffreSerializer(serializers.ModelSerializer):
    class Meta:
        model = Offre
        fields = '__all__'

# Convertir le modèle Candidat en JSON
class CandidatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Candidat
        fields = '__all__'

# Convertir le modèle Candidature en JSON
class CandidatureSerializer(serializers.ModelSerializer):
    # Afficher les détails au lieu des IDs (Optionnel)
    candidat_name = serializers.ReadOnlyField(source='candidat.nom')
    offre_titre = serializers.ReadOnlyField(source='offre.titre')

    class Meta:
        model = Candidature
        fields = '__all__'