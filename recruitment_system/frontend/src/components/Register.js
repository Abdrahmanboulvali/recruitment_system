import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';

const Register = () => {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        email: '',
        username: '',
        password: '',
        re_password: ''
    });

    const [message, setMessage] = useState('');
    const [isError, setIsError] = useState(false);
    const [isDarkMode, setIsDarkMode] = useState(false); // ميزة الوضع المظلم

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });
    const toggleTheme = () => setIsDarkMode(!isDarkMode);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setIsError(false);

        try {
            await axios.post('http://127.0.0.1:8000/auth/users/', formData);
            localStorage.setItem('pending_email', formData.email);
            navigate('/verify-otp');
        } catch (err) {
            setMessage('Échec de l\'inscription. Veuillez vérifier vos informations ou si l\'utilisateur existe déjà.');
            setIsError(true);
        }
    };

    // تعريف الألوان بناءً على الوضع المختار
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
                    <h2 style={{ ...styles.title, color: theme.text }}>Créer un compte</h2>
                    <p style={{ ...styles.subtitle, color: theme.subText }}>Rejoignez notre plateforme de recrutement</p>
                </div>

                <form onSubmit={handleSubmit} style={styles.form}>
                    <div style={styles.inputGroup}>
                        <input
                            type="text"
                            name="username"
                            placeholder="Nom d'utilisateur"
                            style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                            onChange={handleChange}
                            required
                        />
                    </div>
                    <div style={styles.inputGroup}>
                        <input
                            type="email"
                            name="email"
                            placeholder="E-mail"
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
                    <div style={styles.inputGroup}>
                        <input
                            type="password"
                            name="re_password"
                            placeholder="Confirmer le mot de passe"
                            style={{ ...styles.input, backgroundColor: theme.inputBg, border: `1px solid ${theme.inputBorder}`, color: theme.text }}
                            onChange={handleChange}
                            required
                        />
                    </div>

                    <button type="submit" style={{ ...styles.button, backgroundColor: theme.button }}>
                        S'inscrire
                    </button>
                </form>

                {message && (
                    <p style={{
                        color: isError ? '#ef4444' : '#10b981',
                        fontSize: '14px',
                        marginTop: '15px',
                        backgroundColor: isError ? 'rgba(239, 68, 68, 0.1)' : 'rgba(16, 185, 129, 0.1)',
                        padding: '10px',
                        borderRadius: '8px'
                    }}>
                        {message}
                    </p>
                )}

                <div style={styles.footer}>
                    <p style={{ ...styles.footerText, color: theme.subText }}>
                        Déjà inscrit ?
                        <Link to="/login" style={{ ...styles.link, color: theme.button }}> Se connecter</Link>
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
        position: 'relative',
        padding: '20px'
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
        backgroundColor: '#6366f1',
        color: 'white',
        boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
    },
    glassCard: {
        backdropFilter: 'blur(12px)',
        borderRadius: '24px',
        padding: '40px',
        width: '100%',
        maxWidth: '450px',
        boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        textAlign: 'center',
        transition: 'all 0.4s ease',
    },
    headerSection: { marginBottom: '30px' },
    title: { fontSize: '28px', fontWeight: 'bold', margin: '0 0 10px 0' },
    subtitle: { fontSize: '14px', margin: 0 },
    form: { display: 'flex', flexDirection: 'column', gap: '15px' },
    input: {
        width: '100%',
        padding: '12px 16px',
        borderRadius: '10px',
        fontSize: '15px',
        outline: 'none',
        boxSizing: 'border-box',
        transition: 'all 0.3s ease',
    },
    button: {
        padding: '14px',
        borderRadius: '10px',
        border: 'none',
        color: '#fff',
        fontSize: '16px',
        fontWeight: 'bold',
        cursor: 'pointer',
        boxShadow: '0 10px 15px -3px rgba(99, 102, 241, 0.3)',
        marginTop: '10px',
        transition: 'transform 0.2s',
    },
    footer: { marginTop: '25px' },
    footerText: { fontSize: '13px' },
    link: { textDecoration: 'none', fontWeight: 'bold', marginLeft: '5px' }
};

export default Register;