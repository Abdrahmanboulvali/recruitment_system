import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

const Postuler = () => {
    const { offreId } = useParams();
    const navigate = useNavigate();
    const [candidatId, setCandidatId] = useState(null);
    const [loading, setLoading] = useState(false);
    const [hasCheckedProfile, setHasCheckedProfile] = useState(false);
    const [alreadyApplied, setAlreadyApplied] = useState(false);

    const [profileForm, setProfileForm] = useState({ nom: '', prenom: '', diplome: '', experience: 0 });
    const [cvFile, setCvFile] = useState(null);

    useEffect(() => {
        const checkStatus = async () => {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };
                const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', config);
                const currentUserId = userRes.data.id;

                const listRes = await axios.get('http://127.0.0.1:8000/api/candidats/', config);
                const profile = listRes.data.find(c => c.user === currentUserId);

                if (profile) {
                    setCandidatId(profile.id);
                    const candidaturesRes = await axios.get('http://127.0.0.1:8000/api/candidatures/', config);
                    const hasApplied = candidaturesRes.data.some(can =>
                        can.candidat === profile.id && can.offre === parseInt(offreId)
                    );
                    if (hasApplied) setAlreadyApplied(true);
                }
            } catch (err) {
                console.error("Erreur checkStatus:", err);
            } finally {
                setHasCheckedProfile(true);
            }
        };
        checkStatus();
    }, [offreId]);

    const handleProcess = async (e) => {
        e.preventDefault();
        if (!cvFile) return alert("Veuillez sélectionner votre CV (PDF)");

        setLoading(true);
        try {
            const token = localStorage.getItem('access');
            const configMultipart = {
                headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
            };

            let currentCandidatId = candidatId;

            if (!currentCandidatId) {
                const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', {
                    headers: { Authorization: `Bearer ${token}` }
                });

                const profileData = new FormData();
                profileData.append('user', userRes.data.id);
                profileData.append('nom', profileForm.nom);
                profileData.append('prenom', profileForm.prenom);
                profileData.append('diplome', profileForm.diplome);
                profileData.append('experience', profileForm.experience);
                profileData.append('cv_file', cvFile);

                const newProfile = await axios.post('http://127.0.0.1:8000/api/candidats/', profileData, configMultipart);
                currentCandidatId = newProfile.data.id;
            }

            const candidatureData = new FormData();
            candidatureData.append('offre', offreId);
            candidatureData.append('candidat', currentCandidatId);
            candidatureData.append('cv_file', cvFile);
            candidatureData.append('statut', 'En attente');

            await axios.post('http://127.0.0.1:8000/api/candidatures/', candidatureData, configMultipart);
            alert("Succès ! Votre candidature a été transmise.");
            navigate('/espace-candidat');
        } catch (err) {
            alert("Erreur lors de la postulation");
        } finally {
            setLoading(false);
        }
    };

    if (!hasCheckedProfile) return <div style={styles.loadingText}>Vérification du profil...</div>;

    if (alreadyApplied) {
        return (
            <div style={styles.alertCard}>
                <div style={styles.iconCircle('#ef4444')}>⚠️</div>
                <h3 style={{ color: '#ef4444', marginBottom: '10px' }}>Déjà postulé</h3>
                <p style={{ opacity: 0.8 }}>Vous avez déjà soumis votre candidature pour ce poste. Vous ne pouvez pas postuler deux fois.</p>
                <button onClick={() => navigate('/mes-candidatures')} style={styles.secondaryBtn}>
                    Suivre ma candidature
                </button>
            </div>
        );
    }

    return (
        <div style={styles.pageContainer}>
            <div style={styles.glassContainer}>
                <h2 style={styles.title}>Finaliser votre candidature</h2>
                <p style={styles.subtitle}>Plus qu'une étape pour postuler à l'offre <strong>#{offreId}</strong></p>

                <form onSubmit={handleProcess}>
                    {!candidatId && (
                        <div style={styles.profileSection}>
                            <h4 style={styles.sectionTitle}>📝 Informations personnelles</h4>
                            <div style={styles.inputGroup}>
                                <input style={styles.glassInput} placeholder="Nom" required onChange={e => setProfileForm({...profileForm, nom: e.target.value})} />
                                <input style={styles.glassInput} placeholder="Prénom" required onChange={e => setProfileForm({...profileForm, prenom: e.target.value})} />
                            </div>
                            <input style={styles.glassInput} placeholder="Dernier diplôme obtenu" required onChange={e => setProfileForm({...profileForm, diplome: e.target.value})} />
                            <div style={styles.labelGroup}>
                                <label style={styles.label}>Années d'expérience :</label>
                                <input type="number" style={{...styles.glassInput, width: '100px'}} min="0" required onChange={e => setProfileForm({...profileForm, experience: e.target.value})} />
                            </div>
                        </div>
                    )}

                    <div style={styles.uploadBox}>
                        <div style={styles.uploadIcon}>📄</div>
                        <p style={{ margin: '10px 0', fontWeight: '600' }}>Votre CV (Format PDF uniquement)</p>
                        <input
                            type="file"
                            accept=".pdf"
                            required
                            onChange={e => setCvFile(e.target.files[0])}
                            style={styles.fileInput}
                        />
                        {cvFile && <p style={styles.fileName}>✅ {cvFile.name}</p>}
                    </div>

                    <button type="submit" disabled={loading} style={styles.submitBtn(loading)}>
                        {loading ? "Envoi en cours..." : (candidatId ? "Confirmer la postulation" : "Créer mon profil & Postuler")}
                    </button>
                </form>
            </div>
        </div>
    );
};

