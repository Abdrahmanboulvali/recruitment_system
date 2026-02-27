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
    cv_path = models.FileField(upload_to='cvs/')

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


class Candidature(models.Model):
    candidat = models.ForeignKey(Candidat, on_delete=models.CASCADE)
    offre = models.ForeignKey(Offre, on_delete=models.CASCADE)
    statut = models.CharField(max_length=50, default='En attente')
    score = models.FloatField(default=0.0)
    date_postulation = models.DateTimeField(auto_now_add=True)

    def save(self, *args, **kwargs):
        try:
            import fitz  # PyMuPDF

            if self.candidat.cv_path:
                text_cv = ""
                with fitz.open(self.candidat.cv_path.path) as doc:
                    for page in doc:
                        text_cv += page.get_text().lower()

                text_cv = re.sub(r'\s+', ' ', text_cv)

                raw_skills = self.offre.competences_requises.split(',')
                skills_to_find = [s.strip().lower() for s in raw_skills if s.strip()]

                if skills_to_find:
                    matches = 0
                    for skill in skills_to_find:
                        if skill in text_cv:
                            matches += 1

                    self.score = round((matches / len(skills_to_find)) * 100, 2)
                else:
                    self.score = 0.0
        except Exception as e:
            print(f"ERROR CV Analysis: {e}")
            self.score = 0.0

        super().save(*args, **kwargs)

    @property
    def pertinence_label(self):
        if self.score >= 75:
            return "Fortement Pertinente"
        elif 40 <= self.score < 75:
            return "Pertinente"
        else:
            return "Faiblement Pertinente"

    def __str__(self):
        return f"Candidature de {self.candidat} pour {self.offre}"