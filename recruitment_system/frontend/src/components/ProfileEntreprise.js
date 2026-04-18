import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FiArrowLeft, FiEdit3, FiCheck, FiX, FiCamera, FiTrash2 } from 'react-icons/fi';

const ProfileEntreprise = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const token = localStorage.getItem('access');
  const API_BASE_URL = 'http://127.0.0.1:8000';

  const [entreprise, setEntreprise] = useState(null);
  const [userData, setUserData] = useState(null);
  const [isEditing, setIsEditing] = useState(false);

  const [editData, setEditData] = useState({ name: '', description: '' });
  const [selectedFile, setSelectedFile] = useState(null);
  const [removeLogo, setRemoveLogo] = useState(false);

  // مراقبة الوضع الحالي لضمان تحديث الواجهة عند التبديل
  const [isDarkMode, setIsDarkMode] = useState(localStorage.getItem('theme') === 'dark');

  useEffect(() => {
    fetchData();

    // مراقبة التغيير في التخزين المحلي (للتزامن مع الـ Sidebar)
    const checkTheme = () => {
      setIsDarkMode(localStorage.getItem('theme') === 'dark');
    };
    window.addEventListener('storage', checkTheme);
    const interval = setInterval(checkTheme, 500);

    return () => {
      window.removeEventListener('storage', checkTheme);
      clearInterval(interval);
    };
  }, [id, token]);

  const fetchData = () => {
    axios.get(`${API_BASE_URL}/api/enterprises/${id}/`, {
        headers: token ? { Authorization: `Bearer ${token}` } : {}
    })
      .then(res => {
        const data = res.data;
        setEntreprise(data);
        setEditData({
          name: data.nom || data.name || '',
          description: data.description || ''
        });
        setRemoveLogo(false);
      })
      .catch(err => console.error("Fetch Error:", err));

    if (token) {
      axios.get(`${API_BASE_URL}/api/profile/`, {
        headers: { Authorization: `Bearer ${token}` }
      })
      .then(res => setUserData(res.data))
      .catch(err => console.error("Profile Error:", err));
    }
  };

  const handleSave = () => {
    const formData = new FormData();
    formData.append('nom', editData.name);
    formData.append('description', editData.description);

    if (selectedFile) {
      formData.append('logo', selectedFile);
    } else if (removeLogo) {
      formData.append('logo', '');
    }

    axios.patch(`${API_BASE_URL}/api/enterprises/${id}/`, formData, {
      headers: { Authorization: `Bearer ${token}` }
    })
    .then(res => {
      setEntreprise(res.data);
      setIsEditing(false);
      setSelectedFile(null);
      setRemoveLogo(false);
      fetchData();
    })
    .catch(err => {
      console.error("Save Error:", err.response?.data);
      alert("Erreur lors de l'enregistrement.");
    });
  };

  if (!entreprise) return <div style={styles.loader}>Chargement du profil...</div>;

  const isOwnerDG = userData && entreprise && String(userData.id) === String(entreprise.owner_id);

  return (
    /* أضفنا Wrapper لضمان تغطية خلفية الصفحة بالكامل ومنع "التعاقب" */
    <div style={{...styles.pageWrapper, backgroundColor: 'var(--bg-main)'}}>
      <div style={styles.container}>
        <div style={styles.topActions}>
          <button onClick={() => navigate(-1)} style={styles.backBtn}>
            <FiArrowLeft /> Retour
          </button>

          {isOwnerDG && (
            !isEditing ? (
              <button onClick={() => setIsEditing(true)} style={styles.editBtn}>
                <FiEdit3 /> Modifier
              </button>
            ) : (
              <div style={{display: 'flex', gap: '12px'}}>
                <button onClick={() => {
                  setIsEditing(false);
                  setSelectedFile(null);
                  setRemoveLogo(false);
                }} style={styles.cancelBtn}>
                  <FiX /> Annuler
                </button>
                <button onClick={handleSave} style={styles.saveBtn}>
                  <FiCheck /> Enregistrer
                </button>
              </div>
            )
          )}
        </div>

        <div style={styles.header}>
          <div style={styles.logoSection}>
            <div style={{...styles.logoWrapper, background: 'var(--bg-sidebar)'}}>
              {selectedFile ? (
                <img src={URL.createObjectURL(selectedFile)} alt="Preview" style={styles.logoImg} />
              ) : (entreprise.logo && !removeLogo) ? (
                <img
                  src={entreprise.logo.startsWith('http') ? entreprise.logo : `${API_BASE_URL}${entreprise.logo}`}
                  alt="Logo"
                  style={styles.logoImg}
                />
              ) : (
                <span style={styles.placeholder}>
                  {(editData.name || "E").charAt(0).toUpperCase()}
                </span>
              )}

              {isEditing && (
                <>
                  <label style={styles.uploadOverlay}>
                    <FiCamera />
                    <input type="file" hidden accept="image/*" onChange={(e) => {
                      if(e.target.files[0]) {
                          setSelectedFile(e.target.files[0]);
                          setRemoveLogo(false);
                      }
                    }} />
                  </label>
                  {(entreprise.logo || selectedFile) && (
                    <button onClick={() => { setSelectedFile(null); setRemoveLogo(true); }} style={styles.deleteLogoBtn}>
                      <FiTrash2 />
                    </button>
                  )}
                </>
              )}
            </div>
          </div>

          {isEditing ? (
            <input
              style={{...styles.editInput, backgroundColor: 'var(--bg-main)', color: 'var(--text-main)'}}
              value={editData.name}
              onChange={(e) => setEditData({...editData, name: e.target.value})}
              autoFocus
            />
          ) : (
            <h1 style={{...styles.name, color: 'var(--text-main)'}}>{entreprise.nom || "Sans Nom"}</h1>
          )}

          <p style={{...styles.dgName, color: 'var(--text-muted)'}}>
              Dirigé par: <span style={{fontWeight: 'bold', color: 'var(--text-main)'}}>{entreprise.dg_name || "Non assigné"}</span>
          </p>
        </div>

        <div style={{...styles.contentCard, background: 'var(--bg-sidebar)'}}>
          <h3 style={{...styles.cardTitle, color: 'var(--text-main)'}}>À propos de nous</h3>
          {isEditing ? (
            <textarea
              style={{...styles.editTextarea, backgroundColor: 'var(--bg-main)', color: 'var(--text-main)'}}
              value={editData.description}
              onChange={(e) => setEditData({...editData, description: e.target.value})}
            />
          ) : (
            <p style={{...styles.description, color: 'var(--text-muted)'}}>{entreprise.description || "Aucune description disponible."}</p>
          )}
        </div>
      </div>
    </div>
  );
};

