import random
import pdfplumber
import google.generativeai as genai
import joblib
import re
import os
import numpy as np
from django.conf import settings
from django.db.models import Count, Avg
from django.core.mail import send_mail
from django.core.cache import cache
from rest_framework import viewsets, status, generics, permissions, views
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.auth import update_session_auth_hash
from deep_translator import GoogleTranslator
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

from .models import Offre, Candidat, Candidature, User, Enterprise
from .serializers import (
    OffreSerializer, CandidatSerializer, CandidatureSerializer,
    UserSerializer, AgentCreateSerializer, EnterpriseSerializer,
    RegisterSerializer  # Add this one
)
from .permissions import IsResponsableRHOrAdmin, IsResponsableRH

# --- Configurations ---
genai.configure(api_key="YOUR_GEMINI_API_KEY")
ONET_PATH = os.path.join(settings.BASE_DIR, 'onet_knowledge_base.pkl')
try:
    KB_ONET = joblib.load(ONET_PATH)
except:
    KB_ONET = None


def clean_text(text):
    if not text: return ""
    text = str(text).lower()
    text = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()


# --- Auth & User Management ---

class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        # تمرير البيانات والملفات (Files) للـ Serializer
        serializer = RegisterSerializer(data=request.data)

        if serializer.is_valid():
            # 1. إنشاء المستخدم والمؤسسة (تتم مرة واحدة داخل Serializer)
            user = serializer.save()

            # 2. توليد الرمز مرة واحدة فقط وحفظه
            otp = user.otp_code

            # 3. طباعة الرمز للمراقبة في السيرفر
            print(f"DEBUG: OTP {otp} sent to {user.email}")

            # 4. إرسال الإيميل
            send_mail(
                'Vérification',
                f'Code: {otp}',
                'admin@system.com',
                [user.email],
                fail_silently=False
            )

            return Response({"message": "USER_CREATED_OTP_SENT"}, status=201)

        return Response(serializer.errors, status=400)

# recruitment/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_info(request):
    user = request.user
    return Response({
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'role': user.role,
        'is_active': user.is_active
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def user_profile(request):
    # نستخدم السيريالايزر لضمان عودة البيانات بالشكل المتوقع لصفحة Profile.js
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


class VerifyOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        otp_received = str(request.data.get('otp', '')).strip()

        try:
            user = User.objects.get(email=email)

            print(f"DEBUG: DB_OTP: '{user.otp_code}' | RECEIVED_OTP: '{otp_received}'")
            if str(user.otp_code).strip() == otp_received:
                user.is_verified_otp = True
                user.otp_code = None

                if user.role == 'CANDIDAT':
                    user.is_active = True
                    user.save()
                    return Response({"message": "Compte activé avec succès!"}, status=200)
                else:
                    user.save()
                    return Response({
                        "message": "OTP vérifié. Votre dossier est en cours de révision."
                    }, status=202)
            else:
                return Response({"error": "Code incorrect"}, status=400)

        except User.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=404)


from rest_framework import serializers

class CreateEnterpriseWithDGSerializer(serializers.Serializer):
    name = serializers.CharField(max_length=255)
    description = serializers.CharField(required=False, allow_blank=True)
    dg_username = serializers.CharField(max_length=150)
    dg_email = serializers.EmailField()
    dg_password = serializers.CharField(write_only=True)

# 2. دالة تفعيل الحسابات من قبل السوبر أدمن (التي يفتقدها النظام الآن)
class AdminApprovalView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if request.user.role != 'SUPER_ADMIN':
            return Response({"error": "Action non autorisée"}, status=403)

        try:
            user_to_approve = User.objects.get(id=user_id)
            user_to_approve.is_active = True
            if user_to_approve.enterprise:
                user_to_approve.enterprise.is_approved = True
                user_to_approve.enterprise.save()

            user_to_approve.save()
            return Response({"message": "Compte activé avec succès"})
        except User.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=404)


