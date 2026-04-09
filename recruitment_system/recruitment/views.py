from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count, Avg
from .models import Offre, Candidat, Candidature, User
from .serializers import OffreSerializer, CandidatSerializer, CandidatureSerializer
import pdfplumber
import google.generativeai as genai  # pip install google-generativeai

# --- كود التفعيل الجديد (OTP Verification) ---
class VerifyOTPView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        try:
            # البحث عن المستخدم بالبريد والرمز
            user = User.objects.get(email=email, otp_code=otp)
            user.is_active = True
            user.otp_code = None  # مسح الرمز بعد التفعيل بنجاح
            user.save()
            return Response({"message": "Compte activé avec succès!"}, status=200)
        except User.DoesNotExist:
            return Response({"error": "Code incorrect ou expiré"}, status=400)

# --- كود الإحصائيات (Dashboard) ---
class DashboardDataAPI(APIView):
    def get(self, request):
        data = {
            "total_offres": Offre.objects.count(),
            "total_candidatures": Candidature.objects.count(),
            "avg_score": round(Candidature.objects.aggregate(Avg('score'))['score__avg'] or 0, 2),
            "distribution": {
                "Fortement": Candidature.objects.filter(score__gte=75).count(),
                "Pertinente": Candidature.objects.filter(score__range=(40, 74.99)).count(),
                "Faiblement": Candidature.objects.filter(score__lt=40).count(),
            },
            "offres_analytics": list(Offre.objects.annotate(
                count=Count('candidature'),
                avg=Avg('candidature__score')
            ).values('titre', 'count', 'avg'))
        }
        return Response(data)


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Offre
from .serializers import OffreSerializer # تأكد من وجود Serializer للعروض

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_info(request):
    # إرجاع بيانات المستخدم ودوره البرمجي
    return Response({
        'id': request.user.id,
        'email': request.user.email,
        'role': request.user.role, # 'Candidat' أو 'AgentRH'
        'username': request.user.username
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_offres(request):
    # جلب قائمة العروض للمترشحين
    offres = Offre.objects.all().order_size('-date_publication')
    serializer = OffreSerializer(offres, many=True)
    return Response(serializer.data)

# recruitment/views.py
from rest_framework import generics
from .models import User # أو اسم موديل المستخدم لديك
from .serializers import UserSerializer
from rest_framework.permissions import IsAdminUser

class UserListView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser] # للسماح للمسؤولين فقط برؤية القائمة

def patch(self, request, pk):
    instance = self.get_object(pk)
    serializer = CandidatureSerializer(instance, data=request.data, partial=True) # partial=True ضرورية للـ PATCH
    if serializer.is_valid():
        serializer.save() # هنا يتم الحفظ الفعلي في قاعدة البيانات
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

# --- ViewSets لإدارة البيانات عبر API ---
from rest_framework.permissions import IsAuthenticatedOrReadOnly
# أو
from rest_framework.permissions import AllowAny
from .permissions import IsResponsableRHOrAdmin

from rest_framework import viewsets, permissions
from rest_framework.permissions import IsAuthenticated
# تأكد من استيراد صلاحيتك المخصصة
# from .permissions import IsResponsableRHOrAdmin

class OffreViewSet(viewsets.ModelViewSet):
    queryset = Offre.objects.all()
    serializer_class = OffreSerializer

    def get_permissions(self):
        # 1. السماح للجميع (بما فيهم الزوار) برؤية العروض
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]

        # 2. حصر الإضافة والتعديل والحذف للمسجلين (Authenticated)
        # والذين يملكون رتبة مدير أو وكيل
        # لاحظ إضافة update و partial_update لضمان عمل زر التعديل
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), IsResponsableRHOrAdmin()]

        # كخيار احتياطي (Fallback)
        return [IsAuthenticated()]

class CandidatViewSet(viewsets.ModelViewSet):
    queryset = Candidat.objects.all()
    serializer_class = CandidatSerializer


# recruitment/views.py
import pdfplumber
import google.generativeai as genai
from rest_framework import viewsets, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User, Offre, Candidat, Candidature
from .serializers import OffreSerializer, CandidatureSerializer, UserSerializer
from django.db.models import Avg, Count
from .permissions import IsResponsableRH
from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count, Avg
from .models import Offre, Candidat, Candidature, User
from .serializers import OffreSerializer, CandidatSerializer, CandidatureSerializer
import pdfplumber
import google.generativeai as genai  # pip install google-generativeai

