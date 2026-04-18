import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { FiBriefcase, FiFileText, FiUsers, FiTarget, FiActivity, FiPieChart } from 'react-icons/fi';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [role, setRole] = useState('');
  const [enterpriseName, setEnterpriseName] = useState('');

  useEffect(() => {
    const token = localStorage.getItem('access');
    const userRole = (localStorage.getItem('role') || "").toUpperCase().trim();
    const eName = localStorage.getItem('enterprise_name') || "Entreprise";

    setRole(userRole);
    setEnterpriseName(eName);

    axios.get('http://127.0.0.1:8000/api/stats/', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => {
        setData(res.data);
        setLoading(false);
      })
      .catch(err => {
          console.error("Erreur de stats:", err);
          setData({
              total_offres: 0, total_candidatures: 0, total_users: 0, avg_score: 0,
              distribution: { Fortement: 0, Pertinente: 0, Faiblement: 0 }
          });
          setLoading(false);
      });
  }, []);

  const pieData = [
    { name: 'Fortement', value: data?.distribution?.Fortement || 0, color: '#10b981' },
    { name: 'Pertinente', value: data?.distribution?.Pertinente || 0, color: '#f59e0b' },
    { name: 'Faiblement', value: data?.distribution?.Faiblement || 0, color: '#ef4444' },
  ];

  return (
    <div style={styles.pageWrapper}>
      {/* Header - يظهر دائماً لمنع الوميض */}
      <header style={styles.header}>
        <div style={{minWidth: 0}}>
          <h1 style={styles.title}>
            <FiActivity style={{color: '#6366f1', marginRight: '12px'}} />
            {role === 'DG' ? 'Direction Stratégique' : 'Dashboard RH'}
          </h1>
          <p style={styles.subtitle}>{enterpriseName.toUpperCase()} • ANALYSIS SYSTEM</p>
        </div>
      </header>

      {/* Stats Grid */}
      <div style={styles.statsGrid}>
        <StatCard title="Total Offres" count={data?.total_offres} loading={loading} icon={<FiBriefcase />} gradient="linear-gradient(135deg, #6366f1, #4f46e5)" />
        <StatCard title="Candidatures" count={data?.total_candidatures} loading={loading} icon={<FiFileText />} gradient="linear-gradient(135deg, #10b981, #059669)" />
        <StatCard title="Score IA" count={data ? `${data.avg_score}%` : ''} loading={loading} icon={<FiTarget />} gradient="linear-gradient(135deg, #f59e0b, #d97706)" />
        {(role === 'DG' || role === 'ADMIN') && (
          <StatCard title="Équipe RH" count={data?.total_users} loading={loading} icon={<FiUsers />} gradient="linear-gradient(135deg, #8b5cf6, #7c3aed)" />
        )}
      </div>

      {/* Chart Section */}
      <div style={styles.chartContainer}>
        <div style={styles.chartCard}>
          <h4 style={styles.chartTitle}>
            <FiPieChart style={{marginRight: '10px'}} /> Répartition de la Pertinence des CV
          </h4>
          <div style={{height: '350px', width: '100%', opacity: loading ? 0.3 : 1, transition: 'opacity 0.5s'}}>
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={pieData}
                  dataKey="value"
                  innerRadius="65%"
                  outerRadius="90%"
                  paddingAngle={8}
                  stroke="none"
                >
                  {pieData.map((e, i) => <Cell key={i} fill={e.color} />)}
                </Pie>
                <Tooltip
                  contentStyle={{
                    background: 'var(--bg-sidebar)',
                    border: '1px solid rgba(128,128,128,0.2)',
                    borderRadius: '15px',
                    color: 'var(--text-main)',
                    boxShadow: '0 10px 25px rgba(0,0,0,0.1)'
                  }}
                />
                <Legend verticalAlign="bottom" height={36} iconType="circle" />
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};

// المكون المحدث مع حالة التحميل الداخلية
const StatCard = ({ title, count, icon, gradient, loading }) => (
  <div style={{...styles.cardWrapper, background: gradient}}>
    <div style={styles.cardInner}>
      <div style={{...styles.iconBox, background: gradient}}>
        {React.cloneElement(icon, { size: 24, color: '#fff' })}
      </div>
      <div style={{textAlign: 'right'}}>
        <p style={styles.cardLabel}>{title}</p>
        {loading ? (
          <div className="pulse-loader" style={styles.skeletonText}></div>
        ) : (
          <h3 style={styles.statNum}>{count ?? 0}</h3>
        )}
      </div>
      <div style={styles.cardDecoration}></div>
    </div>
  </div>
);

const styles = {
  pageWrapper: { padding: '40px', minHeight: '100vh', backgroundColor: 'var(--bg-main)', transition: 'all 0.3s ease' },
  header: { marginBottom: '45px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' },
  title: { fontSize: '32px', fontWeight: '900', color: 'var(--text-main)', display: 'flex', alignItems: 'center' },
  subtitle: { color: 'var(--text-muted)', fontSize: '13px', fontWeight: 'bold', letterSpacing: '2px', marginTop: '5px' },
  statsGrid: { display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(240px, 1fr))', gap: '25px' },
  cardWrapper: { padding: '1px', borderRadius: '30px' },
  cardInner: {
    background: 'var(--bg-sidebar)',
    borderRadius: '29px',
    padding: '30px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    position: 'relative',
    overflow: 'hidden',
    minHeight: '120px'
  },
  iconBox: { padding: '15px', borderRadius: '18px', display: 'flex', alignItems: 'center', justifyContent: 'center' },
  cardLabel: { color: 'var(--text-muted)', fontSize: '11px', fontWeight: '900', textTransform: 'uppercase', marginBottom: '5px' },
  statNum: { fontSize: '32px', fontWeight: '900', color: 'var(--text-main)', margin: 0, animation: 'fadeIn 0.5s ease' },
  skeletonText: {
    height: '32px',
    width: '60px',
    backgroundColor: 'rgba(128,128,128,0.1)',
    borderRadius: '8px',
    display: 'inline-block',
    animation: 'pulse 1.5s infinite ease-in-out'
  },
  cardDecoration: { position: 'absolute', bottom: '-20px', right: '-20px', width: '80px', height: '80px', borderRadius: '50%', background: 'rgba(128,128,128,0.03)' },
  chartContainer: { marginTop: '50px', display: 'flex', justifyContent: 'center' },
  chartCard: {
    background: 'var(--bg-sidebar)',
    padding: '40px',
    borderRadius: '40px',
    width: '100%',
    maxWidth: '900px',
    border: '1px solid rgba(128,128,128,0.08)'
  },
  chartTitle: { color: 'var(--text-main)', fontSize: '18px', fontWeight: 'bold', textAlign: 'center', marginBottom: '30px', display: 'flex', alignItems: 'center', justifyContent: 'center' }
};

// إضافة كود CSS للـ Pulse Animation (يمكنك وضعه في ملف App.css أو استخدام Styled Components)
const styleTag = document.createElement("style");
styleTag.innerHTML = `
  @keyframes pulse {
    0% { opacity: 0.5; }
    50% { opacity: 1; }
    100% { opacity: 0.5; }
  }
  @keyframes fadeIn {
    from { opacity: 0; transform: translateY(5px); }
    to { opacity: 1; transform: translateY(0); }
  }
`;
document.head.appendChild(styleTag);

export default Dashboard;