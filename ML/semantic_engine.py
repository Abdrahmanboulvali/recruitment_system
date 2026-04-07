import joblib
import pdfplumber
import re
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

# Chargement de la base de connaissances
kb = joblib.load('onet_knowledge_base.pkl')


def nettoyer_texte(texte):
    texte = str(texte).lower()
    texte = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', texte)
    return re.sub(r'\s+', ' ', texte).strip()


def extraire_pdf(chemin):
    with pdfplumber.open(chemin) as pdf:
        return " ".join([p.extract_text() for p in pdf.pages if p.extract_text()])


def calculer_matching(cv_path, job_target):
    # 1. Préparation du texte du CV
    cv_text = nettoyer_texte(extraire_pdf(cv_path))

    # 2. Récupération du profil O*NET pour le métier cible
    job_profile = kb[kb['Alternate Title'].str.contains(job_target, case=False, na=False)]

    if job_profile.empty:
        return "❌ Métier non trouvé dans la base O*NET."

    target_text = job_profile['full_profile'].iloc[0]

    # 3. Vectorisation TF-IDF (Analyse des poids des mots)
    vectorizer = TfidfVectorizer(ngram_range=(1, 2))
    vectors = vectorizer.fit_transform([cv_text, target_text])

    # 4. Calcul de la similarité (Le cœur de l'IA)
    score = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]
    return score