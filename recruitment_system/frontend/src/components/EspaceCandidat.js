import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { FiSearch, FiBriefcase, FiMapPin, FiClock, FiCheckCircle, FiChevronRight } from 'react-icons/fi';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);
  const [entreprises, setEntreprises] = useState([]);
  const [activeTab, setActiveTab] = useState('OFFRES');
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedSpecialty, setSelectedSpecialty] = useState("Tous");
  const [expandedOffres, setExpandedOffres] = useState({});
  const [currentTime, setCurrentTime] = useState(new Date());

  const navigate = useNavigate();
  const API_BASE_URL = 'http://127.0.0.1:8000';

  useEffect(() => {
    const fetchData = async () => {
      try {
        const token = localStorage.getItem('access');
        const config = {
          headers: token ? { Authorization: `Bearer ${token}` } : {}
        };

        const [offresRes, entRes] = await Promise.all([
            axios.get(`${API_BASE_URL}/api/offres/`, config),
            axios.get(`${API_BASE_URL}/api/enterprises/`, config)
        ]);

        setOffres(Array.isArray(offresRes.data) ? offresRes.data : offresRes.data.results || []);
        setEntreprises(Array.isArray(entRes.data) ? entRes.data : entRes.data.results || []);

      } catch (err) {
        console.error("Erreur de récupération: ", err);
      }
    };

    fetchData();
    const timer = setInterval(() => setCurrentTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, [API_BASE_URL]);

  const calculateTimeLeft = (expiryDate) => {
    if (!expiryDate) return null;
    const difference = new Date(expiryDate) - currentTime;
    if (difference <= 0) return "Expiré";

    const days = Math.floor(difference / (1000 * 60 * 60 * 24));
    const hours = Math.floor((difference / (1000 * 60 * 60)) % 24);
    if (days > 0) return `Reste ${days}j ${hours}h`;
    return "Moins d'un jour";
  };

  const toggleDescription = (id) => setExpandedOffres(prev => ({ ...prev, [id]: !prev[id] }));

  const handleApplyClick = (offreId) => {
    const token = localStorage.getItem('access');
    navigate(token ? `/postuler/${offreId}` : '/login');
  };

  const mainSpecialties = ["Data Science", "Full Stack", "Data Analyst", "Comptabilité", "Marketing", "RH", "Design", "Finance"];
  const specialties = ["Tous", ...mainSpecialties, "Autre"];

  const filteredOffres = offres.filter(offre => {
    const title = (offre.titre || "").toLowerCase();
    const search = searchTerm.toLowerCase();
    const matchesSearch = title.includes(search) || (offre.description || "").toLowerCase().includes(search);

    if (selectedSpecialty === "Tous") return matchesSearch;
    const mapping = {
      "Data Science": ["data science", "stat", "بيانات"],
      "Full Stack": ["full stack", "dev", "front", "back"],
      "Data Analyst": ["analyst", "data"],
      "Comptabilité": ["compt", "محاسب"],
      "Marketing": ["market", "تسويق"],
      "RH": ["rh", "ressource"],
      "Design": ["design", "ui", "ux"],
      "Finance": ["finan", "مالية"]
    };
    const targetKeywords = mapping[selectedSpecialty] || [selectedSpecialty.toLowerCase()];
    return matchesSearch && targetKeywords.some(keyword => title.includes(keyword));
  });

  const filteredEntreprises = entreprises.filter(ent =>
    (ent.nom || ent.name || "").toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h2 style={styles.title}>Portail de Recrutement</h2>
        <p style={styles.subtitle}>Plateforme intelligente pour la gestion des carrières</p>
      </header>

      <div style={styles.smartFilterBar}>
        <div style={styles.searchContainer}>
          <FiSearch style={styles.searchIcon} />
          <input
            type="text"
            placeholder="Rechercher un emploi, une compétence..."
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
          <FiBriefcase /> OFFRES ({filteredOffres.length})
        </button>
        <button
          onClick={() => setActiveTab('ENTREPRISES')}
          style={activeTab === 'ENTREPRISES' ? styles.activeTab : styles.inactiveTab}
        >
          🏢 ENTREPRISES ({filteredEntreprises.length})
        </button>
      </div>

      <main style={styles.mainContent}>
        {activeTab === 'OFFRES' ? (
          <div style={styles.grid}>
            {filteredOffres.map(offre => {
              const timeLeft = calculateTimeLeft(offre.date_expiration);
              const isExpired = timeLeft === "Expiré";
              return (
                <div key={offre.id} style={styles.glassCard}>
                  <div style={styles.cardTop}>
                    <div style={styles.badgeRow}>
                      <span style={styles.categoryBadge}>Recrutement</span>
                      {timeLeft && (
                        <span style={{...styles.timeBadge, color: isExpired ? 'var(--danger-red)' : 'var(--success-green)'}}>
                          <FiClock /> {timeLeft}
                        </span>
                      )}
                    </div>
                    <h3 style={styles.offreTitle}>{offre.titre}</h3>
                    <p style={styles.entNameLink}>🏢 {offre.enterprise_name}</p>
                  </div>

                  <div style={styles.infoSection}>
                    <div style={styles.skillsContainer}>
                      {(offre.competences_requises || "").split(',').map((skill, i) => (
                        <span key={i} style={styles.skillTag}>{skill.trim()}</span>
                      ))}
                    </div>
                    <p style={styles.description}>
                      {expandedOffres[offre.id] ? offre.description : `${offre.description?.substring(0, 100)}...`}
                      <span onClick={() => toggleDescription(offre.id)} style={styles.voirPlus}>
                        {expandedOffres[offre.id] ? " Voir moins" : " Voir plus"}
                      </span>
                    </p>
                  </div>

                  <button
                    onClick={() => handleApplyClick(offre.id)}
                    style={{...styles.postulerBtn, opacity: isExpired ? 0.5 : 1}}
                    disabled={isExpired}
                  >
                    {isExpired ? "Expiré" : "Postuler maintenant"}
                  </button>
                </div>
              );
            })}
          </div>
        ) : (
          <div style={styles.grid}>
            {filteredEntreprises.map(ent => (
              <div key={ent.id} style={styles.enterpriseCard}>
                <div style={styles.entLogoWrapper}>
                  {ent.logo ? <img src={ent.logo} alt="Logo" style={styles.entLogo} /> : <div style={styles.entPlaceholder}>{(ent.nom || ent.name || "E").charAt(0)}</div>}
                </div>
                <h3 style={styles.entName}>{ent.nom || ent.name}</h3>
                <button onClick={() => navigate(`/entreprises/${ent.id}`)} style={styles.viewEntBtn}>Voir Profil</button>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  );
};

const styles = {
    pageWrapper: { padding: '30px', maxWidth: '1400px', margin: '0 auto', backgroundColor: 'var(--bg-main)', minHeight: '100vh', transition: 'var(--transition-speed)' },
    header: { marginBottom: '40px' },
    title: { fontSize: '2.5rem', fontWeight: '900', color: 'var(--text-main)', marginBottom: '10px' },
    subtitle: { color: 'var(--text-muted)', fontSize: '1rem' },

    smartFilterBar: { background: 'var(--bg-sidebar)', padding: '25px', borderRadius: '24px', marginBottom: '35px', border: '1px solid rgba(255,255,255,0.05)', boxShadow: 'var(--shadow-lg)' },
    searchContainer: { position: 'relative', marginBottom: '20px' },
    searchIcon: { position: 'absolute', left: '15px', top: '50%', transform: 'translateY(-50%)', color: 'var(--text-muted)' },
    smartSearchInput: { width: '100%', padding: '15px 15px 15px 45px', borderRadius: '14px', border: '1px solid rgba(255,255,255,0.1)', background: 'var(--bg-main)', color: 'var(--text-main)', outline: 'none' },

    specialtiesScrollContainer: { display: 'flex', gap: '10px', overflowX: 'auto', paddingBottom: '5px' },
    specBtn: { padding: '10px 20px', borderRadius: '12px', border: '1px solid var(--accent-primary)', background: 'transparent', color: 'var(--text-muted)', cursor: 'pointer', whiteSpace: 'nowrap' },
    activeSpecBtn: { padding: '10px 20px', borderRadius: '12px', border: 'none', background: 'var(--accent-primary)', color: 'white', fontWeight: 'bold', cursor: 'pointer', whiteSpace: 'nowrap' },

    tabsContainer: { display: 'flex', gap: '15px', marginBottom: '40px' },
    activeTab: { flex: 1, padding: '15px', backgroundColor: 'var(--accent-primary)', color: 'white', border: 'none', borderRadius: '16px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' },
    inactiveTab: { flex: 1, padding: '15px', backgroundColor: 'var(--bg-sidebar)', color: 'var(--text-muted)', border: 'none', borderRadius: '16px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' },

    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '30px' },
    glassCard: { background: 'var(--bg-sidebar)', borderRadius: '28px', padding: '25px', border: '1px solid rgba(255,255,255,0.05)', display: 'flex', flexDirection: 'column', transition: '0.3s' },
    badgeRow: { display: 'flex', justifyContent: 'space-between', marginBottom: '15px' },
    categoryBadge: { fontSize: '11px', color: 'var(--accent-primary)', fontWeight: 'bold', padding: '4px 10px', background: 'rgba(99, 102, 241, 0.1)', borderRadius: '8px' },
    timeBadge: { fontSize: '12px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
    offreTitle: { fontSize: '1.4rem', color: 'var(--text-main)', fontWeight: '800', marginBottom: '8px' },
    entNameLink: { color: 'var(--accent-primary)', fontSize: '0.9rem', marginBottom: '20px' },

    skillTag: { padding: '5px 12px', background: 'rgba(99, 102, 241, 0.05)', color: 'var(--text-muted)', borderRadius: '10px', fontSize: '12px', border: '1px solid rgba(255,255,255,0.05)' },
    skillsContainer: { display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '20px' },
    description: { color: 'var(--text-muted)', fontSize: '0.95rem', lineHeight: '1.6' },
    voirPlus: { color: 'var(--accent-primary)', cursor: 'pointer', fontWeight: 'bold', marginLeft: '5px' },
    postulerBtn: { marginTop: '25px', padding: '16px', background: 'var(--success-green)', color: 'white', border: 'none', borderRadius: '16px', fontWeight: 'bold', cursor: 'pointer', fontSize: '1rem' },

    enterpriseCard: { background: 'var(--bg-sidebar)', borderRadius: '28px', padding: '30px', textAlign: 'center', border: '1px solid rgba(255,255,255,0.05)' },
    entLogoWrapper: { width: '90px', height: '90px', borderRadius: '24px', background: 'var(--bg-main)', margin: '0 auto 20px', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
    entLogo: { width: '100%', height: '100%', objectFit: 'cover' },
    entPlaceholder: { fontSize: '2.5rem', fontWeight: '900', color: 'var(--accent-primary)' },
    entName: { color: 'var(--text-main)', fontSize: '1.2rem', fontWeight: '800', marginBottom: '20px' },
    viewEntBtn: { width: '100%', padding: '12px', background: 'transparent', border: '2px solid var(--accent-primary)', color: 'var(--accent-primary)', borderRadius: '14px', fontWeight: 'bold', cursor: 'pointer' }
};

export default EspaceCandidat;