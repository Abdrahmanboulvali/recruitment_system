import pandas as pd
import joblib

# Configuration des fichiers O*NET
FILES = {
    'titles': 'Alternate Titles.xlsx',
    'skills': 'Skills.xlsx',
    'knowledge': 'Knowledge.xlsx',
    'activities': 'Work Activities.xlsx',
    'styles': 'Work Styles.xlsx'
}


def build_semantic_library():
    print("⏳ Fusion des données O*NET en cours...")

    # 1. Chargement et regroupement des titres alternatifs
    df_titles = pd.read_excel(FILES['titles'])
    titles_grouped = df_titles.groupby('O*NET-SOC Code')['Alternate Title'].apply(
        lambda x: ' '.join(set(map(str, x)))).reset_index()

    # 2. Chargement des compétences (Skills)
    df_skills = pd.read_excel(FILES['skills'])
    skills_grouped = df_skills.groupby('O*NET-SOC Code')['Element Name'].apply(
        lambda x: ' '.join(set(map(str, x)))).reset_index()

    # 3. Chargement des connaissances (Knowledge)
    df_knowledge = pd.read_excel(FILES['knowledge'])
    knowledge_grouped = df_knowledge.groupby('O*NET-SOC Code')['Element Name'].apply(
        lambda x: ' '.join(set(map(str, x)))).reset_index()

    # 4. Fusion finale (Le Master DataFrame)
    master_df = titles_grouped.merge(skills_grouped, on='O*NET-SOC Code', how='left')
    master_df = master_df.merge(knowledge_grouped, on='O*NET-SOC Code', how='left')

    # Création de la signature textuelle complète
    master_df['full_profile'] = master_df['Alternate Title'] + " " + master_df['Element Name_x'] + " " + master_df[
        'Element Name_y']

    # Sauvegarde de la base de données propre
    joblib.dump(master_df, 'onet_knowledge_base.pkl')
    print("✅ Base de connaissances créée : 'onet_knowledge_base.pkl'")


if __name__ == "__main__":
    build_semantic_library()