from django.urls import path, include
from rest_framework.routers import DefaultRouter

# استيراد كافة الـ Views من ملفك
from .views import (
    # ViewSets
    OffreViewSet, CandidatViewSet, CandidatureViewSet, EnterpriseViewSet,
    SubscriptionPlanViewSet, PaymentMethodViewSet, SubscriptionRequestViewSet,
    # Auth & Profile
    RegisterView, VerifyOTPView, ResendOTPView, ForgotPasswordView, ResetPasswordView,
    get_user_info, UserProfileView, ChangePasswordView,
    # Admin & Users
    UserListView, UserUpdateView, toggle_user_status,
    CreateAgentView, DeactivateEnterpriseView, DashboardDataAPI,
    AdminSubscriptionListView, VerifySubscriptionView, MySubscriptionView
)

# 1. إعداد الـ Router
router = DefaultRouter()
router.register(r'offres', OffreViewSet, basename='offre')
router.register(r'candidats', CandidatViewSet, basename='candidat')
router.register(r'candidatures', CandidatureViewSet, basename='candidature')
router.register(r'enterprises', EnterpriseViewSet, basename='enterprise')
router.register(r'subscription-plans', SubscriptionPlanViewSet, basename='subscription-plans')
router.register(r'payment-methods', PaymentMethodViewSet, basename='payment-methods')
router.register(r'subscriptions', SubscriptionRequestViewSet, basename='subscriptions')

# 2. ترتيب المسارات (هام جداً: المسارات المحددة تأتي قبل الـ Router)
urlpatterns = [
    # --- إدارة المستخدمين والكيانات (حل مشكلة 404 و 500 في الصور) ---
    path('users/', UserListView.as_view(), name='user-list'),
    path('users/<int:pk>/', UserUpdateView.as_view(), name='user-update'),
    path('users/<int:user_id>/activate/', toggle_user_status, name='activate-user'),
    path('users/<int:user_id>/deactivate/', toggle_user_status, name='deactivate-user'),

    # --- الإحصائيات والمعلومات العامة ---
    path('stats/', DashboardDataAPI.as_view(), name='api-stats'),
    path('user-info/', get_user_info, name='user-info'),
    path('profile/', UserProfileView.as_view(), name='user-profile-api'),

    # --- نظام المصادقة ---
    path('register/', RegisterView.as_view(), name='register'),
    path('verify-otp/', VerifyOTPView.as_view(), name='verify-otp'),
    path('resend-otp/', ResendOTPView.as_view(), name='resend-otp'),
    path('change-password/', ChangePasswordView.as_view(), name='change-password'),
    path('forgot-password/', ForgotPasswordView.as_view(), name='forgot-password'),
    path('reset-password/', ResetPasswordView.as_view(), name='reset-password'),

    # --- إدارة الوكلاء والاشتراكات ---
    path('manage-agents/create/', CreateAgentView.as_view(), name='create-agent'),
    path('admin/subscriptions/pending/', AdminSubscriptionListView.as_view(), name='admin-subscriptions-list'),
    path('admin/subscriptions/verify/<int:pk>/', VerifySubscriptionView.as_view(), name='verify-subscription'),
    path('my-subscription/', MySubscriptionView.as_view(), name='my-subscription'),
    # --- دمج مسارات الـ ViewSets التلقائية ---
    path('', include(router.urls)),
]