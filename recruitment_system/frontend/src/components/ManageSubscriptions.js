import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPackage, FiClock, FiCheckCircle } from 'react-icons/fi';

const ManageSubscriptions = () => {
    const [plans, setPlans] = useState([]);
    const token = localStorage.getItem('access');
    const config = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => {
        fetchPlans();
    }, []);

    const fetchPlans = async () => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/admin/subscription-plans/', config);
            setPlans(res.data);
        } catch (err) {
            console.error("Erreur lors du chargement des plans");
        }
    };

    const handleDelete = async (id) => {
        if(window.confirm("Voulez-vous supprimer ce plan ?")) {
            try {
                await axios.delete(`http://127.0.0.1:8000/api/admin/subscription-plans/${id}/`, config);
                fetchPlans();
            } catch (err) {
                alert("Erreur de suppression");
            }
        }
    };

    return (
        <div style={styles.container}>
            <h2 style={styles.title}>Gestion des Offres d'Abonnement</h2>
            <p style={styles.subtitle}>Consultez et gérez les packs visibles par les entreprises.</p>

            <div style={styles.grid}>
                {plans.map(plan => (
                    <div key={plan.id} style={styles.card}>
                        <div style={styles.cardHeader}>
                            <FiPackage size={24} color="#6366f1" />
                            <div style={styles.actions}>
                                <button onClick={() => handleDelete(plan.id)} style={styles.iconBtnRed}><FiTrash2 /></button>
                            </div>
                        </div>
                        <h3 style={styles.planTitle}>{plan.title}</h3>
                        <div style={styles.priceTag}>{plan.price} <span style={{fontSize: '14px'}}>MRU</span></div>

                        <div style={styles.details}>
                            <div style={styles.detailItem}><FiCheckCircle color="#10b981" /> {plan.offres_count} Offres d'emploi</div>
                            <div style={styles.detailItem}><FiClock color="#f59e0b" /> Validité: {plan.duration_months} mois</div>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

const styles = {
    container: { padding: '30px' },
    title: { fontSize: '24px', fontWeight: 'bold', marginBottom: '5px' },
    subtitle: { color: 'gray', marginBottom: '30px' },
    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: '20px' },
    card: { background: 'var(--bg-card)', padding: '25px', borderRadius: '20px', border: '1px solid var(--border-color)', position: 'relative' },
    cardHeader: { display: 'flex', justifyContent: 'space-between', marginBottom: '15px' },
    planTitle: { fontSize: '20px', fontWeight: '800', margin: '10px 0' },
    priceTag: { fontSize: '28px', fontWeight: 'bold', color: '#6366f1', marginBottom: '20px' },
    details: { borderTop: '1px solid var(--border-color)', paddingTop: '15px' },
    detailItem: { display: 'flex', alignItems: 'center', gap: '10px', marginBottom: '10px', fontSize: '14px' },
    actions: { display: 'flex', gap: '5px' },
    iconBtnRed: { background: 'none', border: 'none', color: '#ef4444', cursor: 'pointer', padding: '5px' }
};

export default ManageSubscriptions;