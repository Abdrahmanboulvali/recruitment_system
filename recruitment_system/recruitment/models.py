from django.db import models
from django.contrib.auth.models import AbstractUser

# Modèle User (Extension du modèle de base pour inclure le rôle)
class User(models.Model):
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=255)
    role = models.CharField(max_length=50)

    def __str__(self):
        return self.email

# Modèle Candidat
class Candidat(models.Model):
    # Relation 1..1 avec User (user ForeignKey)
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    nom = models.CharField(max_length=100)
    prenom = models.CharField(max_length=100)
    diplome = models.CharField(max_length=255)
    experience = models.IntegerField()
    cv_path = models.FileField(upload_to='cvs/')

    def __str__(self):
        return f"{self.prenom} {self.nom}"

# Modèle Offre
class Offre(models.Model):
    titre = models.CharField(max_length=255)
    description = models.TextField()
    competences_requises = models.TextField()
    experience_min = models.IntegerField()
    date_publication = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.titre

# Modèle Candidature
class Candidature(models.Model):
    # Relations Foreign Key (0..* dans le diagramme)
    candidat = models.ForeignKey(Candidat, on_delete=models.CASCADE)
    offre = models.ForeignKey(Offre, on_delete=models.CASCADE)
    statut = models.CharField(max_length=50, default='En attente')
    score = models.FloatField(default=0.0)
    date_postulation = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Candidature de {self.candidat} pour {self.offre}"