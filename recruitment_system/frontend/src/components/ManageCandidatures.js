import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageCandidatures = () => {
    const [candidatures, setCandidatures] = useState([]);
    const [offres, setOffres] = useState({});
    const [candidats, setCandidats] = useState({});
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [selectedCv, setSelectedCv] = useState(null);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };
                const [offresRes, candidatsRes, candidaturesRes] = await Promise.all([
                    axios.get('http://127.0.0.1:8000/api/offres/', config),
                    axios.get('http://127.0.0.1:8000/api/candidats/', config),
                    axios.get('http://127.0.0.1:8000/api/candidatures/', config)
                ]);

                const offresMap = {};
                offresRes.data.forEach(o => offresMap[o.id] = o.titre);
                setOffres(offresMap);

                const candidatsMap = {};
                candidatsRes.data.forEach(c => candidatsMap[c.id] = `${c.nom} ${c.prenom}`);
                setCandidats(candidatsMap);

                setCandidatures(candidaturesRes.data);
            } catch (err) {
                console.error("Erreur lors du chargement", err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    const handleAccept = async (id) => {
        if (window.confirm("Voulez-vous vraiment accepter cette candidature ?")) {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };
                await axios.patch(`http://127.0.0.1:8000/api/candidatures/${id}/`,
                    { statut: 'Accepté' },
                    config
                );
                alert("Candidature acceptée !");

                // تحديث الحالة محلياً لنقل الطلب فوراً إلى جدول المقبولين
                setCandidatures(prev => prev.map(can =>
                    can.id === id ? { ...can, statut: 'Accepté' } : can
                ));
            } catch (err) {
                console.error("Erreur lors de l'acceptation", err);
                alert("Erreur lors de l'opération");
            }
        }
    };

    const handleOpenModal = (cvPath) => {
        const baseUrl = "http://127.0.0.1:8000";
        let fullUrl = cvPath.startsWith('http') ? cvPath : `${baseUrl}${cvPath}`;
        setSelectedCv(fullUrl);
        setShowModal(true);
    };

    if (loading) return <div style={{textAlign:'center', padding:'100px', fontWeight:'bold'}}>Chargement des dossiers...</div>;

    // فلترة الطلبات برمجياً
    const pendingCandidatures = candidatures.filter(can => can.statut === 'En attente');
    const acceptedCandidatures = candidatures.filter(can => can.statut === 'Accepté');

    return (
        <div style={styles.pageWrapper}>
            {/* القسم الأول: طلبات قيد الانتظار */}
            <header style={styles.header}>
                <h2 style={styles.title}>Candidatures En Attente</h2>
                <p style={{ opacity: 0.7 }}>Dossiers à évaluer et valider</p>
            </header>

            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Candidat</th>
                            <th style={styles.th}>Offre</th>
                            <th style={styles.th}>Score IA</th>
                            <th style={styles.th}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {pendingCandidatures.map(can => (
                            <tr key={can.id} style={styles.tr}>
                                <td style={styles.td}>{candidats[can.candidat] || `ID: ${can.candidat}`}</td>
                                <td style={styles.td}>{offres[can.offre] || `Offre #${can.offre}`}</td>
                                <td style={styles.td}>
                                    <span style={styles.scoreBadge(can.score)}>{can.score}%</span>
                                </td>
                                <td style={styles.td}>
                                    <button onClick={() => handleOpenModal(can.cv_file)} style={styles.btnAction('#6366f1')}>
                                        Visualiser
                                    </button>
                                    <button onClick={() => handleAccept(can.id)} style={styles.btnAction('#10b981')}>Accepter</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {/* القسم الثاني: الطلبات المقبولة */}
            <header style={{...styles.header, marginTop: '60px', borderLeftColor: '#10b981'}}>
                <h2 style={styles.title}>Candidatures Acceptées</h2>
                <p style={{ opacity: 0.7 }}>Historique des candidats retenus</p>
            </header>

            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr style={{...styles.headerRow, background: 'rgba(16, 185, 129, 0.1)'}}>
                            <th style={styles.th}>Candidat</th>
                            <th style={styles.th}>Offre</th>
                            <th style={styles.th}>Score IA</th>
                            <th style={styles.th}>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        {acceptedCandidatures.map(can => (
                            <tr key={can.id} style={styles.tr}>
                                <td style={styles.td}>{candidats[can.candidat] || `ID: ${can.candidat}`}</td>
                                <td style={styles.td}>{offres[can.offre] || `Offre #${can.offre}`}</td>
                                <td style={styles.td}>{can.score}%</td>
                                <td style={styles.td}>
                                    <span style={{color: '#10b981', fontWeight: 'bold'}}>✅ Accepté</span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {showModal && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <div style={styles.modalHeader}>
                            <h3 style={{ margin: 0 }}>Visualisation du CV</h3>
                            <button onClick={() => setShowModal(false)} style={styles.closeBtn}>&times;</button>
                        </div>
                        <iframe src={selectedCv} title="CV Viewer" style={styles.iframe}></iframe>
                    </div>
                </div>
            )}
        </div>
    );
};

const styles = {
    pageWrapper: { padding: '40px 20px', maxWidth: '1200px', margin: '0 auto', minHeight: '100vh' },
    header: { marginBottom: '30px', borderLeft: '5px solid #6366f1', paddingLeft: '20px' },
    title: { fontSize: '28px', fontWeight: '800', margin: '0 0 5px 0' },
    tableContainer: { background: 'rgba(255, 255, 255, 0.05)', backdropFilter: 'blur(10px)', borderRadius: '20px', border: '1px solid rgba(255, 255, 255, 0.1)', overflow: 'hidden', boxShadow: '0 10px 30px rgba(0,0,0,0.1)' },
    table: { width: '100%', borderCollapse: 'collapse', color: 'inherit' },
    headerRow: { background: 'rgba(99, 102, 241, 0.1)' },
    th: { padding: '18px', textAlign: 'left', fontSize: '14px', textTransform: 'uppercase', letterSpacing: '1px', opacity: 0.8 },
    tr: { borderBottom: '1px solid rgba(255, 255, 255, 0.05)', transition: '0.3s' },
    td: { padding: '18px', fontSize: '15px' },
    scoreBadge: (score) => ({ backgroundColor: score > 70 ? 'rgba(16, 185, 129, 0.15)' : 'rgba(245, 158, 11, 0.15)', color: score > 70 ? '#10b981' : '#f59e0b', padding: '5px 12px', borderRadius: '8px', fontWeight: 'bold', fontSize: '14px' }),
    btnAction: (color) => ({ marginRight: '10px', padding: '8px 16px', border: `1px solid ${color}`, background: 'transparent', color: color, borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: '600', transition: '0.3s' }),
    modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0, 0, 0, 0.7)', backdropFilter: 'blur(5px)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 2000 },
    modalContent: { background: 'rgba(30, 41, 59, 0.95)', color: 'white', padding: '25px', borderRadius: '24px', width: '90%', maxWidth: '1000px', border: '1px solid rgba(255, 255, 255, 0.1)', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)' },
    modalHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' },
    closeBtn: { fontSize: '30px', border: 'none', background: 'none', cursor: 'pointer', color: '#ef4444' },
    iframe: { width: '100%', height: '70vh', border: 'none', borderRadius: '15px', background: 'white' }
};

export default ManageCandidatures;