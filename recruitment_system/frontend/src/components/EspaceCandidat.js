import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);
  const [activeTab, setActiveTab] = useState('OFFRES'); // الحالة للتحكم في التبويب النشط
  const navigate = useNavigate();

  useEffect(() => {
    axios.get('http://127.0.0.1:8000/api/offres/')
    .then(res => setOffres(res.data))
    .catch(err => console.error("Erreur lors du chargement des offres", err));
  }, []);

  const handleApplyClick = (offreId) => {
    const token = localStorage.getItem('access');
    if (token) navigate(`/postuler/${offreId}`);
    else {
      alert("Connectez-vous pour postuler...");
      navigate('/login');
    }
  };

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h2 style={styles.title}>Portail de Recrutement</h2>
        <p style={{ opacity: 0.7 }}>Plateforme intelligente pour la gestion des carrières</p>
      </header>

      {/* شريط التبويبات العلوي */}
      <div style={styles.tabsContainer}>
        <button
          onClick={() => setActiveTab('OFFRES')}
          style={activeTab === 'OFFRES' ? styles.activeTab : styles.inactiveTab}
        >
          📋 OFFRES D'EMPLOI ({offres.length})
        </button>
        <button
          onClick={() => setActiveTab('ENTREPRISES')}
          style={activeTab === 'ENTREPRISES' ? styles.activeTab : styles.inactiveTab}
        >
          🏢 LES ENTREPRISES
        </button>
        <button
          onClick={() => setActiveTab('AVIS')}
          style={activeTab === 'AVIS' ? styles.activeTab : styles.inactiveTab}
        >
          📢 AVIS ET PUBLICATIONS
        </button>
      </div>

      {/* عرض المحتوى بناءً على التبويب المختار */}
      <main style={styles.mainContent}>
        {activeTab === 'OFFRES' && (
          <div style={styles.grid}>
            {offres.map(offre => (
              <div key={offre.id} style={styles.glassCard}>
                <div style={styles.cardHeader}>
                   <span style={styles.categoryBadge}>Recrutement</span>
                   <h3 style={styles.offreTitle}>{offre.titre}</h3>
                </div>
                <div style={styles.infoSection}>
                   <p style={styles.expInfo}>⏳ <strong>Expérience:</strong> {offre.experience_min} ans min</p>
                   <p style={styles.description}>{offre.description ? offre.description.substring(0, 150) : "..."}...</p>
                </div>
                <button onClick={() => handleApplyClick(offre.id)} style={styles.postulerBtn}>Postuler via IA 🚀</button>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'ENTREPRISES' && (
          <div style={styles.companiesGrid}>
            {['Alcom', 'SNDE', 'Mauritel', 'Chinguittel', 'Attijari Bank', 'Star Oil'].map((company, index) => (
              <div key={index} style={styles.companyCard}>
                <div style={styles.companyIcon}>{company[0]}</div>
                <h4 style={styles.companyName}>{company}</h4>
                <p style={styles.companyMeta}>Siège: Nouakchott, MRT</p>
                <button style={styles.viewJobsBtn}>Voir les offres</button>
              </div>
            ))}
          </div>
        )}

        {activeTab === 'AVIS' && (
          <div style={styles.emptyState}>
            <p>📢 Aucune nouvelle publication pour le moment.</p>
          </div>
        )}
      </main>
    </div>
  );
};

const styles = {
  pageWrapper: { padding: '40px 20px', maxWidth: '1400px', margin: '0 auto', color: 'white' },
  header: { marginBottom: '30px' },
  title: { fontSize: '32px', fontWeight: '900', margin: '0' },

  // تنسيق شريط التبويبات
  tabsContainer: { display: 'flex', gap: '10px', marginBottom: '40px', borderBottom: '1px solid rgba(255,255,255,0.1)', paddingBottom: '10px' },
  activeTab: { padding: '12px 25px', backgroundColor: '#6366f1', color: 'white', border: 'none', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer', transition: '0.3s' },
  inactiveTab: { padding: '12px 25px', backgroundColor: 'transparent', color: 'rgba(255,255,255,0.5)', border: 'none', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer', transition: '0.3s' },

  mainContent: { minHeight: '400px' },

  // شبكة العروض
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '25px' },
  glassCard: { background: 'rgba(255, 255, 255, 0.05)', borderRadius: '24px', padding: '25px', border: '1px solid rgba(255, 255, 255, 0.1)' },
  offreTitle: { fontSize: '20px', color: '#6366f1', margin: '10px 0' },
  postulerBtn: { width: '100%', padding: '14px', backgroundColor: '#10b981', color: 'white', borderRadius: '15px', fontWeight: 'bold', border: 'none', cursor: 'pointer' },

  // شبكة الشركات
  companiesGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(220px, 1fr))', gap: '20px' },
  companyCard: { background: 'rgba(255, 255, 255, 0.03)', padding: '30px', borderRadius: '24px', textAlign: 'center', border: '1px solid rgba(255, 255, 255, 0.05)' },
  companyIcon: { width: '60px', height: '60px', background: '#6366f1', borderRadius: '15px', margin: '0 auto 15px', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '24px', fontWeight: 'bold' },
  companyName: { fontSize: '18px', fontWeight: 'bold', marginBottom: '5px' },
  companyMeta: { fontSize: '12px', opacity: 0.5, marginBottom: '15px' },
  viewJobsBtn: { padding: '8px 15px', background: 'rgba(99, 102, 241, 0.1)', color: '#6366f1', border: 'none', borderRadius: '8px', cursor: 'pointer', fontSize: '12px', fontWeight: 'bold' },

  emptyState: { textAlign: 'center', padding: '100px', opacity: 0.5 }
};

export default EspaceCandidat;