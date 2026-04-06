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


class OffreViewSet(viewsets.ModelViewSet):
    queryset = Offre.objects.all()
    serializer_class = OffreSerializer

    # هذا السطر يسمح للجميع بالـ GET (القراءة)
    # ويحصر الـ POST/DELETE (الكتابة) للمسجلين فقط
    permission_classes = [IsAuthenticatedOrReadOnly]

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
from recruitment.permissions import IsResponsableRH

# إعداد Gemini
genai.configure(api_key="AIzaSyBznYS6ltLzOaNnElF3fw16ZmzroH-24JE")


class CandidatureViewSet(viewsets.ModelViewSet):
    queryset = Candidature.objects.all()
    serializer_class = CandidatureSerializer

    def perform_create(self, serializer):
        # 1. حفظ الطلب أولاً
        candidature = serializer.save()

        try:
            # 2. استخراج النص (استخدمنا cv_file كما في الموديل الجديد)
            cv_text = ""
            with pdfplumber.open(candidature.cv_file.path) as pdf:
                for page in pdf.pages:
                    cv_text += page.extract_text() or ""

            # 3. صياغة الـ Prompt للحصول على النتيجة والتعليق
            model = genai.GenerativeModel('gemini-pro')
            prompt = f"""
            Analyze this CV for the position: {candidature.offre.titre}
            Description: {candidature.offre.description}
            CV Content: {cv_text[:3000]}

            Return the result in this exact format:
            Score: [number 0-100]
            Comment: [short summary of why]
            """

            response = model.generate_content(prompt)
            res_text = response.text

            # 4. استخراج البيانات وحفظها
            import re
            score_match = re.search(r'Score:\s*(\d+)', res_text)
            comment_match = re.search(r'Comment:\s*(.*)', res_text, re.DOTALL)

            if score_match:
                candidature.score = int(score_match.group(1))
            if comment_match:
                candidature.commentaire_ia = comment_match.group(1).strip()

            candidature.save()

        except Exception as e:
            print(f"AI Error: {e}")


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

