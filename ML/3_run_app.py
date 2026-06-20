import tkinter as tk
from tkinter import filedialog, messagebox
from semantic_engine import calculer_matching  # Importation du moteur mis à jour

def demarrer_analyse():
    job_name = entry_job.get()
    if not job_name:
        messagebox.showwarning("Attention", "Veuillez entrer un nom de métier !")
        return

    # Ouverture de la fenêtre de sélection de fichier
    file_path = filedialog.askopenfilename(filetypes=[("PDF files", "*.pdf")])

    if file_path:
        # On récupère maintenant deux valeurs : le score et le booléen de conflit
        score, is_conflict = calculer_matching(file_path, job_name)

        # 1. Gestion des erreurs renvoyées par le moteur
        if score == "ERROR_UNREADABLE":
            messagebox.showerror("Analyse Impossible",
                                 "Ce fichier PDF n'est pas textuel (scan/image).\n\n"
                                 "L'IA ne peut pas extraire les données.")
            return

        if isinstance(score, str) and "❌" in score:
            messagebox.showwarning("Métier Inconnu", score)
            return

        # 2. Cas de succès (score est un float)
        if isinstance(score, float):
            resultat_pourcentage = score * 100

            # Détermination de l'appréciation textuelle
            if resultat_pourcentage >= 75:
                appreciation = "Excellent Match (Fortement Pertinent)"
            elif resultat_pourcentage >= 50:
                appreciation = "Bon Match (Pertinent)"
            else:
                appreciation = "Match Faible (Peu de correspondance)"

            # --- DÉTECTION INTELLIGENTE DE CONFLIT ---
            # Au lieu de tester si score < 25, on utilise l'analyse métier du moteur
            if is_conflict:
                messagebox.showwarning("Conflit de Spécialité détecté",
                                       "L'IA a identifié que votre profil (ex: Data/Tech) ne correspond pas "
                                       "au domaine métier cible (ex: Médical).\n\n"
                                       "Le score a été ajusté en conséquence.")

            messagebox.showinfo("Résultat de l'Expertise IA",
                                f"Score de cohérence : {resultat_pourcentage:.2f}%\n\n"
                                f"Évaluation : {appreciation}")
        else:
            messagebox.showerror("Erreur Technique", "Une erreur inattendue est survenue.")

# --- Configuration de l'Interface Graphique ---
root = tk.Tk()
root.title("Système Expert RH - O*NET Framework")
root.geometry("450x320")
root.configure(bg="#f5f5f5")

# En-tête
tk.Label(root, text="Recrutement Intelligent", font=("Helvetica", 16, "bold"), bg="#f5f5f5", fg="#2c3e50").pack(pady=15)

# Saisie du métier
tk.Label(root, text="Métier visé (ex: Data Science, Médical) :", bg="#f5f5f5").pack(pady=5)
entry_job = tk.Entry(root, width=40, font=("Helvetica", 10), justify='center')
entry_job.pack(pady=5)
entry_job.insert(0, "Data Scientist")

# Bouton d'analyse
tk.Button(root, text="📁 Sélectionner CV et Analyser",
          command=demarrer_analyse,
          bg="#2ecc71", fg="white", font=("Helvetica", 11, "bold"),
          padx=20, pady=10, relief="flat", cursor="hand2").pack(pady=25)

# Footer
tk.Label(root, text="Analyse basée sur la classification O*NET", font=("Helvetica", 8, "italic"), bg="#f5f5f5", fg="#7f8c8d").pack(side="bottom", pady=10)

root.mainloop()