# --- كود التفعيل الجديد (OTP Verification) ---
class VerifyOTPView(APIView):
    def post(self, request):
        email = request.data.get('email')
        otp = request.data.get('otp')
        try:
            # البحث عن المستخدم بالبريد والرمز
            user = User.objects.get(email=email, otp_code=otp)
            user.is_active = True
            user.otp_code = None  # مسح الرمز بعد التفعيل بنجاح
            user.save()
            return Response({"message": "Compte activé avec succès!"}, status=200)
        except User.DoesNotExist:
            return Response({"error": "Code incorrect ou expiré"}, status=400)

# --- كود الإحصائيات (Dashboard) ---
class DashboardDataAPI(APIView):
    def get(self, request):
        data = {
            "total_offres": Offre.objects.count(),
            "total_candidatures": Candidature.objects.count(),
            "avg_score": round(Candidature.objects.aggregate(Avg('score'))['score__avg'] or 0, 2),
            "distribution": {
                "Fortement": Candidature.objects.filter(score__gte=75).count(),
                "Pertinente": Candidature.objects.filter(score__range=(40, 74.99)).count(),
                "Faiblement": Candidature.objects.filter(score__lt=40).count(),
            },
            "offres_analytics": list(Offre.objects.annotate(
                count=Count('candidature'),
                avg=Avg('candidature__score')
            ).values('titre', 'count', 'avg'))
        }
        return Response(data)


from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Offre
from .serializers import OffreSerializer # تأكد من وجود Serializer للعروض

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_info(request):
    # إرجاع بيانات المستخدم ودوره البرمجي
    return Response({
        'id': request.user.id,
        'email': request.user.email,
        'role': request.user.role, # 'Candidat' أو 'AgentRH'
        'username': request.user.username
    })

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def list_offres(request):
    # جلب قائمة العروض للمترشحين
    offres = Offre.objects.all().order_size('-date_publication')
    serializer = OffreSerializer(offres, many=True)
    return Response(serializer.data)

# recruitment/views.py
from rest_framework import generics
from .models import User # أو اسم موديل المستخدم لديك
from .serializers import UserSerializer
from rest_framework.permissions import IsAdminUser

class UserListView(generics.ListAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAdminUser] # للسماح للمسؤولين فقط برؤية القائمة

def patch(self, request, pk):
    instance = self.get_object(pk)
    serializer = CandidatureSerializer(instance, data=request.data, partial=True) # partial=True ضرورية للـ PATCH
    if serializer.is_valid():
        serializer.save() # هنا يتم الحفظ الفعلي في قاعدة البيانات
        return Response(serializer.data)
    return Response(serializer.errors, status=400)

# --- ViewSets لإدارة البيانات عبر API ---
from rest_framework.permissions import IsAuthenticatedOrReadOnly
# أو
from rest_framework.permissions import AllowAny
from .permissions import IsResponsableRHOrAdmin

from rest_framework import viewsets, permissions
from rest_framework.permissions import IsAuthenticated
# تأكد من استيراد صلاحيتك المخصصة
# from .permissions import IsResponsableRHOrAdmin

class OffreViewSet(viewsets.ModelViewSet):
    queryset = Offre.objects.all()
    serializer_class = OffreSerializer

    def get_permissions(self):
        # 1. السماح للجميع (بما فيهم الزوار) برؤية العروض
        if self.action in ['list', 'retrieve']:
            return [permissions.AllowAny()]

        # 2. حصر الإضافة والتعديل والحذف للمسجلين (Authenticated)
        # والذين يملكون رتبة مدير أو وكيل
        # لاحظ إضافة update و partial_update لضمان عمل زر التعديل
        if self.action in ['create', 'update', 'partial_update', 'destroy']:
            return [IsAuthenticated(), IsResponsableRHOrAdmin()]

        # كخيار احتياطي (Fallback)
        return [IsAuthenticated()]

class CandidatViewSet(viewsets.ModelViewSet):
    queryset = Candidat.objects.all()
    serializer_class = CandidatSerializer


# recruitment/views.py
import pdfplumber
import google.generativeai as genai
from rest_framework import viewsets, generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import User, Offre, Candidat, Candidature
from .serializers import OffreSerializer, CandidatureSerializer, UserSerializer
from django.db.models import Avg, Count
from .permissions import IsResponsableRH

# إعداد Gemini
genai.configure(api_key="AIzaSyDP8gavdzDxQUBfGgAzV8zeVeQmTTwRXNI")


# recruitment/views.py

# recruitment/views.py
import joblib, pdfplumber, re, os
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from deep_translator import GoogleTranslator
from django.conf import settings
from rest_framework import viewsets, status
from rest_framework.response import Response
from .models import Candidature
from .serializers import CandidatureSerializer

