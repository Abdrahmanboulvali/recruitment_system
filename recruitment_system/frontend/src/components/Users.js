import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchUsers = async () => {
            try {
                const token = localStorage.getItem('access');
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

    if (loading) return (
        <div style={{ textAlign: 'center', padding: '100px', fontWeight: 'bold', opacity: 0.6 }}>
            Chargement de la base utilisateurs...
        </div>
    );

    return (
        <div style={styles.pageWrapper}>
            <header style={styles.header}>
                <h2 style={styles.title}>Gestion des Utilisateurs</h2>
                <p style={{ opacity: 0.7, margin: 0 }}>Administrez les comptes et les accès système</p>
            </header>

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Utilisateur</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Rôle</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        {users.map(user => (
                            <tr key={user.id} style={styles.tr}>
                                <td style={{...styles.td, fontWeight: '600'}}>
                                    <div style={styles.userCell}>
                                        <div style={styles.avatar}>{user.username.charAt(0).toUpperCase()}</div>
                                        {user.username}
                                    </div>
                                </td>
                                <td style={styles.td}>{user.email}</td>
                                <td style={styles.td}>
                                    <span style={styles.roleBadge(user.role)}>
                                        {user.role || 'N/A'}
                                    </span>
                                </td>
                                <td style={{...styles.td, textAlign: 'center'}}>
                                    <span style={styles.statusBadge(user.is_active)}>
                                        {user.is_active ? '● Actif' : '○ Inactif'}
                                    </span>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

// التنسيقات المتوافقة مع النظام الجديد
const styles = {
    pageWrapper: {
        padding: '40px 20px',
        maxWidth: '1100px',
        margin: '0 auto',
        minHeight: '100vh'
    },
    header: {
        marginBottom: '35px',
        borderLeft: '5px solid #6366f1',
        paddingLeft: '20px'
    },
    title: {
        fontSize: '30px',
        fontWeight: '800',
        margin: '0 0 5px 0',
        letterSpacing: '-1px'
    },
    tableCard: {
        background: 'rgba(255, 255, 255, 0.03)',
        backdropFilter: 'blur(12px)',
        borderRadius: '24px',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        overflow: 'hidden',
        boxShadow: '0 15px 35px rgba(0,0,0,0.1)'
    },
    table: {
        width: '100%',
        borderCollapse: 'collapse',
        color: 'inherit'
    },
    headerRow: {
        background: 'rgba(99, 102, 241, 0.08)',
    },
    th: {
        padding: '20px',
        textAlign: 'left',
        fontSize: '13px',
        textTransform: 'uppercase',
        letterSpacing: '1px',
        opacity: 0.6
    },
    tr: {
        borderBottom: '1px solid rgba(255, 255, 255, 0.05)',
        transition: '0.3s'
    },
    td: {
        padding: '18px',
        fontSize: '15px'
    },
    userCell: {
        display: 'flex',
        alignItems: 'center',
        gap: '12px'
    },
    avatar: {
        width: '32px',
        height: '32px',
        borderRadius: '50%',
        background: '#6366f1',
        color: 'white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '14px',
        fontWeight: 'bold'
    },
    roleBadge: (role) => ({
        padding: '5px 12px',
        borderRadius: '8px',
        fontSize: '12px',
        fontWeight: 'bold',
        backgroundColor: role === 'ADMIN' ? 'rgba(239, 68, 68, 0.15)' : 'rgba(99, 102, 241, 0.15)',
        color: role === 'ADMIN' ? '#ef4444' : '#6366f1',
    }),
    statusBadge: (isActive) => ({
        padding: '5px 12px',
        borderRadius: '20px',
        fontSize: '13px',
        fontWeight: '600',
        backgroundColor: isActive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(255, 255, 255, 0.05)',
        color: isActive ? '#10b981' : '#94a3b8',
    })
};

export default Users;