class ApproveEnterpriseView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, user_id):
        if request.user.role != 'SUPER_ADMIN':
            return Response({"error": "Action non autorisée"}, status=403)

        try:
            user_to_approve = User.objects.get(id=user_id)
            user_to_approve.is_active = True  # تفعيل الحساب

            if user_to_approve.enterprise:
                enterprise = user_to_approve.enterprise
                enterprise.is_approved = True  # تفعيل المؤسسة

                # --- التعديل المضاف استناداً للـ Models الخاصة بك ---
                # نقوم بالبحث عن خطة افتراضية (مثلاً "Basic" أو "Gratuit") لربطها بالمؤسسة عند التفعيل لأول مرة
                # هذا يضمن أن 'current_plan' ليس فارغاً في الـ Backend
                try:
                    default_plan = SubscriptionPlan.objects.filter(price=0).first() or SubscriptionPlan.objects.first()
                    if default_plan:
                        enterprise.current_plan = default_plan
                except SubscriptionPlan.DoesNotExist:
                    pass
                    # -----------------------------------------------

                enterprise.save()

            user_to_approve.save()

            # إرسال إيميل ترحيبي للمدير الجديد
            send_mail(
                'Compte Activé',
                'Félicitations, votre compte et votre entreprise ont été approuvés.',
                'admin@system.com',
                [user_to_approve.email]
            )
            return Response({"message": "Compte activé par le Super Admin"})
        except User.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=404)


# recruitment/views.py
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import User

from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import User


@api_view(['POST'])
def toggle_user_status(request, user_id):
    try:
        user = User.objects.get(id=user_id)
        # نتحقق من المسار لمعرفة العملية المطلوبة
        is_deactivating = 'deactivate' in request.path

        if is_deactivating:
            # 1. تعطيل المستخدم
            user.is_active = False
            message = "Utilisateur désactivé"

            # 2. إذا كان مديراً، نعطل الشركة وجميع الوكلاء
            if user.role in ['DG', 'DG_GOV', 'DG_BUSINESS'] and user.enterprise:
                # تعطيل المؤسسة لثبات واجهة السوبر أدمن
                user.enterprise.is_approved = False
                user.enterprise.save()

                # تعطيل جميع الوكلاء (Agents) التابعين لهذه الشركة
                User.objects.filter(
                    enterprise=user.enterprise,
                    role='ADMIN'
                ).update(is_active=False)
                message = "Le DG, l'entreprise et tous les agents ont été désactivés"

        else:
            # 1. تفعيل المستخدم
            user.is_active = True
            message = "Utilisateur activé"

            # 2. إذا كان مديراً، نعيد تفعيل الشركة والوكلاء تلقائياً
            if user.role in ['DG', 'DG_GOV', 'DG_BUSINESS'] and user.enterprise:
                # تفعيل المؤسسة
                user.enterprise.is_approved = True
                user.enterprise.save()

                # تفعيل جميع الوكلاء (Agents) ليعودوا للعمل فور عودة المدير
                User.objects.filter(
                    enterprise=user.enterprise,
                    role='ADMIN'
                ).update(is_active=True)
                message = "Le DG, l'entreprise et tous les agents ont été réactivés"

        user.save()
        return Response({"message": message}, status=200)

    except User.DoesNotExist:
        return Response({"error": "Utilisateur introuvable"}, status=404)


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(UserSerializer(request.user).data)

    # إضافة دالة put لتتوافق مع طلب الـ React
    def put(self, request):
        new_email = request.data.get('email')
        otp_received = request.data.get('otp')

        # 1. منطق تغيير البريد الإلكتروني مع OTP
        if new_email and new_email != request.user.email and not otp_received:
            otp = str(random.randint(100000, 999999))
            cache.set(f'otp_{request.user.id}', otp, timeout=300)
            cache.set(f'pending_email_{request.user.id}', new_email, timeout=300)
            send_mail('Vérification', f'Code: {otp}', 'admin@system.com', [new_email])
            return Response({"detail": "OTP_SENT"})

        # 2. التحقق من الـ OTP إذا تم إرساله
        if otp_received:
            cached_otp = cache.get(f'otp_{request.user.id}')
            pending_email = cache.get(f'pending_email_{request.user.id}')

            if cached_otp == str(otp_received):
                request.user.email = pending_email
                request.user.save()
                cache.delete(f'otp_{request.user.id}')
                cache.delete(f'pending_email_{request.user.id}')
            else:
                return Response({"detail": "Code OTP incorrect"}, status=400)

        # 3. تحديث باقي البيانات (مثل username أو photo)
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=400)

    # اجعل الـ patch تنفذ نفس كود الـ put لضمان عمل الجهتين
    def patch(self, request):
        return self.put(request)


