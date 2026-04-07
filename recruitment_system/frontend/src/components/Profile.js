import React, { useState, useEffect, useRef } from 'react';
import axios from 'axios';

const Profile = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [isEditing, setIsEditing] = useState(false);
    const [editData, setEditData] = useState({ username: '', email: '' });

    const [showOTPField, setShowOTPField] = useState(false);
    const [otp, setOtp] = useState('');

    const [isChangingPassword, setIsChangingPassword] = useState(false);
    const [passData, setPassData] = useState({ old_password: '', new_password: '', confirm_password: '' });

    const fileInputRef = useRef(null);
    const token = localStorage.getItem('access');

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/profile/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUser(res.data);
            setEditData({ username: res.data.username, email: res.data.email });
            setLoading(false);
        } catch (err) {
            setLoading(false);
        }
    };

    const handleFileChange = async (e) => {
        const file = e.target.files[0];
        if (!file) return;
        const formData = new FormData();
        formData.append('photo', file);
        try {
            await axios.patch('http://127.0.0.1:8000/api/profile/', formData, {
                headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'multipart/form-data' }
            });
            fetchData();
        } catch (err) {
            alert("Erreur lors du changement de photo");
        }
    };

    const handleSaveInfo = async () => {
        try {
            const payload = showOTPField ? { ...editData, otp: otp } : editData;
            const res = await axios.patch('http://127.0.0.1:8000/api/profile/', payload, {
                headers: { Authorization: `Bearer ${token}` }
            });

            if (res.data.detail === "OTP_SENT") {
                setShowOTPField(true);
                alert("Un code de vérification a été envoyé à votre nouvel email.");
            } else {
                setIsEditing(false);
                setShowOTPField(false);
                setOtp('');
                fetchData();
                alert("Profil mis à jour !");
            }
        } catch (err) {
            alert(err.response?.data?.detail || "Erreur lors de la mise à jour");
        }
    };

    const handlePasswordUpdate = async () => {
        try {
            const res = await axios.post('http://127.0.0.1:8000/api/change-password/', passData, {
                headers: { Authorization: `Bearer ${token}` }
            });
            alert(res.data.detail);
            setIsChangingPassword(false);
            setPassData({ old_password: '', new_password: '', confirm_password: '' });
        } catch (err) {
            alert(err.response?.data?.detail || "Erreur lors du changement de mot de passe");
        }
    };

    if (loading) return <div style={localStyles.loading}>Chargement...</div>;

    return (
        <div style={localStyles.container}>
            <div style={localStyles.card}>
                <div style={localStyles.header}>
                    <h2 style={{ color: 'var(--text-main)' }}>Mon Profil</h2>
                    <button onClick={() => {
                        setIsEditing(!isEditing);
                        setShowOTPField(false);
                        setIsChangingPassword(false);
                    }} style={localStyles.editToggle}>
                        {isEditing || isChangingPassword ? "Annuler" : "Modifier"}
                    </button>
                </div>

                <div style={localStyles.imageSection} onClick={() => fileInputRef.current.click()}>
                    <div style={localStyles.avatarWrapper}>
                        {user?.photo ? (
                            <img src={`http://127.0.0.1:8000${user.photo}`} style={localStyles.avatar} alt="Profile" />
                        ) : (
                            <div style={localStyles.largeDefaultAvatar}>{user?.username?.charAt(0).toUpperCase()}</div>
                        )}
                        <div style={localStyles.cameraOverlay}>📷</div>
                    </div>
                    <input type="file" ref={fileInputRef} onChange={handleFileChange} style={{ display: 'none' }} />
                </div>

                <div style={localStyles.infoContainer}>
                    {!isChangingPassword ? (
                        <>
                            <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>👤</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Nom d'utilisateur</label>
                                    {isEditing ? (
                                        <input
                                            value={editData.username}
                                            onChange={e => setEditData({...editData, username: e.target.value})}
                                            style={localStyles.inputField}
                                        />
                                    ) : <p style={localStyles.valueText}>{user?.username}</p>}
                                </div>
                            </div>

                            <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>✉️</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Adresse Email</label>
                                    {isEditing ? (
                                        <input
                                            value={editData.email}
                                            onChange={e => setEditData({...editData, email: e.target.value})}
                                            style={localStyles.inputField}
                                            disabled={showOTPField}
                                        />
                                    ) : <p style={localStyles.valueText}>{user?.email}</p>}
                                </div>
                            </div>

                            {showOTPField && (
                                <div style={localStyles.infoCard}>
                                    <div style={localStyles.iconWrapper}>🔑</div>
                                    <div style={localStyles.textWrapper}>
                                        <label style={localStyles.label}>Code OTP</label>
                                        <input
                                            placeholder="000000"
                                            value={otp}
                                            onChange={e => setOtp(e.target.value)}
                                            style={localStyles.inputField}
                                        />
                                    </div>
                                </div>
                            )}

                            <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>🛡️</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Rôle du compte</label>
                                    <p style={localStyles.roleBadge}>{user?.role}</p>
                                </div>
                            </div>

                            {isEditing ? (
                                <button onClick={handleSaveInfo} style={localStyles.saveBtn}>
                                    {showOTPField ? "Vérifier OTP" : "Sauvegarder"}
                                </button>
                            ) : (
                                <button onClick={() => setIsChangingPassword(true)} style={localStyles.passwordBtn}>
                                    Changer le mot de passe
                                </button>
                            )}
                        </>
                    ) : (
                        <div style={localStyles.passwordSection}>
                             <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>🔒</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Ancien mot de passe</label>
                                    <input
                                        type="password"
                                        placeholder="••••••••"
                                        style={localStyles.inputField}
                                        onChange={e => setPassData({...passData, old_password: e.target.value})}
                                    />
                                </div>
                            </div>

                            <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>🔑</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Nouveau mot de passe</label>
                                    <input
                                        type="password"
                                        placeholder="••••••••"
                                        style={localStyles.inputField}
                                        onChange={e => setPassData({...passData, new_password: e.target.value})}
                                    />
                                </div>
                            </div>

                            <div style={localStyles.infoCard}>
                                <div style={localStyles.iconWrapper}>✅</div>
                                <div style={localStyles.textWrapper}>
                                    <label style={localStyles.label}>Confirmer le mot de passe</label>
                                    <input
                                        type="password"
                                        placeholder="••••••••"
                                        style={localStyles.inputField}
                                        onChange={e => setPassData({...passData, confirm_password: e.target.value})}
                                    />
                                </div>
                            </div>

                            <button onClick={handlePasswordUpdate} style={localStyles.saveBtn}>
                                Mettre à jour le mot de passe
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

const localStyles = {
    container: { padding: '80px 20px', display: 'flex', justifyContent: 'center', minHeight: '100vh', background: 'var(--bg-main)' },
    card: {
        background: 'var(--bg-sidebar)',
        padding: '30px',
        borderRadius: '24px',
        width: '100%',
        maxWidth: '450px',
        color: 'var(--text-main)',
        border: '1px solid rgba(128, 128, 128, 0.1)',
        boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
    },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' },
    editToggle: { background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', border: 'none', padding: '8px 15px', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold' },
    imageSection: { display: 'flex', justifyContent: 'center', marginBottom: '30px', cursor: 'pointer' },
    avatarWrapper: { position: 'relative', width: '120px', height: '120px' },
    avatar: { width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover', border: '3px solid #6366f1' },
    largeDefaultAvatar: { width: '100%', height: '100%', borderRadius: '50%', backgroundColor: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '40px', fontWeight: 'bold', color: '#fff' },
    cameraOverlay: { position: 'absolute', bottom: '5px', right: '5px', background: '#6366f1', padding: '8px', borderRadius: '50%', fontSize: '14px', boxShadow: '0 2px 10px rgba(0,0,0,0.3)', color: '#fff' },
    infoContainer: { display: 'flex', flexDirection: 'column', gap: '15px' },
    infoCard: {
        display: 'flex',
        alignItems: 'center',
        background: 'rgba(128, 128, 128, 0.05)',
        padding: '12px 18px',
        borderRadius: '16px',
        border: '1px solid rgba(128, 128, 128, 0.1)',
        transition: 'all 0.3s ease'
    },
    iconWrapper: {
        fontSize: '20px',
        marginRight: '15px',
        background: 'rgba(99, 102, 241, 0.1)',
        width: '42px',
        height: '42px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '12px'
    },
    textWrapper: { display: 'flex', flexDirection: 'column', alignItems: 'flex-start', flex: 1 },
    label: { fontSize: '10px', color: 'var(--text-muted)', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '4px' },
    valueText: { fontSize: '16px', fontWeight: '500', color: 'var(--text-main)', margin: 0 },
    inputField: {
        width: '100%',
        padding: '5px 0',
        border: 'none',
        borderBottom: '1px solid rgba(99, 102, 241, 0.3)',
        background: 'transparent',
        color: 'var(--text-main)',
        outline: 'none',
        fontSize: '15px'
    },
    roleBadge: { background: 'linear-gradient(135deg, #6366f1 0%, #4338ca 100%)', color: 'white', padding: '4px 12px', borderRadius: '8px', fontSize: '12px', fontWeight: 'bold', marginTop: '5px' },
    saveBtn: {
        background: 'linear-gradient(135deg, #6366f1 0%, #4f46e5 100%)',
        color: 'white',
        border: 'none',
        padding: '14px',
        borderRadius: '14px',
        cursor: 'pointer',
        fontWeight: 'bold',
        marginTop: '10px',
        boxShadow: '0 4px 15px rgba(99, 102, 241, 0.3)',
        fontSize: '15px'
    },
    passwordBtn: {
        background: 'rgba(128, 128, 128, 0.05)',
        color: '#6366f1',
        border: '1px solid rgba(99, 102, 241, 0.2)',
        padding: '12px',
        borderRadius: '14px',
        cursor: 'pointer',
        marginTop: '10px',
        fontSize: '14px',
        transition: 'all 0.3s',
        fontWeight: '600'
    },
    passwordSection: {
        display: 'flex',
        flexDirection: 'column',
        gap: '15px',
        animation: 'fadeIn 0.4s ease'
    },
    loading: { color: 'var(--text-main)', textAlign: 'center', marginTop: '100px' }
};

export default Profile;