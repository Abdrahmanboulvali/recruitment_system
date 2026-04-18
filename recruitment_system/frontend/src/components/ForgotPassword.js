import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { FiArrowLeft, FiSun, FiMoon } from 'react-icons/fi';

const ForgotPassword = () => {
    const [step, setStep] = useState(1);
    const [email, setEmail] = useState('');
    const [otp, setOtp] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [message, setMessage] = useState('');
    const navigate = useNavigate();

    // 1. إدارة حالة المظهر
    const [isDarkMode, setIsDarkMode] = useState(localStorage.getItem('theme') === 'dark');

    // 2. وظيفة التبديل (معدلة لتجبر المتصفح على قراءة التغيير)
    const applyTheme = (theme) => {
        if (theme === 'dark') {
            document.documentElement.classList.add('dark');
            document.documentElement.setAttribute('data-theme', 'dark');
            // التأكد من تغيير خلفية الصفحة بالكامل لتجنب "التعاقب"
            document.body.style.backgroundColor = '#0f172a';
        } else {
            document.documentElement.classList.remove('dark');
            document.documentElement.setAttribute('data-theme', 'light');
            document.body.style.backgroundColor = '#ffffff';
        }
    };

    const toggleTheme = () => {
        const newTheme = isDarkMode ? 'light' : 'dark';
        setIsDarkMode(!isDarkMode);
        localStorage.setItem('theme', newTheme);
        applyTheme(newTheme);
    };

    // 3. عند تحميل الصفحة لأول مرة
    useEffect(() => {
        const savedTheme = localStorage.getItem('theme') || 'dark';
        applyTheme(savedTheme);
    }, []);

    const handleSendOTP = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://127.0.0.1:8000/api/auth/forgot-password/', { email });
            setStep(2);
            setMessage("Un code a été envoyé à votre email.");
        } catch (err) {
            setMessage("Erreur lors de l'envoi du code.");
        }
    };

    const handleResetPassword = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://127.0.0.1:8000/api/auth/reset-password/', {
                email,
                otp,
                new_password: newPassword
            });
            alert("Mot de passe modifié avec succès !");
            navigate('/login');
        } catch (err) {
            setMessage("Code OTP incorrect ou expiré.");
        }
    };

    return (
        <div style={{...styles.pageWrapper, backgroundColor: isDarkMode ? '#0f172a' : '#ffffff'}}>
            {/* زر تبديل الوضع (موضع ثابت في الزاوية) */}
            <button onClick={toggleTheme} style={styles.themeToggle}>
                {isDarkMode ? <FiSun size={20} color="#facc15" /> : <FiMoon size={20} color="#6366f1" />}
            </button>

            <div style={{
                ...styles.card,
                backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#f8fafc',
                border: isDarkMode ? 'none' : '1px solid #e2e8f0'
            }}>
                {/* زر الرجوع */}
                <button onClick={() => step === 2 ? setStep(1) : navigate('/login')} style={styles.backBtn}>
                    <FiArrowLeft size={24} />
                </button>

                <h2 style={{ color: isDarkMode ? 'var(--text-main)' : '#1e293b', marginBottom: '10px' }}>
                    {step === 1 ? "Récupération" : "Nouveau mot de passe"}
                </h2>

                <p style={{ fontSize: '14px', color: '#ef4444', minHeight: '20px' }}>{message}</p>

                <form onSubmit={step === 1 ? handleSendOTP : handleResetPassword} style={styles.form}>
                    <input
                        type="email" placeholder="Email" value={email}
                        style={{
                            ...styles.input,
                            backgroundColor: isDarkMode ? 'var(--bg-main)' : '#ffffff',
                            color: isDarkMode ? 'white' : '#1e293b',
                            borderColor: isDarkMode ? 'rgba(128,128,128,0.2)' : '#cbd5e1'
                        }}
                        onChange={(e) => setEmail(e.target.value)} required
                        disabled={step === 2}
                    />

                    {step === 2 && (
                        <>
                            <input
                                type="text" placeholder="Code OTP" value={otp}
                                style={{
                                    ...styles.input,
                                    backgroundColor: isDarkMode ? 'var(--bg-main)' : '#ffffff',
                                    color: isDarkMode ? 'white' : '#1e293b'
                                }}
                                onChange={(e) => setOtp(e.target.value)} required
                            />
                            <input
                                type="password" placeholder="Nouveau mot de passe" value={newPassword}
                                style={{
                                    ...styles.input,
                                    backgroundColor: isDarkMode ? 'var(--bg-main)' : '#ffffff',
                                    color: isDarkMode ? 'white' : '#1e293b'
                                }}
                                onChange={(e) => setNewPassword(e.target.value)} required
                            />
                        </>
                    )}

                    <button type="submit" style={styles.button}>
                        {step === 1 ? "Envoyer le code" : "Réinitialiser"}
                    </button>
                </form>
            </div>
        </div>
    );
};

const styles = {
    pageWrapper: {
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        minHeight: '100vh', transition: 'all 0.3s ease', position: 'relative'
    },
    card: {
        padding: '40px', borderRadius: '24px',
        width: '380px', textAlign: 'center',
        boxShadow: '0 10px 25px rgba(0,0,0,0.1)',
        position: 'relative'
    },
    backBtn: {
        position: 'absolute', top: '20px', left: '20px',
        background: 'transparent', border: 'none',
        color: '#6366f1', cursor: 'pointer'
    },
    themeToggle: {
        position: 'absolute', top: '30px', right: '30px',
        background: 'var(--bg-sidebar)', border: '1px solid rgba(128,128,128,0.3)',
        padding: '10px', borderRadius: '12px', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center'
    },
    form: { display: 'flex', flexDirection: 'column', gap: '18px', marginTop: '20px' },
    input: {
        padding: '14px', borderRadius: '12px',
        border: '1px solid', outline: 'none', fontSize: '15px'
    },
    button: {
        padding: '14px', borderRadius: '12px', border: 'none',
        backgroundColor: '#6366f1', color: 'white',
        fontWeight: 'bold', cursor: 'pointer', fontSize: '16px'
    }
};

export default ForgotPassword;