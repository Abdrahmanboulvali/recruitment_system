import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';

const Navbar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const token = localStorage.getItem('access');
  const role = localStorage.getItem('role');

  // التعديل المطلوب في السطر 11
  const [isDarkMode, setIsDarkMode] = useState(true);
  const [userData, setUserData] = useState(null);

  useEffect(() => {
    if (token) {
      axios.get('http://127.0.0.1:8000/api/profile/', {
        headers: { Authorization: `Bearer ${token}` }
      })
      .then(res => setUserData(res.data))
      .catch(err => console.error("Erreur profile navbar:", err));
    }
  }, [token, location.pathname]);

  useEffect(() => {
    document.body.style.backgroundColor = isDarkMode ? '#0f172a' : '#f8fafc';
    document.body.style.color = isDarkMode ? '#f8fafc' : '#1e293b';
  }, [isDarkMode]);

  if (location.pathname === '/login' || location.pathname === '/register' || !token) {
    return null;
  }

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  const isDG = role === 'Directeur Général' || role === 'DG';
  const isAgent = role === 'Responsable RH' || role === 'ADMIN';
  // إضافة تعريف المترشح
  const isCandidat = role === 'Candidat' || role === 'CANDIDAT';

  const textColor = isDarkMode ? '#f8fafc' : '#1e293b';

  return (
    <nav style={{
      ...styles.nav,
      backgroundColor: isDarkMode ? 'rgba(30, 41, 59, 0.8)' : 'rgba(255, 255, 255, 0.8)',
      color: textColor,
      borderBottom: `1px solid ${isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`
    }}>
      <div style={styles.brand}>
        <div style={styles.logoBadge}>RH</div>
        <span style={{ fontWeight: '800', fontSize: '18px' }}>Recrutement</span>
      </div>

      <div style={styles.linksContainer}>
        {/* روابط المدير العام */}
        {(isDG) && (
          <Link to="/dashboard" style={styles.link(location.pathname === '/dashboard', textColor)}>
            Dashboard
          </Link>
        )}

        {/* روابط المدير العام والوكيل */}
        {(isDG || isAgent) && (
          <>
            <Link to="/manage-offres" style={styles.link(location.pathname === '/manage-offres', textColor)}>
              Offres
            </Link>
            <Link to="/manage-candidatures" style={styles.link(location.pathname === '/manage-candidatures', textColor)}>
              Candidatures
            </Link>
          </>
        )}

        {/* روابط المترشح فقط */}
        {isCandidat && (
          <>
            <Link to="/espace-candidat" style={styles.link(location.pathname === '/espace-candidat', textColor)}>
              Offres
            </Link>
            <Link to="/mes-candidatures" style={styles.link(location.pathname === '/mes-candidatures', textColor)}>
              Suivi mes candidatures
            </Link>
          </>
        )}

        {isDG && (
          <Link to="/users" style={styles.link(location.pathname === '/users', textColor)}>
            Utilisateurs
          </Link>
        )}
      </div>

      <div style={styles.actions}>
        {isDG && (
          <Link to="/add-agent" style={styles.addAgentBtn}>
            + Ajouter Agent
          </Link>
        )}

        <Link to="/profile" style={styles.profileBtn(textColor)}>
          {userData?.photo ? (
            <img
              src={`http://127.0.0.1:8000${userData.photo}`}
              alt="P"
              style={styles.profileImg}
            />
          ) : (
            <div style={styles.defaultAvatar}>
              {userData?.username?.charAt(0).toUpperCase()}
            </div>
          )}
          <span style={styles.userName}>{userData?.username}</span>
        </Link>

        <button onClick={() => setIsDarkMode(!isDarkMode)} style={styles.themeBtn(isDarkMode)}>
          {isDarkMode ? '☀️' : '🌙'}
        </button>
        <button onClick={handleLogout} style={styles.logoutBtn}>
          Déconnexion
        </button>
      </div>
    </nav>
  );
};

const styles = {
  nav: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 30px', backdropFilter: 'blur(10px)', position: 'sticky', top: 0, zIndex: 1000, transition: 'all 0.4s ease' },
  brand: { display: 'flex', alignItems: 'center', gap: '10px' },
  logoBadge: { backgroundColor: '#6366f1', color: 'white', padding: '5px 8px', borderRadius: '8px', fontWeight: 'bold', fontSize: '14px' },
  linksContainer: { display: 'flex', gap: '10px' },
  link: (isActive, color) => ({ padding: '8px 16px', color: color, textDecoration: 'none', fontSize: '14px', fontWeight: '600', borderRadius: '10px', backgroundColor: isActive ? 'rgba(99, 102, 241, 0.15)' : 'transparent', color: isActive ? '#6366f1' : color, transition: 'all 0.3s ease' }),
  addAgentBtn: { backgroundColor: '#6366f1', color: 'white', padding: '8px 15px', borderRadius: '10px', textDecoration: 'none', fontSize: '13px', fontWeight: 'bold', transition: '0.3s', marginRight: '10px' },
  actions: { display: 'flex', alignItems: 'center', gap: '15px' },
  profileBtn: (color) => ({ display: 'flex', alignItems: 'center', gap: '8px', textDecoration: 'none', color: color, padding: '5px 10px', borderRadius: '12px', background: 'rgba(99, 102, 241, 0.05)', transition: '0.3s' }),
  profileImg: { width: '32px', height: '32px', borderRadius: '50%', objectFit: 'cover', border: '2px solid #6366f1' },
  defaultAvatar: { width: '32px', height: '32px', borderRadius: '50%', backgroundColor: '#6366f1', color: 'white', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 'bold' },
  userName: { fontSize: '13px', fontWeight: '600' },
  themeBtn: (isDark) => ({ background: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)', border: 'none', borderRadius: '50%', width: '35px', height: '35px', cursor: 'pointer', fontSize: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', transition: '0.3s' }),
  logoutBtn: { background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', padding: '8px 15px', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold', fontSize: '13px', transition: '0.3s' }
};

export default Navbar;