# تحميل القاعدة من المسار الصحيح
ONET_PATH = os.path.join(settings.BASE_DIR, 'onet_knowledge_base.pkl')
try:
    KB_ONET = joblib.load(ONET_PATH)
except:
    KB_ONET = None


def clean_text(text):
    if not text: return ""
    text = str(text).lower()
    # تنظيف النصوص مع دعم الحروف الفرنسية
    text = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', text)
    return re.sub(r'\s+', ' ', text).strip()


class CandidatureViewSet(viewsets.ModelViewSet):
    queryset = Candidature.objects.all()
    serializer_class = CandidatureSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # 1. حفظ الطلب أولاً للحصول على مسار الملف
        candidature = serializer.save()

        if KB_ONET is None:
            candidature.commentaire_ia = "Erreur: Base O*NET introuvable."
            candidature.save()
            return Response(self.get_serializer(candidature).data, status=201)

        try:
            # 2. استخراج النص من الـ PDF
            cv_raw = ""
            with pdfplumber.open(candidature.cv_file.path) as pdf:
                cv_raw = " ".join([p.extract_text() or "" for p in pdf.pages])

            if cv_raw.strip():
                # 3. الترجمة للإنجليزية (لأن O*NET تعتمد المصطلحات الإنجليزية)
                try:
                    cv_en = GoogleTranslator(source='auto', target='en').translate(cv_raw[:4500])
                    cv_final = clean_text(cv_en)
                except:
                    cv_final = clean_text(cv_raw)

                # 4. منطق البحث المرن عن الوظيفة (حل مشكلة الـ 0% لـ Full Stack)
                original_title = candidature.offre.titre
                # محاولة البحث عن المسمى الكامل
                mask = KB_ONET['Alternate Title'].str.contains(original_title, case=False, na=False)
                job_profile = KB_ONET[mask]

                # إذا فشل، نبحث بالكلمات المفتاحية (مثل Developer أو Software)
                if job_profile.empty:
                    keywords = original_title.replace('-', ' ').split()
                    for word in keywords:
                        if len(word) > 3:  # تجنب الكلمات القصيرة مثل 'de' أو 'and'
                            mask = KB_ONET['Alternate Title'].str.contains(word, case=False, na=False)
                            job_profile = KB_ONET[mask]
                            if not job_profile.empty: break

                if not job_profile.empty:
                    # 5. المقارنة الدلالية
                    target_text = clean_text(" ".join(job_profile['full_profile'].astype(str)))
                    vectorizer = TfidfVectorizer(ngram_range=(1, 2))
                    vectors = vectorizer.fit_transform([cv_final, target_text])
                    raw_score = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]

                    # 6. تحسين النسبة (Scaling) لضمان قيم منطقية
                    if raw_score > 0:
                        # استخدام الجذر التربيعي لرفع النسب الصغيرة (Normalization)
                        final_score = np.sqrt(raw_score) * 100
                        candidature.score = int(min(final_score + 5, 99))  # +5 تحفيزية
                    else:
                        candidature.score = 10  # نسبة دنيا لوجود نص مقروء

                    candidature.commentaire_ia = f"Analyse réussie pour le profil: {original_title}"
                else:
                    candidature.score = 0
                    candidature.commentaire_ia = "Profil métier non identifié dans O*NET"
            else:
                candidature.commentaire_ia = "Échec de lecture du contenu PDF"

            # 7. الحفظ النهائي بعد التحديث
            candidature.save()

        except Exception as e:
            print(f"DEBUG IA ERROR: {e}")
            candidature.commentaire_ia = f"Erreur technique: {str(e)[:50]}"
            candidature.save()

        return Response(self.get_serializer(candidature).data, status=201)


# --- API للمدير العام (DG) ---
class DGAdminListView(generics.ListCreateAPIView):
    """عرض وإضافة المسؤولين (Admins) - للمدير العام فقط"""
    serializer_class = UserSerializer

    def get_queryset(self):
        return User.objects.filter(role='ADMIN')


class FullDashboardStatsAPI(APIView):
    """إحصائيات شاملة للمدير العام"""
    permission_classes = [IsAuthenticated, IsResponsableRH]

    def get(self, request):
        # التأكد أن الطلب من DG أو ADMIN
        if request.user.role not in ['DG', 'ADMIN']:
            return Response({"error": "Unauthorized"}, status=403)

        stats = {
            "total_users": User.objects.count(),
            "total_offres": Offre.objects.count(),
            "total_candidatures": Candidature.objects.count(),
            "global_avg_score": Candidature.objects.aggregate(Avg('score'))['score__avg'],
            "by_status": Candidature.objects.values('statut').annotate(count=Count('id'))
        }
        return Response(stats)


