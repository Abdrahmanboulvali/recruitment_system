import React, { useState, useEffect } from 'react';
import axios from 'axios';

const MesCandidatures = () => {
    const [candidatures, setCandidatures] = useState([]);
    const [offres, setOffres] = useState({}); // لتخزين أسماء الوظائف كمفتاح وقيمة
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchMyData = async () => {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };

                // 1. جلب قائمة الوظائف لبناء خريطة (Map) بالأسماء
                const offresRes = await axios.get('http://127.0.0.1:8000/api/offres/', config);
                const offresMap = {};
                offresRes.data.forEach(o => {
                    offresMap[o.id] = o.titre; // ربط الـ ID بالعنوان
                });
                setOffres(offresMap);

                // 2. جلب ID المترشح الحالي
                const userRes = await axios.get('http://127.0.0.1:8000/api/user-info/', config);
                const candidatesRes = await axios.get('http://127.0.0.1:8000/api/candidats/', config);
                const myProfile = candidatesRes.data.find(c => c.user === userRes.data.id);

                if (myProfile) {
                    // 3. جلب ترشيحاتي فقط
                    const res = await axios.get('http://127.0.0.1:8000/api/candidatures/', config);
                    const filtered = res.data.filter(can => can.candidat === myProfile.id);
                    setCandidatures(filtered);
                }
            } catch (err) {
                console.error("Erreur lors du chargement", err);
            } finally {
                setLoading(false);
            }
        };
        fetchMyData();
    }, []);

    // دالة لجلب اسم الوظيفة بناءً على الـ ID
    const getOffreTitle = (id) => offres[id] || `Offre #${id}`;

    if (loading) return <div style={{textAlign:'center', padding:'50px'}}>Chargement de vos dossiers...</div>;

    return (
        <div style={{ padding: '30px', maxWidth: '1000px', margin: '0 auto' }}>
            <h2 style={{ borderBottom: '2px solid #28a745', paddingBottom: '10px', color: '#2c3e50' }}>Suivi de mes candidatures</h2>

            <div style={{ overflowX: 'auto', marginTop: '20px' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', backgroundColor: 'white', boxShadow: '0 2px 8px rgba(0,0,0,0.1)' }}>
                    <thead>
                        <tr style={{ backgroundColor: '#f8f9fa' }}>
                            <th style={thStyle}>Poste convoité</th> {/* تم تغيير العنوان هنا */}
                            <th style={thStyle}>Date de postulation</th>
                            <th style={thStyle}>Score IA</th>
                            <th style={thStyle}>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        {candidatures.map(can => (
                            <tr key={can.id} style={{ borderBottom: '1px solid #eee' }}>
                                <td style={{...tdStyle, fontWeight: 'bold', color: '#007bff'}}>
                                    {getOffreTitle(can.offre)} {/* عرض الاسم بدلاً من الرقم */}
                                </td>
                                <td style={tdStyle}>{new Date(can.date_postulation).toLocaleDateString()}</td>
                                <td style={tdStyle}>{can.score}%</td>
                                <td style={{ ...tdStyle, fontWeight: 'bold', color: can.statut === 'Accepté' ? '#28a745' : '#f39c12' }}>
                                    {can.statut}
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const thStyle = { padding: '15px', textAlign: 'left', borderBottom: '2px solid #dee2e6', color: '#495057' };
const tdStyle = { padding: '15px', color: '#333' };

export default MesCandidatures;