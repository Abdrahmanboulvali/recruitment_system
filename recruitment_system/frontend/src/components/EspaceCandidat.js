import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

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
        const offresRes = await axios.get('http://127.0.0.1:8000/api/offres/');
        setOffres(Array.isArray(offresRes.data) ? offresRes.data : offresRes.data.results || []);

        const entRes = await axios.get('http://127.0.0.1:8000/api/enterprises/');
        setEntreprises(Array.isArray(entRes.data) ? entRes.data : entRes.data.results || []);
      } catch (err) {
        console.error("خطأ في جلب البيانات: ", err);
      }
    };

    fetchData();

    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    return () => clearInterval(timer);
  }, []);

  const calculateTimeLeft = (expiryDate) => {
    if (!expiryDate) return null;
    const difference = new Date(expiryDate) - currentTime;

    if (difference <= 0) return "Expiré";

    const days = Math.floor(difference / (1000 * 60 * 60 * 24));
    const hours = Math.floor((difference / (1000 * 60 * 60)) % 24);
    const minutes = Math.floor((difference / 1000 / 60) % 60);
    const seconds = Math.floor((difference / 1000) % 60);

    if (days > 0) return `Reste ${days}j ${hours}h`;
    if (hours > 0) return `Reste ${hours}h ${minutes}m`;
    if (minutes > 0) return `Reste ${minutes}m ${seconds}s`;
    return `Reste ${seconds}s`;
  };

  const toggleDescription = (id) => {
    setExpandedOffres(prev => ({ ...prev, [id]: !prev[id] }));
  };

  const handleApplyClick = (offreId) => {
    const token = localStorage.getItem('access');
    if (token) {
      navigate(`/postuler/${offreId}`);
    } else {
      navigate('/login');
    }
  };

  const mainSpecialties = ["Data Science", "Full Stack", "Data Analyst", "Comptabilité", "Marketing", "RH", "Design", "Finance"];
  const specialties = ["Tous", ...mainSpecialties, "Autre"];

  // --- الجزء الذي تم إصلاحه ليعمل مع العناوين الفرنسية والإنجليزية ---
  const filteredOffres = offres.filter(offre => {
    const title = (offre.titre || "").toLowerCase();
    const desc = (offre.description || "").toLowerCase();
    const skills = (offre.competences_requises || "").toLowerCase();
    const search = searchTerm.toLowerCase();

    const matchesSearch = title.includes(search) || desc.includes(search) || skills.includes(search);

    let matchesSpecialty = false;

    if (selectedSpecialty === "Tous") {
      matchesSpecialty = true;
    } else if (selectedSpecialty === "Autre") {
      // إذا لم يكن العنوان يحتوي على أي من الكلمات المفتاحية للتخصصات الرئيسية
      const keywords = ["data", "stat", "analyst", "donnée", "stack", "dev", "compt", "market", "rh", "design", "finan"];
      matchesSpecialty = !keywords.some(key => title.includes(key));
    } else {
      // ربط كل تخصص بكلمات دلالية محتملة في العنوان (فرنسي/إنجليزي)
      const mapping = {
        "Data Science": ["data science", "stat", "بيانات", "donnée"],
        "Full Stack": ["full stack", "dev", "front", "back", "logiciel", "برمج"],
        "Data Analyst": ["analyst", "data", "donnée", "تحليل"],
        "Comptabilité": ["compt", "محاسب"],
        "Marketing": ["market", "تسويق"],
        "RH": ["rh", "ressource", "بشرية"],
        "Design": ["design", "ui", "ux", "مصمم"],
        "Finance": ["finan", "مالية"]
      };

      const targetKeywords = mapping[selectedSpecialty] || [selectedSpecialty.toLowerCase()];
      matchesSpecialty = targetKeywords.some(keyword => title.includes(keyword));
    }

    return matchesSearch && matchesSpecialty;
  });

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h2 style={styles.title}>Portail de Recrutement</h2>
        <p style={{ opacity: 0.7, color: '#94a3b8' }}>Plateforme intelligente pour la gestion des carrières</p>
      </header>

      <div style={styles.smartFilterBar}>
        <div style={styles.searchWrapper}>
          <input
            type="text"
            placeholder="🔍 Rechercher un emploi, une compétence ou une entreprise..."
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
          🏢 LES ENTREPRISES ({entreprises.length})
        </button>
      </div>

      <main style={styles.mainContent}>
        {activeTab === 'OFFRES' && (
          <div style={styles.grid}>
            {filteredOffres.length > 0 ? filteredOffres.map(offre => {
              const isExpanded = expandedOffres[offre.id];
              const fullDescription = offre.description || "";
              const displayedText = isExpanded ? fullDescription : fullDescription.substring(0, 150) + (fullDescription.length > 150 ? "..." : "");

              const timeLeft = calculateTimeLeft(offre.date_expiration);

              return (
                <div key={offre.id} style={styles.glassCard}>
                  <div>
                    <div style={styles.cardHeader}>
                       <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                          <span style={styles.categoryBadge}>Recrutement</span>
                          {timeLeft && (
                            <span style={{
                               fontSize: '11px',
                               color: timeLeft === "Expiré" ? "#ef4444" : "#10b981",
                               backgroundColor: 'rgba(255,255,255,0.05)',
                               padding: '4px 8px',
                               borderRadius: '8px',
                               fontWeight: 'bold',
                               minWidth: '100px',
                               textAlign: 'center'
                            }}>
                               ⏱ {timeLeft}
                            </span>
                          )}
                       </div>
                       <h3 style={styles.offreTitle}>{offre.titre}</h3>
                       {offre.enterprise_name && <p style={styles.entNameLink}>🏢 {offre.enterprise_name}</p>}
                    </div>
                    <div style={styles.infoSection}>
                       <p style={styles.expInfo}>⏳ <strong>Expérience:</strong> {offre.experience_min} ans min</p>

                       {offre.competences_requises && (
                         <div style={styles.skillsContainer}>
                           {offre.competences_requises.split(',').map((skill, i) => (
                             <span key={i} style={styles.skillTag}>{skill.trim()}</span>
                           ))}
                         </div>
                       )}

                       <p style={styles.description}>
                         {displayedText}
                         {fullDescription.length > 150 && (
                           <span onClick={() => toggleDescription(offre.id)} style={styles.voirPlus}>
                             {isExpanded ? " Voir moins" : " Voir plus"}
                           </span>
                         )}
                       </p>
                    </div>
                  </div>
                  <button
                    onClick={() => handleApplyClick(offre.id)}
                    style={{
                        ...styles.postulerBtn,
                        backgroundColor: timeLeft === "Expiré" ? "#334155" : "#10b981",
                        cursor: timeLeft === "Expiré" ? "not-allowed" : "pointer"
                    }}
                    disabled={timeLeft === "Expiré"}
                  >
                    {timeLeft === "Expiré" ? "Expiré" : "Postuler"}
                  </button>
                </div>
              );
            }) : (
              <div style={styles.emptyMsg}>Aucun résultat ne correspond.</div>
            )}
          </div>
        )}

        {activeTab === 'ENTREPRISES' && (
          <div style={styles.grid}>
            {entreprises.length > 0 ? entreprises.map(ent => (
              <div key={ent.id} style={styles.enterpriseCard}>
                <div style={styles.entLogoWrapper}>
                  {ent.logo ? (
                    <img
                      src={ent.logo.startsWith('http') ? ent.logo : `${API_BASE_URL}${ent.logo}`}
                      alt={ent.name}
                      style={styles.entLogo}
                    />
                  ) : (
                    <div style={styles.entPlaceholder}>{ent.name ? ent.name.charAt(0) : "E"}</div>
                  )}
                </div>
                <h3 style={styles.entName}>{ent.name || "Sans nom"}</h3>
                <p style={styles.entDescription}>
                  {ent.description ? (ent.description.substring(0, 100) + "...") : "Aucune description."}
                </p>
                <button onClick={() => navigate(`/entreprises/${ent.id}`)} style={styles.viewEntBtn}>Voir Profil</button>
              </div>
            )) : (
              <div style={styles.emptyMsg}>Aucune entreprise disponible.</div>
            )}
          </div>
        )}
      </main>
    </div>
  );
};

