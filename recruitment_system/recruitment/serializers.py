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

class DashboardStatsSerializer(serializers.Serializer):
    total_offres = serializers.IntegerField()
    total_candidatures = serializers.IntegerField()
    avg_score = serializers.FloatField()
    distribution = serializers.DictField()
    offres_analytics = serializers.ListField()

from djoser.serializers import UserSerializer as BaseUserSerializer

class UserSerializer(BaseUserSerializer):
    class Meta(BaseUserSerializer.Meta):
        fields = ('id', 'email', 'username', 'role') # إضافة الـ role هنا