const styles = {
  pageWrapper: { minHeight: '100vh', transition: 'background-color 0.3s' },
  container: { padding: '40px 20px', maxWidth: '900px', margin: '0 auto' },
  topActions: { display: 'flex', justifyContent: 'space-between', marginBottom: '30px', alignItems: 'center' },
  backBtn: { background: 'transparent', color: 'var(--accent-primary)', border: 'none', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px' },
  editBtn: { backgroundColor: 'var(--accent-primary)', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' },
  saveBtn: { backgroundColor: 'var(--success-green)', color: 'white', border: 'none', padding: '10px 20px', borderRadius: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' },
  cancelBtn: { backgroundColor: 'transparent', color: 'var(--text-muted)', border: '1px solid var(--text-muted)', padding: '10px 20px', borderRadius: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px' },
  header: { textAlign: 'center', marginBottom: '50px' },
  logoSection: { display: 'flex', flexDirection: 'column', alignItems: 'center', gap: '15px', marginBottom: '25px' },
  logoWrapper: { position: 'relative', width: '150px', height: '150px', borderRadius: '40px', display: 'flex', alignItems: 'center', justifyContent: 'center', border: '3px solid var(--accent-primary)', overflow: 'hidden' },
  logoImg: { width: '100%', height: '100%', objectFit: 'cover' },
  placeholder: { fontSize: '60px', fontWeight: 'bold', color: 'var(--accent-primary)' },
  uploadOverlay: { position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', fontSize: '30px' },
  deleteLogoBtn: { position: 'absolute', bottom: '10px', right: '10px', background: '#ef4444', color: 'white', border: 'none', borderRadius: '50%', width: '30px', height: '30px', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' },
  name: { fontSize: '42px', fontWeight: '900', marginBottom: '10px' },
  dgName: { fontSize: '18px' },
  contentCard: { padding: '40px', borderRadius: '32px' },
  cardTitle: { marginBottom: '20px', fontSize: '22px', fontWeight: 'bold' },
  description: { lineHeight: '1.8', fontSize: '17px' },
  editInput: { border: '2px solid var(--accent-primary)', padding: '12px', borderRadius: '15px', width: '100%', textAlign: 'center', fontSize: '30px', outline: 'none' },
  editTextarea: { border: '1px solid rgba(128,128,128,0.2)', padding: '20px', borderRadius: '15px', width: '100%', minHeight: '150px', fontSize: '16px', outline: 'none' },
  loader: { textAlign: 'center', marginTop: '100px', color: 'var(--text-muted)', fontSize: '20px' }
};

export default ProfileEntreprise;