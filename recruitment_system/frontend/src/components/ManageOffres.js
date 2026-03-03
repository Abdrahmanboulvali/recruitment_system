import React, { useState, useEffect } from 'react';
import axios from 'axios';

const ManageOffres = () => {
    const [offres, setOffres] = useState([]);
    const [showForm, setShowForm] = useState(false);
    const [newOffre, setNewOffre] = useState({
        titre: '',
        description: '',
        experience_min: 0,
        competences_requises: ''
    });

    const token = localStorage.getItem('access');
    const config = { headers: { Authorization: `Bearer ${token}` } };

    useEffect(() => {
        fetchOffres();
    }, []);

    const fetchOffres = async () => {
        try {
            const res = await axios.get('http://127.0.0.1:8000/api/offres/', config);
            setOffres(res.data);
        } catch (err) { console.error("Erreur chargement offres"); }
    };

    const handleCreate = async (e) => {
        e.preventDefault();
        try {
            await axios.post('http://127.0.0.1:8000/api/offres/', newOffre, config);
            alert("Offre ajoutée avec succès !");
            setNewOffre({ titre: '', description: '', experience_min: 0, competences_requises: '' });
            setShowForm(false);
            fetchOffres();
        } catch (err) { alert("Erreur lors de l'ajout"); }
    };

    return (
        <div style={{ padding: '30px', maxWidth: '1000px', margin: '0 auto' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
                <h2>Gestion des Offres d'Emploi</h2>
                <button
                    onClick={() => setShowForm(!showForm)}
                    style={{ padding: '10px 20px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}
                >
                    {showForm ? "Fermer" : "+ Ajouter une Offre"}
                </button>
            </div>

            {showForm && (
                <form onSubmit={handleCreate} style={formStyle}>
                    <h3>Nouvelle Offre</h3>
                    <input style={inputStyle} placeholder="Titre du poste" required onChange={e => setNewOffre({...newOffre, titre: e.target.value})} />
                    <input type="number" style={inputStyle} placeholder="Expérience min (ans)" required onChange={e => setNewOffre({...newOffre, experience_min: e.target.value})} />
                    <textarea style={{...inputStyle, height: '100px'}} placeholder="Description du poste" required onChange={e => setNewOffre({...newOffre, description: e.target.value})} />
                    <button type="submit" style={submitButtonStyle}>Publier l'Offre</button>
                </form>
            )}

            <div style={{ marginTop: '20px' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', backgroundColor: 'white' }}>
                    <thead>
                        <tr style={{ backgroundColor: '#343a40', color: 'white' }}>
                            <th style={tdStyle}>Titre</th>
                            <th style={tdStyle}>Expérience</th>
                            <th style={tdStyle}>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
                        {offres.map(o => (
                            <tr key={o.id} style={{ borderBottom: '1px solid #ddd' }}>
                                <td style={tdStyle}>{o.titre}</td>
                                <td style={tdStyle}>{o.experience_min} ans</td>
                                <td style={tdStyle}>
                                    <button style={{ color: 'red', border: 'none', background: 'none', cursor: 'pointer' }}>Supprimer</button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

// Styles
const formStyle = { background: '#f8f9fa', padding: '20px', borderRadius: '8px', border: '1px solid #ddd', marginBottom: '20px' };
const inputStyle = { width: '100%', padding: '10px', marginBottom: '10px', borderRadius: '4px', border: '1px solid #ccc' };
const submitButtonStyle = { width: '100%', padding: '12px', backgroundColor: '#007bff', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer' };
const tdStyle = { padding: '12px', textAlign: 'left' };

export default ManageOffres;