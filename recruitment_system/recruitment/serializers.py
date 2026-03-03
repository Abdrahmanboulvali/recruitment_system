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
    class Meta:
        model = Candidature
        fields = ['id', 'candidat', 'offre', 'cv_file', 'statut', 'score', 'date_postulation']

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