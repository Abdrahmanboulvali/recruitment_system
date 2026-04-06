import React, { useState, useEffect } from 'react';
import axios from 'axios';

const MesCandidatures = () => {
    const [candidatures, setCandidatures] = useState([]);
    const [offres, setOffres] = useState({});
    const [loading, setLoading] = useState(true);

    // دالة جلب البيانات (بقيت كما هي مع إمكانية استدعائها مجدداً عند الحذف)
    const fetchMyData = async () => {
        try {
            const token = localStorage.getItem('access');
            const config = { headers: { Authorization: `Bearer ${token}` } };

            const offresRes = await axios.get('http://127.0.0.1:8000/api/offres/', config);
            const offresMap = {};
            offresRes.data.forEach(o => { offresMap[o.id] = o.titre; });
            setOffres(offresMap);

            const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', config);
            const candidatesRes = await axios.get('http://127.0.0.1:8000/api/candidats/', config);

            // العثور على البروفايل الخاص بالمستخدم الحالي
            const myProfile = candidatesRes.data.find(c => c.user === userRes.data.id);

            if (myProfile) {
                const res = await axios.get('http://127.0.0.1:8000/api/candidatures/', config);
                const filtered = res.data.filter(can => can.candidat === myProfile.id);
                setCandidatures(filtered);
            }
        } catch (err) {
            console.error("Erreur lors du chargement", err);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchMyData();
    }, []);

    // دالة إلغاء الترشح الجديدة
    const handleAnnuler = async (id) => {
        if (window.confirm("Voulez-vous vraiment annuler cette candidature ?")) {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };

                await axios.delete(`http://127.0.0.1:8000/api/candidatures/${id}/`, config);
                // تحديث القائمة فوراً بعد الحذف
                fetchMyData();
            } catch (err) {
                alert("Erreur lors de l'annulation de la candidature.");
            }
        }
    };

    const getOffreTitle = (id) => offres[id] || `Offre #${id}`;

    if (loading) return (
        <div style={{textAlign:'center', padding:'100px', fontWeight: 'bold', opacity: 0.7}}>
            Analyse de vos candidatures en cours...
        </div>
    );

    return (
        <div style={styles.pageWrapper}>
            <header style={styles.header}>
                <h2 style={styles.title}>Mes Candidatures</h2>
                <p style={{ opacity: 0.7 }}>Suivez l'état de vos demandes et vos scores d'adéquation</p>
            </header>

            <div style={styles.tableCard}>
                <div style={{ overflowX: 'auto' }}>
                    <table style={styles.table}>
                        <thead>
                            <tr style={styles.headerRow}>
                                <th style={styles.th}>Poste convoité</th>
                                <th style={styles.th}>Date</th>
                                <th style={styles.th}>Score IA</th>
                                <th style={styles.th}>Statut</th>
                                <th style={{...styles.th, textAlign: 'center'}}>Action</th> {/* عمود جديد */}
                            </tr>
                        </thead>
                        <tbody>
                            {candidatures.length > 0 ? (
                                candidatures.map(can => (
                                    <tr key={can.id} style={styles.tr}>
                                        <td style={{...styles.td, fontWeight: 'bold', color: '#6366f1'}}>
                                            {getOffreTitle(can.offre)}
                                        </td>
                                        <td style={styles.td}>
                                            {new Date(can.date_postulation).toLocaleDateString('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' })}
                                        </td>
                                        <td style={styles.td}>
                                            <div style={styles.scoreContainer}>
                                                <div style={styles.scoreBar(can.score)}></div>
                                                <span style={{fontWeight: 'bold'}}>{can.score}%</span>
                                            </div>
                                        </td>
                                        <td style={{...styles.td, textAlign: 'center'}}>
                                            <span style={styles.statusBadge(can.statut)}>
                                                {can.statut || 'En attente'}
                                            </span>
                                        </td>
                                        {/* زر الإلغاء المضاف */}
                                        <td style={{...styles.td, textAlign: 'center'}}>
                                            <button
                                                onClick={() => handleAnnuler(can.id)}
                                                style={styles.annulerBtn}
                                            >
                                                Annuler
                                            </button>
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="5" style={{...styles.td, textAlign: 'center', padding: '40px', opacity: 0.5}}>
                                        Vous n'avez postulé à aucune offre pour le moment.
                                    </td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

// التنسيقات (تم إضافة تنسيق annulerBtn)
const styles = {
    // ... التنسيقات السابقة كما هي تماماً ...
    pageWrapper: { padding: '40px 20px', maxWidth: '1100px', margin: '0 auto', minHeight: '100vh' },
    header: { marginBottom: '35px', borderLeft: '5px solid #10b981', paddingLeft: '20px' },
    title: { fontSize: '30px', fontWeight: '800', margin: '0 0 5px 0' },
    tableCard: { background: 'rgba(255, 255, 255, 0.03)', backdropFilter: 'blur(12px)', borderRadius: '24px', border: '1px solid rgba(255, 255, 255, 0.1)', overflow: 'hidden', boxShadow: '0 15px 35px rgba(0,0,0,0.1)' },
    table: { width: '100%', borderCollapse: 'collapse', color: 'inherit' },
    headerRow: { background: 'rgba(16, 185, 129, 0.1)' },
    th: { padding: '20px', textAlign: 'left', fontSize: '13px', textTransform: 'uppercase', letterSpacing: '1px', opacity: 0.6 },
    tr: { borderBottom: '1px solid rgba(255, 255, 255, 0.05)', transition: '0.3s ease' },
    td: { padding: '20px', fontSize: '15px' },
    scoreContainer: { display: 'flex', alignItems: 'center', gap: '10px' },
    scoreBar: (score) => ({
        width: '40px', height: '6px', borderRadius: '10px',
        background: `linear-gradient(90deg, #6366f1 ${score}%, rgba(255,255,255,0.1) ${score}%)`,
        border: '1px solid rgba(255,255,255,0.05)'
    }),
    statusBadge: (statut) => {
        const isAccepted = statut === 'Accepté' || statut === 'Acceptée';
        return {
            padding: '6px 14px', borderRadius: '10px', fontSize: '13px', fontWeight: 'bold',
            backgroundColor: isAccepted ? 'rgba(16, 185, 129, 0.15)' : 'rgba(245, 158, 11, 0.15)',
            color: isAccepted ? '#10b981' : '#f59e0b', display: 'inline-block'
        };
    },
    // التنسيق الجديد لزر الإلغاء
    annulerBtn: {
        padding: '6px 14px',
        borderRadius: '10px',
        fontSize: '12px',
        fontWeight: 'bold',
        backgroundColor: 'rgba(239, 68, 68, 0.1)',
        color: '#ef4444',
        border: '1px solid rgba(239, 68, 68, 0.2)',
        cursor: 'pointer',
        transition: '0.3s'
    }
};

export default MesCandidatures;