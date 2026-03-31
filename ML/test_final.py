import joblib
import pdfplumber
import re
import numpy as np

# 1. Chargement du "Cerveau" (النموذج والمحول)
model = joblib.load('expert_rf_model.pkl')
tfidf = joblib.load('vectorizer_expert.pkl')


def extraire_et_nettoyer(chemin_pdf):
    with pdfplumber.open(chemin_pdf) as pdf:
        texte = " ".join([p.extract_text() for p in pdf.pages if p.extract_text()])
    # Nettoyage identique à celui de l'entraînement
    texte = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', texte.lower())
    return re.sub(r'\s+', ' ', texte).strip()


# --- DÉBUT DU TEST ---
print("\n" + "🚀 Système de Matching Intelligent Ready !".center(50, "="))

# أ. الوظيفة المستهدفة
poste_vise = input("\n🎯 Entrez le poste cible (ex: Data Science, Python Developer) : ")

# ب. الملف الخاص بك
pdf_nom = "CV(23605).pdf"  # الملف الفرنسي الخاص بك
print(f"⏳ Analyse de votre CV : {pdf_nom}...")

try:
    resume_nettoye = extraire_et_nettoyer(pdf_nom)

    # ج. تحويل السيرة الذاتية إلى أرقام
    vecteur = tfidf.transform([resume_nettoye])

    # د. حساب الاحتمالات (هنا تظهر العلاقات بين التخصصات)
    probabilites = model.predict_proba(vecteur)[0]
    classes = model.classes_
    scores = dict(zip(classes, probabilites))

    # هـ. النتيجة النهائية
    profil_detecte = model.predict(vecteur)[0]
    score_match = scores.get(poste_vise, 0.0)

    # --- AFFICHAGE DU RAPPORT ---
    print("\n" + " RESULTAT DE L'ANALYSE ".center(40, "-"))
    print(f"✅ Profil majoritaire détecté : {profil_detecte}")
    print(f"📊 Score de correspondance pour '{poste_vise}' : {score_match * 100:.2f}%")

    if score_match > 0.8:
        print("\n🌟 Statut : Excellent candidat pour ce poste !")
    elif score_match > 0.4:
        print("\n⚖️ Statut : Profil intéressant, mais nécessite des compétences spécifiques.")
    else:
        print("\n❌ Statut : Faible correspondance avec ce titre de poste.")
    print("-" * 40)

except Exception as e:
    print(f"❌ Erreur lors de l'analyse : {e}")