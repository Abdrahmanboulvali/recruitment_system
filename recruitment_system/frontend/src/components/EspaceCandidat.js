import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { FiSearch, FiBriefcase, FiMapPin, FiClock, FiCheckCircle, FiChevronRight, FiLogIn, FiUserPlus, FiSun, FiMoon } from 'react-icons/fi';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);
  const [entreprises, setEntreprises] = useState([]);
  const [activeTab, setActiveTab] = useState('OFFRES');
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedSpecialty, setSelectedSpecialty] = useState("Tous");
  const [expandedOffres, setExpandedOffres] = useState({});
  const [currentTime, setCurrentTime] = useState(new Date());

  // حالة الوضع الداكن (خاصة بالزوار)
  const [isDarkMode, setIsDarkMode] = useState(true);

  // التحقق من حالة تسجيل الدخول
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  const navigate = useNavigate();
  const API_BASE_URL = 'http://127.0.0.1:8000';

  // تبديل الوضع وتحديث متغيرات CSS العالمية
  const toggleTheme = () => {
    const newMode = !isDarkMode;
    setIsDarkMode(newMode);
    document.documentElement.setAttribute('data-theme', newMode ? 'dark' : 'light');
  };

  useEffect(() => {
    const token = localStorage.getItem('access');
    setIsLoggedIn(!!token);

    const fetchData = async () => {
      try {
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
    if (isLoggedIn) {
      navigate(`/postuler/${offreId}`);
    } else {
      navigate('/login');
    }
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
    <div style={{
      ...styles.pageWrapper,
      backgroundColor: isDarkMode ? 'var(--bg-main)' : '#f0f2f5'
    }}>
      <header style={styles.header}>
        <div style={styles.headerTop}>
          <div>
            <h2 style={{...styles.title, color: isDarkMode ? 'var(--text-main)' : '#0f172a'}}>Portail de Recrutement</h2>
            <p style={{...styles.subtitle, color: isDarkMode ? '#64748b' : '#475569'}}>Plateforme intelligente pour la gestion des carrières</p>
          </div>

          <div style={styles.authGroup}>
            {/* يظهر زر التبديل فقط إذا لم يكن المستخدم مسجلاً للدخول */}
            {!isLoggedIn && (
              <>
                <button onClick={toggleTheme} style={{
                  ...styles.themeBtn,
                  backgroundColor: isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.07)',
                  color: isDarkMode ? '#ffcc00' : '#4338ca'
                }}>
                  {isDarkMode ? <FiSun size={20} /> : <FiMoon size={20} />}
                </button>

                <button onClick={() => navigate('/login')} style={styles.loginBtn}>
                  <FiLogIn /> Se connecter
                </button>
                <button onClick={() => navigate('/register')} style={styles.registerBtn}>
                  <FiUserPlus /> S'inscrire
                </button>
              </>
            )}
          </div>
        </div>
      </header>

      <div style={{
        ...styles.smartFilterBar,
        backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#ffffff',
        boxShadow: isDarkMode ? '0 10px 15px -3px rgba(0, 0, 0, 0.3)' : '0 4px 6px -1px rgba(0, 0, 0, 0.1)'
      }}>
        <div style={styles.searchContainer}>
          <FiSearch style={{...styles.searchIcon, color: isDarkMode ? '#64748b' : '#334155'}} />
          <input
            type="text"
            placeholder="Rechercher un emploi, une compétence..."
            style={{
              ...styles.smartSearchInput,
              backgroundColor: isDarkMode ? 'var(--bg-main)' : '#f8fafc',
              color: isDarkMode ? 'var(--text-main)' : '#1e293b',
              border: isDarkMode ? '1px solid rgba(255,255,255,0.05)' : '1px solid #e2e8f0'
            }}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
        </div>
        <div style={styles.specialtiesScrollContainer}>
          {specialties.map(spec => (
            <button
              key={spec}
              onClick={() => setSelectedSpecialty(spec)}
              style={selectedSpecialty === spec ? styles.activeSpecBtn : {
                ...styles.specBtn,
                color: isDarkMode ? 'var(--text-muted)' : '#334155',
                borderColor: isDarkMode ? '#6366f1' : '#cbd5e1'
              }}
            >
              {spec}
            </button>
          ))}
        </div>
      </div>

      <div style={styles.tabsContainer}>
        <button
          onClick={() => setActiveTab('OFFRES')}
          style={activeTab === 'OFFRES' ? styles.activeTab : {
            ...styles.inactiveTab,
            backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#ffffff',
            color: isDarkMode ? '#64748b' : '#334155',
            border: isDarkMode ? 'none' : '1px solid #e2e8f0'
          }}
        >
          <FiBriefcase /> OFFRES ({filteredOffres.length})
        </button>
        <button
          onClick={() => setActiveTab('ENTREPRISES')}
          style={activeTab === 'ENTREPRISES' ? styles.activeTab : {
            ...styles.inactiveTab,
            backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#ffffff',
            color: isDarkMode ? '#64748b' : '#334155',
            border: isDarkMode ? 'none' : '1px solid #e2e8f0'
          }}
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
                <div key={offre.id} style={{
                  ...styles.glassCard,
                  backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#ffffff',
                  boxShadow: isDarkMode ? '0 4px 6px -1px rgba(0, 0, 0, 0.2)' : '0 10px 15px -3px rgba(0, 0, 0, 0.05)'
                }}>
                  <div style={styles.cardTop}>
                    <div style={styles.badgeRow}>
                      <span style={styles.categoryBadge}>Recrutement</span>
                      {timeLeft && (
                        <span style={{...styles.timeBadge, color: isExpired ? '#dc2626' : '#16a34a'}}>
                          <FiClock /> {timeLeft}
                        </span>
                      )}
                    </div>
                    <h3 style={{...styles.offreTitle, color: isDarkMode ? 'var(--text-main)' : '#0f172a'}}>{offre.titre}</h3>
                    <p style={{...styles.entNameLink, color: '#4f46e5'}}>🏢 {offre.enterprise_name}</p>
                  </div>

                  <div style={styles.infoSection}>
                    <div style={styles.skillsContainer}>
                      {(offre.competences_requises || "").split(',').map((skill, i) => (
                        <span key={i} style={{
                          ...styles.skillTag,
                          backgroundColor: isDarkMode ? 'rgba(99, 102, 241, 0.1)' : '#f1f5f9',
                          color: isDarkMode ? 'var(--text-muted)' : '#1e293b'
                        }}>{skill.trim()}</span>
                      ))}
                    </div>
                    <p style={{...styles.description, color: isDarkMode ? 'var(--text-muted)' : '#334155'}}>
                      {expandedOffres[offre.id] ? offre.description : `${offre.description?.substring(0, 100)}...`}
                      <span onClick={() => toggleDescription(offre.id)} style={styles.voirPlus}>
                        {expandedOffres[offre.id] ? " Voir moins" : " Voir plus"}
                      </span>
                    </p>
                  </div>

                  <button
                    onClick={() => handleApplyClick(offre.id)}
                    style={{
                        ...styles.postulerBtn,
                        opacity: isExpired ? 0.5 : 1,
                        background: isLoggedIn ? '#16a34a' : '#4f46e5'
                    }}
                    disabled={isExpired}
                  >
                    {isExpired ? "Expiré" : isLoggedIn ? "Postuler maintenant" : "Connectez-vous pour postuler"}
                  </button>
                </div>
              );
            })}
          </div>
        ) : (
          <div style={styles.grid}>
            {filteredEntreprises.map(ent => (
              <div key={ent.id} style={{
                ...styles.enterpriseCard,
                backgroundColor: isDarkMode ? 'var(--bg-sidebar)' : '#ffffff'
              }}>
                <div style={{...styles.entLogoWrapper, backgroundColor: isDarkMode ? 'var(--bg-main)' : '#f8fafc', border: isDarkMode ? 'none' : '1px solid #e2e8f0'}}>
                  {ent.logo ? <img src={ent.logo} alt="Logo" style={styles.entLogo} /> : <div style={styles.entPlaceholder}>{(ent.nom || ent.name || "E").charAt(0)}</div>}
                </div>
                <h3 style={{...styles.entName, color: isDarkMode ? 'var(--text-main)' : '#0f172a'}}>{ent.nom || ent.name}</h3>
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
    pageWrapper: { padding: '30px', maxWidth: '1400px', margin: '0 auto', minHeight: '100vh', transition: '0.4s ease' },
    header: { marginBottom: '40px' },
    headerTop: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '20px' },
    title: { fontSize: '2.5rem', fontWeight: '900', marginBottom: '10px' },
    subtitle: { fontSize: '1.1rem' },

    authGroup: { display: 'flex', gap: '12px', alignItems: 'center' },
    themeBtn: { width: '45px', height: '45px', borderRadius: '12px', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: '0.3s' },
    loginBtn: { display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 20px', borderRadius: '12px', border: '1.5px solid #4f46e5', background: 'transparent', color: '#4f46e5', fontWeight: 'bold', cursor: 'pointer', transition: '0.3s' },
    registerBtn: { display: 'flex', alignItems: 'center', gap: '8px', padding: '10px 20px', borderRadius: '12px', border: 'none', background: '#4f46e5', color: 'white', fontWeight: 'bold', cursor: 'pointer', transition: '0.3s' },

    smartFilterBar: { padding: '25px', borderRadius: '24px', marginBottom: '35px', border: '1px solid rgba(0,0,0,0.05)' },
    searchContainer: { position: 'relative', marginBottom: '20px' },
    searchIcon: { position: 'absolute', left: '15px', top: '50%', transform: 'translateY(-50%)' },
    smartSearchInput: { width: '100%', padding: '15px 15px 15px 45px', borderRadius: '14px', outline: 'none' },

    specialtiesScrollContainer: { display: 'flex', gap: '10px', overflowX: 'auto', paddingBottom: '5px' },
    specBtn: { padding: '10px 20px', borderRadius: '12px', border: '1px solid', background: 'transparent', cursor: 'pointer', whiteSpace: 'nowrap', fontWeight: '600' },
    activeSpecBtn: { padding: '10px 20px', borderRadius: '12px', border: 'none', background: '#4f46e5', color: 'white', fontWeight: 'bold', cursor: 'pointer', whiteSpace: 'nowrap' },

    tabsContainer: { display: 'flex', gap: '15px', marginBottom: '40px' },
    activeTab: { flex: 1, padding: '15px', backgroundColor: '#4f46e5', color: 'white', border: 'none', borderRadius: '16px', fontWeight: 'bold', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px' },
    inactiveTab: { flex: 1, padding: '15px', border: 'none', borderRadius: '16px', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '10px', fontWeight: '600' },

    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(340px, 1fr))', gap: '30px' },
    glassCard: { borderRadius: '28px', padding: '25px', border: '1px solid rgba(0,0,0,0.05)', display: 'flex', flexDirection: 'column', transition: '0.3s' },
    badgeRow: { display: 'flex', justifyContent: 'space-between', marginBottom: '15px' },
    categoryBadge: { fontSize: '11px', color: '#4f46e5', fontWeight: 'bold', padding: '4px 10px', background: 'rgba(79, 70, 229, 0.1)', borderRadius: '8px' },
    timeBadge: { fontSize: '12px', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '5px' },
    offreTitle: { fontSize: '1.4rem', fontWeight: '800', marginBottom: '8px' },
    entNameLink: { fontSize: '0.95rem', marginBottom: '20px', fontWeight: '700' },

    skillTag: { padding: '5px 12px', borderRadius: '10px', fontSize: '12px', border: '1px solid rgba(0,0,0,0.05)', fontWeight: '600' },
    skillsContainer: { display: 'flex', flexWrap: 'wrap', gap: '8px', marginBottom: '20px' },
    description: { fontSize: '0.95rem', lineHeight: '1.6', fontWeight: '400' },
    voirPlus: { color: '#4f46e5', cursor: 'pointer', fontWeight: 'bold', marginLeft: '5px' },
    postulerBtn: { marginTop: '25px', padding: '16px', color: 'white', border: 'none', borderRadius: '16px', fontWeight: 'bold', cursor: 'pointer', fontSize: '1rem', transition: '0.3s' },

    enterpriseCard: { borderRadius: '28px', padding: '30px', textAlign: 'center', border: '1px solid rgba(0,0,0,0.05)' },
    entLogoWrapper: { width: '90px', height: '90px', borderRadius: '24px', margin: '0 auto 20px', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' },
    entLogo: { width: '100%', height: '100%', objectFit: 'cover' },
    entPlaceholder: { fontSize: '2.5rem', fontWeight: '900', color: '#4f46e5' },
    entName: { fontSize: '1.2rem', fontWeight: '800', marginBottom: '20px' },
    viewEntBtn: { width: '100%', padding: '12px', background: 'transparent', border: '2px solid #4f46e5', color: '#4f46e5', borderRadius: '14px', fontWeight: 'bold', cursor: 'pointer' }
};

export default EspaceCandidat;