import joblib
import pdfplumber
import re
import numpy as np  # أضفنا numpy للحسابات المتقدمة
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from deep_translator import GoogleTranslator

# تحميل قاعدة البيانات
try:
    kb = joblib.load('onet_knowledge_base.pkl')
except:
    print("❌ Erreur: Fichier 'onet_knowledge_base.pkl' introuvable.")


def nettoyer_texte(texte):
    if not texte: return ""
    texte = str(texte).lower()
    # تنظيف مع الإبقاء على الحروف اللاتينية والفرنسية والإنجليزية
    texte = re.sub(r'[^a-zA-ZÀ-ÿ\s]', ' ', texte)
    return re.sub(r'\s+', ' ', texte).strip()


def extraire_pdf(chemin):
    try:
        with pdfplumber.open(chemin) as pdf:
            texte = " ".join([p.extract_text() for p in pdf.pages if p.extract_text()])
            return texte
    except:
        return ""


def calculer_matching(cv_path, job_target):
    # 1. استخراج النص الخام
    cv_raw = extraire_pdf(cv_path)

    if not cv_raw.strip():
        return "❌ Impossible de lire le contenu du PDF."

    # --- التعديل الجوهري: الترجمة الآلية لتوحيد اللغة مع O*NET ---
    print(f"🌐 Traduction du CV pour analyse d'expert...")
    try:
        # نترجم أول 4500 حرف لضمان عدم تجاوز حدود المترجم المجاني
        cv_translated = GoogleTranslator(source='auto', target='en').translate(cv_raw[:4500])
        cv_text = nettoyer_texte(cv_translated)
    except Exception as e:
        print(f"⚠️ Note: Traduction échouée ({e}), analyse en langue originale.")
        cv_text = nettoyer_texte(cv_raw)

    # 2. البحث الذكي عن الوظيفة في O*NET
    mask = kb['Alternate Title'].str.contains(job_target, case=False, na=False)
    job_profile = kb[mask]

    if job_profile.empty:
        # محاولة البحث بالكلمة الأولى فقط إذا فشل البحث الكامل
        first_word = job_target.split()[0]
        job_profile = kb[kb['Alternate Title'].str.contains(first_word, case=False, na=False)]

    if job_profile.empty:
        return "❌ Métier non trouvé dans O*NET."

    # تجميع معلومات الوظيفة (Skills + Knowledge + Titles)
    target_text = " ".join(job_profile['full_profile'].astype(str))
    target_text = nettoyer_texte(target_text)

    # 3. الـ Vectorizer المتوازن
    vectorizer = TfidfVectorizer(
        ngram_range=(1, 2),
        token_pattern=r'\b\w\w+\b',
        min_df=1
    )

    try:
        # تحويل النصوص إلى متجهات رقمية
        vectors = vectorizer.fit_transform([cv_text, target_text])
        score = cosine_similarity(vectors[0:1], vectors[1:2])[0][0]

        # --- التعديل الجديد: منحنى التنعيم الذكي ---
        if score > 0:
            # استخدام الجذر التربيعي لرفع القيم المنخفضة بشكل عادل دون تجاوز 100%
            smart_score = np.sqrt(score)

            # بونص بسيط للنتائج ذات التقارب الجيد (فوق 15% أصلي)
            if score > 0.15:
                smart_score += 0.05
        else:
            smart_score = 0

        # حصر النتيجة النهائية لضمان عدم تخطي 1.0 (100%)
        final_score = float(min(smart_score, 1.0))

        return final_score
    except Exception as e:
        print(f"❌ Erreur vectorizer: {e}")
        return 0.0