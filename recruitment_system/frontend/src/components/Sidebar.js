import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';

const Sidebar = ({ isOpen, toggleSidebar }) => {
  // ... (نفس منطق useState و useEffect و الدوال السابقة دون تغيير)
  const navigate = useNavigate();
  const location = useLocation();
  const token = localStorage.getItem('access');
  const role = (localStorage.getItem('role') || "").toUpperCase().trim();
  const [userData, setUserData] = useState(null);
  const [isDarkMode, setIsDarkMode] = useState(true);

  useEffect(() => {
    if (token) {
      axios.get('http://127.0.0.1:8000/api/profile/', {
        headers: { Authorization: `Bearer ${token}` }
      })
      .then(res => setUserData(res.data))
      .catch(err => console.error("Erreur profile sidebar:", err));
    }
  }, [token, location.pathname]);

  if (location.pathname === '/login' || location.pathname === '/register' || !token || !role) {
    return null;
  }

  const handleLogout = () => {
    localStorage.clear();
    navigate('/login');
    window.location.reload();
  };

  const toggleTheme = () => {
    setIsDarkMode(!isDarkMode);
    const root = document.documentElement;
    if (isDarkMode) {
      root.style.setProperty('--bg-main', '#f8fafc');
      root.style.setProperty('--bg-sidebar', '#ffffff');
      root.style.setProperty('--text-main', '#1e293b');
      root.style.setProperty('--text-muted', '#64748b');
    } else {
      root.style.setProperty('--bg-main', '#0f172a');
      root.style.setProperty('--bg-sidebar', '#1e293b');
      root.style.setProperty('--text-main', '#f8fafc');
      root.style.setProperty('--text-muted', '#94a3b8');
    }
  };

  const isDG = role === 'DIRECTEUR GÉNÉRAL' || role === 'DG';
  const isAgent = role === 'RESPONSABLE RH' || role === 'ADMIN';
  const isCandidat = role === 'CANDIDAT';

  return (
    <>
      <button
        onClick={toggleSidebar}
        style={{...styles.toggleBtn, left: isOpen ? '245px' : '15px'}}
      >
        {isOpen ? '❮' : '❯'}
      </button>

      <aside style={{
        ...styles.sidebar,
        width: isOpen ? '260px' : '0px',
        transform: isOpen ? 'translateX(0)' : 'translateX(-100%)',
        opacity: isOpen ? 1 : 0
      }}>

        <div style={styles.brandContainer}>
          <div style={styles.logoBadge}>RH</div>
          <span style={styles.brandName}>Recrutement</span>
        </div>

        <div onClick={() => navigate('/profile')} style={styles.userCard} title="Voir le profil">
          <div style={styles.avatarWrapper}>
            {userData?.photo ? (
              <img src={`http://127.0.0.1:8000${userData.photo}`} alt="P" style={styles.avatarImg} />
            ) : (
              <div style={styles.defaultAvatar}>{userData?.username?.charAt(0).toUpperCase()}</div>
            )}
          </div>
          <div style={styles.userInfo}>
            <div style={styles.userName}>{userData?.username || "Utilisateur"}</div>
            <div style={styles.userRole}>{role}</div>
          </div>
        </div>

        {/* الحاوية القابلة للتمرير */}
        <nav style={styles.navContainer}>
          <div style={styles.scrollArea}>
            {isDG && <SidebarLink to="/dashboard" label="Tableau de bord" icon="📊" active={location.pathname === '/dashboard'} />}
            {(isDG || isAgent) && (
              <>
                <SidebarLink to="/manage-offres" label="Gestion Offres" icon="💼" active={location.pathname === '/manage-offres'} />
                <SidebarLink to="/manage-candidatures" label="Candidatures" icon="📝" active={location.pathname === '/manage-candidatures'} />
              </>
            )}
            {isCandidat && (
              <>
                <SidebarLink to="/espace-candidat" label="Explorer Offres" icon="🔍" active={location.pathname === '/espace-candidat'} />
                <SidebarLink to="/mes-candidatures" label="Mes Postulations" icon="⏳" active={location.pathname === '/mes-candidatures'} />
              </>
            )}
            {isDG && <SidebarLink to="/users" label="Utilisateurs" icon="👥" active={location.pathname === '/users'} />}

            {isDG && (
              <div style={styles.actions}>
                 <Link to="/add-agent" style={styles.addAgentBtn}>
                  + Ajouter Agent
                </Link>
              </div>
            )}
          </div>
        </nav>

        <div style={styles.footerSection}>
          <button onClick={toggleTheme} style={styles.themeBtn}>
            {isDarkMode ? '☀️ Mode Clair' : '🌙 Mode Sombre'}
          </button>
          <button onClick={handleLogout} style={styles.logoutBtn}>
            🚪 Déconnexion
          </button>
        </div>
      </aside>
    </>
  );
};

