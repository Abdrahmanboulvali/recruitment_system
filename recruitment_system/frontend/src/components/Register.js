import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';
import '../App.css'; // التأكد من العودة للمجلد الرئيسي للوصول للملف

const Register = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({ email: '', username: '', password: '', re_password: '' });
    const [isDarkMode, setIsDarkMode] = useState(true);

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });
    const toggleTheme = () => setIsDarkMode(!isDarkMode);

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://127.0.0.1:8000/auth/users/', formData);
            navigate('/login');
        } catch (err) {
            console.error(err);
        }
    };

    // نفس منطق الألوان المحسن لصفحة الدخول
    const theme = {
        background: isDarkMode ? 'var(--bg-main)' : '#f8fafc',
        cardBg: isDarkMode ? 'var(--bg-sidebar)' : 'rgba(255, 255, 255, 0.9)',
        text: isDarkMode ? 'var(--text-main)' : '#1e293b',
        inputBg: isDarkMode ? 'rgba(15, 23, 42, 0.5)' : '#ffffff',
        inputBorder: isDarkMode ? 'rgba(255, 255, 255, 0.1)' : '#e2e8f0',
        buttonGradient: 'linear-gradient(135deg, #6366f1 0%, #4338ca 100%)',
        buttonShadow: '0 12px 20px rgba(99, 102, 241, 0.4)'
    };

    return (
        <div style={{ ...styles.container, backgroundColor: theme.background }}>
            <button onClick={toggleTheme} style={styles.themeToggle}>
                {isDarkMode ? '☀️ Mode Clair' : '🌙 Mode Sombre'}
            </button>
            <div style={{
                ...styles.glassCard,
                backgroundColor: theme.cardBg,
                color: theme.text,
                animation: 'fadeInUp 0.6s ease-out'
            }}>
                <div style={styles.headerSection}>
                    <h2 style={styles.title}>Créer un compte</h2>
                    <p style={{color: isDarkMode ? 'var(--text-muted)' : '#64748b', fontSize: '14px', marginTop: '10px'}}>
                        Rejoignez notre plateforme de recrutement
                    </p>
                </div>
                <form onSubmit={handleSubmit} style={styles.form}>
                    <input type="text" name="username" placeholder="Nom d'utilisateur"
                        style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                        onChange={handleChange} required />

                    <input type="email" name="email" placeholder="E-mail"
                        style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                        onChange={handleChange} required />

                    <input type="password" name="password" placeholder="Mot de passe"
                        style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                        onChange={handleChange} required />

                    <input type="password" name="re_password" placeholder="Confirmer le mot de passe"
                        style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                        onChange={handleChange} required />

                    <button type="submit" style={{
                        ...styles.button,
                        background: theme.buttonGradient,
                        boxShadow: theme.buttonShadow
                    }}>
                        S'inscrire
                    </button>
                </form>
                <div style={styles.footer}>
                    <p style={{fontSize: '14px'}}>
                        Déjà inscrit ? <Link to="/login" style={styles.link}>Se connecter</Link>
                    </p>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex', justifyContent: 'center', alignItems: 'center',
        minHeight: '100vh', width: '100vw', position: 'fixed',
        top: 0, left: 0, zIndex: 9999, transition: 'all 0.5s ease',
        fontFamily: "'Inter', sans-serif",
    },
    themeToggle: {
        position: 'absolute', top: '30px', right: '30px',
        padding: '12px 24px', borderRadius: '30px', border: 'none',
        cursor: 'pointer', backgroundColor: '#6366f1', color: 'white',
        fontWeight: 'bold', boxShadow: '0 10px 15px rgba(0,0,0,0.2)', zIndex: 10000
    },
    glassCard: {
        backdropFilter: 'blur(16px) saturate(180%)',
        borderRadius: '28px', padding: '40px',
        width: '90%', maxWidth: '450px',
        boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.5)',
        border: '1px solid rgba(255, 255, 255, 0.1)', textAlign: 'center'
    },
    headerSection: { marginBottom: '30px' },
    title: { fontSize: '34px', fontWeight: '800', margin: '0', letterSpacing: '-1px' },
    form: { display: 'flex', flexDirection: 'column', gap: '18px' },
    input: {
        width: '100%', padding: '16px 20px', borderRadius: '14px',
        fontSize: '15px', outline: 'none', boxSizing: 'border-box',
        transition: 'all 0.3s ease'
    },
    button: {
        padding: '16px', borderRadius: '14px', border: 'none',
        color: '#fff', fontSize: '17px', fontWeight: '800',
        cursor: 'pointer', transition: 'transform 0.2s', marginTop: '10px'
    },
    footer: { marginTop: '25px' },
    link: { textDecoration: 'none', fontWeight: '800', color: '#6366f1', marginLeft: '5px' }
};

export default Register;