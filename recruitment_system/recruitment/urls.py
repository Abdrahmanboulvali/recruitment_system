from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OffreViewSet, CandidatViewSet, CandidatureViewSet

router = DefaultRouter()
router.register(r'offres', OffreViewSet)
router.register(r'candidats', CandidatViewSet)
router.register(r'candidatures', CandidatureViewSet)

urlpatterns = [
    path('', include(router.urls)),
]