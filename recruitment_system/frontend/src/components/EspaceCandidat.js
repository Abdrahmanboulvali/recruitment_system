import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);
  const [activeTab, setActiveTab] = useState('OFFRES');
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedSpecialty, setSelectedSpecialty] = useState("Tous");

  // --- حالة للتحكم في توسيع النصوص لكل عرض بشكل مستقل ---
  const [expandedOffres, setExpandedOffres] = useState({});

  const navigate = useNavigate();

  useEffect(() => {
    axios.get('http://127.0.0.1:8000/api/offres/')
    .then(res => setOffres(res.data))
    .catch(err => console.error("Erreur lors du chargement des offres", err));
  }, []);

  // دالة لتبديل حالة العرض (فتح/إغلاق)
  const toggleDescription = (id) => {
    setExpandedOffres(prev => ({
      ...prev,
      [id]: !prev[id]
    }));
  };

  const handleApplyClick = (offreId) => {
    const token = localStorage.getItem('access');
    if (token) {
      navigate(`/postuler/${offreId}`);
    } else {
      navigate('/login');
    }
  };

  // تعريف التخصصات الرئيسية لفرز قسم "Autre"
  const mainSpecialties = [
    "Data Science", "Full Stack", "Data Analyst",
    "Comptabilité", "Marketing", "RH", "Design", "Finance"
  ];

  const specialties = ["Tous", ...mainSpecialties, "Autre"];

  const filteredOffres = offres.filter(offre => {
    // 1. منطق البحث النصي
    const matchesSearch =
      offre.titre.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (offre.description && offre.description.toLowerCase().includes(searchTerm.toLowerCase()));

    // 2. منطق تصفية التخصصات (بما في ذلك Autre الذكي)
    let matchesSpecialty = false;

    if (selectedSpecialty === "Tous") {
      matchesSpecialty = true;
    } else if (selectedSpecialty === "Autre") {
      // يعرض الوظائف التي لا تحتوي في عنوانها على أي تخصص من القائمة الرئيسية
      matchesSpecialty = !mainSpecialties.some(spec =>
        offre.titre.toLowerCase().includes(spec.toLowerCase())
      );
    } else {
      // الفلترة العادية بالتطابق النصي
      matchesSpecialty = offre.titre.toLowerCase().includes(selectedSpecialty.toLowerCase());
    }

    return matchesSearch && matchesSpecialty;
  });

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h2 style={styles.title}>Portail de Recrutement</h2>
        <p style={{ opacity: 0.7, color: 'var(--text-main)' }}>Plateforme intelligente pour la gestion des carrières</p>
      </header>

      <div style={styles.smartFilterBar}>
        <div style={styles.searchWrapper}>
          <input
            type="text"
            placeholder="🔍 Rechercher un emploi, une compétence ou une description spécifique..."
            style={styles.smartSearchInput}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div style={styles.specialtiesScrollContainer}>
          {specialties.map(spec => (
            <button
              key={spec}
              onClick={() => setSelectedSpecialty(spec)}
              style={selectedSpecialty === spec ? styles.activeSpecBtn : styles.specBtn}
            >
              {spec}
            </button>
          ))}
        </div>
      </div>

      <div style={styles.tabsContainer}>
        <button
          onClick={() => setActiveTab('OFFRES')}
          style={activeTab === 'OFFRES' ? styles.activeTab : styles.inactiveTab}
        >
          📋 OFFRES D'EMPLOI ({filteredOffres.length})
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

      <main style={styles.mainContent}>
        {activeTab === 'OFFRES' && (
          <div style={styles.grid}>
            {filteredOffres.length > 0 ? filteredOffres.map(offre => {
              const isExpanded = expandedOffres[offre.id];
              const fullDescription = offre.description || "";
              const shouldShowButton = fullDescription.length > 150;
              const displayedText = isExpanded
                ? fullDescription
                : fullDescription.substring(0, 150) + (shouldShowButton ? "..." : "");

              return (
                <div key={offre.id} style={styles.glassCard}>
                  <div>
                    <div style={styles.cardHeader}>
                       <span style={styles.categoryBadge}>Recrutement</span>
                       <h3 style={styles.offreTitle}>{offre.titre}</h3>
                    </div>
                    <div style={styles.infoSection}>
                       <p style={styles.expInfo}>⏳ <strong>Expérience:</strong> {offre.experience_min} ans min</p>
                       <p style={styles.description}>
                         {displayedText}
                         {shouldShowButton && (
                           <span onClick={() => toggleDescription(offre.id)} style={styles.voirPlus}>
                             {isExpanded ? " Voir moins" : " Voir plus"}
                           </span>
                         )}
                       </p>
                    </div>
                  </div>
                  <button onClick={() => handleApplyClick(offre.id)} style={styles.postulerBtn}>Postuler</button>
                </div>
              );
            }) : (
              <div style={{ gridColumn: '1/-1', textAlign: 'center', padding: '50px', color: 'var(--text-muted)' }}>
                <p>Aucun résultat ne correspond à votre recherche actuelle.</p>
              </div>
            )}
          </div>
        )}
      </main>
    </div>
  );
};

