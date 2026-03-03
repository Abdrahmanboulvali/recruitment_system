import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageCandidatures = () => {
    const [candidatures, setCandidatures] = useState([]);
    const [offres, setOffres] = useState({});
    const [candidats, setCandidats] = useState({});
    const [loading, setLoading] = useState(true);

    // حالات التحكم في النافذة الداخلية (Modal)
    const [showModal, setShowModal] = useState(false);
    const [selectedCv, setSelectedCv] = useState(null);

    useEffect(() => {
        const fetchData = async () => {
            try {
                const token = localStorage.getItem('access');
                const config = { headers: { Authorization: `Bearer ${token}` } };

                const [offresRes, candidatsRes, candidaturesRes] = await Promise.all([
                    axios.get('http://127.0.0.1:8000/api/offres/', config),
                    axios.get('http://127.0.0.1:8000/api/candidats/', config),
                    axios.get('http://127.0.0.1:8000/api/candidatures/', config)
                ]);

                const offresMap = {};
                offresRes.data.forEach(o => offresMap[o.id] = o.titre);
                setOffres(offresMap);

                const candidatsMap = {};
                candidatsRes.data.forEach(c => candidatsMap[c.id] = `${c.nom} ${c.prenom}`);
                setCandidats(candidatsMap);

                setCandidatures(candidaturesRes.data);
            } catch (err) {
                console.error("Erreur lors du chargement des données", err);
            } finally {
                setLoading(false);
            }
        };
        fetchData();
    }, []);

    // دالة لفتح النافذة الداخلية مع تنظيف الرابط
    const handleOpenModal = (cvPath) => {
        const baseUrl = "http://127.0.0.1:8000";
        // تنظيف الرابط لمنع التكرار
        let fullUrl = cvPath.startsWith('http') ? cvPath : `${baseUrl}${cvPath}`;

        // إضافة وسم لضمان عرض الملف كـ PDF داخل المتصفح
        setSelectedCv(fullUrl);
        setShowModal(true);
    };

    if (loading) return <div style={{textAlign:'center', padding:'50px'}}>Chargement...</div>;

    return (
        <div style={{ padding: '30px', maxWidth: '1100px', margin: '0 auto', position: 'relative' }}>
            <h2 style={{ color: '#2c3e50', borderBottom: '2px solid #007bff', paddingBottom: '10px' }}>
                Liste des Candidatures Recevables
            </h2>

            <table style={{ width: '100%', borderCollapse: 'collapse', marginTop: '20px', backgroundColor: 'white', boxShadow: '0 2px 10px rgba(0,0,0,0.1)' }}>
                <thead>
                    <tr style={{ backgroundColor: '#f8f9fa' }}>
                        <th style={thStyle}>Candidat</th>
                        <th style={thStyle}>Offre</th>
                        <th style={thStyle}>Score IA</th>
                        <th style={thStyle}>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    {candidatures.map(can => (
                        <tr key={can.id} style={{ borderBottom: '1px solid #eee' }}>
                            <td style={tdStyle}>{candidats[can.candidat] || `Candidat #${can.candidat}`}</td>
                            <td style={tdStyle}>{offres[can.offre] || `Offre #${can.offre}`}</td>
                            <td style={{ ...tdStyle, color: '#007bff', fontWeight: 'bold' }}>{can.score}%</td>
                            <td style={tdStyle}>
                                <button
                                    onClick={() => handleOpenModal(can.cv_file)}
                                    style={{ ...btnStyle, backgroundColor: '#007bff' }}
                                >
                                    Voir CV
                                </button>
                                <button style={{ ...btnStyle, backgroundColor: '#28a745' }}>Accepter</button>
                            </td>
                        </tr>
                    ))}
                </tbody>
            </table>

            {/* النافذة الداخلية (Modal) */}
            {showModal && (
                <div style={modalOverlayStyle}>
                    <div style={modalContentStyle}>
                        <div style={modalHeaderStyle}>
                            <h3 style={{ margin: 0 }}>Visualisation du CV</h3>
                            <button onClick={() => setShowModal(false)} style={closeBtnStyle}>&times;</button>
                        </div>
                        {/* استخدام Google Docs Viewer كمحرك احتياطي إذا رفض المتصفح العرض المباشر، أو iframe عادي */}
                        <iframe
                            src={selectedCv}
                            title="CV Viewer"
                            style={{ width: '100%', height: '75vh', border: 'none', borderRadius: '4px' }}
                        ></iframe>
                        <div style={{ textAlign: 'right', marginTop: '10px' }}>
                            <a href={selectedCv} download style={{ fontSize: '12px', color: '#007bff' }}>Télécharger le fichier si non affiché</a>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

// التنسيقات
const thStyle = { padding: '15px', textAlign: 'left', color: '#495057', borderBottom: '2px solid #dee2e6' };
const tdStyle = { padding: '15px' };
const btnStyle = { marginRight: '8px', padding: '8px 12px', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' };

const modalOverlayStyle = {
    position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
    backgroundColor: 'rgba(0, 0, 0, 0.8)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 9999
};

const modalContentStyle = {
    backgroundColor: 'white', padding: '20px', borderRadius: '12px', width: '85%', maxWidth: '1000px', boxShadow: '0 5px 25px rgba(0,0,0,0.5)'
};

const modalHeaderStyle = {
    display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '15px', borderBottom: '1px solid #eee', paddingBottom: '10px'
};

const closeBtnStyle = {
    fontSize: '28px', border: 'none', background: 'none', cursor: 'pointer', color: '#333', fontWeight: 'bold'
};

export default ManageCandidatures;