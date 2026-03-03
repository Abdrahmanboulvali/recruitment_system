import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const token = localStorage.getItem('access');
                // نستخدم الرابط الصحيح من API الباكيند الخاص بك
                const response = await axios.get('http://127.0.0.1:8000/api/users/', {
                    headers: { Authorization: `Bearer ${token}` }
                });
                setUsers(response.data);
            } catch (err) {
                console.error("Erreur lors جلب المستخدمين", err);
            } finally {
                setLoading(false);
            }
        };
        fetchUsers();
    }, []);

    if (loading) return <div style={{ textAlign: 'center', padding: '50px' }}>Chargement des utilisateurs...</div>;

    return (
        <div style={{ padding: '30px', maxWidth: '1000px', margin: '0 auto' }}>
            <h2 style={{ color: '#2c3e50', borderBottom: '2px solid #e74c3c', paddingBottom: '10px' }}>
                Gestion des Utilisateurs
            </h2>
            <table style={tableStyle}>
                <thead>
                    <tr style={{ backgroundColor: '#f8f9fa' }}>
                        <th style={thStyle}>Nom d'utilisateur</th>
                        <th style={thStyle}>Email</th>
                        <th style={thStyle}>Rôle</th>
                        <th style={thStyle}>Statut</th>
                    </tr>
                </thead>
                <tbody>
                    {users.map(user => (
                        <tr key={user.id} style={{ borderBottom: '1px solid #eee' }}>
                            <td style={tdStyle}>{user.username}</td>
                            <td style={tdStyle}>{user.email}</td>
                            <td style={tdStyle}>
                                <span style={roleBadge(user.role)}>{user.role || 'N/A'}</span>
                            </td>
                            <td style={tdStyle}>
                                {user.is_active ? '✅ Actif' : '❌ Inactif'}
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>
        </div>
    );
};

// التنسيقات (Styles)
const tableStyle = { width: '100%', borderCollapse: 'collapse', marginTop: '20px', backgroundColor: 'white', boxShadow: '0 2px 10px rgba(0,0,0,0.1)' };
const thStyle = { padding: '15px', textAlign: 'left', borderBottom: '2px solid #dee2e6' };
const tdStyle = { padding: '15px' };

const roleBadge = (role) => ({
    padding: '4px 8px',
    borderRadius: '12px',
    fontSize: '12px',
    backgroundColor: role === 'ADMIN' ? '#fdecea' : '#e3f2fd',
    color: role === 'ADMIN' ? '#e74c3c' : '#007bff',
    fontWeight: 'bold'
});

export default Users;