import os
from django.db import models


class User(models.Model):
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    role = models.CharField(max_length=50)

    def __str__(self):
        return self.email


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
            import fitz
            import re

            if self.candidat.cv_path:
                text_cv = ""
                with fitz.open(self.candidat.cv_path.path) as doc:
                    for page in doc:
                        # استخراج النص وتحويله لحروف صغيرة لضمان المطابقة
                        text_cv += page.get_text().lower()

                # تنظيف النص (يدعم العربية والإنجليزية) لتوحيد المسافات
                text_cv = re.sub(r'\s+', ' ', text_cv)

                # تحويل المتطلبات إلى قائمة (تأكد من الفصل بينها بفاصلة في الـ Admin)
                # مثال: Python, Power BI, SQL, الإحصاء
                raw_skills = self.offre.competences_requises.split(',')
                skills_to_find = [s.strip().lower() for s in raw_skills if s.strip()]

                if skills_to_find:
                    matches = 0
                    for skill in skills_to_find:
                        # البحث المباشر عن الكلمة (فعال جداً للعربية والإنجليزية)
                        if skill in text_cv:
                            matches += 1

                    # السكور = (المهارات الموجودة / المهارات المطلوبة) * 100
                    self.score = round((matches / len(skills_to_find)) * 100, 2)
                    print(f"DEBUG: Found {matches} out of {len(skills_to_find)} skills.")
                else:
                    self.score = 0.0
        except Exception as e:
            print(f"ERROR CV Analysis: {e}")
            self.score = 0.0

        super().save(*args, **kwargs)

    def __str__(self):
        return f"Candidature de {self.candidat} pour {self.offre}"