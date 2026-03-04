import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

const Activate = () => {
    const { uid, token } = useParams();
    const navigate = useNavigate();
    const [activated, setActivated] = useState(false);
    const [error, setError] = useState(false);
    const [loading, setLoading] = useState(false);

    const handleActivation = async () => {
        setLoading(true);
        try {
            await axios.post('http://127.0.0.1:8000/auth/users/activation/', { uid, token });
            setActivated(true);
            setTimeout(() => navigate('/login'), 4000);
        } catch (err) {
            setError(true);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            {/* الدوائر الفنية الخلفية المتناسقة مع صفحة الـ Login */}
            <div style={styles.blob1}></div>
            <div style={styles.blob2}></div>

            <div style={styles.glassCard}>
                <div style={styles.iconCircle}>
                    {activated ? '✅' : error ? '❌' : '✉️'}
                </div>

                <h2 style={styles.title}>Activation du compte</h2>

                {!activated && !error && (
                    <div style={styles.content}>
                        <p style={styles.subtitle}>
                            Merci de confirmer votre inscription pour accéder à toutes nos fonctionnalités.
                        </p>
                        <button
                            onClick={handleActivation}
                            disabled={loading}
                            style={styles.button(loading)}
                        >
                            {loading ? "Traitement..." : "Confirmer l'activation"}
                        </button>
                    </div>
                )}

                {activated && (
                    <div style={styles.successBox}>
                        <p style={styles.successText}>Félicitations ! Votre compte est désormais actif.</p>
                        <p style={styles.redirectText}>Redirection automatique vers la page de connexion...</p>
                    </div>
                )}

                {error && (
                    <div style={styles.errorBox}>
                        <p style={styles.errorText}>Le lien est invalide ou a déjà été utilisé.</p>
                        <button onClick={() => navigate('/register')} style={styles.secondaryBtn}>
                            S'inscrire à nouveau
                        </button>
                    </div>
                )}
            </div>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        minHeight: '100vh', fontFamily: "'Inter', sans-serif",
        position: 'relative', overflow: 'hidden', backgroundColor: '#f8fafc' // يتبع الثيم الفاتح افتراضياً
    },
    blob1: {
        position: 'absolute', width: '300px', height: '300px', borderRadius: '50%',
        background: 'linear-gradient(135deg, #10b981 0%, #3b82f6 100%)',
        top: '-50px', left: '-50px', filter: 'blur(80px)', zIndex: 0, opacity: 0.2
    },
    blob2: {
        position: 'absolute', width: '300px', height: '300px', borderRadius: '50%',
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
        bottom: '-50px', right: '-50px', filter: 'blur(80px)', zIndex: 0, opacity: 0.2
    },
    glassCard: {
        backdropFilter: 'blur(20px)', backgroundColor: 'rgba(255, 255, 255, 0.8)',
        borderRadius: '32px', padding: '50px 40px', width: '90%', maxWidth: '450px',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.1)',
        border: '1px solid rgba(255, 255, 255, 0.3)', textAlign: 'center', zIndex: 1
    },
    iconCircle: {
        width: '70px', height: '70px', borderRadius: '50%', backgroundColor: '#f0f4ff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        margin: '0 auto 25px', fontSize: '30px', boxShadow: '0 10px 15px -3px rgba(0,0,0,0.05)'
    },
    title: { fontSize: '28px', fontWeight: '800', marginBottom: '15px', color: '#1e293b' },
    subtitle: { fontSize: '15px', color: '#64748b', lineHeight: '1.6', marginBottom: '30px' },
    button: (loading) => ({
        width: '100%', padding: '16px', borderRadius: '15px', border: 'none',
        backgroundColor: loading ? '#94a3b8' : '#10b981', color: 'white',
        fontSize: '16px', fontWeight: '700', cursor: loading ? 'not-allowed' : 'pointer',
        boxShadow: '0 10px 15px -3px rgba(16, 185, 129, 0.3)', transition: '0.3s'
    }),
    successBox: { marginTop: '10px' },
    successText: { color: '#10b981', fontWeight: '700', fontSize: '16px' },
    redirectText: { fontSize: '13px', color: '#64748b', marginTop: '10px' },
    errorBox: { marginTop: '10px' },
    errorText: { color: '#ef4444', fontWeight: '600', marginBottom: '20px' },
    secondaryBtn: {
        background: 'none', border: '1px solid #6366f1', color: '#6366f1',
        padding: '10px 20px', borderRadius: '12px', cursor: 'pointer', fontWeight: '600'
    }
};

export default Activate;