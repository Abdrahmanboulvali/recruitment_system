from rest_framework import viewsets
from .models import Offre, Candidat, Candidature
from .serializers import OffreSerializer, CandidatSerializer, CandidatureSerializer

# Logique pour gérer les Offres via API
class OffreViewSet(viewsets.ModelViewSet):
    queryset = Offre.objects.all()
    serializer_class = OffreSerializer

# Logique pour gérer les Candidats via API
class CandidatViewSet(viewsets.ModelViewSet):
    queryset = Candidat.objects.all()
    serializer_class = CandidatSerializer

# Logique pour gérer les Candidatures via API
class CandidatureViewSet(viewsets.ModelViewSet):
    queryset = Candidature.objects.all()
    serializer_class = CandidatureSerializer