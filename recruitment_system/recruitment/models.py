import os
import random  # ضروري لتوليد الرمز
import re
from django.db import models
from django.contrib.auth.models import AbstractUser


# recruitment/models.py

class User(AbstractUser):
    email = models.EmailField(unique=True)

    # --- إضافات نظام الـ OTP ---
    otp_code = models.CharField(max_length=6, blank=True, null=True)
    is_active = models.BooleanField(default=False)  # الحساب يبدأ غير نشط حتى التفعيل
    # --------------------------

    ADMIN = 'ADMIN'
    AGENT = 'AGENT'
    CANDIDAT = 'CANDIDAT'

    ROLE_CHOICES = [
        (ADMIN, 'Administrateur'),
        (AGENT, 'Agent RH'),
        (CANDIDAT, 'Candidat'),
    ]
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default=CANDIDAT)

    # حقول المجموعات والصلاحيات (لحظر التعارض مع auth.User)
    groups = models.ManyToManyField(
        'auth.Group',
        related_name='recruitment_user_groups',
        blank=True
    )
    user_permissions = models.ManyToManyField(
        'auth.Permission',
        related_name='recruitment_user_permissions',
        blank=True
    )

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    # دالة توليد الرمز وحفظه
    def generate_otp(self):
        self.otp_code = str(random.randint(100000, 999999))
        self.save()
        return self.otp_code

    def __str__(self):
        return f"{self.email} ({self.role})"


class Candidat(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    diplome = models.CharField(max_length=255)
    experience = models.IntegerField()
    cv_file = models.FileField(upload_to='cvs/')

    def __str__(self):
        return f"{self.prenom} {self.nom}"


class Offre(models.Model):
    titre = models.CharField(max_length=255)
    description = models.TextField()
    competences_requises = models.TextField()
    experience_min = models.IntegerField()
    date_publication = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titre


# recruitment/models.py
import re
import fitz  # PyMuPDF
from django.db import models


class Candidature(models.Model):
    STATUS_CHOICES = [
        ('En attente', 'En attente'),
        ('Accepté', 'Accepté'),
        ('Refusé', 'Refusé'),
    ]

    candidat = models.ForeignKey('Candidat', on_delete=models.CASCADE)
    offre = models.ForeignKey('Offre', on_delete=models.CASCADE)
    # أضفنا null=True لتجاوز الخطأ الظاهر في Terminal
    cv_file = models.FileField(upload_to='cv_submissions/', null=True, blank=True)
    statut = models.CharField(max_length=50, choices=STATUS_CHOICES, default='En attente')
    score = models.FloatField(default=0.0)
    date_postulation = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        # منطق تحليل الـ CV باستخدام PyMuPDF
        if self.cv_file and not self.pk:
            try:
                text_cv = ""
                with fitz.open(stream=self.cv_file.read(), filetype="pdf") as doc:
                    for page in doc:
                        text_cv += page.get_text().lower()

                text_cv = re.sub(r'\s+', ' ', text_cv)
                skills_required = [s.strip().lower() for s in self.offre.competences_requises.split(',') if s.strip()]

                if skills_required:
                    matches = sum(1 for skill in skills_required if skill in text_cv)
                    self.score = round((matches / len(skills_required)) * 100, 2)
            except Exception as e:
                print(f"Analysis Error: {e}")

        super().save(*args, **kwargs)

    @property
    def pertinence(self):
        """هذا ما سيراه المدير في الـ Dashboard"""
        if self.score >= 75: return "Fortement Pertinente"
        if self.score >= 40: return "Pertinente"
        return "Faiblement Pertinente"

    def __str__(self):
        return f"{self.candidat} - {self.offre}"