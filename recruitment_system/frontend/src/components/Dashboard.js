import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom'; // إضافة الموجه
import { PieChart, Pie, Cell, Tooltip, ResponsiveContainer } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);
  const navigate = useNavigate(); // تعريف دالة التنقل

  useEffect(() => {
    const token = localStorage.getItem('access');
    axios.get('http://127.0.0.1:8000/api/stats/', {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    })
      .then(res => {
        setData(res.data);
      })
      .catch(err => {
        console.error("Error fetching data:", err);
      });
  }, []);

  if (!data) return <div style={{textAlign: 'center', marginTop: '50px'}}>Chargement des statistiques...</div>;

  const pieData = [
    { name: 'Fortement', value: data.distribution.Fortement, color: '#4caf50' },
    { name: 'Pertinente', value: data.distribution.Pertinente, color: '#ff9800' },
    { name: 'Faiblement', value: data.distribution.Faiblement, color: '#f44336' },
  ];

  return (
    <div style={{ padding: '20px', backgroundColor: '#f4f7f6', minHeight: '100vh' }}>
      <h1 style={{ textAlign: 'center', color: '#2c3e50' }}>Tableau de Bord RH</h1>

      <div style={{ display: 'flex', justifyContent: 'space-around', marginBottom: '30px' }}>

        {/* بطاقة العروض قابلة للضغط */}
        <div
          onClick={() => navigate('/manage-offres')}
          style={{ ...cardStyle, cursor: 'pointer', border: '1px solid transparent' }}
          onMouseOver={(e) => e.currentTarget.style.borderColor = '#007bff'}
          onMouseOut={(e) => e.currentTarget.style.borderColor = 'transparent'}
        >
          <h3>Offres</h3>
          <p style={numberStyle}>{data.total_offres}</p>
          <small style={{ color: '#007bff' }}>Gérer les offres</small>
        </div>

        {/* بطاقة الترشيحات قابلة للضغط */}
        <div
          onClick={() => navigate('/manage-candidatures')}
          style={{ ...cardStyle, cursor: 'pointer', border: '1px solid transparent' }}
          onMouseOver={(e) => e.currentTarget.style.borderColor = '#28a745'}
          onMouseOut={(e) => e.currentTarget.style.borderColor = 'transparent'}
        >
          <h3>Candidatures</h3>
          <p style={numberStyle}>{data.total_candidatures}</p>
          <small style={{ color: '#28a745' }}>Voir les dossiers</small>
        </div>

        {/* بطاقة السكور (للعرض فقط) */}
        <div style={cardStyle}>
          <h3>Score Moyen</h3>
          <p style={numberStyle}>{data.avg_score}%</p>
          <small style={{ color: '#888' }}>Analyse Globale</small>
        </div>

      </div>

      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '20px' }}>
        <div style={chartBox}>
          <h4>Pertinence des CV</h4>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={pieData} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={80} label>
                {pieData.map((entry, index) => <Cell key={index} fill={entry.color} />)}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};

// تحسين بسيط في التنسيقات
const cardStyle = {
  background: 'white',
  padding: '15px',
  borderRadius: '10px',
  width: '25%',
  textAlign: 'center',
  boxShadow: '0 4px 6px rgba(0,0,0,0.1)',
  transition: '0.3s'
};

const numberStyle = {
  fontSize: '24px',
  fontWeight: 'bold',
  margin: '10px 0'
};

const chartBox = {
  background: 'white',
  padding: '20px',
  borderRadius: '10px',
  flex: '1',
  minWidth: '350px',
  boxShadow: '0 4px 6px rgba(0,0,0,0.1)'
};

export default Dashboard;