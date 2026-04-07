from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import OffreViewSet, CandidatViewSet, CandidatureViewSet, DashboardDataAPI
from .views import VerifyOTPView
from . import views
from .views import UserListView
from .views import CreateAgentView
from .views import UserProfileView
from .views import ChangePasswordView

router = DefaultRouter()
router.register(r'offres', OffreViewSet)
router.register(r'candidats', CandidatViewSet)
router.register(r'candidatures', CandidatureViewSet)

urlpatterns = [

    path('users/', UserListView.as_view(), name='user-list'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('stats/', DashboardDataAPI.as_view(), name='api-stats'),
    path('user-info/', views.get_user_info, name='user_info'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('manage-agents/create/', CreateAgentView.as_view(), name='create-agent'),
    path('', include(router.urls)),


]