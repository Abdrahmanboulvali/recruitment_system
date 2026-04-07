import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageOffres = () => {
    const [offres, setOffres] = useState([]);
    const [showForm, setShowForm] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [currentId, setCurrentId] = useState(null);

    const [newOffre, setNewOffre] = useState({
        titre: '',
        description: '',
        experience_min: 0,
        competences_requises: ''
    });

    const token = localStorage.getItem('access');

    useEffect(() => {
        fetchOffres();
    }, []);

    const fetchOffres = async () => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/offres/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setOffres(res.data);
        } catch (err) {
            console.error("Erreur chargement offres");
        }
    };

    const handleEditClick = (offre) => {
        setNewOffre({
            titre: offre.titre,
            description: offre.description,
            experience_min: offre.experience_min,
            competences_requises: offre.competences_requises || ''
        });
        setCurrentId(offre.id);
        setIsEditing(true);
        setShowForm(true);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const currentToken = localStorage.getItem('access');
        const config = { headers: { Authorization: `Bearer ${currentToken}` } };

        try {
            const dataToSend = {
                ...newOffre,
                experience_min: parseInt(newOffre.experience_min) || 0
            };

            if (isEditing) {
                await axios.put(`http://127.0.0.1:8000/api/offres/${currentId}/`, dataToSend, config);
                alert("Offre modifiée avec succès !");
            } else {
                await axios.post('http://127.0.0.1:8000/api/offres/', dataToSend, config);
                alert("Offre publiée avec succès !");
            }

            resetForm();
            fetchOffres();
        } catch (err) {
            console.error("Erreur API:", err.response);
            const errorMsg = err.response?.data ? JSON.stringify(err.response.data) : "Erreur lors de l'opération";
            alert(errorMsg);
        }
    };

    const resetForm = () => {
        setNewOffre({ titre: '', description: '', experience_min: 0, competences_requises: '' });
        setShowForm(false);
        setIsEditing(false);
        setCurrentId(null);
    };

    const handleDelete = async (id) => {
        if (window.confirm("Voulez-vous supprimer cette offre ?")) {
            try {
                await axios.delete(`http://127.0.0.1:8000/api/offres/${id}/`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                fetchOffres();
            } catch (err) {
                alert("Erreur lors de la suppression");
            }
        }
    };

    return (
        <div style={styles.pageWrapper}>
            <div style={styles.topBar}>
                <div style={styles.titleSection}>
                    <h2 style={styles.mainTitle}>Gestion des Offres</h2>
                    <p style={styles.subTitle}>Contrôlez et mettez à jour vos publications</p>
                </div>
                <button
                    onClick={() => isEditing ? resetForm() : setShowForm(!showForm)}
                    style={styles.toggleBtn(showForm)}
                >
                    {showForm ? "✕ Annuler" : "+ Nouvelle Offre"}
                </button>
            </div>

            {showForm && (
                <div style={styles.glassForm}>
                    <h3 style={{...styles.formTitle, color: 'var(--text-main)'}}>
                        <span>{isEditing ? "📝 Modifier l'offre" : "📌 Nouvelle offre"}</span>
                    </h3>
                    <form onSubmit={handleSubmit}>
                        <div style={styles.inputGrid}>
                            <div style={styles.fieldContainer}>
                                <label style={styles.label}>💼 Titre du poste</label>
                                <input
                                    style={styles.glassInput}
                                    required
                                    value={newOffre.titre}
                                    onChange={e => setNewOffre({...newOffre, titre: e.target.value})}
                                />
                            </div>
                            <div style={{...styles.fieldContainer, flex: '0 1 200px'}}>
                                <label style={styles.label}>⏳ Expérience min</label>
                                <input
                                    type="number"
                                    style={styles.glassInput}
                                    value={newOffre.experience_min}
                                    onChange={e => setNewOffre({...newOffre, experience_min: e.target.value})}
                                />
                            </div>
                        </div>

                        <div style={{marginTop: '20px'}}>
                            <label style={styles.label}>🛠️ Compétences (séparées par des virgules)</label>
                            <input
                                style={styles.glassInput}
                                value={newOffre.competences_requises}
                                onChange={e => setNewOffre({...newOffre, competences_requises: e.target.value})}
                            />
                        </div>

                        <div style={{marginTop: '20px'}}>
                            <label style={styles.label}>📝 Description complète</label>
                            <textarea
                                style={styles.glassTextarea}
                                required
                                value={newOffre.description}
                                onChange={e => setNewOffre({...newOffre, description: e.target.value})}
                            />
                        </div>

                        <button type="submit" style={styles.submitBtn}>
                            {isEditing ? "💾 Enregistrer les modifications" : "🚀 Publier l'offre"}
                        </button>
                    </form>
                </div>
            )}

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Détails du Poste</th>
                            <th style={styles.th}>Compétences</th>
                            <th style={styles.th}>Expérience</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {offres.map(o => (
                            <tr key={o.id} style={styles.tr}>
                                <td style={styles.td}>
                                    <div style={{fontWeight: '700', color: 'var(--text-main)'}}>{o.titre}</div>
                                    <div style={{fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px'}}>
                                        {o.description.substring(0, 50)}...
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <div style={styles.skillsContainer}>
                                        {o.competences_requises?.split(',').map((s, i) => (
                                            <span key={i} style={styles.skillTag}>{s.trim()}</span>
                                        ))}
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <span style={styles.expBadge}>{o.experience_min} ans</span>
                                </td>
                                <td style={{...styles.td, textAlign: 'center'}}>
                                    <div style={styles.actionGroup}>
                                        <button onClick={() => handleEditClick(o)} style={styles.editBtn}>✏️</button>
                                        <button onClick={() => handleDelete(o.id)} style={styles.deleteBtn}>🗑️</button>
                                    </div>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const styles = {
    pageWrapper: { padding: '40px 20px', maxWidth: '1200px', margin: '0 auto', color: 'var(--text-main)' },
    topBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' },
    mainTitle: { fontSize: '28px', fontWeight: 'bold', color: 'var(--text-main)' },
    subTitle: { color: 'var(--text-muted)', fontSize: '14px' },
    toggleBtn: (isOpen) => ({ padding: '10px 20px', backgroundColor: isOpen ? '#ef4444' : '#6366f1', color: 'white', borderRadius: '10px', border: 'none', cursor: 'pointer', fontWeight: '600' }),
    glassForm: { background: 'var(--bg-sidebar)', padding: '30px', borderRadius: '20px', border: '1px solid rgba(128,128,128,0.2)', marginBottom: '30px', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' },
    formTitle: { marginBottom: '20px', fontSize: '18px' },
    inputGrid: { display: 'flex', gap: '20px' },
    fieldContainer: { display: 'flex', flexDirection: 'column', flex: 1 },
    label: { marginBottom: '8px', fontSize: '13px', color: 'var(--text-muted)' },
    glassInput: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid rgba(128,128,128,0.2)', color: 'var(--text-main)', width: '100%', outline: 'none' },
    glassTextarea: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid rgba(128,128,128,0.2)', color: 'var(--text-main)', width: '100%', height: '100px', outline: 'none' },
    submitBtn: { width: '100%', marginTop: '20px', padding: '14px', backgroundColor: '#6366f1', color: 'white', borderRadius: '10px', border: 'none', fontWeight: 'bold', cursor: 'pointer' },
    tableCard: { background: 'var(--bg-sidebar)', borderRadius: '20px', border: '1px solid rgba(128,128,128,0.2)', overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: 'rgba(128,128,128,0.05)' },
    th: { padding: '15px', textAlign: 'left', fontSize: '12px', color: 'var(--text-muted)', borderBottom: '1px solid rgba(128,128,128,0.1)' },
    tr: { borderBottom: '1px solid rgba(128,128,128,0.1)', transition: '0.3s' },
    td: { padding: '15px' },
    skillsContainer: { display: 'flex', gap: '5px', flexWrap: 'wrap' },
    skillTag: { padding: '4px 10px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', borderRadius: '6px', fontSize: '11px', fontWeight: '600' },
    expBadge: { padding: '4px 10px', background: 'rgba(99, 102, 241, 0.15)', color: '#6366f1', borderRadius: '6px', fontSize: '12px', fontWeight: 'bold' },
    actionGroup: { display: 'flex', gap: '10px', justifyContent: 'center' },
    editBtn: { background: 'rgba(128,128,128,0.05)', border: '1px solid rgba(128,128,128,0.2)', borderRadius: '8px', padding: '5px 10px', cursor: 'pointer', transition: '0.2s' },
    deleteBtn: { background: 'rgba(239, 68, 68, 0.05)', border: '1px solid rgba(239, 68, 68, 0.2)', borderRadius: '8px', padding: '5px 10px', cursor: 'pointer', transition: '0.2s' }
};

export default ManageOffres;