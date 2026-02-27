import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom'; // أضفنا هذا لتغيير الصفحة تلقائياً

const Register = () => {
    const navigate = useNavigate(); // تعريف دالة التنقل
    const [formData, setFormData] = useState({
        email: '',
        username: '',
        password: '',
        re_password: ''
    });

    const [message, setMessage] = useState('');
    const [isError, setIsError] = useState(false);

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setIsError(false);

        try {
            // إرسال البيانات إلى Django
            await axios.post('http://127.0.0.1:8000/auth/users/', formData);

            // تخزين الإيميل مؤقتاً لكي نعرف لمن نرسل رمز التحقق في الصفحة التالية
            localStorage.setItem('pending_email', formData.email);

            // التوجيه فوراً إلى صفحة إدخال الرمز التي أنشأناها
            navigate('/verify-otp');

        } catch (err) {
            // في حال حدوث خطأ (مثل اسم مستخدم مكرر كما رأينا في الصور)
            setMessage('Échec de l\'inscription. Veuillez vérifier vos informations ou Si l\'utilisateur existe déjà.');
            setIsError(true);
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '400px', margin: 'auto', textAlign: 'center' }}>
            <h2>Créer un compte</h2>
            <form onSubmit={handleSubmit}>
                <div style={{ marginBottom: '10px' }}>
                    <input type="text" name="username" placeholder="Nom d'utilisateur" onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                </div>
                <div style={{ marginBottom: '10px' }}>
                    <input type="email" name="email" placeholder="E-mail" onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                </div>
                <div style={{ marginBottom: '10px' }}>
                    <input type="password" name="password" placeholder="Mot de passe" onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                </div>
                <div style={{ marginBottom: '10px' }}>
                    <input type="password" name="re_password" placeholder="Confirmer le mot de passe" onChange={handleChange} required style={{ width: '100%', padding: '8px' }} />
                </div>
                <button type="submit" style={{ padding: '10px 20px', backgroundColor: '#007bff', color: '#fff', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>
                    S'inscrire
                </button>
            </form>
            {message && <p style={{ color: isError ? 'red' : 'green', marginTop: '15px' }}>{message}</p>}
        </div>
    );
};

export default Register;