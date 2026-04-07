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
        fields = '__all__' # سيقوم بجلب كل الحقول الموجودة في الموديل


class DashboardStatsSerializer(serializers.Serializer):
    total_offres = serializers.IntegerField()
    total_candidatures = serializers.IntegerField()
    avg_score = serializers.FloatField()
    distribution = serializers.DictField()
    offres_analytics = serializers.ListField()

from djoser.serializers import UserSerializer as BaseUserSerializer

class UserSerializer(BaseUserSerializer):
    class Meta(BaseUserSerializer.Meta):
        fields = ('id', 'email', 'username', 'role', 'photo')

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer

class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        # partial=True للسماح بتحديث الصورة فقط دون المساس بالبقية
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)


from rest_framework import serializers
from .models import User, AgentRH

from rest_framework import serializers
from .models import User  # تأكد من استيراد نموذج المستخدم الخاص بك

# recruitment/serializers.py
from rest_framework import serializers
from .models import User


class AgentCreateSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(write_only=True)
    departement = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = User
        # أضفنا 'role' هنا لكي يتمكن الـ Serializer من التعامل معه
        fields = ['username', 'email', 'password', 'departement']

    def create(self, validated_data):
        dept = validated_data.pop('departement', '')

        # إنشاء المستخدم
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password']
        )

        # --- الجزء الأهم لتعيين الـ Role ---
        # تأكد أن القيمة 'AGENTRH' هي نفسها المعرفة في CHOICES داخل Models.py
        user.role = 'ADMIN'

        # تعيين القسم إذا كان الحقل موجوداً في الموديل
        if hasattr(user, 'departement'):
            user.departement = dept

        user.save()
        return user