import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const Login = () => {
    const [formData, setFormData] = useState({ email: '', password: '' });
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('http://127.0.0.1:8000/auth/jwt/create/', formData);
            const accessToken = response.data.access;
            localStorage.setItem('access', accessToken);

            const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', {
                headers: { Authorization: `Bearer ${accessToken}` }
            });

            // تحويل الدور إلى أحرف كبيرة لضمان المطابقة
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

    return (
        <div style={{ padding: '50px', textAlign: 'center' }}>
            <h2>Connexion</h2>
            <form onSubmit={handleSubmit}>
                <input type="email" name="email" placeholder="Email" onChange={handleChange} required /><br/><br/>
                <input type="password" name="password" placeholder="Mot de passe" onChange={handleChange} required /><br/><br/>
                <button type="submit">Se connecter</button>
            </form>
            {error && <p style={{ color: 'red' }}>{error}</p>}
        </div>
    );
};

export default Login;