from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .serializers import AgentCreateSerializer


class CreateAgentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # التعديل هنا: السماح للمدير العام (DG) والمسؤول (ADMIN)
        # استخدمنا list للتحقق من وجود الدور داخلها
        allowed_roles = ['ADMIN', 'DG', 'ADMINISTRATEUR']

        if request.user.role.upper() not in allowed_roles:
            return Response(
                {"error": "Vous n'êtes pas autorisé à effectuer cette action."},
                status=status.HTTP_403_FOR_REQUESTED_ACTION
            )

        serializer = AgentCreateSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "Le compte agent a été créé avec succès!"},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer
from .models import User

import random
from django.core.mail import send_mail
from django.core.cache import cache
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        new_email = request.data.get('email')
        otp_received = request.data.get('otp')

        # الحالة 1: المستخدم يريد تغيير البريد ولم يرسل الرمز بعد
        if new_email and new_email != request.user.email and not otp_received:
            otp = str(random.randint(100000, 999999))

            # تخزين الرمز والبريد الجديد في الكاش لمدة 5 دقائق
            cache.set(f'otp_{request.user.id}', otp, timeout=300)
            cache.set(f'pending_email_{request.user.id}', new_email, timeout=300)

            try:
                send_mail(
                    'Verification de votre nouvel email',
                    f'Votre code de vérification est : {otp}',
                    'abdobolvalli145@gmail.com',  # البريد المرسل منه
                    [new_email],
                    fail_silently=False,
                )
                return Response({"detail": "OTP_SENT"}, status=200)
            except Exception as e:
                return Response({"detail": "Error sending email"}, status=500)

        # الحالة 2: المستخدم أرسل الرمز للتحقق
        if otp_received:
            stored_otp = cache.get(f'otp_{request.user.id}')
            pending_email = cache.get(f'pending_email_{request.user.id}')

            if stored_otp and otp_received == stored_otp:
                # تحديث البريد في قاعدة البيانات مباشرة
                request.user.email = pending_email
                request.user.save()

                # مسح الكاش بعد النجاح
                cache.delete(f'otp_{request.user.id}')
                cache.delete(f'pending_email_{request.user.id}')

                # إكمال تحديث بقية البيانات (مثل الصورة) إن وجدت
                serializer = UserSerializer(request.user, data=request.data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response(serializer.data)
            else:
                return Response({"detail": "Code OTP invalide ou expiré"}, status=400)

        # المنطق الحالي: تحديث البيانات الأخرى (مثل الصورة) إذا لم يكن هناك تغيير بريد
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=400)


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import update_session_auth_hash
from rest_framework import status

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get("old_password")
        new_password = request.data.get("new_password")
        confirm_password = request.data.get("confirm_password")

        # 1. التحقق من ملء جميع الحقول
        if not all([old_password, new_password, confirm_password]):
            return Response({"detail": "Veuillez remplir tous les champs."}, status=status.HTTP_400_BAD_REQUEST)

        # 2. التحقق من صحة كلمة المرور القديمة
        if not request.user.check_password(old_password):
            return Response({"detail": "L'ancien mot de passe est incorrect."}, status=status.HTTP_400_BAD_REQUEST)

        # 3. التحقق من تطابق كلمة المرور الجديدة مع التأكيد
        if new_password != confirm_password:
            return Response({"detail": "Les nouveaux mots de passe ne correspondent pas."}, status=status.HTTP_400_BAD_REQUEST)

        # 4. تحديث كلمة المرور
        request.user.set_password(new_password)
        request.user.save()

        # تحديث الجلسة لكي لا يتم تسجيل خروج المستخدم بعد تغيير كلمة المرور
        update_session_auth_hash(request, request.user)

        return Response({"detail": "Mot de passe mis à jour avec succès !"}, status=status.HTTP_200_OK)




# --- API للمدير العام (DG) ---
class DGAdminListView(generics.ListCreateAPIView):
    """عرض وإضافة المسؤولين (Admins) - للمدير العام فقط"""
    serializer_class = UserSerializer

    def get_queryset(self):
        return User.objects.filter(role='ADMIN')


class FullDashboardStatsAPI(APIView):
    """إحصائيات شاملة للمدير العام"""
    permission_classes = [IsAuthenticated, IsResponsableRH]

    def get(self, request):
        # التأكد أن الطلب من DG أو ADMIN
        if request.user.role not in ['DG', 'ADMIN']:
            return Response({"error": "Unauthorized"}, status=403)

        stats = {
            "total_users": User.objects.count(),
            "total_offres": Offre.objects.count(),
            "total_candidatures": Candidature.objects.count(),
            "global_avg_score": Candidature.objects.aggregate(Avg('score'))['score__avg'],
            "by_status": Candidature.objects.values('statut').annotate(count=Count('id'))
        }
        return Response(stats)


