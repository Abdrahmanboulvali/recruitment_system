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
    const config = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => {
        fetchOffres();
    }, []);

    const fetchOffres = async () => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/offres/', config);
            setOffres(res.data);
        } catch (err) {
            console.error("Erreur chargement offres");
        }
    };

    // دالة لفتح النموذج في وضع التعديل
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
        try {
            const dataToSend = {
                ...newOffre,
                experience_min: parseInt(newOffre.experience_min) || 0
            };

            if (isEditing) {
                await axios.put(`http://127.0.0.1:8000/api/offres/${currentId}/`, dataToSend, config);
            } else {
                await axios.post('http://127.0.0.1:8000/api/offres/', dataToSend, config);
            }

            resetForm();
            fetchOffres();
        } catch (err) {
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
                await axios.delete(`http://127.0.0.1:8000/api/offres/${id}/`, config);
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
                    <h3 style={styles.formTitle}>
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
                                    <div style={{fontWeight: '700', color: '#fff'}}>{o.titre}</div>
                                    <div style={{fontSize: '12px', opacity: 0.6, marginTop: '4px'}}>
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
    // ... التنسيقات السابقة مع الإضافات الجديدة ...
    pageWrapper: { padding: '40px 20px', maxWidth: '1200px', margin: '0 auto', color: '#e2e8f0' },
    topBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' },
    mainTitle: { fontSize: '28px', fontWeight: 'bold' },
    subTitle: { color: '#94a3b8', fontSize: '14px' },
    toggleBtn: (isOpen) => ({ padding: '10px 20px', backgroundColor: isOpen ? '#ef4444' : '#6366f1', color: 'white', borderRadius: '10px', border: 'none', cursor: 'pointer', fontWeight: '600' }),
    glassForm: { background: 'rgba(30, 41, 59, 0.7)', padding: '30px', borderRadius: '20px', border: '1px solid #334155', marginBottom: '30px' },
    formTitle: { marginBottom: '20px', fontSize: '18px' },
    inputGrid: { display: 'flex', gap: '20px' },
    fieldContainer: { display: 'flex', flexDirection: 'column', flex: 1 },
    label: { marginBottom: '8px', fontSize: '13px', color: '#94a3b8' },
    glassInput: { padding: '12px', borderRadius: '10px', background: '#0f172a', border: '1px solid #334155', color: 'white', width: '100%', outline: 'none' },
    glassTextarea: { padding: '12px', borderRadius: '10px', background: '#0f172a', border: '1px solid #334155', color: 'white', width: '100%', height: '100px', outline: 'none' },
    submitBtn: { width: '100%', marginTop: '20px', padding: '14px', backgroundColor: '#6366f1', color: 'white', borderRadius: '10px', border: 'none', fontWeight: 'bold', cursor: 'pointer' },
    tableCard: { background: 'rgba(30, 41, 59, 0.4)', borderRadius: '20px', border: '1px solid #334155', overflow: 'hidden' },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: '#1e293b' },
    th: { padding: '15px', textAlign: 'left', fontSize: '12px', color: '#94a3b8' },
    tr: { borderBottom: '1px solid #334155' },
    td: { padding: '15px' },
    skillsContainer: { display: 'flex', gap: '5px', flexWrap: 'wrap' },
    skillTag: { padding: '2px 8px', background: '#334155', borderRadius: '5px', fontSize: '11px' },
    expBadge: { padding: '4px 10px', background: 'rgba(99, 102, 241, 0.2)', color: '#818cf8', borderRadius: '6px', fontSize: '12px', fontWeight: 'bold' },
    actionGroup: { display: 'flex', gap: '10px', justifyContent: 'center' },
    editBtn: { background: 'none', border: '1px solid #334155', borderRadius: '8px', padding: '5px 10px', cursor: 'pointer' },
    deleteBtn: { background: 'none', border: '1px solid #ef444455', borderRadius: '8px', padding: '5px 10px', cursor: 'pointer' }
};

export default ManageOffres;