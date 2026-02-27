import React, { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

const Activate = () => {
    const { uid, token } = useParams(); // استخراج البيانات من الرابط المرسل عبر الإيميل
    const navigate = useNavigate();
    const [activated, setActivated] = useState(false);
    const [error, setError] = useState(false);

    const handleActivation = async () => {
        try {
            // إرسال طلب التفعيل إلى Backend API
            await axios.post('http://127.0.0.1:8000/auth/users/activation/', { uid, token });
            setActivated(true);
            setTimeout(() => navigate('/login'), 3000); // التوجيه لصفحة الدخول بعد 3 ثوانٍ
        } catch (err) {
            setError(true);
        }
    };

    return (
        <div style={{ padding: '50px', textAlign: 'center' }}>
            <h2>Activation du compte</h2>
            {!activated && !error && (
                <div>
                    <p>Cliquez sur le bouton ci-dessous pour confirmer votre inscription.</p>
                    <button
                        onClick={handleActivation}
                        style={{ padding: '10px 20px', backgroundColor: '#28a745', color: '#fff', border: 'none', borderRadius: '5px', cursor: 'pointer' }}
                    >
                        Activer mon compte
                    </button>
                </div>
            )}
            {activated && <p style={{ color: 'green' }}>Votre compte a été activé avec succès ! Redirection vers la page de connexion...</p>}
            {error && <p style={{ color: 'red' }}>Le lien d'activation est invalide ou a expiré.</p>}
        </div>
    );
};

export default Activate;