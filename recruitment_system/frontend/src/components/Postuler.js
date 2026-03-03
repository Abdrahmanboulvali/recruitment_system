import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

const Postuler = () => {
    const { offreId } = useParams();
    const navigate = useNavigate();
    const [candidatId, setCandidatId] = useState(null);
    const [loading, setLoading] = useState(false);
    const [hasCheckedProfile, setHasCheckedProfile] = useState(false);
    const [alreadyApplied, setAlreadyApplied] = useState(false); // حالة التحقق من الترشح المسبق

    // حالة بيانات الملف الشخصي
    const [profileForm, setProfileForm] = useState({
        nom: '',
        prenom: '',
        diplome: '',
        experience: 0
    });
    const [cvFile, setCvFile] = useState(null);

    // 1. التحقق من وجود بروفايل ومنع الترشح المزدوج
    useEffect(() => {
        const checkStatus = async () => {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };

                // جلب معلومات المستخدم الحالي
                const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', config);
                const currentUserId = userRes.data.id;

                // جلب قائمة المترشحين للبحث عن بروفايل هذا المستخدم
                const listRes = await axios.get('http://127.0.0.1:8000/api/candidats/', config);
                const profile = listRes.data.find(c => c.user === currentUserId);

                if (profile) {
                    setCandidatId(profile.id);

                    // التحقق مما إذا كان قد تقدم لهذه الوظيفة تحديداً من قبل
                    const candidaturesRes = await axios.get('http://127.0.0.1:8000/api/candidatures/', config);
                    const hasApplied = candidaturesRes.data.some(can =>
                        can.candidat === profile.id && can.offre === parseInt(offreId)
                    );

                    if (hasApplied) {
                        setAlreadyApplied(true);
                    }
                }
            } catch (err) {
                console.error("Erreur lors de la vérification:", err);
            } finally {
                setHasCheckedProfile(true);
            }
        };
        checkStatus();
    }, [offreId]);

    // 2. معالجة العملية: إنشاء البروفايل (إن لم يوجد) ثم إرسال الترشيح
    const handleProcess = async (e) => {
        e.preventDefault();

        if (!cvFile) {
            alert("Veuillez sélectionner votre CV (PDF)");
            return;
        }

        setLoading(true);
        try {
            const token = localStorage.getItem('access');
            const configMultipart = {
                headers: {
                    Authorization: `Bearer ${token}`,
                    'Content-Type': 'multipart/form-data'
                }
            };

            let currentCandidatId = candidatId;

            // أ- إنشاء بروفايل إذا كان المستخدم جديداً
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

            // ب- إرسال الترشيح
            const candidatureData = new FormData();
            candidatureData.append('offre', offreId);
            candidatureData.append('candidat', currentCandidatId);
            candidatureData.append('cv_file', cvFile);
            candidatureData.append('statut', 'En attente');

            await axios.post('http://127.0.0.1:8000/api/candidatures/', candidatureData, configMultipart);

            alert("Succès ! Votre candidature a été transmise avec succès.");
            navigate('/espace-candidat');
        } catch (err) {
            console.error("Erreur API:", err.response?.data);
            alert("Erreur: " + JSON.stringify(err.response?.data || "Problème de connexion"));
        } finally {
            setLoading(false);
        }
    };

    // واجهة الانتظار
    if (!hasCheckedProfile) {
        return <div style={{textAlign: 'center', padding: '50px'}}>Chargement du profil...</div>;
    }

    // واجهة في حال كان قد تقدم مسبقاً
    if (alreadyApplied) {
        return (
            <div style={{ maxWidth: '500px', margin: '100px auto', textAlign: 'center', padding: '30px', border: '1px solid #ffcccc', borderRadius: '15px', background: '#fff5f5' }}>
                <h3 style={{ color: '#d9534f' }}>Candidature déjà envoyée</h3>
                <p style={{ color: '#666' }}>Vous avez déjà postulé pour cette offre. Vous pouvez suivre l'évolution de votre dossier dans votre espace.</p>
                <button
                    onClick={() => navigate('/mes-candidatures')}
                    style={{ marginTop: '20px', padding: '10px 25px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer', fontWeight: 'bold' }}
                >
                    Voir mes candidatures
                </button>
            </div>
        );
    }

    return (
        <div style={{ maxWidth: '600px', margin: '40px auto', padding: '25px', border: '1px solid #ddd', borderRadius: '15px', boxShadow: '0 4px 20px rgba(0,0,0,0.08)', fontFamily: 'Arial, sans-serif' }}>
            <h2 style={{ textAlign: 'center', marginBottom: '30px', color: '#333' }}>Finaliser votre candidature</h2>

            <form onSubmit={handleProcess}>
                {!candidatId && (
                    <div style={{ background: '#f9f9f9', padding: '20px', borderRadius: '10px', marginBottom: '25px', border: '1px solid #eee' }}>
                        <h4 style={{ marginTop: 0, color: '#007bff', marginBottom: '15px' }}>Informations du Profil (Première fois)</h4>
                        <div style={{ display: 'flex', gap: '10px', marginBottom: '15px' }}>
                            <input style={inputStyle} placeholder="Nom" required onChange={e => setProfileForm({...profileForm, nom: e.target.value})} />
                            <input style={inputStyle} placeholder="Prénom" required onChange={e => setProfileForm({...profileForm, prenom: e.target.value})} />
                        </div>
                        <input style={inputStyle} placeholder="Diplôme (ex: Master 2 IT)" required onChange={e => setProfileForm({...profileForm, diplome: e.target.value})} />
                        <div style={{ marginBottom: '10px' }}>
                            <label style={{ fontSize: '13px', color: '#555', display: 'block', marginBottom: '5px' }}>Années d'expérience :</label>
                            <input type="number" style={inputStyle} min="0" required onChange={e => setProfileForm({...profileForm, experience: e.target.value})} />
                        </div>
                    </div>
                )}

                <div style={{ padding: '25px', border: '2px dashed #007bff', borderRadius: '10px', textAlign: 'center', background: '#f0f7ff', marginBottom: '20px' }}>
                    <p style={{ margin: '0 0 15px 0', color: '#555' }}>Postulation pour l'offre n° : <strong>{offreId}</strong></p>
                    <label style={{ display: 'block', marginBottom: '10px', fontWeight: 'bold' }}>Téléchargez votre CV (Format PDF) :</label>
                    <input
                        type="file"
                        accept=".pdf"
                        required
                        onChange={e => setCvFile(e.target.files[0])}
                        style={{ cursor: 'pointer' }}
                    />
                </div>

                <button
                    type="submit"
                    disabled={loading}
                    style={{
                        width: '100%', padding: '15px',
                        backgroundColor: loading ? '#ccc' : '#28a745', color: 'white',
                        border: 'none', borderRadius: '8px', cursor: loading ? 'not-allowed' : 'pointer',
                        fontWeight: 'bold', fontSize: '16px', transition: '0.3s'
                    }}
                >
                    {loading ? "Traitement en cours..." : (candidatId ? "Confirmer la postulation" : "Enregistrer et Postuler")}
                </button>
            </form>
        </div>
    );
};

const inputStyle = {
    width: '100%',
    padding: '12px',
    borderRadius: '6px',
    border: '1px solid #ccc',
    boxSizing: 'border-box',
    marginBottom: '10px',
    fontSize: '14px'
};

export default Postuler;