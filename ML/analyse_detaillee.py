import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from wordcloud import WordCloud
from collections import Counter

# 1. Chargement des données nettoyées
df = pd.read_csv('data_ready.csv')

# --- A. Analyse de la Distribution ---
print("📊 Analyse de la répartition des métiers...")
plt.figure(figsize=(12, 8))
# Voir quelles catégories sont les plus représentées
sns.countplot(y='Category', data=df, order=df['Category'].value_counts().index, palette='magma')
plt.title('Répartition des catégories professionnelles dans le Dataset')
plt.xlabel('Nombre de CV')
plt.ylabel('Métiers')
plt.show()

# --- B. Analyse de la longueur des textes ---
# Est-ce que certains CV sont trop courts ou trop longs ?
df['longueur_cv'] = df['resume_clean'].apply(lambda x: len(str(x).split()))
print(f"\n📝 Longueur moyenne d'un CV : {df['longueur_cv'].mean():.2f} mots")

plt.figure(figsize=(10, 6))
sns.histplot(df['longueur_cv'], bins=30, kde=True, color='blue')
plt.title('Distribution de la longueur des CV (Nombre de mots)')
plt.show()

# --- C. Analyse des mots-clés par catégorie ---
def extraire_top_mots(categorie, n=10):
    """Fonction pour voir les mots les plus fréquents dans un métier spécifique"""
    texte = " ".join(df[df['Category'] == categorie]['resume_clean'])
    mots = texte.split()
    return Counter(mots).most_common(n)

# Exemple : voir les mots clés pour "Data Science"
print("\n🔍 Top 10 mots pour 'Data Science' :")
print(extraire_top_mots('Data Science'))

# --- D. Nuage de mots (WordCloud) global ---
print("\n☁️ Génération du nuage de mots global...")
tous_les_mots = " ".join(df['resume_clean'])
wordcloud = WordCloud(width=800, height=400, background_color='white', colormap='inferno').generate(tous_les_mots)

plt.figure(figsize=(15, 7))
plt.imshow(wordcloud, interpolation='bilinear')
plt.axis('off')
plt.title('Les compétences les plus présentes dans tout le dataset')
plt.show()