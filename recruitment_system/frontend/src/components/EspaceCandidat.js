import React, { useState, useEffect } from 'react';
import axios from 'axios';

const EspaceCandidat = () => {
  const [offres, setOffres] = useState([]);

  useEffect(() => {
    const token = localStorage.getItem('access');
    axios.get('http://127.0.0.1:8000/api/offres/', {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(res => setOffres(res.data))
    .catch(err => console.error("Erreur lors du chargement des offres", err));
  }, []);

  return (
    <div style={{ padding: '30px', backgroundColor: '#f8f9fa', minHeight: '100vh' }}>
      <h2 style={{ color: '#2c3e50' }}>Offres d'emploi disponibles</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: '20px', marginTop: '20px' }}>
        {offres.map(offre => (
          <div key={offre.id} style={cardStyle}>
            <h3 style={{ color: '#007bff' }}>{offre.titre}</h3>
            <p><strong>Expérience requise:</strong> {offre.experience_min} ans</p>
            <p>{offre.description.substring(0, 100)}...</p>
            <button style={buttonStyle}>Postuler via IA</button>
          </div>
        ))}
      </div>
    </div>
  );
};

const cardStyle = { background: 'white', padding: '20px', borderRadius: '10px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' };
const buttonStyle = { width: '100%', padding: '10px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer', marginTop: '10px' };

export default EspaceCandidat;