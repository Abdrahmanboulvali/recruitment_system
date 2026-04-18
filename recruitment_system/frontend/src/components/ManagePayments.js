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

            if (results[0].status === 'fulfilled') {
                setSubscriptions(results[0].value.data);
            } else {
                console.warn("Échec du chargement des abonnements en attente.");
            }

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
            // التعديل: إرسال الطلب ثم تحديث البيانات المحلية فوراً
            await axios.patch(`${API_BASE_URL}/api/admin/subscriptions/verify/${id}/`, { status }, config);

            alert(`Statut mis à jour : ${status}`);

            // إعادة جلب البيانات لتحديث الجدول وإخفاء الطلب المعالج
            fetchData();

            // نصيحة: إذا كنت تختبر بحساب السوبر أدمن نفسه كصاحب شركة،
            // يفضل إلغاء التعليق عن السطر التالي لتحديث الـ Sidebar فوراً
            // window.location.reload();

        } catch (err) {
            console.error("Detail:", err.response?.data);
            alert("Erreur lors de la validation. Vérifiez la console.");
        }
    };

    const handleAddAccount = async (e) => {
        e.preventDefault();
        try {
            await axios.post(`${API_BASE_URL}/api/payment-methods/`, newAccount, config);
            setShowAccountForm(false);
            setNewAccount({ provider_name: '', account_number: '' });
            fetchData();
            alert("Compte ajouté !");
        } catch (err) {
            alert("Erreur lors de l'ajout du compte.");
        }
    };

    const handleDeleteAccount = async (id) => {
        if (window.confirm("Voulez-vous vraiment supprimer ce compte ?")) {
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
            alert("Plan d'abonnement ajouté !");
        } catch (err) {
            alert("Erreur lors de la création du plan");
        }
    };

    const handleDeletePlan = async (id) => {
        if (window.confirm("Voulez-vous vraiment supprimer ce pack d'abonnement ?")) {
            try {
                await axios.delete(`${API_BASE_URL}/api/subscription-plans/${id}/`, config);
                fetchData();
            } catch (err) {
                alert("Erreur lors de la suppression du pack");
            }
        }
    };

    if (loading && accounts.length === 0 && plans.length === 0) {
        return <div style={{textAlign: 'center', marginTop: '50px'}}>Chargement des données financières...</div>;
    }

    return (
        <div style={styles.container}>
            {selectedImage && (
                <div style={styles.modalOverlay} onClick={() => setSelectedImage(null)}>
                    <div style={styles.modalContent} onClick={e => e.stopPropagation()}>
                        <button style={styles.closeModal} onClick={() => setSelectedImage(null)}><FiX /></button>
                        <img src={selectedImage} alt="Reçu de paiement" style={styles.fullImage} />
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
                        <input placeholder="Numéro (Téléphone)" style={styles.input} required value={newAccount.account_number} onChange={e => setNewAccount({...newAccount, account_number: e.target.value})} />
                        <button type="submit" style={styles.submitBtn}>Enregistrer</button>
                    </form>
                </div>
            )}

            {showPlanForm && (
                <div style={styles.glassForm}>
                    <h3 style={styles.formTitle}>Créer une Offre d'Abonnement</h3>
                    <form onSubmit={handleAddPlan} style={styles.formGrid}>
                        <input placeholder="Titre du Pack" style={styles.input} required value={newPlan.title} onChange={e => setNewPlan({...newPlan, title: e.target.value})} />
                        <input placeholder="Prix (MRU)" type="number" style={styles.input} required value={newPlan.price} onChange={e => setNewPlan({...newPlan, price: e.target.value})} />
                        <input placeholder="Nombre d'offres" type="number" style={styles.input} required value={newPlan.offres_count} onChange={e => setNewPlan({...newPlan, offres_count: e.target.value})} />
                        <input placeholder="Durée (Mois)" type="number" style={styles.input} required value={newPlan.duration_months} onChange={e => setNewPlan({...newPlan, duration_months: e.target.value})} />
                        <button type="submit" style={{...styles.submitBtn, backgroundColor: '#f59e0b'}}>Activer le Plan</button>
                    </form>
                </div>
            )}

            <h4 style={styles.sectionLabel}><FiCreditCard /> Comptes de Réception</h4>
            <div style={styles.statsRow}>
                {accounts.length > 0 ? accounts.map(acc => (
                    <div key={acc.id} style={styles.accountCard}>
                        <div style={styles.iconCircle}><FiDollarSign color="#fff" /></div>
                        <div style={{ flex: 1 }}>
                            <div style={styles.accName}>{acc.provider_name}</div>
                            <div style={styles.accNum}>{acc.account_number}</div>
                        </div>
                        <button onClick={() => handleDeleteAccount(acc.id)} style={styles.deleteAccBtn}>
                            <FiTrash2 />
                        </button>
                    </div>
                )) : <p style={{color: 'var(--text-sub)'}}>Aucun compte configuré.</p>}
            </div>

            <h4 style={styles.sectionLabel}><FiLayers /> Packs d'Abonnement Actifs</h4>
            <div style={styles.statsRow}>
                {plans.length > 0 ? plans.map(plan => (
                    <div key={plan.id} style={{...styles.accountCard, borderLeft: '4px solid #f59e0b'}}>
                        <div style={{...styles.iconCircle, backgroundColor: '#f59e0b'}}><FiPackage color="#fff" /></div>
                        <div style={{ flex: 1 }}>
                            <div style={styles.accName}>{plan.title}</div>
                            <div style={styles.accNum}>{plan.price} <small style={{fontSize: '10px'}}>MRU</small></div>
                            <div style={{fontSize: '11px', color: 'var(--text-sub)'}}>{plan.offres_count} Offres / {plan.duration_months} Mois</div>
                        </div>
                        <button onClick={() => handleDeletePlan(plan.id)} style={styles.deleteAccBtn}>
                            <FiTrash2 />
                        </button>
                    </div>
                )) : <p style={{color: 'var(--text-sub)'}}>Aucun pack configuré.</p>}
            </div>

            <div style={styles.tableCard}>
                <div style={styles.tableHeader}>
                    <FiActivity /> <span>Vérification des reçus de paiement</span>
                </div>
                <table style={styles.table}>
                    <thead>
                        <tr style={styles.thRow}>
                            <th style={styles.th}>Entreprise</th>
                            <th style={styles.th}>Plan</th>
                            <th style={styles.th}>Preuve</th>
                            <th style={styles.th}>Date</th>
                            <th style={styles.th}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {subscriptions.length > 0 ? subscriptions.map(sub => (
                            <tr key={sub.id} style={styles.tr}>
                                <td style={styles.td}><strong>{sub.enterprise_name}</strong></td>
                                <td style={styles.td}><span style={styles.planBadge}>{sub.plan_title}</span></td>
                                <td style={styles.td}>
                                    {sub.payment_receipt ? (
                                        <button
                                            onClick={() => setSelectedImage(sub.payment_receipt.startsWith('http') ? sub.payment_receipt : `${API_BASE_URL}${sub.payment_receipt}`)}
                                            style={styles.viewBtn}
                                        >
                                            <FiMaximize2 /> Voir Reçu
                                        </button>
                                    ) : "N/A"}
                                </td>
                                <td style={styles.td}>{new Date(sub.date_subscription).toLocaleDateString()}</td>
                                <td style={styles.td}>
                                    {sub.status === 'PENDING' ? (
                                        <div style={styles.btnGroup}>
                                            <button onClick={() => handleVerifySubscription(sub.id, 'ACTIVE')} style={styles.checkBtn}><FiCheck /></button>
                                            <button onClick={() => handleVerifySubscription(sub.id, 'REJECTED')} style={styles.rejectBtn}><FiX /></button>
                                        </div>
                                    ) : (
                                        <span style={{color: sub.status === 'ACTIVE' ? '#10b981' : '#ef4444', fontWeight: 'bold'}}>{sub.status}</span>
                                    )}
                                </td>
                            </tr>
                        )) : (
                            <tr><td colSpan="5" style={{padding: '30px', textAlign: 'center', color: 'var(--text-sub)'}}>Aucune demande en attente.</td></tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '30px' },
    header: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' },
    title: { fontSize: '26px', fontWeight: 'bold', color: 'var(--text-main)' },
    subtitle: { color: 'var(--text-sub)', fontSize: '14px' },
    sectionLabel: { fontSize: '14px', fontWeight: 'bold', color: 'var(--text-sub)', marginBottom: '15px', display: 'flex', alignItems: 'center', gap: '8px', marginTop: '10px' },
    addBtn: { display: 'flex', alignItems: 'center', gap: '8px', padding: '12px 20px', backgroundColor: '#6366f1', color: 'white', border: 'none', borderRadius: '12px', cursor: 'pointer', fontWeight: '600' },
    glassForm: { background: 'var(--bg-card)', padding: '25px', borderRadius: '18px', marginBottom: '30px', border: '1px solid var(--border-color)' },
    formTitle: { fontSize: '16px', fontWeight: 'bold', marginBottom: '20px' },
    formGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '15px' },
    input: { padding: '12px', borderRadius: '10px', background: 'var(--bg-main)', border: '1px solid var(--border-color)', color: 'var(--text-main)' },
    submitBtn: { padding: '12px', backgroundColor: '#10b981', color: 'white', border: 'none', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold' },
    statsRow: { display: 'flex', gap: '20px', marginBottom: '30px', flexWrap: 'wrap' },
    accountCard: { background: 'var(--bg-card)', padding: '20px', borderRadius: '16px', display: 'flex', alignItems: 'center', gap: '15px', minWidth: '280px', border: '1px solid var(--border-color)', transition: '0.3s' },
    deleteAccBtn: { background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: '18px', padding: '5px', borderRadius: '50%', transition: '0.2s' },
    iconCircle: { width: '40px', height: '40px', borderRadius: '50%', backgroundColor: '#6366f1', display: 'flex', alignItems: 'center', justifyContent: 'center' },
    accName: { fontWeight: 'bold', fontSize: '13px', color: 'var(--text-sub)' },
    accNum: { color: 'var(--text-main)', fontSize: '18px', fontWeight: 'bold' },
    tableCard: { background: 'var(--bg-card)', borderRadius: '20px', overflow: 'hidden', border: '1px solid var(--border-color)', marginTop: '20px' },
    tableHeader: { padding: '20px', background: 'var(--bg-sidebar)', display: 'flex', alignItems: 'center', gap: '10px', fontWeight: 'bold' },
    table: { width: '100%', borderCollapse: 'collapse' },
    th: { padding: '15px', textAlign: 'left', color: 'var(--text-sub)', fontSize: '13px' },
    tr: { borderBottom: '1px solid var(--border-color)' },
    td: { padding: '15px', fontSize: '14px' },
    planBadge: { padding: '4px 10px', borderRadius: '20px', backgroundColor: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', fontWeight: 'bold' },
    viewBtn: { background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', border: 'none', padding: '6px 12px', borderRadius: '8px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '5px', fontWeight: 'bold' },
    modalOverlay: { position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0,0,0,0.85)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 9999 },
    modalContent: { position: 'relative', maxWidth: '90%', maxHeight: '90%' },
    closeModal: { position: 'absolute', top: '-40px', right: '0', background: 'transparent', color: 'white', border: 'none', fontSize: '24px', cursor: 'pointer' },
    fullImage: { maxWidth: '100%', maxHeight: '85vh', borderRadius: '10px', boxShadow: '0 0 20px rgba(0,0,0,0.5)' },
    btnGroup: { display: 'flex', gap: '8px' },
    checkBtn: { background: '#10b981', color: 'white', border: 'none', padding: '8px', borderRadius: '8px', cursor: 'pointer' },
    rejectBtn: { background: '#ef4444', color: 'white', border: 'none', padding: '8px', borderRadius: '8px', cursor: 'pointer' }
};

export default ManagePayments;