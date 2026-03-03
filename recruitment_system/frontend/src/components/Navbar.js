import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';

const Navbar = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const token = localStorage.getItem('access');
  const role = localStorage.getItem('role');

  // 1. إخفاء الشريط تماماً في صفحة تسجيل الدخول والاشتراك
  if (location.pathname === '/login' || location.pathname === '/register' || !token) {
    return null;
  }

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
  };

  // دالة لتحديد شكل الرابط النشط
  const linkStyle = (path) => ({
    margin: '0 15px',
    color: 'white',
    textDecoration: location.pathname === path ? 'underline' : 'none', // تمييز الصفحة الحالية
    fontWeight: location.pathname === path ? 'bold' : 'normal'
  });

  return (
    <nav style={{ backgroundColor: '#333', padding: '10px', color: 'white', display: 'flex', justifyContent: 'space-between' }}>
      <div>
        {/* 2. إظهار الروابط بناءً على الدور فقط */}
        {role === 'CANDIDAT' && (
          <Link to="/espace-candidat" style={linkStyle('/espace-candidat')}>Offres</Link>
        )}

        {(role === 'ADMIN' || role === 'ADMINISTRATEUR') && (
          <>
            <Link to="/dashboard" style={linkStyle('/dashboard')}>Dashboard</Link>
            <Link to="/users" style={linkStyle('/users')}>Utilisateurs</Link>
          </>
        )}
      </div>

      <button onClick={handleLogout} style={{ background: 'none', border: 'none', color: 'red', cursor: 'pointer' }}>
        Déconnexion
      </button>
    </nav>
  );
};

export default Navbar;