import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';

const Login = () => {
    const [formData, setFormData] = useState({ email: '', password: '' });
    const [error, setError] = useState('');
    const [isDarkMode, setIsDarkMode] = useState(false); // حالة الوضع المظلم
    const navigate = useNavigate();

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const toggleTheme = () => setIsDarkMode(!isDarkMode);

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('http://127.0.0.1:8000/auth/jwt/create/', formData);
            const accessToken = response.data.access;
            localStorage.setItem('access', accessToken);

            const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', {
                headers: { Authorization: `Bearer ${accessToken}` }
            });

            const rawRole = userRes.data.role.toUpperCase();
            localStorage.setItem('role', rawRole);

            if (rawRole === 'CANDIDAT') {
                navigate('/espace-candidat');
            } else if (rawRole === 'ADMIN' || rawRole === 'ADMINISTRATEUR' || rawRole === 'AGENTRH') {
                navigate('/dashboard');
            }
        } catch (err) {
            setError("Email ou mot de passe incorrect.");
        }
    };

    // تعريف الألوان بناءً على الوضع
    const theme = {
        background: isDarkMode ? '#0f172a' : '#f8fafc',
        cardBg: isDarkMode ? 'rgba(30, 41, 59, 0.7)' : 'rgba(255, 255, 255, 0.9)',
        text: isDarkMode ? '#f8fafc' : '#1e293b',
        subText: isDarkMode ? '#94a3b8' : '#64748b',
        inputBg: isDarkMode ? '#1e293b' : '#ffffff',
        inputBorder: isDarkMode ? '#334155' : '#e2e8f0',
        button: '#6366f1'
    };

    return (
        <div style={{ ...styles.container, backgroundColor: theme.background }}>
            {/* زر تبديل الوضع العلوي */}
            <button onClick={toggleTheme} style={styles.themeToggle}>
                {isDarkMode ? '☀️ Mode Clair' : '🌙 Mode Sombre'}
            </button>

            <div style={{ ...styles.glassCard, backgroundColor: theme.cardBg, color: theme.text }}>
                <div style={styles.headerSection}>
                    <h2 style={{ ...styles.title, color: theme.text }}>Connexion</h2>
                    <p style={{ ...styles.subtitle, color: theme.subText }}>Accédez à votre compte professionnel</p>
                </div>

                <form onSubmit={handleSubmit} style={styles.form}>
                    <div style={styles.inputGroup}>
                        <input
                            type="email"
                            name="email"
                            placeholder="Email"
                            style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                            onChange={handleChange}
                            required
                        />
                    </div>

                    <div style={styles.inputGroup}>
                        <input
                            type="password"
                            name="password"
                            placeholder="Mot de passe"
                            style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                            onChange={handleChange}
                            required
                        />
                    </div>

                    {error && <p style={styles.errorText}>{error}</p>}

                    <button type="submit" style={{ ...styles.button, backgroundColor: theme.button }}>
                        Se connecter
                    </button>
                </form>

                <div style={styles.footer}>
                    <p style={{ ...styles.footerText, color: theme.subText }}>
                        Vous n'avez pas de compte ?
                        <Link to="/register" style={{ ...styles.registerLink, color: theme.button }}> Créer un compte</Link>
                    </p>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: {
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        minHeight: '100vh',
        transition: 'all 0.4s ease',
        fontFamily: "'Inter', sans-serif",
        position: 'relative'
    },
    themeToggle: {
        position: 'absolute',
        top: '20px',
        right: '20px',
        padding: '10px 15px',
        borderRadius: '20px',
        border: 'none',
        cursor: 'pointer',
        fontWeight: 'bold',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
        backgroundColor: '#6366f1',
        color: 'white'
    },
    glassCard: {
        backdropFilter: 'blur(12px)',
        borderRadius: '24px',
        padding: '50px 40px',
        width: '100%',
        maxWidth: '400px',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        textAlign: 'center',
        transition: 'all 0.4s ease',
    },
    headerSection: { marginBottom: '35px' },
    title: { fontSize: '32px', fontWeight: 'bold', margin: '0 0 10px 0' },
    subtitle: { fontSize: '15px', margin: 0 },
    form: { display: 'flex', flexDirection: 'column', gap: '20px' },
    input: {
        width: '100%',
        padding: '15px 20px',
        borderRadius: '12px',
        fontSize: '16px',
        outline: 'none',
        boxSizing: 'border-box',
        transition: 'all 0.3s ease',
    },
    button: {
        padding: '16px',
        borderRadius: '12px',
        border: 'none',
        color: '#fff',
        fontSize: '17px',
        fontWeight: 'bold',
        cursor: 'pointer',
        boxShadow: '0 10px 15px -3px rgba(99, 102, 241, 0.4)',
        transition: 'transform 0.2s',
    },
    errorText: { color: '#ef4444', fontSize: '14px', margin: '0' },
    footer: { marginTop: '30px' },
    footerText: { fontSize: '14px' },
    registerLink: { textDecoration: 'none', fontWeight: 'bold', marginLeft: '5px' }
};

export default Login;