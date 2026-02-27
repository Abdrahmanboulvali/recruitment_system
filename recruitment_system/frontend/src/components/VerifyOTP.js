import React, { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const VerifyOTP = () => {
    const [otp, setOtp] = useState('');
    const [error, setError] = useState('');
    const email = localStorage.getItem('pending_email');
    const navigate = useNavigate();

    const handleVerify = async (e) => {
        e.preventDefault();
        try {
            // إرسال الرمز للمسار الذي أنشأناه في Django
            await axios.post('http://127.0.0.1:8000/api/verify-otp/', { email, otp });
            alert("Compte activé avec succès !");
            navigate('/login');
        } catch (err) {
            setError("Le code est incorrect ou expiré.");
        }
    };

    return (
        <div style={{ textAlign: 'center', marginTop: '100px' }}>
            <h2>Vérification de l'E-mail</h2>
            <p>Veuillez entrer le code de 6 chiffres envoyé à <b>{email}</b></p>
            <form onSubmit={handleVerify}>
                <input
                    type="text"
                    placeholder="Ex: 123456"
                    maxLength="6"
                    style={{ padding: '10px', fontSize: '18px', textAlign: 'center' }}
                    onChange={(e) => setOtp(e.target.value)}
                />
                <br /><br />
                <button type="submit" style={{ padding: '10px 20px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '5px' }}>
                    Vérifier
                </button>
            </form>
            {error && <p style={{ color: 'red', marginTop: '10px' }}>{error}</p>}
        </div>
    );
};

export default VerifyOTP;