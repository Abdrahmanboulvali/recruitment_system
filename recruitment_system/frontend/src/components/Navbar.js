import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';

const Navbar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const token = localStorage.getItem('access');
  const role = localStorage.getItem('role');

  // إضافة حالة للوضع المظلم داخل النافبار
  const [isDarkMode, setIsDarkMode] = useState(true);

  // تأثير لتغيير خلفية الصفحة بالكامل عند تبديل الوضع
  useEffect(() => {
    document.body.style.backgroundColor = isDarkMode ? '#0f172a' : '#f8fafc';
    document.body.style.color = isDarkMode ? '#f8fafc' : '#1e293b';
    document.body.style.transition = 'all 0.4s ease';
  }, [isDarkMode]);

  if (location.pathname === '/login' || location.pathname === '/register' || !token) {
    return null;
  }

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  const toggleTheme = () => setIsDarkMode(!isDarkMode);

  // ألوان ديناميكية بناءً على الوضع
  const navBg = isDarkMode ? 'rgba(30, 41, 59, 0.8)' : 'rgba(255, 255, 255, 0.8)';
  const textColor = isDarkMode ? '#f8fafc' : '#1e293b';

  return (
    <nav style={{
      ...styles.nav,
      backgroundColor: navBg,
      color: textColor,
      borderBottom: `1px solid ${isDarkMode ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.1)'}`
    }}>
      <div style={styles.brand}>
        <div style={styles.logoBadge}>RH</div>
        <span style={{ fontWeight: '800', fontSize: '18px', letterSpacing: '-0.5px' }}>Recrutement</span>
      </div>

      <div style={styles.linksContainer}>
        {role === 'CANDIDAT' && (
          <Link to="/espace-candidat" style={styles.link(location.pathname === '/espace-candidat', textColor)}>Offres</Link>
        )}

        {(role === 'ADMIN' || role === 'ADMINISTRATEUR') && (
          <>
            <Link to="/dashboard" style={styles.link(location.pathname === '/dashboard', textColor)}>Dashboard</Link>
            <Link to="/users" style={styles.link(location.pathname === '/users', textColor)}>Utilisateurs</Link>
          </>
        )}
      </div>

      <div style={styles.actions}>
        <button onClick={toggleTheme} style={styles.themeBtn(isDarkMode)}>
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
  nav: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px 30px',
    backdropFilter: 'blur(10px)',
    position: 'sticky',
    top: 0,
    zIndex: 1000,
    transition: 'all 0.4s ease',
  },
  brand: {
    display: 'flex',
    alignItems: 'center',
    gap: '10px'
  },
  logoBadge: {
    backgroundColor: '#6366f1',
    color: 'white',
    padding: '5px 8px',
    borderRadius: '8px',
    fontWeight: 'bold',
    fontSize: '14px'
  },
  linksContainer: {
    display: 'flex',
    gap: '10px'
  },
  link: (isActive, color) => ({
    padding: '8px 16px',
    color: color,
    textDecoration: 'none',
    fontSize: '14px',
    fontWeight: '600',
    borderRadius: '10px',
    backgroundColor: isActive ? 'rgba(99, 102, 241, 0.15)' : 'transparent',
    color: isActive ? '#6366f1' : color,
    transition: 'all 0.3s ease'
  }),
  actions: {
    display: 'flex',
    alignItems: 'center',
    gap: '15px'
  },
  themeBtn: (isDark) => ({
    background: isDark ? 'rgba(255,255,255,0.1)' : 'rgba(0,0,0,0.05)',
    border: 'none',
    borderRadius: '50%',
    width: '35px',
    height: '35px',
    cursor: 'pointer',
    fontSize: '16px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    transition: '0.3s'
  }),
  logoutBtn: {
    background: 'rgba(239, 68, 68, 0.1)',
    border: 'none',
    color: '#ef4444',
    padding: '8px 15px',
    borderRadius: '10px',
    cursor: 'pointer',
    fontWeight: 'bold',
    fontSize: '13px',
    transition: '0.3s'
  }
};

export default Navbar;