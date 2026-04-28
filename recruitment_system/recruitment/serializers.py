# recruitment/serializers.py
from rest_framework import serializers
from .models import (
    Candidat, Offre, Candidature, User, Enterprise, AgentRH,
    SubscriptionPlan, PaymentMethod, SubscriptionRequest
)
from djoser.serializers import UserSerializer as BaseUserSerializer
from djoser.serializers import TokenCreateSerializer

# --- 1. Serializer المؤسسات ---
# recruitment/serializers.py

class EnterpriseSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='nom', read_only=True, default="Sans Nom")
    dg_name = serializers.SerializerMethodField()

    # الحل هنا: نستخدم SerializerMethodField لجلب معرف المدير (Owner)
    owner_id = serializers.SerializerMethodField()

    class Meta:
        model = Enterprise
        fields = ['id', 'nom', 'name', 'description', 'dg_name', 'logo', 'is_approved', 'verification_document',
                  'owner_id']

    def get_owner_id(self, obj):
        # البحث عن أول موظف مرتبط بالمؤسسة وله دور مدير (Propriétaire)
        owner = obj.employees.filter(role__in=['DG', 'DG_GOV', 'DG_BUSINESS']).first()
        return owner.id if owner else None

    def get_dg_name(self, obj):
        try:
            # نستخدم الحقل 'employees' لأنه الـ related_name في موديل User
            dg = obj.employees.filter(role__in=['DG', 'DG_GOV', 'DG_BUSINESS']).first()
            return dg.username if dg else "Admin"
        except:
            return "Admin"

# --- 2. Serializer التسجيل (الشامل لكل الأدوار) ---
class RegisterSerializer(serializers.ModelSerializer):
    enterprise_name = serializers.CharField(write_only=True, required=False)
    verification_document = serializers.FileField(write_only=True, required=False)
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'role', 'enterprise_name', 'verification_document']

    def create(self, validated_data):
        role = validated_data.get('role', 'CANDIDAT')
        enterprise_name = validated_data.pop('enterprise_name', None)
        verif_doc = validated_data.pop('verification_document', None)
        password = validated_data.pop('password')

        user = User(**validated_data)
        user.set_password(password)
        user.is_active = False

        if role in ['DG', 'DG_GOV', 'DG_BUSINESS'] and enterprise_name:
            type_map = {
                'DG': 'PRIVATE',
                'DG_GOV': 'GOVERNMENT',
                'DG_BUSINESS': 'ENTREPRENEUR'
            }
            ent = Enterprise.objects.create(
                nom=enterprise_name,
                type_entite=type_map.get(role, 'PRIVATE'),
                verification_document=verif_doc,
                is_approved=False
            )
            user.enterprise = ent

        user.save()
        return user

# --- 3. Serializers الوظائف والترشيحات ---
class OffreSerializer(serializers.ModelSerializer):
    enterprise_name = serializers.CharField(source='enterprise.nom', read_only=True)
    class Meta:
        model = Offre
        fields = '__all__'
        extra_kwargs = {'enterprise': {'read_only': True}}

class CandidatSerializer(serializers.ModelSerializer):
    class Meta:
        model = Candidat
        fields = '__all__'

class CandidatureSerializer(serializers.ModelSerializer):
    class Meta:
        model = Candidature
        fields = '__all__'

# --- 4. Serializers المستخدمين والتوكين ---
class UserSerializer(BaseUserSerializer):
    enterprise_nom = serializers.CharField(source='enterprise.nom', read_only=True)
    is_verified_otp = serializers.BooleanField(read_only=True)
    class Meta(BaseUserSerializer.Meta):
        fields = ('id', 'email', 'username', 'role', 'photo', 'is_active', 'is_verified_otp', 'enterprise', 'enterprise_nom')

class CustomTokenCreateSerializer(TokenCreateSerializer):
    def validate(self, attrs):
        data = super().validate(attrs)
        if not self.user.is_active:
            if self.user.role != 'CANDIDAT' and self.user.is_verified_otp:
                raise serializers.ValidationError("Votre compte est en attente d'approbation par l'administration.")
            raise serializers.ValidationError("Compte non activé. Veuillez vérifier votre code OTP.")
        return data

class AgentCreateSerializer(serializers.ModelSerializer):
    username = serializers.CharField(required=True)
    password = serializers.CharField(write_only=True)
    departement = serializers.CharField(required=False, allow_blank=True)
    class Meta:
        model = User
        fields = ['username', 'email', 'password', 'departement']
    def create(self, validated_data):
        dept = validated_data.pop('departement', '')
        request = self.context.get('request')
        current_user = request.user if request else None
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data['email'],
            password=validated_data['password'],
            is_active=True
        )
        user.role = 'ADMIN'
        if current_user and current_user.enterprise:
            user.enterprise = current_user.enterprise
        user.save()
        AgentRH.objects.create(user=user, departement=dept)
        return user

class DashboardStatsSerializer(serializers.Serializer):
    total_offres = serializers.IntegerField()
    total_candidatures = serializers.IntegerField()
    avg_score = serializers.FloatField()
    distribution = serializers.DictField()
    offres_analytics = serializers.ListField()

# --- 5. إضافات نظام الاشتراكات والمالية (المحدثة) ---
# --- 5. إضافات نظام الاشتراكات والمالية (المحدثة للأتمتة) ---

class SubscriptionPlanSerializer(serializers.ModelSerializer):
    class Meta:
        model = SubscriptionPlan
        fields = ['id', 'title', 'price', 'offres_count', 'duration_months', 'description']


class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        # التعديل: أضفنا technical_name لكي يعرف الموبايل أي تطبيق يفتح (bankily, masrvi...)
        fields = ['id', 'provider_name', 'technical_name', 'account_number', 'account_holder', 'is_active']


class SubscriptionRequestSerializer(serializers.ModelSerializer):
    enterprise_name = serializers.ReadOnlyField(source='enterprise.nom')
    plan_title = serializers.ReadOnlyField(source='plan.title')

    # إضافة تفاصيل وسيلة الدفع لتظهر في تطبيق الموبايل عند الطلب
    payment_details = PaymentMethodSerializer(source='payment_method', read_only=True)

    class Meta:
        model = SubscriptionRequest
        fields = [
            'id', 'enterprise', 'enterprise_name', 'plan', 'plan_title',
            'payment_method', 'payment_details', 'transaction_ref',  # المرجع الفريد الجديد
            'payment_receipt', 'status', 'date_subscription'
        ]
        # المرجع الفريد (transaction_ref) يجب أن يكون للقراءة فقط لأن السيرفر هو من يولده
        read_only_fields = ['status', 'enterprise', 'date_subscription', 'transaction_ref']

    # ملاحظة: لم نعد نحتاج لإجبار المستخدم على رفع الوصل (payment_receipt)
    # لأننا انتقلنا لنظام الأتمتة، لذا يمكن جعلها اختيارية في الـ Validate
    def validate_payment_receipt(self, value):
        # يمكنك ترك هذا الحقل اختيارياً الآن لأن الأتمتة تعتمد على المرجع الرقمي
        return value