const SidebarLink = ({ to, label, icon, active }) => (
  <Link to={to} style={styles.link(active)}>
    <span style={{ marginRight: '12px', fontSize: '18px' }}>{icon}</span>
    {label}
  </Link>
);

const styles = {
  sidebar: {
    position: 'fixed', top: 0, left: 0, height: '100vh',
    backgroundColor: 'var(--bg-sidebar)',
    color: 'var(--text-main)',
    display: 'flex', flexDirection: 'column',
    transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)', zIndex: 1000, overflow: 'hidden',
    borderRight: '1px solid rgba(128, 128, 128, 0.1)'
  },
  toggleBtn: {
    position: 'fixed', top: '25px', zIndex: 1100, border: 'none', backgroundColor: '#6366f1',
    color: 'white', width: '32px', height: '32px', borderRadius: '50%', cursor: 'pointer',
    display: 'flex', alignItems: 'center', justifyContent: 'center', transition: '0.4s'
  },
  brandContainer: { padding: '30px 25px', display: 'flex', alignItems: 'center', gap: '12px', flexShrink: 0 },
  userCard: { margin: '0 15px 25px 15px', padding: '12px', backgroundColor: 'rgba(128,128,128,0.1)', borderRadius: '16px', display: 'flex', alignItems: 'center', gap: '12px', cursor: 'pointer', transition: '0.3s', flexShrink: 0 },

  // التعديل هنا لضمان التمرير
  navContainer: {
    flex: 1,
    overflowY: 'auto',
    overflowX: 'hidden',
    padding: '0 15px',
    // إخفاء شريط التمرير لمتصفحات Chrome/Safari
    scrollbarWidth: 'none', // لمتصفح Firefox
    msOverflowStyle: 'none', // لمتصفح IE/Edge
  },
  // حاوية داخلية إضافية لضمان ترتيب العناصر
  scrollArea: {
    display: 'flex',
    flexDirection: 'column',
    gap: '5px',
    paddingBottom: '20px'
  },

  logoBadge: { background: 'linear-gradient(135deg, #6366f1, #a855f7)', padding: '8px 12px', borderRadius: '12px', fontWeight: 'bold', color: '#fff' },
  brandName: { fontSize: '20px', fontWeight: '800', whiteSpace: 'nowrap', color: 'var(--text-main)' },
  avatarWrapper: { position: 'relative' },
  avatarImg: { width: '40px', height: '40px', borderRadius: '10px', objectFit: 'cover' },
  defaultAvatar: { width: '40px', height: '40px', borderRadius: '10px', backgroundColor: '#6366f1', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' },
  userName: { fontSize: '14px', fontWeight: '700', whiteSpace: 'nowrap', color: 'var(--text-main)' },
  userRole: { fontSize: '11px', color: 'var(--text-muted)' },
  link: (isActive) => ({
    display: 'flex', alignItems: 'center', padding: '12px 16px', textDecoration: 'none',
    color: isActive ? '#fff' : 'var(--text-muted)', borderRadius: '12px',
    backgroundColor: isActive ? '#6366f1' : 'transparent', fontWeight: '600', transition: '0.3s', whiteSpace: 'nowrap'
  }),
  actions: { marginTop: '10px' },
  addAgentBtn: {
    display: 'block', padding: '10px', backgroundColor: 'rgba(99, 102, 241, 0.1)',
    color: '#6366f1', borderRadius: '10px', textDecoration: 'none', textAlign: 'center',
    fontSize: '13px', fontWeight: 'bold', border: '1px dashed #6366f1'
  },
  footerSection: { padding: '20px 15px', borderTop: '1px solid rgba(128,128,128,0.1)', display: 'flex', flexDirection: 'column', gap: '8px', flexShrink: 0 },
  themeBtn: { background: 'rgba(128,128,128,0.1)', border: 'none', color: 'var(--text-main)', padding: '10px', borderRadius: '10px', cursor: 'pointer', textAlign: 'left', fontWeight: 'bold' },
  logoutBtn: { background: 'rgba(239, 68, 68, 0.1)', border: 'none', color: '#ef4444', padding: '10px', borderRadius: '10px', cursor: 'pointer', fontWeight: 'bold', textAlign: 'left' }
};

export default Sidebar;