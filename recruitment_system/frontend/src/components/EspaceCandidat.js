import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('access');
    axios.get('http://127.0.0.1:8000/api/offres/', {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(res => setOffres(res.data))
    .catch(err => console.error("Erreur lors du chargement des offres", err));
  }, []);

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h2 style={styles.title}>Opportunités de Carrière</h2>
        <p style={{ opacity: 0.7 }}>Découvrez les postes qui correspondent à votre profil</p>
      </header>

      <div style={styles.grid}>
        {offres.map(offre => (
          <div key={offre.id} style={styles.glassCard}>
            <div style={styles.cardHeader}>
               <span style={styles.categoryBadge}>New</span>
               <h3 style={styles.offreTitle}>{offre.titre}</h3>
            </div>

            <div style={styles.infoSection}>
               <p style={styles.expInfo}>
                 <strong>⏳ Expérience:</strong> {offre.experience_min} ans minimum
               </p>
               <p style={styles.description}>
                 {offre.description ? offre.description.substring(0, 120) : "Aucune description disponible"}...
               </p>
            </div>

            <button
              onClick={() => navigate(`/postuler/${offre.id}`)}
              style={styles.postulerBtn}
            >
              Postuler via IA 🚀
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};

const styles = {
  pageWrapper: {
    padding: '40px 20px',
    maxWidth: '1200px',
    margin: '0 auto',
    minHeight: '100vh',
    transition: '0.4s'
  },
  header: {
    marginBottom: '40px',
    textAlign: 'left',
    borderLeft: '5px solid #6366f1',
    paddingLeft: '20px'
  },
  title: {
    fontSize: '32px',
    fontWeight: '800',
    margin: '0 0 5px 0',
    letterSpacing: '-1px'
  },
  grid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))',
    gap: '25px',
    marginTop: '20px'
  },
  glassCard: {
    background: 'rgba(255, 255, 255, 0.05)',
    backdropFilter: 'blur(15px)',
    borderRadius: '24px',
    padding: '25px',
    border: '1px solid rgba(255, 255, 255, 0.1)',
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'space-between',
    transition: 'transform 0.3s ease, box-shadow 0.3s ease',
    boxShadow: '0 10px 30px rgba(0,0,0,0.1)',
    cursor: 'default'
  },
  cardHeader: {
    marginBottom: '15px'
  },
  categoryBadge: {
    fontSize: '10px',
    textTransform: 'uppercase',
    background: 'rgba(99, 102, 241, 0.2)',
    color: '#6366f1',
    padding: '4px 10px',
    borderRadius: '20px',
    fontWeight: 'bold',
    marginBottom: '10px',
    display: 'inline-block'
  },
  offreTitle: {
    fontSize: '20px',
    fontWeight: '700',
    margin: '5px 0',
    color: '#6366f1'
  },
  infoSection: {
    marginBottom: '20px'
  },
  expInfo: {
    fontSize: '14px',
    marginBottom: '10px',
    opacity: 0.9
  },
  description: {
    fontSize: '14px',
    lineHeight: '1.6',
    opacity: 0.7
  },
  postulerBtn: {
    width: '100%',
    padding: '14px',
    backgroundColor: '#10b981',
    color: 'white',
    border: 'none',
    borderRadius: '15px',
    fontWeight: 'bold',
    fontSize: '15px',
    cursor: 'pointer',
    transition: '0.3s',
    boxShadow: '0 8px 20px rgba(16, 185, 129, 0.2)'
  }
};

export default EspaceCandidat;