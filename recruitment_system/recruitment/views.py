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
from .permissions import IsResponsableRHOrAdmin, IsResponsableRH, IsCanPostOffre

# استبدل تحميل الـ PKL بهذا:
from sentence_transformers import SentenceTransformer, util
import torch

# تحميل الموديل (سيتم تحميله مرة واحدة عند تشغيل السيرفر)
# هذا الموديل يدعم 50+ لغة وهو مثالي لمشروعك
EVALUATOR_MODEL = SentenceTransformer('paraphrase-multilingual-MiniLM-L12-v2')

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

                try:
                    default_plan = SubscriptionPlan.objects.filter(price=0).first() or SubscriptionPlan.objects.first()
                    if default_plan:
                        enterprise.current_plan = default_plan
                except SubscriptionPlan.DoesNotExist:
                    pass
                    # -----------------------------------------------

                enterprise.save()

            user_to_approve.save()


            send_mail(
                'Compte Activé',
                'Félicitations, votre compte et votre entreprise ont été approuvés.',
                'admin@system.com',
                [user_to_approve.email]
            )
            return Response({"message": "Compte activé par le Super Admin"})
        except User.DoesNotExist:
            return Response({"error": "Utilisateur non trouvé"}, status=404)


from rest_framework.decorators import api_view
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
        return [IsAuthenticated(), IsCanPostOffre()]

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
        # 1. تنفيذ عملية الحفظ الأساسية للطلب
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        candidature = serializer.save()

        # 2. البدء في عملية التقييم الذكي إذا وجد ملف CV
        if candidature.cv_file:
            try:
                # أ. استخراج النص من الـ PDF (دعم كامل لجميع اللغات)
                with pdfplumber.open(candidature.cv_file.path) as pdf:
                    cv_text = " ".join([p.extract_text() or "" for p in pdf.pages])

                # ب. جلب متطلبات الوظيفة (العنوان + الوصف) لزيادة دقة المقارنة
                job_requirements = f"{candidature.offre.titre} {candidature.offre.description}"

                if cv_text.strip() and job_requirements.strip():
                    # ج. تحويل النصوص إلى Vector Embeddings (تمثيل دلالي للمعنى)
                    embeddings = EVALUATOR_MODEL.encode([cv_text, job_requirements], convert_to_tensor=True)

                    # د. حساب تشابه الكوساين (Cosine Similarity)
                    cosine_score = util.cos_sim(embeddings[0], embeddings[1])

                    # هـ. معالجة السكور ليكون نسبة مئوية (0-100)
                    raw_score = float(cosine_score[0][0]) * 100

                    # تحسين النتيجة
                    final_score = round(min(max(raw_score + 5, 0), 99), 2)
                    candidature.score = final_score

                    # و. توليد تعليق الإدارة (Commentaire IA)
                    if final_score >= 80:
                        candidature.commentaire_ia = "Excellent match : Le profil possède les compétences clés recherchées."
                    elif final_score >= 60:
                        candidature.commentaire_ia = "Bon match : Le profil est pertinent pour ce poste."
                    elif final_score >= 40:
                        candidature.commentaire_ia = "Match moyen : Quelques compétences correspondent، des lacunes existent."
                    else:
                        candidature.commentaire_ia = "Faible correspondance : Le profil ne correspond pas aux attentes."
                else:
                    candidature.score = 0
                    candidature.commentaire_ia = "Analyse impossible : Document vide ou illisible."

                # 3. حفظ التعديلات النهائية في قاعدة البيانات
                candidature.save()

            except Exception as e:
                print(f"DL Analysis Error: {e}")
                candidature.score = 0
                candidature.commentaire_ia = "Erreur technique lors de l'évaluation du CV."
                candidature.save()

        return Response(self.get_serializer(candidature).data, status=status.HTTP_201_CREATED)

    # 🚀 --- الدالة المحدثة: إرسال البريد تلقائياً وبلغة ديناميكية متعددة ---
    def update(self, request, *args, **kwargs):
        partial = kwargs.pop('partial', False)
        instance = self.get_object()

        # الاحتفاظ بالحالة القديمة لمقارنتها
        old_statut = instance.statut

        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        candidature = serializer.save()

        # الحالة الجديدة بعد التعديل (مثل: 'Accepté' أو 'Refusé')
        new_statut = candidature.statut

        # التحقق من أن الحالة تغيرت فعلياً لتفادي تكرار الإرسال
        if old_statut != new_statut and new_statut in ['Accepté', 'Refusé']:
            try:
                # 1. جلب بريد صاحب الشركة الحالي واسم المؤسسة
                employer_email = request.user.email
                enterprise_name = request.user.enterprise.nom if request.user.enterprise else "Notre Entreprise"

                # 2. جلب بيانات المشترك (المترشح) للإرسال إليه
                candidat_profile = candidature.candidat
                candidat_user = candidat_profile.user
                candidat_email = candidat_user.email
                candidat_name = f"{getattr(candidat_profile, 'prenom', '')} {getattr(candidat_profile, 'nom', '')}".strip() or candidat_user.username

                job_title = candidature.offre.titre

                # 3. 🌍 تحديد لغة البريد تلقائياً (عربي أم فرنسي)
                # يفحص الـ Header القادم من تطبيق Flutter أو وجود أحرف عربية في عنوان الوظيفة كمؤشر
                user_language = request.headers.get('Accept-Language', '').lower()
                is_arabic = 'ar' in user_language or any(u'\u0600' <= c <= u'\u06FF' for c in job_title)

                # 4. صياغة نصوص الرسائل بناءً على اللغة المحددة والقرار
                if is_arabic:
                    # القوالب باللغة العربية
                    if new_statut == 'Accepté':
                        subject = f"تهانينا! تم قبول طلبك لوظيفة {job_title}"
                        message = f"""
مرحباً {candidat_name}،

يسعدنا إبلاغك بأن طلبك للتقدم لوظيفة ({job_title}) لدى مؤسسة "{enterprise_name}" قد تم قبوله.

سيتواصل معك مسؤول الموارد البشرية قريباً لتحديد الخطوات المقبلة وموعد المقابلة الشخصية.

أطيب التحيات،
{enterprise_name}
                        """
                    else:  # Refusé
                        subject = f"تحديث بشأن طلبك لوظيفة {job_title}"
                        message = f"""
مرحباً {candidat_name}،

نشكرك على اهتمامك ووقتك للتقدم لوظيفة ({job_title}) لدى مؤسسة "{enterprise_name}".

نأسف لإبلاغك بأننا لن نتمكن من المضي قدماً في طلبك هذه المرة نظراً لمتطلبات الوظيفة الحالية، وسنقوم بالاحتفاظ بملفك للفرص المستقبلية.

نتمنى لك التوفيق في مسيرتك المهنية.

أطيب التحيات،
{enterprise_name}
                        """
                else:
                    # القوالب باللغة الفرنسية
                    if new_statut == 'Accepté':
                        subject = f"Notification : Candidature Acceptée pour le poste de {job_title}"
                        message = f"""
Bonjour {candidat_name},

Nous avons le plaisir de vous informer que votre candidature pour le poste de ({job_title}) au sein de "{enterprise_name}" a été acceptée.

Le responsable RH vous contactera sous peu pour planifier les prochaines étapes.

Cordialement,
{enterprise_name}
                        """
                    else:  # Refusé
                        subject = f"Mise à jour concernant votre candidature pour le poste de {job_title}"
                        message = f"""
Bonjour {candidat_name},

Nous vous remercions pour l'intérêt porté à notre établissement. Après étude de votre dossier pour le poste de ({job_title}), nous avons le regret de vous informer que votre profil n'a pas été retenu pour cette fois.

Nous conserverons vos coordonnées pour de futures opportunités.

Cordialement,
{enterprise_name}
                        """

                # 5. الإرسال الأوتوماتيكي الفوري (المرسل: صاحب الشركة الحالي -> المستقبل: المترشح المشترك)
                send_mail(
                    subject=subject,
                    message=message,
                    from_email=employer_email,
                    recipient_list=[candidat_email],
                    fail_silently=False
                )
                print(f"✅ [DYNAMIC EMAIL] Sent in {'Arabic' if is_arabic else 'French'} from {employer_email} to {candidat_email}")

            except Exception as e:
                print(f"❌ [EMAIL ERROR] {e}")

        return Response(serializer.data)

