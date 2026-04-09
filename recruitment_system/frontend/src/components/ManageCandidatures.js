import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageCandidatures = () => {
    const [candidatures, setCandidatures] = useState([]);
    const [offresData, setOffresData] = useState({});
    const [candidats, setCandidats] = useState({});
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [selectedCan, setSelectedCan] = useState(null);

    const [searchTerm, setSearchTerm] = useState("");
    const [minScore, setMinScore] = useState(0);

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

                const oMap = {};
                offresRes.data.forEach(o => oMap[o.id] = o);
                setOffresData(oMap);

                const cMap = {};
                candidatsRes.data.forEach(c => cMap[c.id] = `${c.nom} ${c.prenom}`);
                setCandidats(cMap);

                setCandidatures(candidaturesRes.data);
            } catch (err) {
                console.error("Erreur:", err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    const getFullCvUrl = (cvPath) => {
        if (!cvPath) return null;
        const baseUrl = "http://127.0.0.1:8000";
        return cvPath.startsWith('http') ? cvPath : `${baseUrl}${cvPath}`;
    };

    // وظيفة لتنظيف التعليقات من أي إشارة لـ O*NET أو مصطلحات خارجية
    const cleanComment = (text) => {
        if (!text) return "Aucune analyse disponible pour le moment.";
        return text.replace(/O\*NET/gi, "Système").replace(/Matching/gi, "Analyse");
    };

    const filteredCandidatures = candidatures.filter(can => {
        const name = (candidats[can.candidat] || "").toLowerCase();
        const job = (offresData[can.offre]?.titre || "").toLowerCase();
        const score = can.score.toString();
        const search = searchTerm.toLowerCase();

        const matchesSearch = name.includes(search) || job.includes(search) || score.includes(search);
        const matchesScore = can.score >= minScore;
        return matchesSearch && matchesScore;
    });

    const pending = filteredCandidatures.filter(can =>
        can.statut?.toLowerCase().includes('attente')
    );

    const accepted = filteredCandidatures.filter(can =>
        can.statut?.toLowerCase().includes('accepté')
    );

    const rejected = filteredCandidatures.filter(can =>
        can.statut?.toLowerCase().includes('refusé')
    );

    const handleOpenAnalysis = (can) => {
        setSelectedCan(can);
        setShowModal(true);
    };

    const handleUpdateStatus = async (id, newStatus) => {
        if (!window.confirm(`Confirmer: ${newStatus}?`)) return;
        try {
            const token = localStorage.getItem('access');
            await axios.patch(`http://127.0.0.1:8000/api/candidatures/${id}/`,
                { statut: newStatus },
                { headers: { Authorization: `Bearer ${token}` } }
            );
            setCandidatures(prev => prev.map(c => c.id === id ? { ...c, statut: newStatus } : c));
            setShowModal(false);
        } catch (err) { alert("Erreur"); }
    };

    const CandidatureTable = ({ data, title, color }) => (
        <div style={{ marginTop: '40px' }}>
            <h3 style={{ ...styles.title, fontSize: '20px', color: color || 'var(--text-main)', marginBottom: '15px' }}>
                {title} ({data.length})
            </h3>
            <div style={styles.tableContainer}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Candidat</th>
                            <th style={styles.th}>Offre convoitée</th>
                            <th style={styles.th}>Adéquation</th>
                            <th style={styles.th}>Action</th>
                        </tr>
                    </thead>
                    <tbody>
                        {data.map(can => (
                            <tr key={can.id} style={styles.tr}>
                                <td style={{ ...styles.td, fontWeight: '600' }}>{candidats[can.candidat]}</td>
                                <td style={styles.td}>{offresData[can.offre]?.titre}</td>
                                <td style={styles.td}>
                                    <div style={styles.scoreCell}>
                                        <div style={styles.miniBarContainer}>
                                            <div style={styles.miniBarFill(can.score)}></div>
                                        </div>
                                        <span style={{ fontWeight: 'bold' }}>{can.score}%</span>
                                    </div>
                                </td>
                                <td style={styles.td}>
                                    <button onClick={() => handleOpenAnalysis(can)} style={styles.btnVisualiser}>Visualiser</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );

    if (loading) return <div style={styles.loader}>Chargement...</div>;

    return (
        <div style={styles.pageWrapper}>
            <header style={styles.header}>
                <h2 style={styles.title}>Gestion des Candidatures</h2>
                <p style={{ color: 'var(--text-muted)' }}>Analyse et suivi des profils candidats</p>
            </header>

            <div style={styles.filterBar}>
                <div style={{ flex: 2 }}>
                    <label style={styles.label}>RECHERCHE GLOBALE (Nom, Poste, Score)</label>
                    <input
                        type="text"
                        placeholder="Rechercher partout..."
                        style={styles.searchInput}
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                    />
                </div>
                <div style={{ flex: 1 }}>
                    <label style={styles.label}>SCORE MINIMUM: {minScore}%</label>
                    <input
                        type="range" min="0" max="100"
                        value={minScore}
                        style={styles.rangeInput}
                        onChange={(e) => setMinScore(e.target.value)}
                    />
                </div>
            </div>

            <CandidatureTable data={pending} title="Candidatures En Attente" color="#f59e0b" />
            <CandidatureTable data={accepted} title="Candidatures Acceptées" color="#10b981" />
            <CandidatureTable data={rejected} title="Candidatures Refusées" color="#ef4444" />

            {showModal && selectedCan && (
                <div style={styles.modalOverlay} onClick={() => setShowModal(false)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <div style={styles.modalHeader}>
                            <button onClick={() => setShowModal(false)} style={styles.modalBackBtn}>
                                ❮ Retour à la liste
                            </button>
                            <h3 style={{ margin: 0, color: 'white' }}>Détails de: {candidats[selectedCan.candidat]}</h3>
                            <button onClick={() => setShowModal(false)} style={styles.closeX}>×</button>
                        </div>

                        <div style={styles.modalBody}>
                            <div style={styles.analysisSide}>
                                <div style={styles.infoCard}>
                                    <p style={styles.infoLabel}>Poste:</p>
                                    <p style={styles.infoValue}>{offresData[selectedCan.offre]?.titre}</p>
                                    <p style={styles.infoLabel}>Taux de correspondance:</p>
                                    <p style={{ ...styles.infoValue, color: '#f59e0b', fontSize: '24px' }}>{selectedCan.score}%</p>
                                    <hr style={styles.hr} />
                                    <p style={styles.infoLabel}>Analyse du profil:</p>
                                    <p style={{ ...styles.infoValue, fontSize: '14px', fontWeight: 'normal', color: 'var(--text-muted)', lineHeight: '1.5' }}>
                                        {cleanComment(selectedCan.commentaire_ia)}
                                    </p>
                                </div>

                                <div style={styles.modalActions}>
                                    {selectedCan.statut?.toLowerCase().includes('attente') ? (
                                        <>
                                            <button onClick={() => handleUpdateStatus(selectedCan.id, 'Accepté')} style={styles.btnModalAccept}>Accepter le profil</button>
                                            <button onClick={() => handleUpdateStatus(selectedCan.id, 'Refusé')} style={styles.btnModalRefuse}>Refuser le profil</button>
                                        </>
                                    ) : (
                                        <div style={{
                                            padding: '15px',
                                            textAlign: 'center',
                                            borderRadius: '8px',
                                            fontWeight: 'bold',
                                            background: selectedCan.statut?.toLowerCase().includes('accepté') ? 'rgba(16, 185, 129, 0.1)' : 'rgba(239, 68, 68, 0.1)',
                                            color: selectedCan.statut?.toLowerCase().includes('accepté') ? '#10b981' : '#ef4444',
                                            border: `1px solid ${selectedCan.statut?.toLowerCase().includes('accepté') ? '#10b981' : '#ef4444'}`
                                        }}>
                                            {selectedCan.statut?.toLowerCase().includes('accepté') ? '✓ Candidature Acceptée' : '✕ Candidature Refusée'}
                                        </div>
                                    )}
                                </div>
                            </div>

                            <div style={styles.cvSide}>
                                <div style={styles.cvFallback}>
                                    <div style={{ fontSize: '50px', marginBottom: '15px' }}>📄</div>
                                    <p style={{ color: '#1e293b', fontWeight: 'bold' }}>Document PDF</p>
                                    <a
                                        href={getFullCvUrl(selectedCan.cv_file)}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        style={styles.btnOpenCV}
                                    >
                                        👁️ Ouvrir le CV dans une nouvelle fenêtre
                                    </a>
                                </div>
                                <iframe
                                    src={getFullCvUrl(selectedCan.cv_file)}
                                    style={styles.cvIframe}
                                    title="CV Preview"
                                />
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

const styles = {
    pageWrapper: { padding: '40px', background: 'var(--bg-main)', minHeight: '100vh', color: 'var(--text-main)' },
    header: { marginBottom: '30px' },
    title: { fontSize: '28px', fontWeight: 'bold', color: 'var(--text-main)' },
    filterBar: { display: 'flex', gap: '30px', background: 'var(--bg-sidebar)', padding: '20px', borderRadius: '12px', marginBottom: '30px', border: '1px solid rgba(128,128,128,0.1)', boxShadow: '0 4px 15px rgba(0,0,0,0.05)' },
    label: { display: 'block', fontSize: '11px', color: 'var(--text-muted)', marginBottom: '8px', fontWeight: '600' },
    searchInput: { width: '100%', padding: '10px', borderRadius: '8px', border: '1px solid rgba(128,128,128,0.2)', background: 'var(--bg-main)', color: 'var(--text-main)', outline: 'none' },
    rangeInput: { width: '100%', cursor: 'pointer' },
    tableContainer: { background: 'var(--bg-sidebar)', borderRadius: '15px', overflow: 'hidden', border: '1px solid rgba(128,128,128,0.1)', boxShadow: '0 4px 20px rgba(0,0,0,0.05)' },
    table: { width: '100%', borderCollapse: 'collapse' },
    headerRow: { background: 'rgba(128,128,128,0.05)' },
    th: { padding: '15px', textAlign: 'left', fontSize: '13px', color: 'var(--text-muted)', borderBottom: '1px solid rgba(128,128,128,0.1)' },
    tr: { borderBottom: '1px solid rgba(128,128,128,0.1)', transition: '0.3s' },
    td: { padding: '15px', color: 'var(--text-main)' },
    scoreCell: { display: 'flex', alignItems: 'center', gap: '12px' },
    miniBarContainer: { height: '8px', width: '80px', background: 'rgba(128,128,128,0.1)', borderRadius: '4px', overflow: 'hidden' },
    miniBarFill: (s) => ({
        height: '100%',
        width: `${s}%`,
        background: s > 60 ? '#10b981' : s > 35 ? '#f59e0b' : '#ef4444',
        transition: 'width 0.4s ease'
    }),
    btnVisualiser: { background: 'transparent', border: '1px solid #6366f1', color: '#6366f1', padding: '6px 15px', borderRadius: '6px', cursor: 'pointer', fontWeight: '600' },
    modalOverlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000, backdropFilter: 'blur(4px)' },
    modalContent: { width: '90%', height: '85%', background: 'var(--bg-main)', borderRadius: '20px', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 25px 50px rgba(0,0,0,0.2)' },
    modalHeader: { padding: '15px 25px', background: '#1e293b', display: 'flex', justifyContent: 'space-between', alignItems: 'center' },
    modalBackBtn: { background: '#334155', border: 'none', color: 'white', padding: '6px 12px', borderRadius: '6px', cursor: 'pointer' },
    closeX: { background: 'none', border: 'none', color: '#ef4444', fontSize: '24px', cursor: 'pointer' },
    modalBody: { display: 'flex', flex: 1, overflow: 'hidden' },
    analysisSide: { width: '350px', padding: '25px', borderRight: '1px solid rgba(128,128,128,0.1)', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', background: 'var(--bg-sidebar)' },
    infoCard: { background: 'var(--bg-main)', padding: '20px', borderRadius: '12px', border: '1px solid rgba(128,128,128,0.1)' },
    infoLabel: { fontSize: '11px', color: 'var(--text-muted)', fontWeight: '600' },
    infoValue: { fontSize: '16px', fontWeight: 'bold', marginBottom: '15px', color: 'var(--text-main)' },
    hr: { border: 'none', borderTop: '1px solid rgba(128,128,128,0.1)', margin: '15px 0' },
    modalActions: { display: 'flex', flexDirection: 'column', gap: '10px' },
    btnModalAccept: { padding: '12px', background: '#10b981', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' },
    btnModalRefuse: { padding: '12px', background: '#ef4444', border: 'none', borderRadius: '8px', color: 'white', fontWeight: 'bold', cursor: 'pointer' },
    cvSide: { flex: 1, background: '#f1f5f9', position: 'relative' },
    cvIframe: { width: '100%', height: '100%', border: 'none', position: 'absolute', top: 0, left: 0, zIndex: 1 },
    cvFallback: {
        position: 'absolute', inset: 0, zIndex: 2, background: '#f8fafc',
        display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center'
    },
    btnOpenCV: {
        background: '#6366f1', color: 'white', padding: '12px 20px', borderRadius: '8px', textDecoration: 'none', fontWeight: 'bold'
    },
    loader: { textAlign: 'center', marginTop: '100px', color: 'var(--text-muted)' }
};

export default ManageCandidatures;