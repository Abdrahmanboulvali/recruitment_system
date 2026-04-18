import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageOffres = () => {
    const [offres, setOffres] = useState([]);
    const [showForm, setShowForm] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [currentId, setCurrentId] = useState(null);
    const [expandedOffres, setExpandedOffres] = useState({});

    // حالة الاشتراك وتفاصيله
    const [subscription, setSubscription] = useState(null);
    const [loading, setLoading] = useState(true);

    const [newOffre, setNewOffre] = useState({
        titre: '',
        description: '',
        experience_min: 0,
        competences_requises: '',
        date_expiration: ''
    });

    const token = localStorage.getItem('access');
    const API_BASE_URL = 'http://127.0.0.1:8000';

    useEffect(() => {
        const init = async () => {
            setLoading(true);
            await fetchOffres();
            await checkSubscription();
            setLoading(false);
        };
        init();
    }, []);

    const fetchOffres = async () => {
        try {
            const res = await axios.get(`${API_BASE_URL}/api/offres/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setOffres(res.data);
        } catch (err) {
            console.error("Erreur chargement offres");
        }
    };

    const checkSubscription = async () => {
        try {
            const res = await axios.get(`${API_BASE_URL}/api/my-subscription/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            console.log("Subscription Debug:", res.data);
            setSubscription(res.data);

            const user = JSON.parse(localStorage.getItem('user') || '{}');
            if (user.enterprise) {
                user.enterprise_details = {
                    ...user.enterprise_details,
                    current_plan: res.data.plan_details,
                    is_approved: res.data.status === 'ACTIVE'
                };
                localStorage.setItem('user', JSON.stringify(user));
            }
        } catch (err) {
            console.error("Erreur check subscription", err);
        }
    };

    const handleAddButtonClick = async () => {
        // تحديث البيانات قبل الفحص لضمان الدقة
        await checkSubscription();

        const isSubscribed = subscription && subscription.status === 'ACTIVE';
        const currentUsage = subscription?.plan_details?.current_usage || 0;
        const limit = subscription?.plan_details?.offres_count || 3;

        // التحقق بناءً على الاستخدام الحالي للباقة النشطة فقط
        if (currentUsage >= limit) {
            const message = isSubscribed
                ? `⚠️ Limite de votre pack (${limit} offres) atteinte.`
                : "⚠️ Limite gratuite atteinte (3 offres). Veuillez activer un pack.";
            alert(message);
            return;
        }

        setShowForm(!showForm);
    };

    const toggleDescription = (id) => {
        setExpandedOffres(prev => ({ ...prev, [id]: !prev[id] }));
    };

    const handleEditClick = (offre) => {
        setNewOffre({
            titre: offre.titre,
            description: offre.description,
            experience_min: offre.experience_min,
            competences_requises: offre.competences_requises || '',
            date_expiration: offre.date_expiration ? offre.date_expiration.substring(0, 16) : ''
        });
        setCurrentId(offre.id);
        setIsEditing(true);
        setShowForm(true);
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        const config = { headers: { Authorization: `Bearer ${token}` } };

        try {
            const dataToSend = {
                ...newOffre,
                experience_min: parseInt(newOffre.experience_min) || 0
            };

            if (isEditing) {
                await axios.put(`${API_BASE_URL}/api/offres/${currentId}/`, dataToSend, config);
                alert("Offre modifiée avec succès !");
            } else {
                await axios.post(`${API_BASE_URL}/api/offres/`, dataToSend, config);
                alert("Offre publiée avec succès !");
            }

            resetForm();
            await fetchOffres();
            await checkSubscription();
        } catch (err) {
            const errorMsg = err.response?.data?.detail || err.response?.data?.error || "Erreur lors de l'opération";
            alert(errorMsg);
        }
    };

    const resetForm = () => {
        setNewOffre({ titre: '', description: '', experience_min: 0, competences_requises: '', date_expiration: '' });
        setShowForm(false);
        setIsEditing(false);
        setCurrentId(null);
    };

    const handleDelete = async (id) => {
        if (window.confirm("Voulez-vous supprimer cette offre ?")) {
            try {
                await axios.delete(`${API_BASE_URL}/api/offres/${id}/`, {
                    headers: { Authorization: `Bearer ${token}` }
                });
                await fetchOffres();
                await checkSubscription();
            } catch (err) {
                alert("Erreur lors de la suppression");
            }
        }
    };

    if (loading) return <div style={{textAlign: 'center', padding: '50px', color: 'var(--text-main)'}}>Chargement en cours...</div>;

    return (
        <div style={styles.pageWrapper}>
            <div style={styles.topBar}>
                <div style={styles.titleSection}>
                    <h2 style={styles.mainTitle}>Gestion des Offres</h2>
                    <p style={styles.subTitle}>
                        {subscription && subscription.status === 'ACTIVE'
                            ? `✅ Pack Actif: ${subscription.plan_details?.title || 'Pack'} (${subscription.plan_details?.current_usage || 0}/${subscription.plan_details?.offres_count} offres)`
                            : `🟠 Mode Gratuit (${subscription?.plan_details?.current_usage || 0}/3 offres utilisées)`}
                    </p>
                </div>
                <button
                    onClick={() => isEditing ? resetForm() : handleAddButtonClick()}
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
                            <div style={{...styles.fieldContainer, flex: '0 1 250px'}}>
                                <label style={styles.label}>📅 Date d'expiration</label>
                                <input
                                    type="datetime-local"
                                    style={styles.glassInput}
                                    required
                                    value={newOffre.date_expiration}
                                    onChange={e => setNewOffre({...newOffre, date_expiration: e.target.value})}
                                />
                            </div>
                        </div>

                        <div style={{marginTop: '20px'}}>
                            <label style={styles.label}>🛠️ Compétences (séparées par des virgules)</label>
                            <input
                                style={styles.glassInput}
                                placeholder="ex: React, Django, SQL"
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
                            <th style={styles.th}>Expérience / Expire</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {offres.length > 0 ? offres.map(o => {
                            const isExpanded = expandedOffres[o.id];
                            const fullDesc = o.description || "";
                            const displayedDesc = isExpanded ? fullDesc : fullDesc.substring(0, 60) + (fullDesc.length > 60 ? "..." : "");

                            return (
                                <tr key={o.id} style={styles.tr}>
                                    <td style={styles.td}>
                                        <div style={{fontWeight: '700', color: 'var(--text-main)'}}>{o.titre}</div>
                                        <div style={{fontSize: '12px', color: 'var(--text-muted)', marginTop: '4px', lineHeight: '1.4'}}>
                                            {displayedDesc}
                                            {fullDesc.length > 60 && (
                                                <span onClick={() => toggleDescription(o.id)} style={styles.voirPlus}>
                                                    {isExpanded ? " Voir moins" : " Voir plus"}
                                                </span>
                                            )}
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
                                        <div style={{display: 'flex', flexDirection: 'column', gap: '5px'}}>
                                            <span style={styles.expBadge}>{o.experience_min} ans</span>
                                            <span style={{fontSize: '11px', color: '#ef4444', fontWeight: 'bold'}}>
                                                ⌛ {o.date_expiration ? new Date(o.date_expiration).toLocaleDateString() : 'N/A'}
                                            </span>
                                        </div>
                                    </td>
                                    <td style={{...styles.td, textAlign: 'center'}}>
                                        <div style={styles.actionGroup}>
                                            <button onClick={() => handleEditClick(o)} style={styles.editBtn}>✏️</button>
                                            <button onClick={() => handleDelete(o.id)} style={styles.deleteBtn}>🗑️</button>
                                        </div>
                                    </td>
                                </tr>
                            );
                        }) : (
                             <tr>
                                <td colSpan="4" style={{padding: '40px', textAlign: 'center', color: 'var(--text-muted)'}}>
                                    Aucune offre publiée pour le moment.
                                </td>
                             </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const styles = {
    pageWrapper: { padding: '40px 20px', maxWidth: '1200px', margin: '0 auto' },
    topBar: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' },
    mainTitle: { fontSize: '28px', fontWeight: 'bold', color: 'var(--text-main)' },
    subTitle: { color: 'var(--text-muted)', fontSize: '14px', marginTop: '5px' },
    toggleBtn: (isOpen) => ({ padding: '10px 20px', backgroundColor: isOpen ? '#ef4444' : '#6366f1', color: 'white', borderRadius: '10px', border: 'none', cursor: 'pointer', fontWeight: '600', transition: '0.3s' }),
    glassForm: { background: 'var(--bg-sidebar)', padding: '30px', borderRadius: '20px', border: '1px solid rgba(128,128,128,0.2)', marginBottom: '30px', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' },
    formTitle: { marginBottom: '20px', fontSize: '18px', fontWeight: 'bold' },
    inputGrid: { display: 'flex', gap: '20px', flexWrap: 'wrap' },
    fieldContainer: { display: 'flex', flexDirection: 'column', flex: 1 },
    label: { marginBottom: '8px', fontSize: '13px', color: 'var(--text-muted)', fontWeight: '600' },
    glassInput: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid rgba(128,128,128,0.2)', color: 'var(--text-main)', width: '100%', outline: 'none' },
    glassTextarea: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid rgba(128,128,128,0.2)', color: 'var(--text-main)', width: '100%', height: '100px', outline: 'none', resize: 'vertical' },
    submitBtn: { width: '100%', marginTop: '20px', padding: '14px', backgroundColor: '#6366f1', color: 'white', borderRadius: '10px', border: 'none', fontWeight: 'bold', cursor: 'pointer', transition: '0.2s' },
    tableCard: { background: 'var(--bg-sidebar)', borderRadius: '20px', border: '1px solid rgba(128,128,128,0.2)', overflow: 'hidden' },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: 'rgba(128,128,128,0.05)' },
    th: { padding: '15px', textAlign: 'left', fontSize: '12px', color: 'var(--text-muted)', borderBottom: '1px solid rgba(128,128,128,0.1)' },
    tr: { borderBottom: '1px solid rgba(128,128,128,0.1)' },
    td: { padding: '15px', verticalAlign: 'top' },
    skillsContainer: { display: 'flex', gap: '5px', flexWrap: 'wrap' },
    skillTag: { padding: '4px 10px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', borderRadius: '6px', fontSize: '11px' },
    expBadge: { padding: '4px 10px', background: 'rgba(99, 102, 241, 0.15)', color: '#6366f1', borderRadius: '6px', fontSize: '12px', fontWeight: 'bold' },
    actionGroup: { display: 'flex', gap: '10px' },
    editBtn: { background: 'transparent', border: 'none', cursor: 'pointer', fontSize: '16px' },
    deleteBtn: { background: 'transparent', border: 'none', cursor: 'pointer', fontSize: '16px' },
    voirPlus: { color: '#6366f1', cursor: 'pointer', fontWeight: 'bold', marginLeft: '5px', fontSize: '11px' }
};

export default ManageOffres;