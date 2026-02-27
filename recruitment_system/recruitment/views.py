from rest_framework import viewsets
from rest_framework.views import APIView
from rest_framework.response import Response
from django.db.models import Count, Avg
from .models import Offre, Candidat, Candidature, User
from .serializers import OffreSerializer, CandidatSerializer, CandidatureSerializer

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


# --- ViewSets لإدارة البيانات عبر API ---
class OffreViewSet(viewsets.ModelViewSet):
    queryset = Offre.objects.all()
    serializer_class = OffreSerializer

class CandidatViewSet(viewsets.ModelViewSet):
    queryset = Candidat.objects.all()
    serializer_class = CandidatSerializer

class CandidatureViewSet(viewsets.ModelViewSet):
    queryset = Candidature.objects.all()
    serializer_class = CandidatureSerializer