import fitz  # PyMuPDF
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def calculer_score_cv(pdf_path, job_requirements):
    try:
        # 1. Extraction du texte
        text = ""
        with fitz.open(pdf_path) as doc:
            for page in doc:
                text += page.get_text()

        # 2. Vérification si le texte est vide
        if not text.strip():
            return 0.0

        # 3. Calcul de la similarité
        content = [text, job_requirements]
        vectorizer = TfidfVectorizer()
        matrix = vectorizer.fit_transform(content)
        similarity = cosine_similarity(matrix)

        return round(float(similarity[0][1]), 2)
    except Exception as e:
        print(f"Détail erreur utils: {e}")
        return 0.0