const styles = {
  pageWrapper: { padding: '20px', maxWidth: '1200px', margin: '0 auto', color: 'var(--text-main)', width: '100%', boxSizing: 'border-box' },
  header: { marginBottom: '30px' },
  title: { fontSize: '32px', fontWeight: '900', margin: '0' },
  smartFilterBar: {
    display: 'flex', flexDirection: 'column', gap: '15px', marginBottom: '35px',
    background: 'var(--bg-sidebar)', padding: '20px', borderRadius: '20px',
    border: '1px solid rgba(128,128,128,0.1)', boxShadow: '0 8px 32px rgba(0,0,0,0.1)'
  },
  searchWrapper: { width: '100%' },
  smartSearchInput: {
    width: '100%', padding: '14px 20px', borderRadius: '12px',
    border: '1px solid rgba(128,128,128,0.2)', background: 'var(--bg-main)',
    color: 'var(--text-main)', outline: 'none', fontSize: '15px', boxSizing: 'border-box'
  },
  specialtiesScrollContainer: {
    display: 'flex', gap: '10px', overflowX: 'auto', paddingBottom: '5px',
    msOverflowStyle: 'none', scrollbarWidth: 'none',
  },
  specBtn: {
    padding: '8px 18px', borderRadius: '10px', border: '1px solid rgba(99, 102, 241, 0.2)',
    background: 'rgba(255,255,255,0.05)', color: 'var(--text-muted)', cursor: 'pointer',
    fontSize: '13px', whiteSpace: 'nowrap', transition: '0.3s'
  },
  activeSpecBtn: {
    padding: '8px 18px', borderRadius: '10px', border: 'none',
    background: '#6366f1', color: 'white', cursor: 'pointer',
    fontSize: '13px', whiteSpace: 'nowrap', fontWeight: 'bold',
    boxShadow: '0 4px 12px rgba(99, 102, 241, 0.3)'
  },
  tabsContainer: { display: 'flex', gap: '10px', marginBottom: '40px', borderBottom: '1px solid rgba(128,128,128,0.2)', paddingBottom: '10px' },
  activeTab: { padding: '12px 25px', backgroundColor: '#6366f1', color: 'white', border: 'none', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer' },
  inactiveTab: { padding: '12px 25px', backgroundColor: 'transparent', color: 'var(--text-muted)', border: 'none', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer' },
  mainContent: { minHeight: '400px' },
  grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '25px' },
  glassCard: {
    background: 'var(--bg-sidebar)', borderRadius: '24px', padding: '25px',
    border: '1px solid rgba(128,128,128,0.1)', display: 'flex',
    flexDirection: 'column', justifyContent: 'space-between', transition: 'all 0.3s ease'
  },
  categoryBadge: { fontSize: '10px', textTransform: 'uppercase', color: '#6366f1', fontWeight: 'bold' },
  offreTitle: { fontSize: '20px', margin: '10px 0' },
  expInfo: { fontSize: '14px', marginBottom: '10px' },
  description: { fontSize: '14px', color: 'var(--text-muted)', lineHeight: '1.6', marginBottom: '20px' },
  voirPlus: {
    color: '#6366f1', cursor: 'pointer', fontWeight: 'bold',
    marginLeft: '8px', fontSize: '13px', textDecoration: 'underline'
  },
  postulerBtn: { width: '100%', padding: '14px', backgroundColor: '#10b981', color: 'white', borderRadius: '15px', fontWeight: 'bold', border: 'none', cursor: 'pointer' }
};

export default EspaceCandidat;