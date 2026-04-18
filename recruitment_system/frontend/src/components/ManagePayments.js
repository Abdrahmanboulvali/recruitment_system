import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiDollarSign, FiCheck, FiX, FiCreditCard, FiExternalLink, FiPlus, FiPackage, FiActivity, FiTrash2, FiLayers, FiMaximize2 } from 'react-icons/fi';

const ManagePayments = () => {
    // حالات البيانات
    const [subscriptions, setSubscriptions] = useState([]);
    const [accounts, setAccounts] = useState([]);
    const [plans, setPlans] = useState([]);
    const [loading, setLoading] = useState(true);

    // حالات النوافذ المنبثقة
    const [showAccountForm, setShowAccountForm] = useState(false);
    const [showPlanForm, setShowPlanForm] = useState(false);
    const [selectedImage, setSelectedImage] = useState(null);

    // حالات البيانات الجديدة
    const [newAccount, setNewAccount] = useState({ provider_name: '', account_number: '' });
    const [newPlan, setNewPlan] = useState({ title: '', price: '', offres_count: '', duration_months: '', description: '' });

    const token = localStorage.getItem('access');
    const API_BASE_URL = 'http://127.0.0.1:8000';
    const config = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            const results = await Promise.allSettled([
                axios.get(`${API_BASE_URL}/api/admin/subscriptions/pending/`, config),
                axios.get(`${API_BASE_URL}/api/payment-methods/`, config),
                axios.get(`${API_BASE_URL}/api/subscription-plans/`, config)
            ]);

            if (results[0].status === 'fulfilled') setSubscriptions(results[0].value.data);
            if (results[1].status === 'fulfilled') setAccounts(results[1].value.data);
            if (results[2].status === 'fulfilled') setPlans(results[2].value.data);
        } catch (err) {
            console.error("Erreur critique:", err);
        } finally {
            setLoading(false);
        }
    };

    const handleVerifySubscription = async (id, status) => {
        try {
            await axios.patch(`${API_BASE_URL}/api/admin/subscriptions/verify/${id}/`, { status }, config);
            alert(`Statut mis à jour : ${status}`);
            fetchData();
        } catch (err) {
            alert("Erreur lors de la validation.");
        }
    };

    const handleAddAccount = async (e) => {
        e.preventDefault();
        try {
            await axios.post(`${API_BASE_URL}/api/payment-methods/`, newAccount, config);
            setShowAccountForm(false);
            setNewAccount({ provider_name: '', account_number: '' });
            fetchData();
        } catch (err) {
            alert("Erreur lors de l'ajout.");
        }
    };

    const handleDeleteAccount = async (id) => {
        if (window.confirm("Supprimer ce compte ?")) {
            try {
                await axios.delete(`${API_BASE_URL}/api/payment-methods/${id}/`, config);
                fetchData();
            } catch (err) {
                alert("Erreur lors de la suppression");
            }
        }
    };

    const handleAddPlan = async (e) => {
        e.preventDefault();
        try {
            await axios.post(`${API_BASE_URL}/api/subscription-plans/`, newPlan, config);
            setShowPlanForm(false);
            setNewPlan({ title: '', price: '', offres_count: '', duration_months: '', description: '' });
            fetchData();
        } catch (err) {
            alert("Erreur lors de la création.");
        }
    };

    const handleDeletePlan = async (id) => {
        if (window.confirm("Supprimer ce pack ?")) {
            try {
                await axios.delete(`${API_BASE_URL}/api/subscription-plans/${id}/`, config);
                fetchData();
            } catch (err) {
                alert("Erreur lors de la suppression");
            }
        }
    };

    if (loading && accounts.length === 0) {
        return (
            <div style={{...styles.container, textAlign: 'center', paddingTop: '100px'}}>
                <div style={{color: 'var(--text-main)'}}>Chargement des données financières...</div>
            </div>
        );
    }

    return (
        <div style={styles.container}>
            {selectedImage && (
                <div style={styles.modalOverlay} onClick={() => setSelectedImage(null)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <button style={styles.closeModal} onClick={() => setSelectedImage(null)}><FiX /></button>
                        <img src={selectedImage} alt="Reçu" style={styles.fullImage} />
                    </div>
                </div>
            )}

            <div style={styles.header}>
                <div>
                    <h2 style={styles.title}>Administration Financière</h2>
                    <p style={styles.subtitle}>Gérez les offres، les comptes de réception et validez les paiements.</p>
                </div>
                <div style={{ display: 'flex', gap: '10px' }}>
                    <button onClick={() => {setShowAccountForm(!showAccountForm); setShowPlanForm(false);}} style={styles.addBtn}>
                        <FiCreditCard /> {showAccountForm ? "Fermer" : "Nouveau Compte"}
                    </button>
                    <button onClick={() => {setShowPlanForm(!showPlanForm); setShowAccountForm(false);}} style={{...styles.addBtn, backgroundColor: '#f59e0b'}}>
                        <FiPackage /> {showPlanForm ? "Fermer" : "Créer un Plan"}
                    </button>
                </div>
            </div>

            {showAccountForm && (
                <div style={styles.glassForm}>
                    <h3 style={styles.formTitle}>Nouveau Compte de Réception</h3>
                    <form onSubmit={handleAddAccount} style={styles.formGrid}>
                        <input placeholder="Nom de la Banque" style={styles.input} required value={newAccount.provider_name} onChange={e => setNewAccount({...newAccount, provider_name: e.target.value})} />
                        <input placeholder="Numéro" style={styles.input} required value={newAccount.account_number} onChange={e => setNewAccount({...newAccount, account_number: e.target.value})} />
                        <button type="submit" style={styles.submitBtn}>Enregistrer</button>
                    </form>
                </div>
            )}

            {showPlanForm && (
                <div style={styles.glassForm}>
                    <h3 style={styles.formTitle}>Créer une Offre d'Abonnement</h3>
                    <form onSubmit={handleAddPlan} style={styles.formGrid}>
                        <input placeholder="Titre" style={styles.input} required value={newPlan.title} onChange={e => setNewPlan({...newPlan, title: e.target.value})} />
                        <input placeholder="Prix (MRU)" type="number" style={styles.input} required value={newPlan.price} onChange={e => setNewPlan({...newPlan, price: e.target.value})} />
                        <input placeholder="Offres" type="number" style={styles.input} required value={newPlan.offres_count} onChange={e => setNewPlan({...newPlan, offres_count: e.target.value})} />
                        <input placeholder="Durée" type="number" style={styles.input} required value={newPlan.duration_months} onChange={e => setNewPlan({...newPlan, duration_months: e.target.value})} />
                        <button type="submit" style={{...styles.submitBtn, backgroundColor: '#f59e0b'}}>Activer</button>
                    </form>
                </div>
            )}

            <h4 style={styles.sectionLabel}><FiCreditCard /> Comptes de Réception</h4>
            <div style={styles.statsRow}>
                {accounts.map(acc => (
                    <div key={acc.id} style={styles.accountCard}>
                        <div style={styles.iconCircle}><FiDollarSign color="#fff" /></div>
                        <div style={{ flex: 1 }}>
                            <div style={styles.accName}>{acc.provider_name}</div>
                            <div style={styles.accNum}>{acc.account_number}</div>
                        </div>
                        <button onClick={() => handleDeleteAccount(acc.id)} style={styles.deleteAccBtn}><FiTrash2 /></button>
                    </div>
                ))}
            </div>

            <h4 style={styles.sectionLabel}><FiLayers /> Packs d'Abonnement</h4>
            <div style={styles.statsRow}>
                {plans.map(plan => (
                    <div key={plan.id} style={{...styles.accountCard, borderLeft: '4px solid #f59e0b'}}>
                        <div style={{...styles.iconCircle, backgroundColor: '#f59e0b'}}><FiPackage color="#fff" /></div>
                        <div style={{ flex: 1 }}>
                            <div style={styles.accName}>{plan.title}</div>
                            <div style={styles.accNum}>{plan.price} <small style={{fontSize: '10px'}}>MRU</small></div>
                        </div>
                        <button onClick={() => handleDeletePlan(plan.id)} style={styles.deleteAccBtn}><FiTrash2 /></button>
                    </div>
                ))}
            </div>

            <div style={styles.tableCard}>
                <div style={styles.tableHeader}>
                    <FiActivity /> <span>Vérification des reçus</span>
                </div>
                <div style={{ overflowX: 'auto' }}>
                    <table style={styles.table}>
                        <thead>
                            <tr style={styles.thRow}>
                                <th style={styles.th}>Entreprise</th>
                                <th style={styles.th}>Plan</th>
                                <th style={styles.th}>Preuve</th>
                                <th style={styles.th}>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {subscriptions.map(sub => (
                                <tr key={sub.id} style={styles.tr}>
                                    <td style={{...styles.td, color: 'var(--text-main)', fontWeight: 'bold'}}>{sub.enterprise_name}</td>
                                    <td style={styles.td}><span style={styles.planBadge}>{sub.plan_title}</span></td>
                                    <td style={styles.td}>
                                        <button onClick={() => setSelectedImage(sub.payment_receipt)} style={styles.viewBtn}><FiMaximize2 /> Reçu</button>
                                    </td>
                                    <td style={styles.td}>
                                        <div style={styles.btnGroup}>
                                            <button onClick={() => handleVerifySubscription(sub.id, 'ACTIVE')} style={styles.checkBtn}><FiCheck /></button>
                                            <button onClick={() => handleVerifySubscription(sub.id, 'REJECTED')} style={styles.rejectBtn}><FiX /></button>
                                        </div>
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '30px', backgroundColor: 'var(--bg-main)', minHeight: '100vh', transition: 'var(--transition-speed)' },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' },
    title: { fontSize: '26px', fontWeight: 'bold', color: 'var(--text-main)' },
    subtitle: { color: 'var(--text-muted)', fontSize: '14px' },
    sectionLabel: { fontSize: '14px', fontWeight: 'bold', color: 'var(--text-muted)', marginBottom: '15px', display: 'flex', alignItems: 'center', gap: '8px' },
    addBtn: { display: 'flex', alignItems: 'center', gap: '8px', padding: '12px 20px', backgroundColor: 'var(--accent-primary)', color: 'white', border: 'none', borderRadius: '12px', cursor: 'pointer', fontWeight: '600' },
    glassForm: { background: 'var(--bg-sidebar)', padding: '25px', borderRadius: '18px', marginBottom: '30px', border: '1px solid rgba(255,255,255,0.05)' },
    formTitle: { fontSize: '16px', fontWeight: 'bold', marginBottom: '20px', color: 'var(--text-main)' },
    formGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '15px' },
    input: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid rgba(255,255,255,0.1)', color: 'var(--text-main)' },
    submitBtn: { padding: '12px', backgroundColor: 'var(--success-green)', color: 'white', border: 'none', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold' },
    statsRow: { display: 'flex', gap: '20px', marginBottom: '30px', flexWrap: 'wrap' },
    accountCard: { background: 'var(--bg-sidebar)', padding: '20px', borderRadius: '16px', display: 'flex', alignItems: 'center', gap: '15px', minWidth: '280px', border: '1px solid rgba(255,255,255,0.05)' },
    deleteAccBtn: { background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: '18px' },
    iconCircle: { width: '40px', height: '40px', borderRadius: '50%', backgroundColor: 'var(--accent-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' },
    accName: { fontWeight: 'bold', fontSize: '13px', color: 'var(--text-muted)' },
    accNum: { color: 'var(--text-main)', fontSize: '18px', fontWeight: 'bold' },
    tableCard: { background: 'var(--bg-sidebar)', borderRadius: '20px', overflow: 'hidden', border: '1px solid rgba(255,255,255,0.05)' },
    tableHeader: { padding: '20px', background: 'rgba(255,255,255,0.03)', display: 'flex', alignItems: 'center', gap: '10px', fontWeight: 'bold', color: 'var(--text-main)' },
    table: { width: '100%', borderCollapse: 'collapse' },
    th: { padding: '15px', textAlign: 'left', color: 'var(--text-muted)', fontSize: '13px' },
    tr: { borderBottom: '1px solid rgba(255,255,255,0.05)' },
    td: { padding: '15px', fontSize: '14px', color: 'var(--text-muted)' },
    planBadge: { padding: '4px 10px', borderRadius: '20px', backgroundColor: 'rgba(99, 102, 241, 0.1)', color: 'var(--accent-primary)', fontWeight: 'bold' },
    viewBtn: { background: 'rgba(99, 102, 241, 0.1)', color: 'var(--accent-primary)', border: 'none', padding: '6px 12px', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '5px' },
    modalOverlay: { position: 'fixed', inset: 0, backgroundColor: 'rgba(0,0,0,0.85)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 9999 },
    modalContent: { position: 'relative', maxWidth: '90%' },
    closeModal: { position: 'absolute', top: '-40px', right: '0', background: 'transparent', color: 'white', border: 'none', fontSize: '24px' },
    fullImage: { maxWidth: '100%', maxHeight: '85vh', borderRadius: '10px' },
    btnGroup: { display: 'flex', gap: '8px' },
    checkBtn: { background: 'var(--success-green)', color: 'white', border: 'none', padding: '8px', borderRadius: '8px', cursor: 'pointer' },
    rejectBtn: { background: '#ef4444', color: 'white', border: 'none', padding: '8px', borderRadius: '8px', cursor: 'pointer' }
};

export default ManagePayments;