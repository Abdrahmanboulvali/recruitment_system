import pandas as pd
import re

# 1. Chargement du dataset brut (CSV de Kaggle)
df = pd.read_csv('Curriculum Vitae.csv')

def nettoyer_texte_prof(text):
    """Fonction pour nettoyer le texte du CV de manière professionnelle"""
    text = str(text).lower()
    # Supprimer les liens et emails
    text = re.sub(r'http\S+\s*', ' ', text)
    text = re.sub(r'\S*@\S*\s?', ' ', text)
    # Garder uniquement les caractères alphabétiques (Français/Anglais)
    text = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', text)
    # Supprimer les espaces multiples
    text = re.sub(r'\s+', ' ', text).strip()
    return text

# 2. Application du nettoyage
print("⏳ Nettoyage des données en cours...")
df['resume_clean'] = df['Resume'].apply(nettoyer_texte_prof)

# 3. Sauvegarder les données prêtes pour l'entraînement
df.to_csv('data_ready.csv', index=False)
print("✅ Fichier 'data_ready.csv' créé avec succès.")