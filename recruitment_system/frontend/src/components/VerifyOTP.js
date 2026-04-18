import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { FiArrowLeft } from 'react-icons/fi';

const VerifyOTP = () => {
    const [otp, setOtp] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const [email, setEmail] = useState('');
    const [timer, setTimer] = useState(120);
    const [canResend, setCanResend] = useState(false);
    const navigate = useNavigate();

    useEffect(() => {
        const pendingEmail = localStorage.getItem('pending_email');
        if (!pendingEmail) {
            setError("Session expirée. Veuillez vous réinscrire.");
        } else {
            setEmail(pendingEmail);
        }

        const countdown = setInterval(() => {
            setTimer((prev) => {
                if (prev <= 1) {
                    clearInterval(countdown);
                    setCanResend(true);
                    return 0;
                }
                return prev - 1;
            });
        }, 1000);

        return () => clearInterval(countdown);
    }, []);

    const formatTime = (seconds) => {
        const minutes = Math.floor(seconds / 60);
        const secs = seconds % 60;
        return `${minutes}:${secs < 10 ? '0' : ''}${secs}`;
    };

    const handleVerify = async (e) => {
        e.preventDefault();
        if (!email) return;
        setLoading(true);
        setError('');

        try {
            // تصحيح: إضافة /api/ لمنع خطأ 404 بناءً على سجلات السيرفر
            const response = await axios.post('http://127.0.0.1:8000/api/verify-otp/', {
                email: email,
                otp: otp
            });

            // حذف الإيميل من التخزين المؤقت بعد نجاح العملية
            localStorage.removeItem('pending_email');

            if (response.status === 200) {
                // حالة المترشح (تفعيل فوري)
                alert("Compte activé avec succès !");
                navigate('/login');
            } else if (response.status === 202) {
                // حالة الشركات/المؤسسات (انتظار مراجعة الإدارة)
                alert("Email vérifié ! Votre compte est en attente d'approbation par l'administration.");
                navigate('/login');
            }
        } catch (err) {
            // عرض رسالة الخطأ القادمة من Django أو رسالة افتراضية
            console.error("Verification Error:", err.response?.data);
            setError(err.response?.data?.error || "Code incorrect ou expiré.");
        } finally {
            setLoading(false);
        }
    };

    const handleResend = async () => {
        if (!canResend) return;
        try {
            // تصحيح: إضافة /api/ لضمان الوصول للمسار الصحيح
            await axios.post('http://127.0.0.1:8000/api/resend-otp/', { email });
            setTimer(120);
            setCanResend(false);
            setError('');
            alert("Un nouveau code a été envoyé.");
        } catch (err) {
            alert("Erreur lors de l'envoi du code.");
        }
    };

    return (
        <div style={styles.container}>
            <div style={styles.blob1}></div>
            <div style={styles.blob2}></div>

            <div style={styles.glassCard}>
                <button onClick={() => navigate('/register')} style={styles.backBtn}>
                    <FiArrowLeft size={20} />
                </button>

                <div style={styles.iconCircle}>🔐</div>

                <h2 style={styles.title}>Vérification</h2>
                <p style={styles.subtitle}>
                    Nous avons envoyé un code de sécurité à <br />
                    <span style={styles.emailText}>{email || "votre email"}</span>
                </p>

                <form onSubmit={handleVerify} style={styles.form}>
                    <input
                        type="text"
                        placeholder="000000"
                        maxLength="6"
                        required
                        autoFocus
                        style={styles.otpInput(error)}
                        value={otp}
                        onChange={(e) => setOtp(e.target.value.replace(/\D/g, ""))}
                    />

                    <div style={styles.timerBox}>
                        {timer > 0 ? (
                            <span>Le code expire dans : <strong style={{color: '#6366f1'}}>{formatTime(timer)}</strong></span>
                        ) : (
                            <span style={{color: '#ef4444'}}>Le code a expiré</span>
                        )}
                    </div>

                    {error && <div style={styles.errorBox}>{error}</div>}

                    <button
                        type="submit"
                        disabled={loading || otp.length !== 6}
                        style={styles.button(loading || otp.length !== 6)}
                    >
                        {loading ? "Vérification..." : "Vérifier le code"}
                    </button>
                </form>

                <div style={styles.footer}>
                    <p style={styles.footerText}>
                        Vous n'avez pas reçu le code ?
                        <button
                            onClick={handleResend}
                            disabled={!canResend}
                            style={styles.resendBtn(canResend)}
                        >
                            Renvoyer
                        </button>
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
    backBtn: {
        position: 'absolute', top: '25px', left: '25px',
        background: '#fff', border: '1px solid #e2e8f0', borderRadius: '50%',
        width: '40px', height: '40px', display: 'flex', alignItems: 'center',
        justifyContent: 'center', cursor: 'pointer', color: '#64748b',
        boxShadow: '0 4px 6px rgba(0,0,0,0.05)', transition: '0.3s'
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
        position: 'relative', backdropFilter: 'blur(20px)', backgroundColor: 'rgba(255, 255, 255, 0.8)',
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
    otpInput: (isError) => ({
        width: '100%', padding: '15px', borderRadius: '15px',
        fontSize: '28px', letterSpacing: '10px', textAlign: 'center',
        border: `2px solid ${isError ? '#ef4444' : '#e2e8f0'}`, outline: 'none',
        transition: '0.3s', backgroundColor: 'rgba(255, 255, 255, 0.5)',
        fontWeight: 'bold', color: '#6366f1'
    }),
    timerBox: { fontSize: '14px', color: '#64748b' },
    button: (disabled) => ({
        width: '100%', padding: '16px', borderRadius: '15px', border: 'none',
        backgroundColor: disabled ? '#cbd5e1' : '#6366f1', color: 'white',
        fontSize: '16px', fontWeight: '700', cursor: disabled ? 'not-allowed' : 'pointer',
        boxShadow: disabled ? 'none' : '0 10px 15px -3px rgba(99, 102, 241, 0.3)',
        transition: '0.3s'
    }),
    errorBox: {
        backgroundColor: 'rgba(239, 68, 68, 0.1)', color: '#ef4444',
        padding: '12px', borderRadius: '12px', fontSize: '14px', fontWeight: '500'
    },
    footer: { marginTop: '30px' },
    footerText: { fontSize: '14px', color: '#64748b' },
    resendBtn: (active) => ({
        background: 'none', border: 'none', color: active ? '#6366f1' : '#cbd5e1',
        fontWeight: 'bold', cursor: active ? 'pointer' : 'not-allowed',
        marginLeft: '5px', textDecoration: active ? 'underline' : 'none'
    })
};

export default VerifyOTP;