class UserUpdateView(generics.UpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]


class UserListView(generics.ListAPIView):
    serializer_class = UserSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == 'SUPER_ADMIN':
            return User.objects.all().order_by('-id')
        return User.objects.filter(enterprise=user.enterprise).order_by('-id')


class CreateAgentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if request.user.role not in ['DG', 'ADMIN', 'SUPER_ADMIN']:
            return Response({"error": "Non autorisé"}, status=403)
        serializer = AgentCreateSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            serializer.save()
            return Response({"message": "Agent créé!"}, status=201)
        return Response(serializer.errors, status=400)


class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        user = request.user
        if not user.check_password(request.data.get("old_password")):
            return Response({"detail": "Ancien mot de passe incorrect"}, status=400)
        user.set_password(request.data.get("new_password"))
        user.save()
        update_session_auth_hash(request, user)
        return Response({"detail": "Succès"})


# --- Business Logic ViewSets ---

from django.utils import timezone

from rest_framework import serializers, viewsets
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.utils import timezone
from .models import Offre, SubscriptionRequest  # تأكد من استيراد الموديلات الصحيحة


class OffreViewSet(viewsets.ModelViewSet):
    serializer_class = OffreSerializer

    def get_queryset(self):
        user = self.request.user
        now = timezone.now()

        if not user.is_authenticated or user.role == 'CANDIDAT':
            return Offre.objects.filter(date_expiration__gt=now).order_by('-date_publication')

        return Offre.objects.filter(enterprise=user.enterprise).order_by('-date_publication')

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        return [IsAuthenticated(), IsResponsableRHOrAdmin()]

    def perform_create(self, serializer):
        user = self.request.user
        enterprise = user.enterprise

        # جلب الاشتراك النشط حالياً من قاعدة البيانات
        active_subscription = SubscriptionRequest.objects.filter(
            enterprise=enterprise,
            status='ACTIVE'
        ).first()

        # حساب الوظائف بناءً على "نطاق" الاشتراك الحالي
        if not active_subscription:
            # إذا لم يوجد اشتراك، نحسب الوظائف التي نُشرت في الوضع المجاني (بدون اشتراك)
            usage_count = Offre.objects.filter(enterprise=enterprise, subscription__isnull=True).count()
            limit = 3
            if usage_count >= limit:
                raise serializers.ValidationError({
                    "detail": "Limite gratuite atteinte (3 offres). Veuillez activer un pack لزيادة الحد."
                })
        else:
            # إذا وجد اشتراك، نحسب فقط الوظائف المرتبطة بهذا الاشتراك
            usage_count = Offre.objects.filter(subscription=active_subscription).count()
            limit = active_subscription.plan.offres_count
            if usage_count >= limit:
                raise serializers.ValidationError({
                    "detail": f"Limite de votre pack ({limit} offres) atteinte."
                })

        # حفظ العرض مع ربطه بالاشتراك الحالي (أو None إذا كان مجانياً)
        serializer.save(
            enterprise=enterprise,
            created_by=user,
            subscription=active_subscription
        )


class CandidatViewSet(viewsets.ModelViewSet):
    queryset = Candidat.objects.all()
    serializer_class = CandidatSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'CANDIDAT':
            return Candidat.objects.filter(user=user)
        return Candidat.objects.filter(candidature__offre__enterprise=user.enterprise).distinct()


