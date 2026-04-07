import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [role, setRole] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('access');
    const userRole = localStorage.getItem('role');
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
        {/* بطاقة العروض */}
        <div style={styles.card}>
          <div style={iconCircle('#6366f1')}>💼</div>
          <h3 style={styles.cardLabel}>Total Offres</h3>
          <p style={styles.statNum}>{data.total_offres}</p>
        </div>

        {/* بطاقة الترشيحات */}
        <div style={styles.card}>
          <div style={iconCircle('#10b981')}>📄</div>
          <h3 style={styles.cardLabel}>Total Candidatures</h3>
          <p style={styles.statNum}>{data.total_candidatures}</p>
        </div>

        {/* بطاقة المستخدمين (تظهر فقط للمدير العام) */}
        {role === 'DG' && (
          <div style={styles.card}>
            <div style={iconCircle('#8b5cf6')}>👥</div>
            <h3 style={styles.cardLabel}>Utilisateurs Actifs</h3>
            <p style={styles.statNum}>{data.total_users}</p>
          </div>
        )}

        {/* بطاقة متوسط النقاط */}
        <div style={styles.card}>
          <div style={iconCircle('#f59e0b')}>🎯</div>
          <h3 style={styles.cardLabel}>Score Moyen IA</h3>
          <p style={styles.statNum}>{data.avg_score}%</p>
        </div>
      </div>

      <div style={styles.chartContainer}>
        <div style={styles.chartCard}>
          <h4 style={{ marginBottom: '20px', color: 'var(--text-main)', textAlign: 'center' }}>
            Répartition de la Pertinence des CV
          </h4>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie
                data={pieData}
                dataKey="value"
                innerRadius={65}
                outerRadius={90}
                paddingAngle={8}
                stroke="none"
              >
                {pieData.map((e, i) => <Cell key={i} fill={e.color} />)}
              </Pie>
              <Tooltip
                contentStyle={{
                  background: 'var(--bg-sidebar)',
                  border: '1px solid rgba(128,128,128,0.2)',
                  borderRadius: '12px',
                  color: 'var(--text-main)'
                }}
              />
              <Legend verticalAlign="bottom" height={36} />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

// وظيفة مساعدة لرسم خلفية الأيقونات
const iconCircle = (color) => ({
  width: '56px', height: '56px', borderRadius: '16px',
  backgroundColor: `${color}15`, color: color,
  display: 'flex', alignItems: 'center', justifyContent: 'center',
  fontSize: '28px', margin: '0 auto 20px'
});

const styles = {
  pageWrapper: { padding: '40px', minHeight: '100vh', background: 'var(--bg-main)', color: 'var(--text-main)' },
  title: { fontSize: '32px', fontWeight: '900', marginBottom: '8px', color: 'var(--text-main)' },
  subtitle: { color: 'var(--text-muted)', marginBottom: '45px', fontSize: '16px' },
  statsGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))', gap: '25px' },
  card: {
    background: 'var(--bg-sidebar)',
    boxShadow: '0 10px 30px rgba(0,0,0,0.04)',
    borderRadius: '28px',
    padding: '35px 20px',
    textAlign: 'center',
    border: '1px solid rgba(128,128,128,0.08)',
    transition: 'all 0.3s ease'
  },
  cardLabel: { color: 'var(--text-muted)', fontSize: '15px', fontWeight: '500', textTransform: 'uppercase', letterSpacing: '0.5px' },
  statNum: { fontSize: '42px', fontWeight: '800', margin: '15px 0 0', color: 'var(--text-main)' },
  chartContainer: { marginTop: '50px', display: 'flex', justifyContent: 'center' },
  chartCard: {
    background: 'var(--bg-sidebar)',
    padding: '40px',
    borderRadius: '32px',
    width: '100%',
    maxWidth: '850px',
    border: '1px solid rgba(128,128,128,0.08)',
    boxShadow: '0 10px 40px rgba(0,0,0,0.03)'
  },
  loader: { textAlign: 'center', marginTop: '100px', fontSize: '20px', color: 'var(--text-muted)', fontWeight: '300' }
};

export default Dashboard;