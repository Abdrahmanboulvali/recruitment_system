import React, { useState, useEffect, useCallback } from 'react';
import axios from 'axios';
import { FiCheckCircle, FiStar, FiZap, FiCreditCard, FiUpload, FiX, FiCheck, FiClock, FiInfo } from 'react-icons/fi';

const Subscriptions = () => {
    const [plans, setPlans] = useState([]);
    const [accounts, setAccounts] = useState([]);
    const [pendingRequests, setPendingRequests] = useState([]);
    const [activeSubscription, setActiveSubscription] = useState(null); // تخزين تفاصيل الاشتراك النشط
    const [loading, setLoading] = useState(true);

    const [selectedPlan, setSelectedPlan] = useState(null);
    const [receipt, setReceipt] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [successMessage, setSuccessMessage] = useState(false);

    const token = localStorage.getItem('access');
    const API_BASE_URL = 'http://127.0.0.1:8000';
    const config = { headers: { Authorization: `Bearer ${token}` } };

    const fetchData = useCallback(async () => {
        try {
            const [plansRes, accRes, subRes] = await Promise.all([
                axios.get(`${API_BASE_URL}/api/subscription-plans/`, config),
                axios.get(`${API_BASE_URL}/api/payment-methods/`, config),
                axios.get(`${API_BASE_URL}/api/subscriptions/`, config)
            ]);

            setPlans(plansRes.data);
            setAccounts(accRes.data);

            // 1. تحديد الاشتراك النشط حالياً (إن وجد)
            const active = subRes.data.find(req => req.status === 'ACTIVE');
            setActiveSubscription(active);

            // 2. تحديد الطلبات المعلقة (PENDING)
            const pending = subRes.data.filter(req => req.status === 'PENDING');
            setPendingRequests(pending);

            setLoading(false);
        } catch (err) {
            console.error("Erreur lors du chargement:", err);
            setLoading(false);
        }
    }, [token]);

    useEffect(() => {
        fetchData();
        const interval = setInterval(fetchData, 20000);
        return () => clearInterval(interval);
    }, [fetchData]);

    const handleFinalSubscribe = async (e) => {
        e.preventDefault();
        if (!receipt) {
            alert("Veuillez joindre une image du reçu de paiement.");
            return;
        }

        setIsSubmitting(true);
        const formData = new FormData();
        formData.append('plan', selectedPlan.id);
        formData.append('payment_receipt', receipt);

        try {
            await axios.post(`${API_BASE_URL}/api/subscriptions/`, formData, {
                headers: {
                    ...config.headers,
                    'Content-Type': 'multipart/form-data'
                }
            });
            setSuccessMessage(true);
            setSelectedPlan(null);
            setReceipt(null);
            fetchData();
        } catch (err) {
            alert("Erreur lors de l'envoi de la demande.");
        } finally {
            setIsSubmitting(false);
        }
    };

    if (loading) return <div style={styles.loading}>Chargement des offres...</div>;

    return (
        <div style={styles.container}>
            <h1 style={styles.mainTitle}>Plans d'Abonnement</h1>
            <p style={styles.subtitle}>Gérez votre abonnement et découvrez nos solutions premium.</p>

            {/* --- قسم الاشتراك النشط (يعرض فقط إذا كان هناك اشتراك حالي) --- */}
            {activeSubscription && (
                <div style={styles.activeSubCard}>
                    <div style={styles.activeHeader}>
                        <FiCheckCircle size={24} color="#10b981" />
                        <h3>Votre abonnement actuel est actif</h3>
                    </div>
                    <div style={styles.activeDetails}>
                        <div style={styles.detailItem}>
                            <span>Pack:</span> <strong>{activeSubscription.plan_details?.title}</strong>
                        </div>
                        <div style={styles.detailItem}>
                            <span>Utilisation:</span>
                            <strong>{activeSubscription.plan_details?.current_usage} / {activeSubscription.plan_details?.offres_count} offres</strong>
                        </div>
                        <div style={styles.detailItem}>
                            <span>Expire le:</span>
                            <strong>{new Date(activeSubscription.date_expiration).toLocaleDateString()}</strong>
                        </div>
                    </div>
                </div>
            )}

            {/* --- قسم الطلبات المعلقة --- */}
            {pendingRequests.length > 0 && (
                <div style={styles.pendingSection}>
                    <h3 style={styles.pendingTitle}>
                        <FiClock style={{ color: '#f59e0b' }} /> Demandes en attente de validation
                    </h3>
                    <div style={styles.pendingGrid}>
                        {pendingRequests.map(req => (
                            <div key={req.id} style={styles.pendingCard}>
                                <div style={styles.pendingInfo}>
                                    <strong>{req.plan_details?.title || "Plan choisi"}</strong>
                                    <span>Envoyé le: {new Date(req.date_subscription).toLocaleDateString()}</span>
                                </div>
                                <div style={styles.pendingBadge}>Vérification du paiement...</div>
                            </div>
                        ))}
                    </div>
                </div>
            )}

            {successMessage && (
                <div style={styles.successBox}>
                    <FiCheck size={24} />
                    <span>Demande envoyée ! Nous vérifions votre reçu.</span>
                    <button onClick={() => setSuccessMessage(false)} style={styles.closeMsg}><FiX /></button>
                </div>
            )}

            {/* --- معلومات الدفع --- */}
            {accounts.length > 0 && (
                <div style={styles.accountsInfo}>
                    <h3 style={styles.accountsTitle}><FiCreditCard /> Moyens de paiement disponibles</h3>
                    <div style={styles.accBadgeContainer}>
                        {accounts.map(acc => (
                            <span key={acc.id} style={styles.accBadge}>
                                {acc.provider_name}: <strong>{acc.account_number}</strong>
                            </span>
                        ))}
                    </div>
                </div>
            )}

            {/* --- شبكة الخطط المتاحة --- */}
            <div style={styles.plansGrid}>
                {plans.map((plan) => {
                    const isCurrentPlan = activeSubscription?.plan === plan.id;
                    return (
                        <div key={plan.id} style={{...styles.planCard, borderColor: isCurrentPlan ? '#10b981' : 'var(--accent-primary)'}}>
                            {isCurrentPlan && <div style={styles.currentLabel}>Plan Actuel</div>}
                            <div style={styles.iconWrapper}>
                                {plan.price > 1000 ? <FiZap size={30} color="#f59e0b" /> : <FiStar size={30} color="var(--accent-primary)" />}
                            </div>
                            <h2 style={styles.planTitle}>{plan.title}</h2>
                            <div style={styles.priceTag}>
                                <span style={styles.amount}>{plan.price}</span>
                                <span style={styles.currency}>MRU</span>
                            </div>
                            <ul style={styles.featureList}>
                                <li style={styles.featureItem}><FiCheckCircle style={styles.checkIcon} /> {plan.offres_count} Offres</li>
                                <li style={styles.featureItem}><FiCheckCircle style={styles.checkIcon} /> Validité: {plan.duration_months} mois</li>
                            </ul>
                            <button
                                onClick={() => setSelectedPlan(plan)}
                                style={{...styles.subscribeBtn, backgroundColor: isCurrentPlan ? '#10b981' : 'var(--accent-primary)'}}
                            >
                                {isCurrentPlan ? "Renouveler ce plan" : "Choisir ce plan"}
                            </button>
                        </div>
                    );
                })}
            </div>

            {/* --- نافذة رفع الإيصال (Overlay) --- */}
            {selectedPlan && (
                <div style={styles.uploadOverlay}>
                    <div style={styles.uploadCard}>
                        <button onClick={() => setSelectedPlan(null)} style={styles.closeBtn}><FiX /></button>
                        <h2 style={styles.formTitle}>Confirmer l'abonnement</h2>
                        <p style={styles.formSubtitle}>Veuillez envoyer le reçu pour le pack <strong>{selectedPlan.title}</strong></p>
                        <form onSubmit={handleFinalSubscribe}>
                            <div style={styles.fileDropZone}>
                                <input type="file" accept="image/*" onChange={(e) => setReceipt(e.target.files[0])} style={styles.hiddenInput} id="file-upload" required />
                                <label htmlFor="file-upload" style={styles.fileLabel}>
                                    <FiUpload size={30} style={{marginBottom: '10px'}} />
                                    {receipt ? <strong>{receipt.name}</strong> : "Cliquez لتنزيل صورة الوصل"}
                                </label>
                            </div>
                            <button type="submit" disabled={isSubmitting} style={styles.confirmBtn}>
                                {isSubmitting ? "Envoi en cours..." : "Envoyer la preuve de paiement"}
                            </button>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

const styles = {
    container: { padding: '40px 20px', textAlign: 'center', minHeight: '100vh', backgroundColor: 'var(--bg-main)' },
    mainTitle: { fontSize: '32px', fontWeight: '800', color: 'var(--text-main)', marginBottom: '10px' },
    subtitle: { color: 'var(--text-muted)', marginBottom: '40px' },

    // ستايل الاشتراك النشط
    activeSubCard: { maxWidth: '800px', margin: '0 auto 30px', padding: '20px', borderRadius: '20px', backgroundColor: 'rgba(16, 185, 129, 0.1)', border: '1px solid #10b981', textAlign: 'left' },
    activeHeader: { display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '15px', color: '#10b981', fontWeight: 'bold' },
    activeDetails: { display: 'flex', justifyContent: 'space-between', flexWrap: 'wrap', gap: '20px' },
    detailItem: { fontSize: '14px', color: 'var(--text-main)' },

    // ستايل الطلبات المعلقة
    pendingSection: { maxWidth: '800px', margin: '0 auto 40px', textAlign: 'left', background: 'rgba(245, 158, 11, 0.05)', padding: '20px', borderRadius: '20px', border: '1px dashed #f59e0b' },
    pendingTitle: { fontSize: '16px', fontWeight: 'bold', color: '#f59e0b', display: 'flex', alignItems: 'center', gap: '8px', marginBottom: '15px' },
    pendingGrid: { display: 'flex', flexDirection: 'column', gap: '10px' },
    pendingCard: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: 'var(--bg-sidebar)', padding: '15px', borderRadius: '12px', border: '1px solid rgba(128,128,128,0.2)' },
    pendingInfo: { display: 'flex', flexDirection: 'column', gap: '4px' },
    pendingBadge: { fontSize: '11px', background: 'rgba(245, 158, 11, 0.1)', color: '#f59e0b', padding: '4px 10px', borderRadius: '15px' },

    successBox: { backgroundColor: '#10b981', color: 'white', padding: '15px 25px', borderRadius: '12px', display: 'flex', alignItems: 'center', gap: '15px', maxWidth: '600px', margin: '0 auto 30px' },
    closeMsg: { background: 'none', border: 'none', color: 'white', cursor: 'pointer', marginLeft: 'auto' },

    accountsInfo: { maxWidth: '800px', margin: '0 auto 40px', background: 'var(--bg-sidebar)', padding: '20px', borderRadius: '20px', border: '1px solid rgba(128,128,128,0.2)' },
    accountsTitle: { fontSize: '15px', marginBottom: '15px', color: 'var(--text-main)', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px' },
    accBadgeContainer: { display: 'flex', gap: '10px', justifyContent: 'center', flexWrap: 'wrap' },
    accBadge: { padding: '8px 15px', background: 'var(--bg-main)', borderRadius: '10px', fontSize: '13px', border: '1px solid var(--accent-primary)', color: 'var(--text-main)' },

    plansGrid: { display: 'flex', gap: '25px', justifyContent: 'center', flexWrap: 'wrap' },
    planCard: { background: 'var(--bg-sidebar)', padding: '40px', borderRadius: '24px', width: '310px', border: '1px solid var(--accent-primary)', display: 'flex', flexDirection: 'column', alignItems: 'center', position: 'relative', transition: '0.3s' },
    currentLabel: { position: 'absolute', top: '15px', right: '15px', background: '#10b981', color: 'white', fontSize: '10px', padding: '4px 10px', borderRadius: '10px', fontWeight: 'bold' },
    iconWrapper: { marginBottom: '15px' },
    planTitle: { fontSize: '22px', fontWeight: '700', color: 'var(--text-main)' },
    priceTag: { margin: '20px 0', display: 'flex', alignItems: 'baseline', gap: '5px' },
    amount: { fontSize: '42px', fontWeight: 'bold', color: 'var(--accent-primary)' },
    currency: { fontSize: '18px', color: 'var(--text-muted)' },
    featureList: { listStyle: 'none', padding: 0, margin: '20px 0', width: '100%', textAlign: 'left' },
    featureItem: { display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '12px', fontSize: '14px', color: 'var(--text-main)' },
    checkIcon: { color: '#10b981' },
    subscribeBtn: { width: '100%', padding: '14px', borderRadius: '14px', border: 'none', color: 'white', fontWeight: 'bold', cursor: 'pointer' },

    uploadOverlay: { position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0,0,0,0.8)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 },
    uploadCard: { background: 'var(--bg-sidebar)', padding: '40px', borderRadius: '25px', width: '90%', maxWidth: '450px', position: 'relative' },
    closeBtn: { position: 'absolute', top: '20px', right: '20px', background: 'none', border: 'none', color: 'var(--text-muted)', fontSize: '20px', cursor: 'pointer' },
    formTitle: { color: 'var(--text-main)', marginBottom: '10px' },
    formSubtitle: { color: 'var(--text-muted)', marginBottom: '25px' },
    fileDropZone: { border: '2px dashed var(--accent-primary)', padding: '30px', borderRadius: '15px', marginBottom: '20px', cursor: 'pointer', color: 'var(--accent-primary)' },
    hiddenInput: { display: 'none' },
    fileLabel: { cursor: 'pointer', display: 'flex', flexDirection: 'column', alignItems: 'center' },
    confirmBtn: { width: '100%', padding: '15px', borderRadius: '12px', border: 'none', backgroundColor: '#10b981', color: 'white', fontWeight: 'bold', cursor: 'pointer' },
    loading: { color: 'var(--text-main)', marginTop: '100px', fontSize: '18px' }
};

export default Subscriptions;