# --- إضافة قاموس التصنيف قبل الـ Class (أو في أعلى الملف) ---
DOMAIN_CLASSIFIER = {
    'medical': ['doctor', 'physician', 'medecin', 'sante', 'health', 'clinical', 'hospital', 'medical'],
    'data_tech': ['python', 'programming', 'software', 'sql', 'machine learning', 'data science', 'developer',
                  'statistics', 'informatique'],
    'finance': ['accounting', 'audit', 'finance', 'tax', 'banking', 'econometrics', 'budget', 'comptable'],
    'legal': ['lawyer', 'legal', 'jurisprudence', 'court', 'attorney', 'contract', 'droit']
}


def detect_domain(text):
    scores = {domaine: 0 for domaine in DOMAIN_CLASSIFIER}
    text_lower = text.lower()
    for domaine, keywords in DOMAIN_CLASSIFIER.items():
        for word in keywords:
            if word in text_lower:
                scores[domaine] += 1
    domaine_detecte = max(scores, key=scores.get)
    return domaine_detecte if scores[domaine_detecte] > 0 else "general"


# --- الـ Class المعدل ---
class CandidatureViewSet(viewsets.ModelViewSet):
    serializer_class = CandidatureSerializer

    def get_queryset(self):
        user = self.request.user
        if user.role == 'CANDIDAT':
            return Candidature.objects.filter(candidat__user=user)
        return Candidature.objects.filter(offre__enterprise=user.enterprise)

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        candidature = serializer.save()

        if KB_ONET is not None and candidature.cv_file:
            try:
                # 1. استخراج ومعالجة النص
                with pdfplumber.open(candidature.cv_file.path) as pdf:
                    cv_raw = " ".join([p.extract_text() or "" for p in pdf.pages])

                cv_en = GoogleTranslator(source='auto', target='en').translate(cv_raw[:4000])
                cv_final = clean_text(cv_en)

                # 2. فحص تخصص المجال (Domain Check)
                original_title = candidature.offre.titre
                cv_domain = detect_domain(cv_final)
                job_domain = detect_domain(original_title)

                if cv_domain != job_domain and job_domain != "general" and cv_domain != "general":
                    candidature.score = 0
                    candidature.commentaire_ia = "Aucune pertinence : Le domaine professionnel ne correspond pas à l'offre."
                    candidature.save()
                    return Response(self.get_serializer(candidature).data, status=201)

                # 3. البحث عن الملف الوظيفي في O*NET
                mask = KB_ONET['Alternate Title'].str.contains(original_title, case=False, na=False)
                job_profile = KB_ONET[mask]

                if job_profile.empty:
                    keywords = original_title.replace('-', ' ').split()
                    for word in keywords:
                        if len(word) > 3:
                            mask = KB_ONET['Alternate Title'].str.contains(word, case=False, na=False)
                            job_profile = KB_ONET[mask]
                            if not job_profile.empty: break

                # 4. حساب النتيجة والصياغة النهائية
                if not job_profile.empty:
                    target_text = clean_text(" ".join(job_profile['full_profile'].astype(str)))
                    vectorizer = TfidfVectorizer(ngram_range=(1, 2))
                    vectors = vectorizer.fit_transform([cv_final, target_text])
                    raw_score = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]

                    # تحسين السكور (Scaling)
                    final_score = np.sqrt(raw_score) * 100
                    candidature.score = int(min(final_score + 5, 99)) if final_score > 10 else int(final_score)

                    # اختيار التعبير الإداري المناسب للمدير
                    if final_score >= 75:
                        candidature.commentaire_ia = "Profil hautement qualifié : Excellente adéquation avec les exigences du poste."
                    elif final_score >= 50:
                        candidature.commentaire_ia = "Profil pertinent : Bonne correspondance globale avec le poste."
                    elif final_score >= 25:
                        candidature.commentaire_ia = "Profil moyennement adapté : Des lacunes techniques sont à prévoir."
                    else:
                        candidature.commentaire_ia = "Profil peu pertinent : Faible correspondance avec les compétences requises."
                else:
                    candidature.score = 10 if cv_raw.strip() else 0
                    candidature.commentaire_ia = "Candidature générique : Manque de détails techniques spécifiques."

                candidature.save()
            except Exception as e:
                print(f"IA Error: {e}")
                candidature.score = 5
                candidature.commentaire_ia = "Erreur d'analyse : Impossible d'évaluer la pertinence technique du document."
                candidature.save()

        return Response(self.get_serializer(candidature).data, status=201)

