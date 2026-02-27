import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { BarChart, Bar, XAxis, YAxis, Tooltip, PieChart, Pie, Cell, ResponsiveContainer } from 'recharts';

const Dashboard = () => {
  const [data, setData] = useState(null);

  useEffect(() => {
  // 1. استخراج التوكن من التخزين المحلي (localStorage)
  const token = localStorage.getItem('access');

  // 2. إرسال الطلب مع إضافة التوكن في الـ Headers
  axios.get('http://127.0.0.1:8000/api/stats/', {
    headers: {
      'Authorization': `Bearer ${token}` // هذا السطر هو المفتاح لحل المشكلة
    }
  })
    .then(res => {
      console.log("Data fetched successfully:", res.data);
      setData(res.data);
    })
    .catch(err => {
      console.error("Error fetching data:", err);
      // إذا كان الخطأ 401، فهذا يعني أن التوكن غير صالح أو منتهي
    });
}, []); // تأكد من وجود المصفوفة الفارغة ليعمل الطلب مرة واحدة عند تحميل الصفحة

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
        <div style={cardStyle}><h3>Offres</h3><p>{data.total_offres}</p></div>
        <div style={cardStyle}><h3>Candidatures</h3><p>{data.total_candidatures}</p></div>
        <div style={cardStyle}><h3>Score Moyen</h3><p>{data.avg_score}%</p></div>
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

const cardStyle = { background: 'white', padding: '15px', borderRadius: '10px', width: '25%', textAlign: 'center', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' };
const chartBox = { background: 'white', padding: '20px', borderRadius: '10px', flex: '1', minWidth: '350px', boxShadow: '0 4px 6px rgba(0,0,0,0.1)' };

export default Dashboard;