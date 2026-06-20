import joblib
import pdfplumber
import re
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from deep_translator import GoogleTranslator

# 1. Chargement de la base de données
try:
    kb = joblib.load('onet_knowledge_base.pkl')
except:
    kb = None
    print("❌ Erreur: Fichier 'onet_knowledge_base.pkl' introuvable.")

# قاموس مطور وأكثر دقة يشمل لغات متعددة لضمان الكشف الصحيح
DOMAIN_CLASSIFIER = {
    'medical': [
        'doctor', 'physician', 'medecin', 'sante', 'health', 'clinical', 'hospital',
        'medical', 'chirurgie', 'patient', 'pharmacie', 'طبيب', 'صحة'
    ],
    'data_tech': [
        'python', 'programming', 'software', 'sql', 'machine learning', 'data science',
        'algorithm', 'developer', 'statistics', 'statistique', 'informatique', 'برمجة', 'بيانات'
    ],
    'finance': [
        'accounting', 'audit', 'finance', 'tax', 'banking', 'econometrics', 'budget',
        'comptable', 'gestion', 'محاسبة', 'مالية'
    ],
    'legal': [
        'lawyer', 'legal', 'jurisprudence', 'court', 'attorney', 'contract', 'droit', 'juridique', 'قانون'
    ]
}


def nettoyer_texte(texte):
    if not texte: return ""
    texte = str(texte).lower()
    texte = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', texte)
    return re.sub(r'\s+', ' ', texte).strip()


def extraire_pdf(chemin):
    try:
        with pdfplumber.open(chemin) as pdf:
            texte = " ".join([p.extract_text() for p in pdf.pages if p.extract_text()])
            return texte
    except Exception as e:
        print(f"❌ Erreur PDF: {e}")
        return ""


def detecter_domaine(texte):
    """دالة مطورة تعطي وزناً أكبر للكلمات المفتاحية الصريحة"""
    scores = {domaine: 0 for domaine in DOMAIN_CLASSIFIER}
    texte_clean = texte.lower()
    for domaine, keywords in DOMAIN_CLASSIFIER.items():
        for word in keywords:
            # نستخدم البحث عن الكلمة كجزء من النص لضمان التقاطها حتى لو كانت مشتقة
            if word in texte_clean:
                scores[domaine] += 2  # زيادة الوزن لضمان دقة التصنيف

    domaine_detecte = max(scores, key=scores.get)
    # رفع عتبة التصنيف: يجب وجود كلمتين على الأقل لاعتماد المجال
    return domaine_detecte if scores[domaine_detecte] >= 2 else "general"


def calculer_matching(cv_path, job_target):
    if kb is None:
        return "❌ Erreur interne", False

    cv_raw = extraire_pdf(cv_path)
    if not cv_raw.strip() or len(cv_raw.strip()) < 150:
        return "ERROR_UNREADABLE", False

    # ترجمة وتحليل الهوية
    try:
        job_target_en = GoogleTranslator(source='auto', target='en').translate(job_target).lower()
        cv_translated = GoogleTranslator(source='auto', target='en').translate(cv_raw[:4500]).lower()
        cv_text = nettoyer_texte(cv_translated)
    except:
        job_target_en, cv_text = job_target.lower(), nettoyer_texte(cv_raw)

    # تحديد الهوية المهنية للطرفين
    cv_identity = detecter_domaine(cv_text)
    job_category = detecter_domaine(job_target_en)

    # التحقق من التضارب (Logic-based separation)
    # إذا كانت الوظيفة محددة (ليست general) والـ CV مختلف عنها، فهذا تضارب صريح
    is_conflict = (cv_identity != job_category and job_category != 'general')

    mask = kb['Alternate Title'].str.contains(job_target_en, case=False, na=False)
    job_profile = kb[mask]

    if job_profile.empty:
        return f"❌ Métier '{job_target}' non trouvé.", False

    target_text = nettoyer_texte(" ".join(job_profile['full_profile'].astype(str)))
    # رفع دقة الـ Vectorizer ليشمل كلمات أطول وأكثر دقة
    vectorizer = TfidfVectorizer(ngram_range=(1, 3), token_pattern=r'\b\w\w\w+\b')

    try:
        vectors = vectorizer.fit_transform([cv_text, target_text])
        raw_score = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]

        if is_conflict:
            # عقوبة قاسية جداً (0.05) لضمان أن التقييم لن يتجاوز العشرينيات في حال التضارب
            raw_score = raw_score * 0.05
            print(f"⚠️ Conflit: CV({cv_identity}) vs Job({job_category})")

        smart_score = np.sqrt(raw_score) if raw_score > 0 else 0.05
        return float(min(smart_score, 1.0)), is_conflict

    except Exception as e:
        print(f"❌ Erreur: {e}")
        return 0.0, False