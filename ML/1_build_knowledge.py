import pandas as pd
import joblib
import os

# Configuration des fichiers sources O*NET
FILES = {
    'titles': 'Alternate Titles.xlsx',
    'skills': 'Skills.xlsx',
    'knowledge': 'Knowledge.xlsx',
    'activities': 'Work Activities.xlsx',
    'styles': 'Work Styles.xlsx'
}


def build_semantic_library():
    print("--- [DÉMARRAGE] Construction de la base de connaissances sémantique ---")

    try:
        # 1. Chargement des Titres (Poids doublé pour maximiser la pertinence)
        print("⏳ Fusion des titres alternatifs...")
        df_titles = pd.read_excel(FILES['titles'])
        titles_grouped = df_titles.groupby('O*NET-SOC Code')['Alternate Title'].apply(
            lambda x: ' '.join(set(map(str, x))) * 2).reset_index()

        # 2. Chargement des Compétences (Skills)
        print("⏳ Intégration des compétences techniques...")
        df_skills = pd.read_excel(FILES['skills'])
        skills_grouped = df_skills.groupby('O*NET-SOC Code')['Element Name'].apply(
            lambda x: ' '.join(set(map(str, x)))).reset_index()

        # 3. Chargement des Connaissances (Knowledge)
        print("⏳ Analyse des domaines de connaissances...")
        df_knowledge = pd.read_excel(FILES['knowledge'])
        knowledge_grouped = df_knowledge.groupby('O*NET-SOC Code')['Element Name'].apply(
            lambda x: ' '.join(set(map(str, x)))).reset_index()

        # 4. Chargement des Activités (Work Activities)
        print("⏳ Mapping des activités professionnelles...")
        df_activities = pd.read_excel(FILES['activities'])
        activities_grouped = df_activities.groupby('O*NET-SOC Code')['Element Name'].apply(
            lambda x: ' '.join(set(map(str, x)))).reset_index()

        # 5. Fusion de toutes les dimensions (Master Merge)
        print("💡 Création de l'empreinte sémantique globale...")
        master_df = titles_grouped.merge(skills_grouped, on='O*NET-SOC Code', how='left')
        master_df = master_df.merge(knowledge_grouped, on='O*NET-SOC Code', how='left',
                                    suffixes=('_skills', '_knowledge'))
        master_df = master_df.merge(activities_grouped, on='O*NET-SOC Code', how='left')

        # Construction du profil complet pour le matching TF-IDF
        master_df['full_profile'] = (
                master_df['Alternate Title'].fillna('') + " " +
                master_df['Element Name_skills'].fillna('') + " " +
                master_df['Element Name_knowledge'].fillna('') + " " +
                master_df['Element Name'].fillna('')
        ).str.lower()

        # Optimisation : Garder uniquement les colonnes nécessaires pour le serveur Django
        final_kb = master_df[['O*NET-SOC Code', 'Alternate Title', 'full_profile']]

        # Sauvegarde au format binaire
        joblib.dump(final_kb, 'onet_knowledge_base.pkl')

        size_mb = os.path.getsize('onet_knowledge_base.pkl') / (1024 * 1024)
        print(f"✅ [SUCCÈS] Base de données créée : 'onet_knowledge_base.pkl'")
        print(f"📊 Statistiques : {len(final_kb)} métiers indexés | Taille : {size_mb:.2f} MB")

    except FileNotFoundError as e:
        print(f"❌ [ERREUR] Fichier manquant : {e.filename}")
    except Exception as e:
        print(f"❌ [ERREUR] Une erreur inattendue est survenue : {e}")


if __name__ == "__main__":
    build_semantic_library()