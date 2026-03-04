import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const VerifyOTP = () => {
    const [otp, setOtp] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const email = localStorage.getItem('pending_email') || "votre email";
    const navigate = useNavigate();

    const handleVerify = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            await axios.post('http://127.0.0.1:8000/api/verify-otp/', { email, otp });
            navigate('/login');
        } catch (err) {
            setError("Le code est incorrect ou expiré.");
        } finally {
            setLoading(false);
        }
    };

    return (
        <div style={styles.container}>
            {/* الخلفية الفنية الموحدة للنظام */}
            <div style={styles.blob1}></div>
            <div style={styles.blob2}></div>

            <div style={styles.glassCard}>
                <div style={styles.iconCircle}>🔐</div>

                <h2 style={styles.title}>Vérification</h2>
                <p style={styles.subtitle}>
                    Nous avons envoyé un code de sécurité à <br />
                    <span style={styles.emailText}>{email}</span>
                </p>

                <form onSubmit={handleVerify} style={styles.form}>
                    <input
                        type="text"
                        placeholder="000000"
                        maxLength="6"
                        required
                        style={styles.otpInput}
                        onChange={(e) => setOtp(e.target.value)}
                    />

                    {error && <div style={styles.errorBox}>{error}</div>}

                    <button type="submit" disabled={loading} style={styles.button(loading)}>
                        {loading ? "Vérification..." : "Vérifier le code"}
                    </button>
                </form>

                <div style={styles.footer}>
                    <p style={styles.footerText}>
                        Vous n'avez pas reçu le code ?
                        <button onClick={() => window.location.reload()} style={styles.resendBtn}>Renvoyer</button>
                    </p>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        minHeight: '100vh', fontFamily: "'Inter', sans-serif",
        position: 'relative', overflow: 'hidden', backgroundColor: '#f8fafc'
    },
    blob1: {
        position: 'absolute', width: '300px', height: '300px', borderRadius: '50%',
        background: 'linear-gradient(135deg, #6366f1 0%, #a855f7 100%)',
        top: '-50px', left: '-50px', filter: 'blur(80px)', zIndex: 0, opacity: 0.2
    },
    blob2: {
        position: 'absolute', width: '300px', height: '300px', borderRadius: '50%',
        background: 'linear-gradient(135deg, #10b981 0%, #3b82f6 100%)',
        bottom: '-50px', right: '-50px', filter: 'blur(80px)', zIndex: 0, opacity: 0.15
    },
    glassCard: {
        backdropFilter: 'blur(20px)', backgroundColor: 'rgba(255, 255, 255, 0.8)',
        borderRadius: '32px', padding: '50px 40px', width: '90%', maxWidth: '420px',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.1)',
        border: '1px solid rgba(255, 255, 255, 0.4)', textAlign: 'center', zIndex: 1
    },
    iconCircle: {
        width: '70px', height: '70px', borderRadius: '50%', backgroundColor: '#f0f4ff',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        margin: '0 auto 25px', fontSize: '30px'
    },
    title: { fontSize: '28px', fontWeight: '800', marginBottom: '10px', color: '#1e293b' },
    subtitle: { fontSize: '15px', color: '#64748b', lineHeight: '1.5', marginBottom: '30px' },
    emailText: { color: '#1e293b', fontWeight: '700' },
    form: { display: 'flex', flexDirection: 'column', gap: '20px' },
    otpInput: {
        width: '100%', padding: '15px', borderRadius: '15px',
        fontSize: '24px', letterSpacing: '8px', textAlign: 'center',
        border: '2px solid #e2e8f0', outline: 'none', transition: '0.3s',
        backgroundColor: 'rgba(255, 255, 255, 0.5)', fontWeight: 'bold', color: '#6366f1'
    },
    button: (loading) => ({
        width: '100%', padding: '16px', borderRadius: '15px', border: 'none',
        backgroundColor: loading ? '#94a3b8' : '#6366f1', color: 'white',
        fontSize: '16px', fontWeight: '700', cursor: loading ? 'not-allowed' : 'pointer',
        boxShadow: '0 10px 15px -3px rgba(99, 102, 241, 0.3)', transition: '0.3s'
    }),
    errorBox: {
        backgroundColor: 'rgba(239, 68, 68, 0.1)', color: '#ef4444',
        padding: '12px', borderRadius: '12px', fontSize: '14px', fontWeight: '500'
    },
    footer: { marginTop: '30px' },
    footerText: { fontSize: '14px', color: '#64748b' },
    resendBtn: {
        background: 'none', border: 'none', color: '#6366f1',
        fontWeight: 'bold', cursor: 'pointer', marginLeft: '5px', textDecoration: 'underline'
    }
};

export default VerifyOTP;