const styles = {
    pageContainer: { padding: '40px 20px', display: 'flex', justifyContent: 'center' },
    glassContainer: {
        background: 'rgba(255, 255, 255, 0.05)', backdropFilter: 'blur(15px)',
        borderRadius: '24px', padding: '40px', width: '100%', maxWidth: '600px',
        border: '1px solid rgba(255, 255, 255, 0.1)', boxShadow: '0 20px 40px rgba(0,0,0,0.2)'
    },
    title: { textAlign: 'center', fontSize: '28px', fontWeight: '800', marginBottom: '10px' },
    subtitle: { textAlign: 'center', opacity: 0.7, marginBottom: '30px' },
    profileSection: {
        background: 'rgba(255, 255, 255, 0.03)', padding: '20px', borderRadius: '15px',
        border: '1px solid rgba(255, 255, 255, 0.05)', marginBottom: '25px'
    },
    sectionTitle: { marginTop: 0, fontSize: '16px', marginBottom: '15px' },
    inputGroup: { display: 'flex', gap: '10px', marginBottom: '15px' },
    glassInput: {
        width: '100%', padding: '12px 15px', borderRadius: '10px',
        border: '1px solid rgba(255, 255, 255, 0.1)', background: 'rgba(255, 255, 255, 0.05)',
        color: 'inherit', outline: 'none', marginBottom: '15px'
    },
    labelGroup: { display: 'flex', alignItems: 'center', gap: '15px' },
    label: { fontSize: '14px', opacity: 0.8 },
    uploadBox: {
        padding: '30px', border: '2px dashed rgba(99, 102, 241, 0.3)', borderRadius: '15px',
        textAlign: 'center', background: 'rgba(99, 102, 241, 0.05)', marginBottom: '30px'
    },
    uploadIcon: { fontSize: '30px', marginBottom: '10px' },
    fileInput: { cursor: 'pointer', fontSize: '14px' },
    fileName: { marginTop: '10px', fontSize: '12px', color: '#10b981', fontWeight: 'bold' },
    submitBtn: (loading) => ({
        width: '100%', padding: '16px', borderRadius: '12px', border: 'none',
        backgroundColor: loading ? '#64748b' : '#6366f1', color: 'white',
        fontWeight: 'bold', fontSize: '16px', cursor: loading ? 'not-allowed' : 'pointer',
        boxShadow: '0 10px 15px -3px rgba(99, 102, 241, 0.3)', transition: '0.3s'
    }),
    alertCard: {
        maxWidth: '500px', margin: '100px auto', textAlign: 'center', padding: '40px',
        background: 'rgba(239, 68, 68, 0.05)', borderRadius: '24px', border: '1px solid rgba(239, 68, 68, 0.1)'
    },
    iconCircle: (color) => ({
        width: '60px', height: '60px', borderRadius: '50%', backgroundColor: `${color}20`,
        color: color, display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontSize: '30px', margin: '0 auto 20px auto'
    }),
    secondaryBtn: {
        marginTop: '20px', padding: '12px 25px', backgroundColor: 'transparent',
        border: '1px solid #6366f1', color: '#6366f1', borderRadius: '10px',
        fontWeight: 'bold', cursor: 'pointer'
    },
    loadingText: { textAlign: 'center', padding: '100px', fontWeight: 'bold' }
};

export default Postuler;