import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    const token = localStorage.getItem('access');
    axios.get('http://127.0.0.1:8000/api/stats/', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => setData(res.data))
      .catch(err => console.error("Error fetching data:", err));
  }, []);

  if (!data) return <div style={{textAlign: 'center', marginTop: '100px', fontWeight: 'bold'}}>Chargement...</div>;

  const pieData = [
    { name: 'Fortement', value: data.distribution.Fortement, color: '#10b981' },
    { name: 'Pertinente', value: data.distribution.Pertinente, color: '#f59e0b' },
    { name: 'Faiblement', value: data.distribution.Faiblement, color: '#ef4444' },
  ];

  // التنسيقات تعتمد الآن على الشفافية (Glassmorphism) لتناسب أي وضع (Dark/Light)
  const dynamicCardStyle = {
    background: 'rgba(255, 255, 255, 0.05)', // شفافية خفيفة جداً
    backdropFilter: 'blur(10px)', // تأثير الضباب
    border: '1px solid rgba(255, 255, 255, 0.1)',
    borderRadius: '20px',
    padding: '25px',
    width: '280px',
    textAlign: 'center',
    transition: '0.3s ease',
    boxShadow: '0 8px 32px rgba(0,0,0,0.1)',
    cursor: 'pointer',
    color: 'inherit' // يأخذ لون النص من الأب (الذي يغيره النافبار)
  };

  return (
    <div style={{ padding: '40px 20px', minHeight: '100vh', transition: '0.4s' }}>
      <header style={{ textAlign: 'center', marginBottom: '40px' }}>
        <h1 style={{ fontSize: '2.5rem', fontWeight: '800', margin: 0 }}>Tableau de Bord</h1>
        <p style={{ opacity: 0.7 }}>Statistiques de recrutement en temps réel</p>
      </header>

      <div style={{ display: 'flex', justifyContent: 'center', flexWrap: 'wrap', gap: '25px', marginBottom: '40px' }}>

        {/* بطاقة العروض */}
        <div
          onClick={() => navigate('/manage-offres')}
          style={dynamicCardStyle}
          onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-10px)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={iconCircle('#6366f1')}>💼</div>
          <h3 style={{ fontSize: '1.1rem', opacity: 0.8 }}>Offres</h3>
          <p style={{ fontSize: '2.2rem', fontWeight: 'bold', margin: '10px 0' }}>{data.total_offres}</p>
          <small style={{ color: '#6366f1', fontWeight: 'bold' }}>Gérer →</small>
        </div>

        {/* بطاقة الترشيحات */}
        <div
          onClick={() => navigate('/manage-candidatures')}
          style={dynamicCardStyle}
          onMouseEnter={(e) => e.currentTarget.style.transform = 'translateY(-10px)'}
          onMouseLeave={(e) => e.currentTarget.style.transform = 'translateY(0)'}
        >
          <div style={iconCircle('#10b981')}>📄</div>
          <h3 style={{ fontSize: '1.1rem', opacity: 0.8 }}>Candidatures</h3>
          <p style={{ fontSize: '2.2rem', fontWeight: 'bold', margin: '10px 0' }}>{data.total_candidatures}</p>
          <small style={{ color: '#10b981', fontWeight: 'bold' }}>Voir →</small>
        </div>

        {/* بطاقة السكور */}
        <div style={{ ...dynamicCardStyle, cursor: 'default' }}>
          <div style={iconCircle('#f59e0b')}>🎯</div>
          <h3 style={{ fontSize: '1.1rem', opacity: 0.8 }}>Score Moyen</h3>
          <p style={{ fontSize: '2.2rem', fontWeight: 'bold', margin: '10px 0' }}>{data.avg_score}%</p>
          <small style={{ opacity: 0.6 }}>Analyse Globale</small>
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'center' }}>
        <div style={{ ...dynamicCardStyle, width: '100%', maxWidth: '600px', cursor: 'default' }}>
          <h4 style={{ marginBottom: '20px' }}>Répartition de la Pertinence</h4>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={60} outerRadius={80} paddingAngle={5}>
                {pieData.map((entry, index) => <Cell key={index} fill={entry.color} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: '15px', border: 'none' }} />
              <Legend verticalAlign="bottom" height={36}/>
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

// دالة مساعدة لشكل الأيقونات
const iconCircle = (color) => ({
  width: '50px',
  height: '50px',
  borderRadius: '12px',
  backgroundColor: `${color}20`, // شفافية للون الأيقونة
  color: color,
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'center',
  fontSize: '24px',
  margin: '0 auto 15px auto'
});

export default Dashboard;