# --- Stats & Dashboards ---

class DashboardDataAPI(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        # دعم لوحة تحكم السوبر أدمن (الإحصائيات العامة)
        if user.role == 'SUPER_ADMIN':
            stats = {
                "total_enterprises": Enterprise.objects.count(),
                "total_users": User.objects.count(),
                "total_candidates": Candidat.objects.count(),
                "total_offers": Offre.objects.count(),
            }
            return Response(stats)

        # لوحة تحكم الشركات (DG/Admin)
        qs_offres = Offre.objects.filter(enterprise=user.enterprise)
        qs_cands = Candidature.objects.filter(offre__enterprise=user.enterprise)
        data = {
            "total_offres": qs_offres.count(),
            "total_candidatures": qs_cands.count(),
            "avg_score": round(qs_cands.aggregate(Avg('score'))['score__avg'] or 0, 2),
            "distribution": {
                "Fortement": qs_cands.filter(score__gte=75).count(),
                "Pertinente": qs_cands.filter(score__range=(40, 74.99)).count(),
                "Faiblement": qs_cands.filter(score__lt=40).count(),
            },
            "offres_analytics": list(
                qs_offres.annotate(count=Count('candidature'), avg=Avg('candidature__score')).values('titre', 'count',
                                                                                                     'avg'))
        }
        return Response(data)


# --- Enterprise Management ---

from rest_framework import viewsets, status
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from .models import Enterprise, User
from .serializers import EnterpriseSerializer


class EnterpriseViewSet(viewsets.ModelViewSet):
    serializer_class = EnterpriseSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_queryset(self):
        user = self.request.user
        # 1. السوبر أدمن يرى كل المؤسسات
        if user.role == 'SUPER_ADMIN':
            return Enterprise.objects.all().order_by('is_approved', '-id')

        # 2. المستخدم العادي يرى شركته فقط (بأمان)
        if hasattr(user, 'enterprise') and user.enterprise:
            return Enterprise.objects.filter(id=user.enterprise.id)

        # 3. إذا كان مرشح أو مستخدم تائه، لا نرسل خطأ 500، بل نرسل قائمة فارغة
        return Enterprise.objects.none()

class CreateEnterpriseWithDGView(views.APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            data = serializer.validated_data
            enterprise = Enterprise.objects.create(
                nom=data['name'],
                description=data.get('description', '')
            )
            dg_user = User.objects.create_user(
                username=data['dg_username'],
                email=data['dg_email'],
                password=data['dg_password'],
                role='DG',
                enterprise=enterprise
            )
            return Response({
                "message": "Entreprise et compte DG créés avec succès",
                "enterprise": enterprise.nom,
                "dg": dg_user.email
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


import random
from django.core.mail import send_mail
from django.core.cache import cache
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import User


# المرحلة الأولى: طلب إرسال الرمز
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        try:
            user = User.objects.get(email=email)
            # توليد رمز عشوائي من 6 أرقام
            otp = str(random.randint(100000, 999999))

            # تخزين الرمز في الكاش لمدة 5 دقائق (300 ثانية) مرتبطاً بالإيميل
            cache.set(f'reset_otp_{email}', otp, timeout=300)

            # إرسال الإيميل للمستخدم
            send_mail(
                'Réinitialisation de mot de passe',
                f'Votre code de réinitialisation est : {otp}',
                'admin@recrutement.com',
                [email],
                fail_silently=False,
            )
            return Response({"message": "OTP_SENT"}, status=status.HTTP_200_OK)
        except User.DoesNotExist:
            # للأمن، لا نخبر المخترق أن الإيميل غير موجود، بل نعطي نفس الرد
            return Response({"message": "OTP_SENT"}, status=status.HTTP_200_OK)


# المرحلة الثانية: التحقق من الرمز وتغيير كلمة المرور
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')
        otp_received = request.data.get('otp')
        new_password = request.data.get('new_password')

        # استرجاع الرمز المخزن من الكاش
        cached_otp = cache.get(f'reset_otp_{email}')

        if cached_otp and cached_otp == str(otp_received):
            try:
                user = User.objects.get(email=email)
                user.set_password(new_password)
                user.save()
                # حذف الرمز من الكاش بعد الاستخدام
                cache.delete(f'reset_otp_{email}')
                return Response({"message": "PASSWORD_RESET_SUCCESS"}, status=status.HTTP_200_OK)
            except User.DoesNotExist:
                return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)

        return Response({"error": "Code invalide ou expiré"}, status=status.HTTP_400_BAD_REQUEST)


class ResendOTPView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email')

        if not email:
            return Response({"error": "L'email est requis"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # البحث عن المستخدم بواسطة البريد الإلكتروني
            user = User.objects.get(email=email)

            # التأكد من أن الحساب لم يتم تفعيله بعد لتجنب إساءة الاستخدام
            if user.is_active and user.is_verified_otp:
                return Response({"error": "Ce compte est déjà vérifié."}, status=status.HTTP_400_BAD_REQUEST)

            # 1. توليد رمز OTP جديد باستخدام الدالة الموجودة في موديل User
            otp = user.otp_code


            # 2. إرسال البريد الإلكتروني
            send_mail(
                'Nouveau code de vérification',
                f'Votre nouveau code de sécurité est : {otp}',
                'admin@system.com',
                [email],
                fail_silently=False,
            )

            return Response({"message": "Nouveau code envoyé avec succès"}, status=status.HTTP_200_OK)

        except User.DoesNotExist:
            # للأمن نرجع رسالة عامة حتى لا يعرف المهاجم الإيميلات المسجلة
            return Response({"message": "Si cet email existe, un code a été envoyé."}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# recruitment/permissions.py (أو أضفه في views.py)
from rest_framework import permissions

class IsSuperAdmin(permissions.BasePermission):
    """
    يسمح فقط للمستخدمين الذين يملكون رتبة SUPER_ADMIN بالوصول.
    """
    def has_permission(self, request, view):
        return (
            request.user and
            request.user.is_authenticated and
            request.user.role == 'SUPER_ADMIN'
        )

class DeactivateEnterpriseView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin] # للسوبر أدمن فقط

    def post(self, request, pk):
        try:
            enterprise = Enterprise.objects.get(pk=pk)
            enterprise.is_approved = False # إلغاء التفعيل
            enterprise.save()
            return Response({"message": "Désactivée avec succès"}, status=200)
        except Enterprise.DoesNotExist:
            return Response({"error": "Non trouvée"}, status=404)


from .models import SubscriptionPlan, PaymentMethod, SubscriptionRequest
from .serializers import (
    SubscriptionPlanSerializer, PaymentMethodSerializer,
    SubscriptionRequestSerializer
)


# --- إضافات الإدارة المالية والاشتراكات ---

# 1. عرض خطط الاشتراك
class SubscriptionPlanViewSet(viewsets.ModelViewSet):
    queryset = SubscriptionPlan.objects.all()
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]
        return [IsAuthenticated(), IsSuperAdmin()]


# 2. عرض طرق الدفع
class PaymentMethodViewSet(viewsets.ModelViewSet):
    queryset = PaymentMethod.objects.all()
    serializer_class = PaymentMethodSerializer

    def get_permissions(self):
        if self.action == 'list':
            return [IsAuthenticated()]
        return [IsSuperAdmin()]


# 3. معالجة طلبات الاشتراك من قبل المستخدمين
class SubscriptionRequestViewSet(viewsets.ModelViewSet):
    serializer_class = SubscriptionRequestSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.role == 'SUPER_ADMIN':
            return SubscriptionRequest.objects.all()
        return SubscriptionRequest.objects.filter(enterprise=user.enterprise)

    def perform_create(self, serializer):
        serializer.save(enterprise=self.request.user.enterprise, status='PENDING')


# 4. الـ View الذي تسبب في الخطأ (AdminSubscriptionListView)
class AdminSubscriptionListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]
    serializer_class = SubscriptionRequestSerializer
    queryset = SubscriptionRequest.objects.filter(status='PENDING').order_by('-date_subscription')


# 5. التحقق وتفعيل الاشتراك (VerifySubscriptionView)
class VerifySubscriptionView(APIView):
    permission_classes = [IsAuthenticated, IsSuperAdmin]

    def patch(self, request, pk):
        try:
            subscription = SubscriptionRequest.objects.get(pk=pk)
            status_received = request.data.get('status')

            if status_received not in ['ACTIVE', 'REJECTED']:
                return Response({"error": "Statut invalide"}, status=400)

            # 1. تحديث حالة الطلب
            subscription.status = status_received
            subscription.save()

            # 2. التفعيل الفعلي للمؤسسة (هذا ما كان ينقصك)
            if status_received == 'ACTIVE' and subscription.enterprise:
                ent = subscription.enterprise
                ent.current_plan = subscription.plan  # ربط الخطة (موجود في موديل Enterprise)
                ent.is_approved = True               # تفعيل المؤسسة
                ent.save()

            return Response({
                "message": f"Statut mis à jour: {status_received}",
                "new_status": subscription.status
            }, status=200)

        except SubscriptionRequest.DoesNotExist:
            return Response({"error": "Demande non trouvée"}, status=404)


# مثال لما يجب أن يكون عليه الكود في الخلفية (نسخة محسنة)
@api_view(['PATCH'])
@permission_classes([IsAuthenticated, IsSuperAdmin])
# في ملف views.py - الجزء الخاص بالموافقة
def approve_subscription(request, pk):
    try:
        subscription = SubscriptionRequest.objects.get(pk=pk)
        subscription.status = 'ACTIVE'
        subscription.save()

        # الخطوة الناقصة والضرورية جداً:
        # ربط المؤسسة بالخطة الجديدة وتفعيلها
        enterprise = subscription.enterprise
        enterprise.current_plan = subscription.plan # تأكد أن هذا الحقل موجود في موديل Enterprise
        enterprise.is_approved = True
        enterprise.save()

        return Response({'status': 'Statut mis à jour : ACTIVE'})
    except SubscriptionRequest.DoesNotExist:
        return Response({'error': 'Demande non trouvée'}, status=404)


class MySubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            enterprise = getattr(request.user, 'enterprise', None) or getattr(request.user, 'enterprise_profile', None)

            if not enterprise:
                return Response({"detail": "Aucune entreprise associée"}, status=400)

            # البحث عن الاشتراك النشط حالياً
            subscription = SubscriptionRequest.objects.filter(
                enterprise=enterprise,
                status='ACTIVE'
            ).select_related('plan').first()

            if subscription:
                # حساب العروض المرتبطة بهذا الاشتراك تحديداً لكي يبدأ العداد من الصفر للباقة الجديدة
                current_usage = Offre.objects.filter(subscription=subscription).count()

                return Response({
                    "id": subscription.id,
                    "status": subscription.status,
                    "plan_details": {
                        "title": subscription.plan.title,
                        "offres_count": subscription.plan.offres_count,
                        "current_usage": current_usage  # العداد الخاص بالباقة الحالية فقط
                    }
                })

            # في حالة الوضع المجاني: نحسب العروض التي ليس لها اشتراك مرتبط (subscription=None)
            free_usage = Offre.objects.filter(enterprise=enterprise, subscription__isnull=True).count()
            return Response({
                "status": "INACTIVE",
                "plan_details": {
                    "title": "Mode Gratuit",
                    "offres_count": 3,
                    "current_usage": free_usage
                }
            }, status=200)

        except Exception as e:
            return Response({"error": str(e)}, status=500)