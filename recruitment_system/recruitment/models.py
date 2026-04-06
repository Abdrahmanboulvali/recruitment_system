# recruitment/models.py
import random
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    email = models.EmailField(unique=True)
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    is_active = models.BooleanField(default=False) 

    # Les roles
    DG = 'DG'          # Directeur Général
    ADMIN = 'ADMIN'    # Responsable RH
    CANDIDAT = 'CANDIDAT'

    ROLE_CHOICES = [
        (DG, 'Directeur Général'),
        (ADMIN, 'Responsable RH'),
        (CANDIDAT, 'Candidat'),
    ]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default=CANDIDAT)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    def generate_otp(self):
        self.otp_code = str(random.randint(100000, 999999))
        self.save()
        return self.otp_code

class Offre(models.Model):
    titre = models.CharField(max_length=255)
    description = models.TextField()
    competences_requises = models.TextField()
    experience_min = models.IntegerField()
    date_publication = models.DateTimeField(auto_now_add=True)

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
    score = models.FloatField(default=0.0) # سيتم تحديثه بواسطة Gemini
    date_postulation = models.DateTimeField(auto_now_add=True)

    # حقل إضافي لتخزين تحليل الذكاء الاصطناعي (كما في مخطط الأصناف)
    commentaire_ia = models.TextField(null=True, blank=True)

class AgentRH(models.Model):
    # علاقة OneToOne مع المستخدم
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='agent_profile')
    departement = models.CharField(max_length=100)

    def __str__(self):
        return f"Agent: {self.user.email} - {self.departement}"