import React, { useState } from 'react';
import axios from 'axios';

const AddAgent = () => {
    const [formData, setFormData] = useState({
        username: '', //
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
            // تأكد من تفريغ الـ username أيضاً هنا
            setFormData({ username: '', email: '', password: '', departement: '' });
        } catch (error) {
            setMessage('Erreur : Vérifiez les autorisations de l\'administrateur ou l\'exactitude des données.');
        }
    };

    return (
        <div style={{ padding: '40px', maxWidth: '500px', margin: 'auto', color: '#f8fafc' }}>
            <h2 style={{ textAlign: 'center', marginBottom: '30px' }}>Ajouter un Nouvel Agent RH</h2>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                <input
                    type="text"
                    name="username"
                    placeholder="Nom d'utilisateur (Username)"
                    value={formData.username} // إضافة الربط مع الحالة
                    style={inputStyle} // تصحيح اسم التنسيق من styles.input إلى inputStyle
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

// التنسيقات (تأكد أنها مطابقة للمستخدم في الأعلى)
const inputStyle = {
    padding: '12px',
    borderRadius: '8px',
    border: '1px solid rgba(255,255,255,0.1)',
    backgroundColor: 'rgba(255,255,255,0.05)',
    color: 'white'
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