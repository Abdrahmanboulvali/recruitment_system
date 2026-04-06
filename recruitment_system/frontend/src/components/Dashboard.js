import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [role, setRole] = useState('');
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('access');
    const userRole = localStorage.getItem('role'); // تأكد من تخزينه عند Login
    setRole(userRole);

    axios.get('http://127.0.0.1:8000/api/stats/', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => setData(res.data))
      .catch(err => console.error(err));
  }, []);

  if (!data) return <div style={styles.loader}>Initialisation du système...</div>;

  const pieData = [
    { name: 'Fortement', value: data.distribution.Fortement, color: '#10b981' },
    { name: 'Pertinente', value: data.distribution.Pertinente, color: '#f59e0b' },
    { name: 'Faiblement', value: data.distribution.Faiblement, color: '#ef4444' },
  ];

  return (
    <div style={styles.pageWrapper}>
      <header style={styles.header}>
        <h1 style={styles.title}>{role === 'DG' ? "Direction Stratégique" : "Tableau de Bord"}</h1>
        <p style={styles.subtitle}>Analyse globale des processus de recrutement</p>
      </header>

      <div style={styles.statsGrid}>
        <div onClick={() => navigate('/manage-offres')} style={styles.card}>
          <div style={iconCircle('#6366f1')}>💼</div>
          <h3>Offres</h3>
          <p style={styles.statNum}>{data.total_offres}</p>
          <small style={{color: '#6366f1'}}>Gérer les postes →</small>
        </div>

        <div onClick={() => navigate('/manage-candidatures')} style={styles.card}>
          <div style={iconCircle('#10b981')}>📄</div>
          <h3>Candidatures</h3>
          <p style={styles.statNum}>{data.total_candidatures}</p>
          <small style={{color: '#10b981'}}>Visualiser →</small>
        </div>

        {role === 'DG' && (
          <div onClick={() => navigate('/users')} style={{...styles.card, border: '1px solid #6366f1'}}>
            <div style={iconCircle('#8b5cf6')}>👥</div>
            <h3>Utilisateurs</h3>
            <p style={styles.statNum}>{data.total_users}</p>
            <small style={{color: '#8b5cf6'}}>Administration →</small>
          </div>
        )}

        <div style={styles.card}>
          <div style={iconCircle('#f59e0b')}>🎯</div>
          <h3>Score Moyen</h3>
          <p style={styles.statNum}>{data.avg_score}%</p>
          <small>Précision IA</small>
        </div>
      </div>

      <div style={styles.chartContainer}>
        <div style={styles.chartCard}>
          <h4 style={{marginBottom: '20px'}}>Répartition de la Pertinence des CV</h4>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={pieData} dataKey="value" innerRadius={60} outerRadius={85} paddingAngle={5}>
                {pieData.map((e, i) => <Cell key={i} fill={e.color} />)}
              </Pie>
              <Tooltip contentStyle={{background: '#1e2532', border: 'none', borderRadius: '10px'}} />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

const iconCircle = (color) => ({
  width: '50px', height: '50px', borderRadius: '14px',
  backgroundColor: `${color}15`, color: color,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  fontSize: '24px', margin: '0 auto 15px'
});

const styles = {
  pageWrapper: { padding: '40px', minHeight: '100vh', color: 'white' },
  title: { fontSize: '32px', fontWeight: '900', marginBottom: '5px' },
  subtitle: { opacity: 0.6, marginBottom: '40px' },
  statsGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '25px' },
  card: { background: 'rgba(255,255,255,0.05)', backdropFilter: 'blur(10px)', borderRadius: '24px', padding: '30px', textAlign: 'center', border: '1px solid rgba(255,255,255,0.1)', cursor: 'pointer', transition: '0.3s' },
  statNum: { fontSize: '36px', fontWeight: 'bold', margin: '10px 0' },
  chartContainer: { marginTop: '40px', display: 'flex', justifyContent: 'center' },
  chartCard: { background: 'rgba(255,255,255,0.03)', padding: '30px', borderRadius: '24px', width: '100%', maxWidth: '700px', border: '1px solid rgba(255,255,255,0.05)' },
  loader: { textAlign: 'center', marginTop: '100px', fontSize: '20px', opacity: 0.5 }
};

export default Dashboard;