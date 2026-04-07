import tkinter as tk
from tkinter import filedialog, messagebox
from semantic_engine import calculer_matching  # On importe notre moteur


def demarrer_analyse():
    job_name = entry_job.get()
    if not job_name:
        messagebox.showwarning("Attention", "Entrez un nom de métier !")
        return

    file_path = filedialog.askopenfilename(filetypes=[("PDF files", "*.pdf")])
    if file_path:
        score = calculer_matching(file_path, job_name)
        if isinstance(score, float):
            resultat = f"Score de cohérence : {score * 100:.2f}%"
            messagebox.showinfo("Résultat IA", resultat)
        else:
            messagebox.showerror("Erreur", score)


# Configuration simple de la fenêtre
root = tk.Tk()
root.title("Système Expert de Recrutement O*NET")
tk.Label(root, text="Métier visé (ex: Data Science) :").pack(pady=5)
entry_job = tk.Entry(root, width=40)
entry_job.pack(pady=5)
tk.Button(root, text="Choisir CV et Analyser", command=demarrer_analyse).pack(pady=20)
root.mainloop()