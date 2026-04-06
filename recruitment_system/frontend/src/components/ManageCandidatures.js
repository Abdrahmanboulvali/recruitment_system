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

                // جلب البيانات
                const [offresRes, candidatsRes, candidaturesRes] = await Promise.all([
                    axios.get('http://127.0.0.1:8000/api/offres/', config),
                    axios.get('http://127.0.0.1:8000/api/candidats/', config),
                    axios.get('http://127.0.0.1:8000/api/candidatures/', config)
                ]);

                // تحويل العروض والترشيحات لخرائط (Maps) لسهولة الوصول
                const offresMap = {};
                offresRes.data.forEach(o => offresMap[o.id] = o.titre);
                setOffres(offresMap);

                const candidatsMap = {};
                candidatsRes.data.forEach(c => {
                    candidatsMap[c.id] = `${c.nom} ${c.prenom}`;
                });
                setCandidats(candidatsMap);

                // تخزين الترشيحات مع التأكد من وجود البيانات
                console.log("Candidatures من السيرفر:", candidaturesRes.data);
                setCandidatures(candidaturesRes.data);

            } catch (err) {
                console.error("Erreur lors du chargement", err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    // دالة مساعدة لجلب الاسم سواء كان القادم ID أو Object
    const getCandidatName = (can) => {
        const id = typeof can.candidat === 'object' ? can.candidat.id : can.candidat;
        return candidats[id] || `Candidat #${id}`;
    };

    const getOffreTitle = (can) => {
        const id = typeof can.offre === 'object' ? can.offre.id : can.offre;
        return offres[id] || `Offre #${id}`;
    };

    const handleAccept = async (id) => {
        if (window.confirm("Voulez-vous vraiment accepter cette candidature ?")) {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };
                await axios.patch(`http://127.0.0.1:8000/api/candidatures/${id}/`,
                    { statut: 'Accepté' },
                    config
                );

                // تحديث الحالة محلياً فوراً
                setCandidatures(prev => prev.map(can =>
                    can.id === id ? { ...can, statut: 'Accepté' } : can
                ));
                alert("Candidature acceptée !");
            } catch (err) {
                console.error(err);
                alert("Erreur lors de l'opération");
            }
        }
    };

    const handleOpenModal = (cvPath) => {
        if(!cvPath) return alert("Aucun fichier CV trouvé");
        const baseUrl = "http://127.0.0.1:8000";
        let fullUrl = cvPath.startsWith('http') ? cvPath : `${baseUrl}${cvPath}`;
        setSelectedCv(fullUrl);
        setShowModal(true);
    };

    if (loading) return <div style={styles.loader}>Chargement des dossiers...</div>;

    // فلترة مع مراعاة حالة الأحرف (Case Insensitive)
    const pendingCandidatures = candidatures.filter(can =>
        can.statut?.toLowerCase() === 'en attente' || can.statut?.toLowerCase() === 'en_attente'
    );
    const acceptedCandidatures = candidatures.filter(can =>
        can.statut?.toLowerCase() === 'accepté' || can.statut?.toLowerCase() === 'accepte'
    );

    return (
        <div style={styles.pageWrapper}>
            <header style={styles.header}>
                <h2 style={styles.title}>Candidatures En Attente ({pendingCandidatures.length})</h2>
                <p style={{ opacity: 0.7 }}>Dossiers à évaluer par l'IA et valider</p>
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
                        {pendingCandidatures.length > 0 ? pendingCandidatures.map(can => (
                            <tr key={can.id} style={styles.tr}>
                                <td style={styles.td}>{getCandidatName(can)}</td>
                                <td style={styles.td}>{getOffreTitle(can)}</td>
                                <td style={styles.td}>
                                    <span style={styles.scoreBadge(can.score)}>{can.score}%</span>
                                </td>
                                <td style={styles.td}>
                                    <button onClick={() => handleOpenModal(can.cv_file)} style={styles.btnAction('#6366f1')}>Visualiser</button>
                                    <button onClick={() => handleAccept(can.id)} style={styles.btnAction('#10b981')}>Accepter</button>
                                </td>
                            </tr>
                        )) : (
                            <tr><td colSpan="4" style={{textAlign: 'center', padding: '20px', opacity: 0.5}}>Aucune candidature en attente</td></tr>
                        )}
                    </tbody>
                </table>
            </div>

            <header style={{...styles.header, marginTop: '60px', borderLeftColor: '#10b981'}}>
                <h2 style={styles.title}>Candidatures Acceptées ({acceptedCandidatures.length})</h2>
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
                                <td style={styles.td}>{getCandidatName(can)}</td>
                                <td style={styles.td}>{getOffreTitle(can)}</td>
                                <td style={styles.td}>{can.score}%</td>
                                <td style={styles.td}><span style={{color: '#10b981', fontWeight: 'bold'}}>✅ Accepté</span></td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>

            {showModal && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <div style={styles.modalHeader}>
                            <h3>Analyse du CV</h3>
                            <button onClick={() => setShowModal(false)} style={styles.closeBtn}>&times;</button>
                        </div>
                        <object data={selectedCv} type="application/pdf" style={styles.iframe}>
                            <div style={{color: 'white', textAlign: 'center'}}>
                                <p>Le navigateur لا يدعم عرض الملف مباشرة.</p>
                                <a href={selectedCv} target="_blank" rel="noreferrer" style={{color: '#6366f1'}}>Ouvrir le PDF</a>
                            </div>
                        </object>
                    </div>
                </div>
            )}
        </div>
    );
};

// ... التنسيقات (نفس التي لديك مع تحسينات طفيفة)
const styles = {
    pageWrapper: { padding: '40px 20px', maxWidth: '1200px', margin: '0 auto', color: 'white' },
    header: { marginBottom: '30px', borderLeft: '5px solid #6366f1', paddingLeft: '20px' },
    title: { fontSize: '26px', fontWeight: 'bold', margin: 0 },
    loader: { textAlign: 'center', padding: '100px', fontSize: '20px', color: 'gray' },
    tableContainer: { background: 'rgba(255, 255, 255, 0.03)', borderRadius: '20px', border: '1px solid rgba(255, 255, 255, 0.1)', overflow: 'hidden' },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: 'rgba(255, 255, 255, 0.05)' },
    th: { padding: '15px', textAlign: 'left', opacity: 0.6, fontSize: '13px' },
    tr: { borderBottom: '1px solid rgba(255, 255, 255, 0.05)' },
    td: { padding: '15px' },
    scoreBadge: (score) => ({ background: score > 60 ? 'rgba(16, 185, 129, 0.2)' : 'rgba(245, 158, 11, 0.2)', color: score > 60 ? '#10b981' : '#f59e0b', padding: '4px 10px', borderRadius: '6px', fontWeight: 'bold' }),
    btnAction: (color) => ({ marginRight: '10px', padding: '6px 12px', border: `1px solid ${color}`, background: 'transparent', color: color, borderRadius: '6px', cursor: 'pointer' }),
    modalOverlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    modalContent: { background: '#1e293b', padding: '20px', borderRadius: '15px', width: '80%', height: '80%' },
    modalHeader: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px' },
    closeBtn: { background: 'none', border: 'none', color: 'red', fontSize: '24px', cursor: 'pointer' },
    iframe: { width: '100%', height: '90%', borderRadius: '10px' }
};

export default ManageCandidatures;