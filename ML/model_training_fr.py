import pandas as pd
import joblib
from sklearn.model_selection import train_test_split
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, accuracy_score

# 1. Chargement des données que vous avez analysées
# Nous utilisons le fichier nettoyé après votre analyse approfondie
df = pd.read_csv('data_ready.csv')
df = df.dropna(subset=['resume_clean'])

# 2. Vectorisation (Conversion du texte en nombres)
# Le TF-IDF donne du poids aux mots importants que vous avez vus dans le WordCloud
print("⏳ Transformation des textes en vecteurs numériques...")
tfidf = TfidfVectorizer(max_features=3500, ngram_range=(1, 2))
X = tfidf.fit_transform(df['resume_clean'])
y = df['Category']

# 3. Division du Dataset (Train/Test)
# 80% pour l'apprentissage et 20% pour vérifier l'intelligence du modèle
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# 4. Création du Random Forest
# On utilise 200 arbres pour capturer les relations complexes entre les métiers
print("🚀 Entraînement du Random Forest en cours...")
rf_model = RandomForestClassifier(n_estimators=200, random_state=42, class_weight='balanced')
rf_model.fit(X_train, y_train)

# 5. Évaluation de la performance
y_pred = rf_model.predict(X_test)
precision = accuracy_score(y_test, y_pred)

print(f"\n✅ Précision du modèle : {precision:.2%}")
print("\n--- Rapport de Classification détaillé ---")
print(classification_report(y_test, y_pred))

# 6. Sauvegarde du "Cerveau" du projet
# Ces fichiers seront utilisés dans votre application Django
joblib.dump(rf_model, 'expert_rf_model.pkl')
joblib.dump(tfidf, 'vectorizer_expert.pkl')

print("\n💾 Modèle et Vectoriseur sauvegardés avec succès !")