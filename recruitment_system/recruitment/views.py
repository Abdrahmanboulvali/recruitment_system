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
genai.configure(api_key="***")


# recruitment/views.py

class CandidatureViewSet(viewsets.ModelViewSet):
    queryset = Candidature.objects.all()
    serializer_class = CandidatureSerializer

    def create(self, request, *args, **kwargs):
        # 1. إنشاء الطلب وحفظه أولاً للحصول على ملف الـ CV
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        candidature = serializer.save()

        try:
            # 2. استخراج النص من PDF
            cv_text = ""
            with pdfplumber.open(candidature.cv_file.path) as pdf:
                for page in pdf.pages:
                    cv_text += page.extract_text() or ""
            # أضف هذا السطر في دالة create لتعرف الأسماء المتاحة لك
            for m in genai.list_models():
                if 'generateContent' in m.supported_generation_methods:
                    print(f"Available Model: {m.name}")
            # 3. استدعاء Gemini وانتظار الرد (Synchronous)
            model = genai.GenerativeModel('gemini-2.0-flash')
            prompt = f"""
            Analyze the following CV for a {candidature.offre.titre} position.
            CV Content: {cv_text[:3000]}

            Return the result strictly in this format:
            Score: [number between 0 and 100]
            Comment: [Your brief analysis in French]
            """
            print(prompt)

            response = model.generate_content(prompt)
            res_text = response.text

            # 4. معالجة النص بدقة أكبر
            import re
            score_match = re.search(r'Score:\s*(\d+)', res_text, re.IGNORECASE)
            comment_match = re.search(r'Comment:\s*(.*)', res_text, re.DOTALL | re.IGNORECASE)

            if score_match:
                candidature.score = int(score_match.group(1))
            if comment_match:
                candidature.commentaire_ia = comment_match.group(1).strip()

            # 5. حفظ التحديثات النهائية
            candidature.save()

            # 6. إرجاع البيانات المحدثة بالكامل للـ Frontend
            return Response(self.get_serializer(candidature).data, status=201)

        except Exception as e:
            print(f"AI Error: {e}")
            # في حال الفشل، نرجع الطلب كما هو لكي لا يتوقف البرنامج
            return Response(serializer.data, status=201)


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