from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .serializers import AgentCreateSerializer


class CreateAgentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        # التعديل هنا: السماح للمدير العام (DG) والمسؤول (ADMIN)
        # استخدمنا list للتحقق من وجود الدور داخلها
        allowed_roles = ['ADMIN', 'DG', 'ADMINISTRATEUR']

        if request.user.role.upper() not in allowed_roles:
            return Response(
                {"error": "Vous n'êtes pas autorisé à effectuer cette action."},
                status=status.HTTP_403_FOR_REQUESTED_ACTION
            )

        serializer = AgentCreateSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(
                {"message": "Le compte agent a été créé avec succès!"},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer
from .models import User

import random
from django.core.mail import send_mail
from django.core.cache import cache
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from .serializers import UserSerializer


class UserProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def patch(self, request):
        new_email = request.data.get('email')
        otp_received = request.data.get('otp')

        # الحالة 1: المستخدم يريد تغيير البريد ولم يرسل الرمز بعد
        if new_email and new_email != request.user.email and not otp_received:
            otp = str(random.randint(100000, 999999))

            # تخزين الرمز والبريد الجديد في الكاش لمدة 5 دقائق
            cache.set(f'otp_{request.user.id}', otp, timeout=300)
            cache.set(f'pending_email_{request.user.id}', new_email, timeout=300)

            try:
                send_mail(
                    'Verification de votre nouvel email',
                    f'Votre code de vérification est : {otp}',
                    'abdobolvalli145@gmail.com',  # البريد المرسل منه
                    [new_email],
                    fail_silently=False,
                )
                return Response({"detail": "OTP_SENT"}, status=200)
            except Exception as e:
                return Response({"detail": "Error sending email"}, status=500)

        # الحالة 2: المستخدم أرسل الرمز للتحقق
        if otp_received:
            stored_otp = cache.get(f'otp_{request.user.id}')
            pending_email = cache.get(f'pending_email_{request.user.id}')

            if stored_otp and otp_received == stored_otp:
                # تحديث البريد في قاعدة البيانات مباشرة
                request.user.email = pending_email
                request.user.save()

                # مسح الكاش بعد النجاح
                cache.delete(f'otp_{request.user.id}')
                cache.delete(f'pending_email_{request.user.id}')

                # إكمال تحديث بقية البيانات (مثل الصورة) إن وجدت
                serializer = UserSerializer(request.user, data=request.data, partial=True)
                if serializer.is_valid():
                    serializer.save()
                    return Response(serializer.data)
            else:
                return Response({"detail": "Code OTP invalide ou expiré"}, status=400)

        # المنطق الحالي: تحديث البيانات الأخرى (مثل الصورة) إذا لم يكن هناك تغيير بريد
        serializer = UserSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=400)


from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth import update_session_auth_hash
from rest_framework import status

class ChangePasswordView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        old_password = request.data.get("old_password")
        new_password = request.data.get("new_password")
        confirm_password = request.data.get("confirm_password")

        # 1. التحقق من ملء جميع الحقول
        if not all([old_password, new_password, confirm_password]):
            return Response({"detail": "Veuillez remplir tous les champs."}, status=status.HTTP_400_BAD_REQUEST)

        # 2. التحقق من صحة كلمة المرور القديمة
        if not request.user.check_password(old_password):
            return Response({"detail": "L'ancien mot de passe est incorrect."}, status=status.HTTP_400_BAD_REQUEST)

        # 3. التحقق من تطابق كلمة المرور الجديدة مع التأكيد
        if new_password != confirm_password:
            return Response({"detail": "Les nouveaux mots de passe ne correspondent pas."}, status=status.HTTP_400_BAD_REQUEST)

        # 4. تحديث كلمة المرور
        request.user.set_password(new_password)
        request.user.save()

        # تحديث الجلسة لكي لا يتم تسجيل خروج المستخدم بعد تغيير كلمة المرور
        update_session_auth_hash(request, request.user)

        return Response({"detail": "Mot de passe mis à jour avec succès !"}, status=status.HTTP_200_OK)

# أضف هذا الكلاس لتمكين التحديث (PATCH) للمستخدمين
class UserUpdateView(generics.UpdateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated] # يمكنك تغييرها لـ IsAdminUser لزيادة الأمان