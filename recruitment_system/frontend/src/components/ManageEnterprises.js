import React, { useState, useEffect } from 'react';
import axios from 'axios';
import '../App.css';

const ManageEnterprises = () => {
    const [enterprises, setEnterprises] = useState([]);
    const [loading, setLoading] = useState(true);
    const [previewFile, setPreviewFile] = useState(null);
    const [fileType, setFileType] = useState('');

    const token = localStorage.getItem('access');
    const API_BASE_URL = 'http://127.0.0.1:8000';

    useEffect(() => {
        fetchEnterprises();
    }, []);

    const fetchEnterprises = async () => {
        try {
            setLoading(true);
            const res = await axios.get(`${API_BASE_URL}/api/enterprises/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setEnterprises(res.data);
        } catch (err) {
            console.error("Erreur fetching enterprises:", err);
        } finally {
            setLoading(false);
        }
    };

    const openPreview = (fileUrl) => {
        if (!fileUrl) return;
        // تصحيح الرابط لضمان إضافة عنوان السيرفر إذا كان المسار نسبياً
        const fullUrl = fileUrl.startsWith('http')
            ? fileUrl
            : `${API_BASE_URL}${fileUrl.startsWith('/') ? '' : '/'}${fileUrl}`;

        const extension = fileUrl.split(/[#?]/)[0].split('.').pop().trim().toLowerCase();
        setFileType(extension);
        setPreviewFile(fullUrl);
    };

    const handleApprove = async (userId) => {
        if (!userId) return alert("Identifiant introuvable.");
        if (!window.confirm("Approuver cette entité ?")) return;

        try {
            await axios.post(`${API_BASE_URL}/api/users/${userId}/activate/`, {}, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setEnterprises(prev => prev.map(ent =>
                ent.owner_id === userId ? { ...ent, is_approved: true } : ent
            ));

            alert("Entité activée !");
            fetchEnterprises(); // تحديث القائمة لضمان مزامنة البيانات
        } catch (err) {
            alert("Erreur lors de l'activation.");
        }
    };

    const handleDeactivate = async (userId) => {
        if (!userId) return alert("Identifiant introuvable.");
        if (!window.confirm("Désactiver cette entité ?")) return;

        try {
            await axios.post(`${API_BASE_URL}/api/users/${userId}/deactivate/`, {}, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setEnterprises(prev => prev.map(ent =>
                ent.owner_id === userId ? { ...ent, is_approved: false } : ent
            ));

            alert("Entité désactivée !");
            fetchEnterprises();
        } catch (err) {
            alert("Erreur lors de la désactivation.");
        }
    };

    const handleDelete = async (enterpriseId) => {
        if (!enterpriseId) return;
        if (!window.confirm("Voulez-vous vraiment supprimer définitivement cette entreprise ?")) return;

        try {
            await axios.delete(`${API_BASE_URL}/api/enterprises/${enterpriseId}/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert("Entreprise supprimée !");
            setEnterprises(enterprises.filter(ent => ent.id !== enterpriseId));
        } catch (err) {
            alert("Erreur lors de la suppression.");
        }
    };

    return (
        <div style={styles.container}>
            <header style={styles.header}>
                <div>
                    <h1 style={styles.title}>Gestion des Entités</h1>
                    <p style={styles.subtitle}>Vérifiez les documents et gérez les accès</p>
                </div>
            </header>

            {loading ? (
                <div style={{textAlign: 'center', color: 'var(--text-main)'}}>Chargement...</div>
            ) : (
                <div style={styles.grid}>
                    {enterprises.map(ent => (
                        <div key={ent.id} style={{
                            ...styles.card,
                            border: ent.is_approved ? '2px solid #22c55e' : '2px solid #f59e0b'
                        }}>
                            <div style={{
                                ...styles.statusBadge,
                                backgroundColor: ent.is_approved ? 'rgba(34, 197, 94, 0.2)' : 'rgba(245, 158, 11, 0.2)',
                                color: ent.is_approved ? '#22c55e' : '#f59e0b'
                            }}>
                                {ent.is_approved ? '● ACTIVE' : '● EN ATTENTE'}
                            </div>

                            <div style={styles.cardIcon}>🏢</div>

                            {/* يستخدم الآن ent.name المجهز في الـ Serializer */}
                            <h3 style={styles.cardTitle}>{ent.name || "Nom non défini"}</h3>

                            <p style={styles.cardDesc}>{ent.description || 'Aucune description'}</p>

                            <div style={styles.infoStack}>
                                <div style={styles.dgInfo}>
                                    <strong>👤 Manager:</strong> {ent.dg_name || 'Non assigné'}
                                </div>

                                {/* التحقق من حقل الملف كما هو في الـ Serializer الجديد */}
                                {ent.verification_document ? (
                                    <button
                                        onClick={() => openPreview(ent.verification_document)}
                                        style={styles.viewDocBtn}
                                    >
                                        🔍 Voir le document
                                    </button>
                                ) : (
                                    <span style={{color: '#ef4444', fontSize: '12px', fontWeight: 'bold'}}>
                                        ⚠️ Document manquant
                                    </span>
                                )}
                            </div>

                            <div style={{ marginTop: '20px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
                                {ent.is_approved ? (
                                    <button onClick={() => handleDeactivate(ent.owner_id)} style={styles.deactivateBtn}>
                                        Désactiver l'entité
                                    </button>
                                ) : (
                                    <button onClick={() => handleApprove(ent.owner_id)} style={styles.approveBtn}>
                                        Approuver l'entité
                                    </button>
                                )}

                                <button onClick={() => handleDelete(ent.id)} style={styles.deleteBtn}>
                                    Supprimer l'entreprise
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            {/* Modal Preview */}
            {previewFile && (
                <div style={styles.modalOverlay} onClick={() => setPreviewFile(null)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <div style={styles.modalHeader}>
                            <h3>Aperçu du document</h3>
                            <button onClick={() => setPreviewFile(null)} style={styles.closeBtn}>×</button>
                        </div>
                        <div style={styles.fileContainer}>
                            {fileType === 'pdf' ? (
                                <iframe src={previewFile} style={styles.iframePreview} title="PDF Preview" />
                            ) : (
                                <img src={previewFile} alt="Document" style={styles.imgPreview} />
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

const styles = {
    container: { padding: '40px' },
    header: { marginBottom: '40px' },
    title: { fontSize: '28px', fontWeight: '800' },
    subtitle: { color: 'var(--text-muted)' },
    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '25px' },
    card: {
        position: 'relative',
        background: 'var(--bg-sidebar)',
        padding: '25px',
        borderRadius: '20px',
        textAlign: 'center',
        transition: 'all 0.3s ease'
    },
    statusBadge: {
        position: 'absolute',
        top: '15px',
        right: '15px',
        padding: '5px 10px',
        borderRadius: '12px',
        fontSize: '10px',
        fontWeight: 'bold'
    },
    cardIcon: { fontSize: '40px', marginBottom: '10px' },
    cardTitle: { fontSize: '20px', marginBottom: '10px', color: 'var(--text-main)', fontWeight: 'bold' },
    cardDesc: { color: 'var(--text-muted)', fontSize: '14px', marginBottom: '15px', minHeight: '40px' },
    infoStack: { display: 'flex', flexDirection: 'column', gap: '10px' },
    dgInfo: {
        background: 'rgba(99, 102, 241, 0.1)',
        color: '#6366f1',
        padding: '10px',
        borderRadius: '10px',
        fontSize: '13px',
        border: '1px solid rgba(99, 102, 241, 0.2)'
    },
    viewDocBtn: {
        background: 'rgba(251, 191, 36, 0.1)',
        color: '#fbbf24',
        border: '1px solid #fbbf24',
        padding: '8px',
        borderRadius: '8px',
        cursor: 'pointer',
        fontWeight: 'bold'
    },
    approveBtn: { background: '#22c55e', color: '#fff', border: 'none', padding: '12px', borderRadius: '10px', cursor: 'pointer', width: '100%', fontWeight: 'bold' },
    deactivateBtn: { background: '#f59e0b', color: '#fff', border: 'none', padding: '12px', borderRadius: '10px', cursor: 'pointer', width: '100%', fontWeight: 'bold' },
    deleteBtn: { background: 'transparent', color: '#ef4444', border: '1px solid #ef4444', padding: '10px', borderRadius: '10px', cursor: 'pointer', width: '100%', fontSize: '12px', fontWeight: 'bold' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(0,0,0,0.85)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 3000 },
    modalContent: { background: '#1e1e2e', width: '80%', height: '90%', borderRadius: '20px', display: 'flex', flexDirection: 'column', overflow: 'hidden' },
    modalHeader: { padding: '15px 25px', display: 'flex', justifyContent: 'space-between', alignItems: 'center', borderBottom: '1px solid rgba(255,255,255,0.1)', color: '#fff' },
    closeBtn: { fontSize: '30px', background: 'none', border: 'none', color: '#fff', cursor: 'pointer' },
    fileContainer: { flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '20px', overflowY: 'auto' },
    iframePreview: { width: '100%', height: '100%', border: 'none', borderRadius: '10px', background: '#fff' },
    imgPreview: { maxWidth: '100%', maxHeight: '100%', borderRadius: '10px', objectFit: 'contain' }
};

export default ManageEnterprises;