const styles = {
    pageWrapper: { padding: '20px', maxWidth: '1200px', margin: '0 auto', color: 'white', width: '100%', boxSizing: 'border-box' },
    header: { marginBottom: '30px' },
    title: { fontSize: '32px', fontWeight: '900', margin: '0' },
    smartFilterBar: { display: 'flex', flexDirection: 'column', gap: '15px', marginBottom: '35px', background: '#1e293b', padding: '20px', borderRadius: '20px' },
    searchWrapper: { width: '100%' },
    smartSearchInput: { width: '100%', padding: '14px 20px', borderRadius: '12px', border: '1px solid #334155', background: '#0f172a', color: 'white', outline: 'none', boxSizing: 'border-box'},
    specialtiesScrollContainer: { display: 'flex', gap: '10px', overflowX: 'auto', paddingBottom: '5px' },
    specBtn: { padding: '8px 18px', borderRadius: '10px', border: '1px solid #6366f1', background: 'transparent', color: '#94a3b8', cursor: 'pointer', whiteSpace: 'nowrap' },
    activeSpecBtn: { padding: '8px 18px', borderRadius: '10px', border: 'none', background: '#6366f1', color: 'white', cursor: 'pointer', whiteSpace: 'nowrap', fontWeight: 'bold' },
    tabsContainer: { display: 'flex', gap: '10px', marginBottom: '40px' },
    activeTab: { padding: '12px 25px', backgroundColor: '#6366f1', color: 'white', border: 'none', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer' },
    inactiveTab: { padding: '12px 25px', backgroundColor: 'transparent', color: '#94a3b8', border: 'none', cursor: 'pointer' },
    mainContent: { minHeight: '400px' },
    grid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: '25px' },
    glassCard: { background: '#1e293b', borderRadius: '24px', padding: '25px', display: 'flex', flexDirection: 'column', justifyContent: 'space-between', border: '1px solid rgba(255,255,255,0.05)' },
    categoryBadge: { fontSize: '10px', textTransform: 'uppercase', color: '#6366f1', fontWeight: 'bold' },
    offreTitle: { fontSize: '20px', margin: '10px 0', fontWeight: '700' },
    entNameLink: { fontSize: '14px', color: '#6366f1', marginBottom: '10px' },
    expInfo: { fontSize: '13px', marginBottom: '10px', color: '#cbd5e1' },
    skillsContainer: { display: 'flex', flexWrap: 'wrap', gap: '6px', marginBottom: '15px' },
    skillTag: { padding: '4px 8px', background: 'rgba(99, 102, 241, 0.1)', color: '#818cf8', borderRadius: '6px', fontSize: '11px', border: '1px solid rgba(99, 102, 241, 0.2)' },
    description: { fontSize: '14px', color: '#94a3b8', lineHeight: '1.6' },
    voirPlus: { color: '#6366f1', cursor: 'pointer', fontWeight: 'bold', marginLeft: '8px' },
    postulerBtn: { width: '100%', padding: '14px', backgroundColor: '#10b981', color: 'white', borderRadius: '15px', fontWeight: 'bold', border: 'none', cursor: 'pointer', marginTop: '15px' },
    enterpriseCard: { background: '#1e293b', borderRadius: '24px', padding: '30px', display: 'flex', flexDirection: 'column', alignItems: 'center' },
    entLogoWrapper: { width: '80px', height: '80px', borderRadius: '20px', background: '#334155', display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: '15px', overflow: 'hidden' },
    entLogo: { width: '100%', height: '100%', objectFit: 'cover' },
    entPlaceholder: { fontSize: '32px', fontWeight: '900', color: '#6366f1' },
    entName: { fontSize: '18px', margin: '5px 0 10px 0', fontWeight: '800' },
    entDescription: { fontSize: '13px', color: '#94a3b8', textAlign: 'center', marginBottom: '20px' },
    viewEntBtn: { width: '100%', padding: '10px', backgroundColor: 'transparent', border: '1.5px solid #6366f1', color: '#6366f1', borderRadius: '12px', fontWeight: 'bold', cursor: 'pointer' },
    emptyMsg: { gridColumn: '1/-1', textAlign: 'center', padding: '50px', color: '#94a3b8' }
};

export default EspaceCandidat;