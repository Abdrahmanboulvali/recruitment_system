import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageOffres = () => {
    const [offres, setOffres] = useState([]);
    const [showForm, setShowForm] = useState(false);
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

    const handleCreate = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://127.0.0.1:8000/api/offres/', newOffre, config);
            setNewOffre({ titre: '', description: '', experience_min: 0, competences_requises: '' });
            setShowForm(false);
            fetchOffres();
        } catch (err) {
            alert("Erreur lors de l'ajout");
        }
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
                    <p style={styles.subTitle}>Publiez et gérez les opportunités d'emploi disponibles</p>
                </div>
                <button
                    onClick={() => setShowForm(!showForm)}
                    style={styles.toggleBtn(showForm)}
                >
                    {showForm ? "✕ Fermer" : "+ Nouvelle Offre"}
                </button>
            </div>

            {showForm && (
                <div style={styles.glassForm}>
                    <h3 style={styles.formTitle}>
                        <span>📌</span> Détails de la nouvelle offre
                    </h3>
                    <form onSubmit={handleCreate}>
                        <div style={styles.inputGrid}>
                            <div style={styles.fieldContainer}>
                                <label style={styles.label}>💼 Titre du poste</label>
                                <input
                                    style={styles.glassInput}
                                    placeholder="Ex: Développeur Fullstack Python"
                                    required
                                    value={newOffre.titre}
                                    onChange={e => setNewOffre({...newOffre, titre: e.target.value})}
                                />
                            </div>

                            <div style={{...styles.fieldContainer, flex: '0 1 200px'}}>
                                <label style={styles.label}>⏳ Expérience min (ans)</label>
                                <input
                                    type="number"
                                    min="0"
                                    style={styles.glassInput}
                                    placeholder="0"
                                    required
                                    value={newOffre.experience_min}
                                    onChange={e => setNewOffre({...newOffre, experience_min: e.target.value})}
                                />
                            </div>
                        </div>

                        <div style={{...styles.fieldContainer, marginTop: '25px'}}>
                            <label style={styles.label}>📝 Description du poste</label>
                            <textarea
                                style={styles.glassTextarea}
                                placeholder="Décrivez les missions..."
                                required
                                value={newOffre.description}
                                onChange={e => setNewOffre({...newOffre, description: e.target.value})}
                            />
                        </div>

                        <button type="submit" style={styles.submitBtn}>🚀 Publier l'offre</button>
                    </form>
                </div>
            )}

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Poste</th>
                            <th style={styles.th}>Expérience</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {offres.length > 0 ? offres.map(o => (
                            <tr key={o.id} style={styles.tr}>
                                <td style={{...styles.td, fontWeight: '600'}}>{o.titre}</td>
                                <td style={styles.td}>
                                    <span style={styles.expBadge}>{o.experience_min} ans min</span>
                                </td>
                                <td style={{...styles.td, textAlign: 'center'}}>
                                    <button onClick={() => handleDelete(o.id)} style={styles.deleteBtn}>
                                        🗑️ Supprimer
                                    </button>
                                </td>
                            </tr>
                        )) : (
                            <tr>
                                <td colSpan="3" style={{...styles.td, textAlign: 'center', opacity: 0.5}}>
                                    Aucune offre disponible.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

// التنسيقات المحدثة لتدعم الوضعين (Light & Dark) تلقائياً
const styles = {
    pageWrapper: {
        padding: '40px 20px',
        maxWidth: '1100px',
        margin: '0 auto',
        minHeight: '100vh',
        color: 'inherit' // سيأخذ اللون من الـ Body (أسود في النهار وأبيض في الليل)
    },
    topBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' },
    mainTitle: { fontSize: '32px', fontWeight: '800', margin: 0, color: 'inherit' },
    subTitle: { opacity: 0.7, margin: 0, color: 'inherit' },
    toggleBtn: (isOpen) => ({
        padding: '12px 25px',
        backgroundColor: isOpen ? 'rgba(239, 68, 68, 0.1)' : '#6366f1',
        color: isOpen ? '#ef4444' : 'white',
        border: isOpen ? '1px solid #ef4444' : 'none',
        borderRadius: '12px',
        fontWeight: 'bold',
        cursor: 'pointer'
    }),
    glassForm: {
        background: 'rgba(120, 120, 120, 0.05)', // خلفية شفافة رمادية تعمل في الوضعين
        backdropFilter: 'blur(20px)',
        padding: '40px',
        borderRadius: '24px',
        border: '1px solid rgba(150, 150, 150, 0.2)',
        marginBottom: '40px'
    },
    formTitle: { marginBottom: '30px', color: '#6366f1', display: 'flex', alignItems: 'center', gap: '10px', fontSize: '20px' },
    inputGrid: { display: 'flex', gap: '25px', flexWrap: 'wrap' },
    fieldContainer: { display: 'flex', flexDirection: 'column', flex: 1, gap: '12px' },
    label: { fontSize: '14px', fontWeight: '600', color: 'inherit', opacity: 0.8 },
    glassInput: {
        padding: '16px',
        borderRadius: '14px',
        border: '1px solid rgba(150, 150, 150, 0.3)',
        background: 'rgba(150, 150, 150, 0.05)',
        color: 'inherit', // يضمن ظهور النص المكتوب بوضوح
        fontSize: '15px',
        outline: 'none'
    },
    glassTextarea: {
        padding: '16px',
        borderRadius: '14px',
        border: '1px solid rgba(150, 150, 150, 0.3)',
        background: 'rgba(150, 150, 150, 0.05)',
        color: 'inherit',
        fontSize: '15px',
        height: '150px',
        resize: 'none',
        outline: 'none'
    },
    submitBtn: { width: '100%', marginTop: '30px', padding: '16px', backgroundColor: '#6366f1', color: 'white', borderRadius: '14px', fontWeight: '800', border: 'none', cursor: 'pointer' },
    tableCard: {
        background: 'rgba(150, 150, 150, 0.05)',
        borderRadius: '24px',
        border: '1px solid rgba(150, 150, 150, 0.2)',
        overflow: 'hidden'
    },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: 'rgba(99, 102, 241, 0.1)' },
    th: { padding: '20px', textAlign: 'left', color: 'inherit', fontSize: '13px', textTransform: 'uppercase' },
    tr: { borderBottom: '1px solid rgba(150, 150, 150, 0.1)', color: 'inherit' },
    td: { padding: '20px', color: 'inherit' },
    expBadge: { padding: '5px 12px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', borderRadius: '8px', fontSize: '13px', fontWeight: 'bold' },
    deleteBtn: { padding: '8px 15px', background: 'rgba(239, 68, 68, 0.1)', color: '#ef4444', border: 'none', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold' }
};

export default ManageOffres;