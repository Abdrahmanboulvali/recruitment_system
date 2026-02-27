from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OffreViewSet, CandidatViewSet, CandidatureViewSet, DashboardDataAPI
from .views import VerifyOTPView
from . import views

router = DefaultRouter()
router.register(r'offres', OffreViewSet)
router.register(r'candidats', CandidatViewSet)
router.register(r'candidatures', CandidatureViewSet)

urlpatterns = [

    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('stats/', DashboardDataAPI.as_view(), name='api-stats'),
    path('user-info/', views.get_user_info, name='user_info'),
    path('', include(router.urls)),
]