# --- Stats & Dashboards ---
from django.db.models import Avg, Count, Sum  # تم إضافة Sum هنا لحل الخطأ الخاص بها نهائياً
from django.db.models.functions import ExtractMonth
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

# استيراد الموديلات الحقيقية بناءً على ملف serializers.py الخاص بك
from .models import (
    Enterprise, User, Candidat, Offre,
    Candidature, SubscriptionPlan, SubscriptionRequest
)
from django.db.models import Avg, Count, Sum
from django.db.models.functions import ExtractMonth
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import (
    Enterprise, User, Candidat, Offre,
    Candidature, SubscriptionRequest
)


class DashboardDataAPI(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        user_role = str(user.role).upper().strip() if user.role else ""

        # التحقق الآمن والمباشر من السوبر أدمن
        if user_role == 'SUPER_ADMIN' or user.is_superuser or user.is_staff:

            all_cands = Candidature.objects.all()
            distribution_system = {
                "Fortement": all_cands.filter(score__gte=75).count(),
                "Pertinente": all_cands.filter(score__range=(40, 74.99)).count(),
                "Faiblement": all_cands.filter(score__lt=40).count(),
            }

            sectors_data = {
                "Tech": Offre.objects.filter(titre__icontains='Tech').count() or Offre.objects.filter(
                    titre__icontains='تكنو').count(),
                "Santé": Offre.objects.filter(titre__icontains='Santé').count() or Offre.objects.filter(
                    titre__icontains='صحة').count(),
                "Finance": Offre.objects.filter(titre__icontains='Finance').count() or Offre.objects.filter(
                    titre__icontains='مال').count(),
                "Droit": Offre.objects.filter(titre__icontains='Droit').count() or Offre.objects.filter(
                    titre__icontains='قانون').count(),
            }

            financial_flux = [0.0] * 6
            current_year = timezone.now().year

            try:
                monthly_revenues = (
                    SubscriptionRequest.objects.filter(status__in=['ACTIVE', 'APPROVED', 'COMPLETED'],
                                                       date_subscription__year=current_year)
                    .annotate(month=ExtractMonth('date_subscription'))
                    .values('month')
                    .annotate(total=Sum('plan__price'))
                    .order_by('month')
                )
                for rev in monthly_revenues:
                    month_idx = rev['month'] - 1
                    if 0 <= month_idx < 6:
                        financial_flux[month_idx] = float(rev['total'] or 0.0)
            except Exception as e:
                financial_flux = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]

            stats = {
                "role": "SUPER_ADMIN",
                "total_enterprises": Enterprise.objects.count(),
                "total_users": User.objects.count(),
                "total_candidates": Candidat.objects.count(),
                "total_offers": Offre.objects.count(),
                "distribution": distribution_system,
                "sectors_activities": sectors_data,
                "financial_flux": financial_flux,
            }
            return Response(stats)

        # --- لوحة تحكم الشركات (DG) ---
        else:
            if not user.enterprise:
                return Response({
                    "role": "DG",
                    "total_enterprises": 0, "total_users": 0, "total_candidates": 0, "total_offers": 0,
                    "distribution": {"Fortement": 0, "Pertinente": 0, "Faiblement": 0},
                    "sectors_activities": {"Tech": 0, "Santé": 0, "Finance": 0, "Droit": 0},
                    "status_breakdown": {"Pending": 0, "Accepted": 0, "Rejected": 0},
                    "offres_analytics": [],
                    "financial_flux": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
                })

            # إضافة حساب متوسط السكور لكل وظيفة
            qs_offres = Offre.objects.filter(enterprise=user.enterprise).annotate(avg_score=Avg('candidature__score'))
            qs_cands = Candidature.objects.filter(offre__enterprise=user.enterprise)

            # تحضير بيانات تحليلات الوظائف مع السكور
            offres_analytics = [
                {
                    "titre": o.titre,
                    "count": o.candidature_set.count(),
                    "avg_score": float(o.avg_score or 0.0)
                } for o in qs_offres
            ]

            # --- إضافة حساب حالة المرشحين (Recruitment Funnel) ---
            status_stats = qs_cands.values('statut').annotate(count=Count('id'))
            # تنظيف البيانات لتجنب مشكلة الفراغات أو اختلاف الحالة
            status_map = {}
            for item in status_stats:
                if item['statut']:
                    key = str(item['statut']).strip().upper()
                    status_map[key] = status_map.get(key, 0) + item['count']

            data = {
                "role": "DG",
                "total_enterprises": 1,
                "total_users": user.enterprise.employees.count(),
                "total_candidates": qs_cands.values('candidat').distinct().count(),
                "total_offers": qs_offres.count(),
                "offres_analytics": offres_analytics,
                "distribution": {
                    "Fortement": qs_cands.filter(score__gte=75).count(),
                    "Pertinente": qs_cands.filter(score__range=(40, 74.99)).count(),
                    "Faiblement": qs_cands.filter(score__lt=40).count(),
                },
                "sectors_activities": {
                    "Tech": qs_offres.filter(titre__icontains='Tech').count(),
                    "Santé": qs_offres.filter(titre__icontains='Santé').count(),
                    "Finance": qs_offres.filter(titre__icontains='Finance').count(),
                    "Droit": qs_offres.filter(titre__icontains='Droit').count(),
                },
                "status_breakdown": {
                    "Pending": status_map.get('PENDING', 0),
                    "Accepted": status_map.get('ACCEPTED', 0),
                    "Rejected": status_map.get('REJECTED', 0),
                },
                "financial_flux": [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
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
    # حذفنا الصلاحية العامة هنا لنخصصها داخل دالة get_permissions
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_queryset(self):
        user = self.request.user

        # 1. السوبر أدمن يرى كل المؤسسات (النشطة وغير النشطة)
        if user.is_authenticated and user.role == 'SUPER_ADMIN':
            return Enterprise.objects.all().order_by('is_approved', '-id')

        # 2. المستخدم الإداري (DG/Admin) يرى شركته الخاصة فقط للتحكم بها
        if user.is_authenticated and hasattr(user, 'enterprise') and user.enterprise:
            if user.role in ['DG', 'DG_GOV', 'DG_BUSINESS', 'ADMIN']:
                return Enterprise.objects.filter(id=user.enterprise.id)

        # 3. التعديل المضاف: المرشح (Candidat) أو أي مستخدم آخر يرى فقط الشركات المعتمدة (النشطة)
        # هذا يضمن ظهور الشركات في "Espace Candidat"
        return Enterprise.objects.filter(is_approved=True).order_by('-id')

    def get_permissions(self):
        """
        تخصيص الصلاحيات:
        - القراءة (list, retrieve) متاحة للجميع (أو للمسجلين فقط حسب رغبتك).
        - التعديل والإضافة يتطلب أن يكون المستخدم مسجلاً وله صلاحيات إدارية.
        """
        if self.action in ['list', 'retrieve']:
            # السماح للمرشحين والزوار برؤية الشركات فقط
            return [permissions.AllowAny()]

        # العمليات الأخرى (create, update, destroy) تتطلب تسجيل دخول
        return [permissions.IsAuthenticated()]

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
            enterprise.is_approved = False
            enterprise.save()
            return Response({"message": "Désactivée avec succès"}, status=200)
        except Enterprise.DoesNotExist:
            return Response({"error": "Non trouvée"}, status=404)


import time
import requests
import random
from django.db import transaction
from rest_framework import viewsets, permissions, status, generics
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from .models import SubscriptionPlan, PaymentMethod, SubscriptionRequest, Offre
from .serializers import (
    SubscriptionPlanSerializer, PaymentMethodSerializer,
    SubscriptionRequestSerializer
)


# --- دالة المساعدة للربط مع API البنك (معدلة ومصححة بالملي متر) ---
def verify_bpay_with_bank(client_phone, passcode, amount):
    auth_url = "https://ebankily-tst.appspot.com/authentification"
    payment_url = "https://ebankily-tst.appspot.com/payment"

    try:
        # 1. الحصول على التوكن (تمت إضافة البيانات التجريبية الصحيحة للحساب التاجر)
        auth_data = {
            "grant_type": "password",
            "username": "merchant_pilot",
            "password": "1234",
            "client_id": "ebankily"
        }
        headers_auth = {
            "Content-Type": "application/x-www-form-urlencoded"
        }

        auth_res = requests.post(auth_url, data=auth_data, headers=headers_auth, timeout=10)
        access_token = auth_res.json().get('access_token')

        if not access_token:
            return {"errorCode": "1", "errorMessage": "Failed to retrieve access token"}

        # 2. توليد معرف عملية فريد وديناميكي تماماً لمنع خطأ "Operation ID already existe"
        # الآن ستعمل الدالة بنجاح وبدون انهيار بفضل استيراد مكتبة random
        unique_op_id = f"PAY-{int(time.time())}-{random.randint(1000, 9999)}"

        # 3. إرسال طلب الدفع الفعلي
        payment_headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        payment_data = {
            "clientPhone": client_phone,
            "passcode": passcode,
            "amount": str(amount),
            "operationId": unique_op_id,  # تم التصحيح من operationID إلى operationId الحساسة للحالة
            "language": "AR"
        }

        pay_res = requests.post(payment_url, json=payment_data, headers=payment_headers, timeout=10)
        return pay_res.json()

    except Exception as e:
        return {"errorCode": "1", "errorMessage": str(e)}


# --- ViewSets ---

class SubscriptionPlanViewSet(viewsets.ModelViewSet):
    queryset = SubscriptionPlan.objects.all()
    serializer_class = SubscriptionPlanSerializer

    def get_permissions(self):
        if self.action in ['list', 'retrieve']: return [permissions.AllowAny()]
        return [IsAuthenticated()]


class PaymentMethodViewSet(viewsets.ModelViewSet):
    queryset = PaymentMethod.objects.all()
    serializer_class = PaymentMethodSerializer

    def get_permissions(self):
        if self.action == 'list':
            return [IsAuthenticated()]
        return [IsAuthenticated()]

    def create(self, request, *args, **kwargs):
        """
        دالة إضافة مخصصة متوافقة تماماً مع الحقول المرسلة من React
        ومطابقة لموديل الـ PaymentMethod في Django
        """
        # 1. طباعة البيانات للتأكد (كما ظهرت في الـ Terminal)
        print("DEBUG RECEIVED DATA FROM REACT:", request.data)

        # 2. جلب البيانات بناءً على المسمى القادم من React وهو 'provider_name'
        bank_name = request.data.get('provider_name') or request.data.get('name') or request.data.get('provider')
        account_number = request.data.get('account_number') or request.data.get('number')

        # 3. التحقق من وجود البيانات
        if not bank_name or not account_number:
            return Response(
                {"detail": "Veuillez fournir le nom du fournisseur (provider_name) et le numéro de compte."},
                status=status.HTTP_400_BAD_REQUEST
            )

        try:
            # 4. الإنشاء في قاعدة البيانات
            # لتجنب خطأ unexpected keyword argument 'name'، سنقوم بإنشاء الكائن بمرونة:
            # نقوم بتجربة الحقل المتوقع في الموديل وهو provider أو provider_name
            payment_method = PaymentMethod.objects.create(
                provider=str(bank_name),
                # إذا كان الحقل في الـ Model اسمه provider_name استبدله بـ provider_name=str(bank_name)
                account_number=str(account_number)
            )

            # 5. تمرير الكائن للـ Serializer لإرجاع الاستجابة للـ React بنجاح
            serializer = self.get_serializer(payment_method, partial=True)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        except Exception as e:
            # في حال كان اسم الحقل في الـ Model مختلفاً أيضاً، سيطبع لك الخطأ البديل هنا
            print(f"DATABASE INSERTION ERROR: {str(e)}")

            # خطة احتياطية ثانية: إذا كان اسم الحقل في الـ Model هو 'provider_name' وليس 'provider'
            try:
                payment_method = PaymentMethod.objects.create(
                    provider_name=str(bank_name),
                    account_number=str(account_number)
                )
                serializer = self.get_serializer(payment_method, partial=True)
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            except Exception as e2:
                print(f"FALLBACK DATABASE ERROR: {str(e2)}")
                return Response(
                    {"detail": f"Erreur d'insertion. Vérifiez les champs du modèle: {str(e2)}"},
                    status=status.HTTP_500_INTERNAL_SERVER_ERROR
                )


class SubscriptionRequestViewSet(viewsets.ModelViewSet):
    queryset = SubscriptionRequest.objects.all()
    serializer_class = SubscriptionRequestSerializer
    permission_classes = [IsAuthenticated]

    def create(self, request, *args, **kwargs):
        # 1. فحص وجود المؤسسة لتجنب انهيار السيرفر
        try:
            enterprise = request.user.enterprise
        except Exception:
            return Response({"detail": "Ce compte n'est affilié à aucune entreprise."}, status=403)

        plan_id = request.data.get('plan')
        method_id = request.data.get('payment_method')
        is_bpay = request.data.get('is_bpay', False)

        if is_bpay:
            # 2. التأكد من وجود الخطة ومعالجة الخطأ
            try:
                plan = SubscriptionPlan.objects.get(id=plan_id)
            except SubscriptionPlan.DoesNotExist:
                return Response({"detail": "Le plan requis n'existe pas."}, status=400)

            client_phone = request.data.get('client_phone')
            passcode = request.data.get('passcode')

            if not client_phone or not passcode:
                return Response({"detail": "Veuillez saisir votre numéro de téléphone et votre code de confirmation."}, status=400)

            # 3. محاولة الاتصال بالبنك مع معالجة أخطاء الشبكة
            try:
                # تحويل errorCode إلى نص أو رقم للتأكد من المقارنة السليمة
                bank_res = verify_bpay_with_bank(client_phone, passcode, plan.price)
                print(f"DEBUG BANK RESPONSE: {bank_res}")
            except Exception as e:
                return Response({"detail": f"Erreur de connexion au serveur de la banque: {str(e)}"}, status=502)

            # 4. معالجة رد البنك (التحقق من النجاح "0" أو 0 كقيمة عددية)
            if str(bank_res.get('errorCode')) == "0":
                try:
                    with transaction.atomic():
                        # تأمين عدم انهيار الكود في حال كان method_id فارغاً من الموبايل
                        # إذا كان الحقل يقبل null تأكد من تعديل الـ Model، أو قم بجلب أول وسيلة دفع متاحة كاحتياط:
                        if not method_id:
                            payment_method_obj = PaymentMethod.objects.filter(name__icontains="Bankily").first() or PaymentMethod.objects.first()
                            method_id = payment_method_obj.id if payment_method_obj else None

                        sub = SubscriptionRequest.objects.create(
                            enterprise=enterprise,
                            plan=plan,
                            payment_method_id=method_id,
                            status='ACTIVE',
                            transaction_ref=bank_res.get('transactionId', f'BPAY_{int(time.time())}')
                        )
                        enterprise.current_plan = plan
                        enterprise.is_approved = True
                        enterprise.save()
                    return Response({"message": "SUCCESS", "detail": "Abonnement activé avec succès"}, status=201)
                except Exception as e:
                    # طباعة الخطأ الفعلي في الـ console لتعرف إذا كان هناك حقل آخر يمنع الحفظ
                    print(f"DATABASE SAVE ERROR: {str(e)}")
                    return Response({"detail": f"Une erreur s'est produite lors de l'enregistrement des données d'abonnement dans Base de données: {str(e)}"}, status=500)
            else:
                return Response({"detail": bank_res.get('errorMessage', 'La banque a rejeté la transaction.')}, status=400)

        # في حال الدفع العادي (Manual)
        return super().create(request, *args, **kwargs)


# --- Views الإدارة والتحقق ---

class AdminSubscriptionListView(generics.ListAPIView):
    permission_classes = [IsAuthenticated]
    serializer_class = SubscriptionRequestSerializer
    queryset = SubscriptionRequest.objects.filter(status='PENDING').order_by('-date_subscription')


class VerifySubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            sub = SubscriptionRequest.objects.get(pk=pk)
            status_received = request.data.get('status')
            sub.status = status_received
            sub.save()
            if status_received == 'ACTIVE':
                ent = sub.enterprise
                ent.current_plan = sub.plan
                ent.is_approved = True
                ent.save()
            return Response({"status": sub.status}, status=200)
        except:
            return Response(status=404)


from datetime import timedelta
from django.utils import timezone


class MySubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        enterprise = getattr(request.user, 'enterprise', None)
        if not enterprise:
            return Response({"status": "INACTIVE"}, status=200)

        # جلب آخر اشتراك نشط للمؤسسة
        sub = SubscriptionRequest.objects.filter(enterprise=enterprise, status='ACTIVE').order_by(
            '-date_subscription').first()

        if sub and sub.plan:
            # حساب عدد الإعلانات المستخدمة من هذه المؤسسة بناءً على اشتراكها الحالي
            usage = Offre.objects.filter(enterprise=enterprise).count()

            # حساب تاريخ انتهاء الاشتراك تلقائياً بناءً على تاريخ الاشتراك ومدة الخطة بالشهور
            # إذا كان الموديل يحتوي على تاريخ انتهاء مسبق يمكنك استخدامه مباشرة: sub.date_expiration
            duration_days = sub.plan.duration_months * 30 if getattr(sub.plan, 'duration_months', None) else 30
            expiration_date = sub.date_subscription + timedelta(days=duration_days)

            return Response({
                "status": "ACTIVE",
                "plan_title": sub.plan.title,
                "offres_count": sub.plan.offres_count,
                "current_usage": usage,
                "expire_date": expiration_date.strftime('%Y-%m-%d'),  # إرسال التاريخ كنص منسق وجاهز للقراءة
                "plan_details": {
                    "title": sub.plan.title,
                    "offres_count": sub.plan.offres_count,
                    "current_usage": usage
                }
            })

        return Response({"status": "INACTIVE"}, status=200)