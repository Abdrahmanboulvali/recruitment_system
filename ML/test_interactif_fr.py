import joblib
import pdfplumber
import re
import tkinter as tk
from tkinter import filedialog
import os

# 1. Chargement du modèle et du vectoriseur (Le cerveau de l'IA)
print("⏳ Chargement de l'intelligence artificielle...")
model = joblib.load('expert_rf_model.pkl')
tfidf = joblib.load('vectorizer_expert.pkl')


def nettoyer_texte_fr(texte):
    """Nettoyage du texte pour correspondre au format d'entraînement"""
    texte = str(texte).lower()
    texte = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', texte)
    return re.sub(r'\s+', ' ', texte).strip()


def extraire_pdf(chemin):
    """Extraction du contenu textuel du fichier PDF"""
    with pdfplumber.open(chemin) as pdf:
        return " ".join([p.extract_text() for p in pdf.pages if p.extract_text()])


def choisir_fichier():
    """Affiche une fenêtre système pour sélectionner le CV"""
    root = tk.Tk()
    root.withdraw()  # Cacher la fenêtre principale de Tkinter
    root.attributes("-topmost", True)  # Mettre la fenêtre au premier plan

    print("📂 Veuillez sélectionner votre fichier CV (PDF) dans la fenêtre qui vient de s'ouvrir...")
    chemin_fichier = filedialog.askopenfilename(
        title="Sélectionnez votre CV",
        filetypes=[("Fichiers PDF", "*.pdf")]
    )
    root.destroy()
    return chemin_fichier


# --- DÉBUT DU SYSTÈME ---
print("\n" + " SYSTEME DE MATCHING INTERACTIF ".center(50, "="))

# أ. طلب المسمى الوظيفي
poste_cible = input("\n🎯 Entrez le nom du poste cible (ex: Data Science) : ")

# ب. فتح نافذة اختيار الملف
chemin_cv = choisir_fichier()

if chemin_cv:
    print(f"✅ Fichier sélectionné : {os.path.basename(chemin_cv)}")

    try:
        # ج. معالجة السيرة الذاتية
        raw_text = extraire_pdf(chemin_cv)
        clean_text = nettoyer_texte_fr(raw_text)

        # د. التحويل والتحليل
        vecteur = tfidf.transform([clean_text])
        probabilites = model.predict_proba(vecteur)[0]
        classes = model.classes_
        scores = dict(zip(classes, probabilites))

        # هـ. النتائج
        profil_detecte = model.predict(vecteur)[0]
        score_final = scores.get(poste_cible, 0.0)

        # --- AFFICHAGE DU RAPPORT FINAL ---
        print("\n" + " RAPPORT D'ANALYSE ".center(40, "-"))
        print(f"👤 Profil dominant détecté : {profil_detecte}")
        print(f"📊 Score de cohérence pour '{poste_cible}' : {score_final * 100:.2f}%")

        if score_final > 0.75:
            print("\n✅ Résultat : Recommandé pour ce poste.")
        elif score_final > 0.40:
            print("\n⚠️ Résultat : Cohérence moyenne.")
        else:
            print("\n❌ Résultat : Non recommandé.")
        print("-" * 40)

    except Exception as e:
        print(f"❌ Erreur lors de la lecture du fichier : {e}")
else:
    print("⚠️ Aucun fichier n'a été sélectionné.")