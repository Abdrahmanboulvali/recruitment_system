# recruitment/models.py
import random
from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


# --- 1. نظام الاشتراكات والدفع (يجب تعريفه أولاً ليتم استخدامه في Enterprise) ---

class SubscriptionPlan(models.Model):
    """ الباقات التي يحددها المدير العام """
    title = models.CharField(max_length=100)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    offres_count = models.IntegerField(default=5)  # عدد الوظائف المسموح بها
    duration_months = models.IntegerField(default=1)
    description = models.TextField(blank=True, null=True)

    def __str__(self):
        return self.title


class PaymentMethod(models.Model):
    """ الحسابات البنكية للاستلام يحددها المدير العام """
    provider_name = models.CharField(max_length=100)  # الاسم الظاهر (مثلاً: بنكيلي - إدارة النظام)

    # هذا الحقل مهم للمبرمج: المدير يكتب فيه 'bankily' أو 'masrvi'
    # لكي يعرف تطبيق الموبايل أي رابط (URI Scheme) يفتح
    technical_name = models.SlugField(max_length=50, help_text="Exemple: bankily ou masrvi (Aucun espace)")

    account_number = models.CharField(max_length=50)  # الرقم المستلم
    account_holder = models.CharField(max_length=150, blank=True, null=True)
    is_active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.provider_name} - {self.account_number}"


# --- 2. موديل الشركة والمؤسسة (Enterprise) ---

class Enterprise(models.Model):
    TYPE_CHOICES = [
        ('PRIVATE', 'Entreprise Privée'),
        ('GOVERNMENT', 'Institution Gouvernementale'),
        ('ENTREPRENEUR', 'Homme d\'affaires / Freelance'),
    ]

    nom = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    logo = models.ImageField(upload_to='company_logos/', null=True, blank=True)
    type_entite = models.CharField(max_length=20, choices=TYPE_CHOICES, default='PRIVATE')

    # ربط الباقة الحالية بالمؤسسة
    current_plan = models.ForeignKey(SubscriptionPlan, on_delete=models.SET_NULL, null=True, blank=True)

    verification_document = models.FileField(upload_to='verification_docs/', null=True, blank=True)
    is_approved = models.BooleanField(default=False)
    date_creation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.nom} ({self.get_type_entite_display()})"


# --- 3. موديل المستخدم والأدوار ---

class User(AbstractUser):
    email = models.EmailField(unique=True)
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    is_active = models.BooleanField(default=False)
    is_verified_otp = models.BooleanField(default=False)

    SUPER_ADMIN = 'SUPER_ADMIN'
    DG_COMPANY = 'DG'
    DG_GOV = 'DG_GOV'
    DG_BUSINESS = 'DG_BUSINESS'
    ADMIN = 'ADMIN'
    CANDIDAT = 'CANDIDAT'

    ROLE_CHOICES = [
        (SUPER_ADMIN, 'Super Admin Système'),
        (DG_COMPANY, 'Propriétaire d\'Entreprise'),
        (DG_GOV, 'Directeur Institution Publique'),
        (DG_BUSINESS, 'Homme d\'affaires'),
        (ADMIN, 'Responsable RH / Agent'),
        (CANDIDAT, 'Candidat'),
    ]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default=CANDIDAT)

    enterprise = models.ForeignKey(Enterprise, on_delete=models.CASCADE, null=True, blank=True,
                                   related_name='employees')
    photo = models.ImageField(upload_to='profiles/', null=True, blank=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def generate_otp(self):
        self.otp_code = str(random.randint(100000, 999999))
        self.save()
        return self.otp_code


# --- 4. العروض والترشيحات ---

class Offre(models.Model):
    enterprise = models.ForeignKey(Enterprise, on_delete=models.CASCADE, related_name='offres', null=True)
    titre = models.CharField(max_length=255)
    description = models.TextField()
    competences_requises = models.TextField()
    experience_min = models.IntegerField()
    date_publication = models.DateTimeField(auto_now_add=True)
    date_expiration = models.DateTimeField(null=True, blank=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    subscription = models.ForeignKey(
        'SubscriptionRequest',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='offres'
    )
    @property
    def is_active(self):
        if self.date_expiration:
            return timezone.now() < self.date_expiration
        return True

    def __str__(self):
        return self.titre


class Candidat(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    diplome = models.CharField(max_length=255)
    experience = models.IntegerField()
    cv_file = models.FileField(upload_to='cvs/')


class Candidature(models.Model):
    STATUS_CHOICES = [
        ('En attente', 'En attente'),
        ('Accepté', 'Accepté'),
        ('Refusé', 'Refusé'),
    ]
    candidat = models.ForeignKey(Candidat, on_delete=models.CASCADE)
    offre = models.ForeignKey(Offre, on_delete=models.CASCADE)
    cv_file = models.FileField(upload_to='cv_submissions/', null=True)
    statut = models.CharField(max_length=50, choices=STATUS_CHOICES, default='En attente')
    score = models.FloatField(default=0.0)
    date_postulation = models.DateTimeField(auto_now_add=True)
    commentaire_ia = models.TextField(null=True, blank=True)


class AgentRH(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='agent_profile')
    departement = models.CharField(max_length=100)


# --- 5. طلبات الاشتراك والتحقق المالي ---

import uuid


class SubscriptionRequest(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'En attente de validation'),
        ('ACTIVE', 'Activé'),
        ('EXPIRED', 'Expiré'),
        ('REJECTED', 'Refusé'),
    ]
    enterprise = models.ForeignKey(Enterprise, on_delete=models.CASCADE, related_name='subscription_requests')
    plan = models.ForeignKey(SubscriptionPlan, on_delete=models.SET_NULL, null=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')

    # المرجع الفريد للأتمتة (يظهر للمستخدم ليضعه في ملاحظات الدفع)
    transaction_ref = models.CharField(max_length=50, unique=True, editable=False, null=True)

    # ربط الطلب بالوسيلة التي اختارها المدير
    payment_method = models.ForeignKey(PaymentMethod, on_delete=models.SET_NULL, null=True, blank=True)

    payment_receipt = models.ImageField(upload_to='receipts/', null=True, blank=True)
    date_subscription = models.DateTimeField(auto_now_add=True)
    expiry_date = models.DateTimeField(null=True, blank=True)

    date_expiration = models.DateTimeField(null=True, blank=True)
    def save(self, *args, **kwargs):
        if not self.transaction_ref:
            # توليد كود قصير وسهل القراءة للمستخدم الموريتاني
            self.transaction_ref = f"REC-{uuid.uuid4().hex[:6].upper()}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.enterprise.nom} - {self.transaction_ref}"