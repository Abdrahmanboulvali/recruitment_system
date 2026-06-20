import React, { useState } from 'react';
import axios from 'axios';

const AddAgent = () => {
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        password: '',
        departement: ''
    });
    const [message, setMessage] = useState('');

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            const token = localStorage.getItem('access');
            await axios.post('http://127.0.0.1:8000/api/manage-agents/create/', formData, {
                headers: {
                    'Authorization': `Bearer ${token}`
                }
            });
            setMessage('Le compte agent a été créé avec succès!');
            setFormData({ username: '', email: '', password: '', departement: '' });
        } catch (error) {
            if (error.response && error.response.data && error.response.data.email) {
                setMessage('Erreur : ' + error.response.data.email[0]);
            } else {
                setMessage('Erreur : Vérifiez les autorisations de l\'administrateur ou l\'exactitude des données.');
            }
        }
    };

    return (
        <div style={{ padding: '40px', maxWidth: '500px', margin: 'auto', color: 'inherit' }}>
            <h2 style={{ textAlign: 'center', marginBottom: '30px', color: 'inherit' }}>Ajouter un Nouvel Agent RH</h2>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                <input
                    type="text"
                    name="username"
                    placeholder="Nom d'utilisateur (Username)"
                    value={formData.username}
                    style={inputStyle}
                    onChange={handleChange}
                    required
                />
                <input
                    type="email" name="email" placeholder="Email"
                    value={formData.email} onChange={handleChange} required
                    style={inputStyle}
                />
                <input
                    type="password" name="password" placeholder="Mot de passe"
                    value={formData.password} onChange={handleChange} required
                    style={inputStyle}
                />
                <input
                    type="text" name="departement" placeholder="Département"
                    value={formData.departement} onChange={handleChange} required
                    style={inputStyle}
                />
                <button type="submit" style={buttonStyle}>Créer le compte</button>
            </form>
            {message && <p style={{ marginTop: '20px', color: '#6366f1', textAlign: 'center' }}>{message}</p>}
        </div>
    );
};

// التنسيقات المعدلة لتكون متوافقة مع كلا الوضعين
const inputStyle = {
    padding: '12px',
    borderRadius: '8px',
    border: '1px solid rgba(128, 128, 128, 0.2)', // تم تعديل الحدود لتكون أوضح في الوضع الفاتح
    backgroundColor: 'rgba(128, 128, 128, 0.05)',
    color: 'inherit' // سيأخذ اللون تلقائياً حسب الوضع
};

const buttonStyle = {
    padding: '12px',
    borderRadius: '8px',
    border: 'none',
    backgroundColor: '#6366f1',
    color: 'white',
    fontWeight: 'bold',
    cursor: 'pointer'
};

export default AddAgent;