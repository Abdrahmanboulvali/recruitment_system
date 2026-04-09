import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Users = () => {
    const [users, setUsers] = useState([]);
    const [loading, setLoading] = useState(true);

    // حالات الفلترة
    const [searchTerm, setSearchTerm] = useState("");
    const [roleFilter, setRoleFilter] = useState("ALL");
    const [statusFilter, setStatusFilter] = useState("ALL");

    useEffect(() => {
        fetchUsers();
    }, []);

    const fetchUsers = async () => {
        try {
            const token = localStorage.getItem('access');
            const response = await axios.get('http://127.0.0.1:8000/api/users/', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUsers(response.data);
        } catch (err) {
            console.error("Erreur lors d'amener les utilisateurs", err);
        } finally {
            setLoading(false);
        }
    };

    // وظيفة تبديل حالة الحساب (تفعيل/تعطيل)
    const toggleUserStatus = async (user) => {
        const action = user.is_active ? "désactiver" : "réactiver";
        if (!window.confirm(`Voulez-vous vraiment ${action} le compte de ${user.username} ?`)) return;

        try {
            const token = localStorage.getItem('access');
            await axios.patch(`http://127.0.0.1:8000/api/users/${user.id}/`,
                { is_active: !user.is_active },
                { headers: { Authorization: `Bearer ${token}` } }
            );

            setUsers(users.map(u => u.id === user.id ? { ...u, is_active: !u.is_active } : u));
        } catch (err) {
            alert("Erreur lors de la modification du statut.");
            console.error(err);
        }
    };

    // منطق الفلترة القوي
    const filteredUsers = users.filter(user => {
        const matchesSearch =
            user.username.toLowerCase().includes(searchTerm.toLowerCase()) ||
            user.email.toLowerCase().includes(searchTerm.toLowerCase());

        const matchesRole = roleFilter === "ALL" || user.role === roleFilter;

        const matchesStatus =
            statusFilter === "ALL" ||
            (statusFilter === "ACTIVE" && user.is_active) ||
            (statusFilter === "INACTIVE" && !user.is_active);

        return matchesSearch && matchesRole && matchesStatus;
    });

    if (loading) return (
        <div style={{ textAlign: 'center', padding: '100px', fontWeight: 'bold', opacity: 0.6, color: 'white' }}>
            Chargement de la base utilisateurs...
        </div>
    );

    return (
        <div style={styles.pageWrapper}>
            <header style={styles.header}>
                <h2 style={styles.title}>Gestion des Utilisateurs</h2>
                <p style={{ opacity: 0.7, margin: 0, color: 'white' }}>Administrez les comptes et les accès système</p>
            </header>

            {/* شريط الفلترة القوي */}
            <div style={styles.filterBar}>
                <input
                    type="text"
                    placeholder="Rechercher par nom ou email..."
                    style={styles.searchInput}
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                />
                <select
                    style={styles.selectInput}
                    value={roleFilter}
                    onChange={(e) => setRoleFilter(e.target.value)}
                >
                    <option style={styles.optionStyle} value="ALL">Tous les Rôles</option>
                    <option style={styles.optionStyle} value="ADMIN">Admin</option>
                    <option style={styles.optionStyle} value="CANDIDAT">Candidat</option>
                    <option style={styles.optionStyle} value="DG">DG</option>
                </select>
                <select
                    style={styles.selectInput}
                    value={statusFilter}
                    onChange={(e) => setStatusFilter(e.target.value)}
                >
                    <option style={styles.optionStyle} value="ALL">Tous les Statuts</option>
                    <option style={styles.optionStyle} value="ACTIVE">Actifs uniquement</option>
                    <option style={styles.optionStyle} value="INACTIVE">Inactifs uniquement</option>
                </select>
            </div>

            <div style={styles.tableCard}>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.headerRow}>
                            <th style={styles.th}>Utilisateur</th>
                            <th style={styles.th}>Email</th>
                            <th style={styles.th}>Rôle</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Statut</th>
                            <th style={{...styles.th, textAlign: 'center'}}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {filteredUsers.length > 0 ? filteredUsers.map(user => (
                            <tr key={user.id} style={styles.tr}>
                                <td style={{...styles.td, fontWeight: '600', color: 'white'}}>
                                    <div style={styles.userCell}>
                                        <div style={styles.avatar}>{user.username.charAt(0).toUpperCase()}</div>
                                        {user.username}
                                    </div>
                                </td>
                                <td style={{...styles.td, color: 'rgba(255,255,255,0.7)'}}>{user.email}</td>
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
                                <td style={{...styles.td, textAlign: 'center'}}>
                                    <button
                                        onClick={() => toggleUserStatus(user)}
                                        style={user.is_active ? styles.btnDisable : styles.btnEnable}
                                    >
                                        {user.is_active ? 'Désactiver' : 'Réactiver'}
                                    </button>
                                </td>
                            </tr>
                        )) : (
                            <tr>
                                <td colSpan="5" style={{padding: '40px', textAlign: 'center', opacity: 0.5, color: 'white'}}>
                                    Aucun utilisateur ne correspond à vos critères.
                                </td>
                            </tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const styles = {
    pageWrapper: { padding: '40px 20px', maxWidth: '1100px', margin: '0 auto', minHeight: '100vh' },
    header: { marginBottom: '35px', borderLeft: '5px solid #6366f1', paddingLeft: '20px' },
    title: { fontSize: '30px', fontWeight: '800', margin: '0 0 5px 0', letterSpacing: '-1px', color: 'white' },

    filterBar: { display: 'flex', gap: '15px', marginBottom: '20px', flexWrap: 'wrap' },
    searchInput: {
        flex: 2,
        padding: '12px 20px',
        borderRadius: '12px',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        background: 'rgba(255, 255, 255, 0.05)',
        color: 'white',
        outline: 'none',
        fontSize: '14px'
    },
    selectInput: {
        flex: 1,
        padding: '12px',
        borderRadius: '12px',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        background: '#1e1e2d', // تم تغييره لضمان عدم ظهور خلفية بيضاء
        color: 'white',
        outline: 'none',
        cursor: 'pointer'
    },
    optionStyle: {
        background: '#1e1e2d',
        color: 'white'
    },

    tableCard: {
        background: 'rgba(255, 255, 255, 0.03)',
        backdropFilter: 'blur(12px)',
        borderRadius: '24px',
        border: '1px solid rgba(255, 255, 255, 0.1)',
        overflow: 'hidden',
        boxShadow: '0 15px 35px rgba(0,0,0,0.1)'
    },
    table: { width: '100%', borderCollapse: 'collapse', color: 'inherit' },
    headerRow: { background: 'rgba(99, 102, 241, 0.08)' },
    th: { padding: '20px', textAlign: 'left', fontSize: '12px', textTransform: 'uppercase', letterSpacing: '1px', opacity: 0.6, color: 'white' },
    tr: { borderBottom: '1px solid rgba(255, 255, 255, 0.05)', transition: '0.3s' },
    td: { padding: '18px', fontSize: '15px' },
    userCell: { display: 'flex', alignItems: 'center', gap: '12px' },
    avatar: { width: '32px', height: '32px', borderRadius: '50%', background: '#6366f1', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 'bold' },

    roleBadge: (role) => ({
        padding: '5px 12px',
        borderRadius: '8px',
        fontSize: '12px',
        fontWeight: 'bold',
        backgroundColor: 'rgba(99, 102, 241, 0.15)',
        color: '#6366f1',
    }),
    statusBadge: (isActive) => ({
        padding: '5px 12px',
        borderRadius: '20px',
        fontSize: '13px',
        fontWeight: '600',
        backgroundColor: isActive ? 'rgba(16, 185, 129, 0.1)' : 'rgba(255, 255, 255, 0.05)',
        color: isActive ? '#10b981' : '#94a3b8',
    }),

    btnDisable: {
        padding: '6px 12px',
        borderRadius: '8px',
        border: '1px solid #ef4444',
        background: 'transparent',
        color: '#ef4444',
        cursor: 'pointer',
        fontSize: '12px',
        fontWeight: '600',
        transition: '0.2s'
    },
    btnEnable: {
        padding: '6px 12px',
        borderRadius: '8px',
        border: '1px solid #10b981',
        background: 'transparent',
        color: '#10b981',
        cursor: 'pointer',
        fontSize: '12px',
        fontWeight: '600',
        transition: '0.2s'
    }
};

export default Users;