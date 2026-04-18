import React, { useState, useEffect } from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';

const Sidebar = ({ isOpen, toggleSidebar }) => {
  const navigate = useNavigate();
  const location = useLocation();
  const token = localStorage.getItem('access');
  const role = (localStorage.getItem('role') || "").toUpperCase().trim();
  const [userData, setUserData] = useState(null);
  const [subscriptionInfo, setSubscriptionInfo] = useState(null); // حالة جديدة للاشتراك الدقيق
  const [isDarkMode, setIsDarkMode] = useState(true);

  // --- التعديل: جلب الملف الشخصي وحالة الاشتراك الحقيقية ---
  useEffect(() => {
    if (token) {
      const config = { headers: { Authorization: `Bearer ${token}` } };

      // جلب بيانات البروفايل وحالة الاشتراك في وقت واحد لضمان المزامنة
      Promise.all([
        axios.get('http://127.0.0.1:8000/api/profile/', config),
        axios.get('http://127.0.0.1:8000/api/my-subscription/', config)
      ])
      .then(([profileRes, subRes]) => {
        setUserData(profileRes.data);
        setSubscriptionInfo(subRes.data);

        // تحديث التخزين المحلي لضمان اطلاع بقية المكونات
        const updatedUser = {
          ...profileRes.data,
          subscription: subRes.data
        };
        localStorage.setItem('user', JSON.stringify(updatedUser));
      })
      .catch(err => console.error("Erreur sync sidebar:", err));
    }
  }, [token, location.pathname]); // التحديث عند تغيير الصفحة لضمان الانعكاس الفوري لأي تغيير

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

  const isSuperAdmin = role === 'SUPER_ADMIN';
  const isDG = ['DG', 'DIRECTEUR GÉNÉRAL', 'DG_BUSINESS', 'DG_GOV', 'PROPRIÉTAIRE D\'ENTREPRISE', 'HOMME D\'AFFAIRES'].includes(role);
  const isAgent = role === 'RESPONSABLE RH' || role === 'ADMIN';
  const isCandidat = role === 'CANDIDAT';

  // --- التعديل: استخراج البيانات من اشتراك الـ API المباشر ---
  const currentPlanName = subscriptionInfo?.plan_details?.title || "Mode Gratuit";
  const isPlanActive = subscriptionInfo?.status === 'ACTIVE';

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
            {/* عرض النقطة الخضراء فقط إذا كان الاشتراك ACTIVE فعلاً */}
            {isDG && isPlanActive && <div style={styles.activeStatusDot} title="Compte Premium"></div>}
          </div>
          <div style={styles.userInfo}>
            <div style={styles.userName}>{userData?.username || "Utilisateur"}</div>
            {/* التعديل: عرض اسم الباقة بلون مختلف حسب الحالة */}
            <div style={{
                ...styles.userRole,
                color: isPlanActive ? '#10b981' : '#f59e0b',
                fontWeight: isPlanActive ? 'bold' : 'normal'
            }}>
                {isDG ? currentPlanName : role}
            </div>
          </div>
        </div>

        <nav style={styles.navContainer}>
          <div style={styles.scrollArea}>
            {isSuperAdmin && (
              <>
                <SidebarLink to="/AllStats" label="Stats Globales" icon="🌍" active={location.pathname === '/AllStats'} />
                <SidebarLink to="/manage-enterprises" label="Gestion Entreprises" icon="🏢" active={location.pathname === '/manage-enterprises'} />
                <SidebarLink to="/manage-payments" label="Gestion Paiements" icon="💳" active={location.pathname === '/manage-payments'} />
              </>
            )}

            {isDG && (
              <>
                <SidebarLink to="/dashboard" label="Tableau de bord" icon="📊" active={location.pathname === '/dashboard'} />
                <SidebarLink to="/subscriptions" label="Abonnements" icon="⭐" active={location.pathname === '/subscriptions'} />
                {userData?.enterprise && (
                  <SidebarLink
                    to={`/entreprises/${userData.enterprise}`}
                    label="Mon Entreprise"
                    icon="🏢"
                    active={location.pathname.startsWith('/entreprises/')}
                  />
                )}
              </>
            )}

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

            {(isDG || isSuperAdmin) && <SidebarLink to="/users" label="Utilisateurs" icon="👥" active={location.pathname === '/users'} />}

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
  // الأنماط كما هي في كودك الأصلي مع بقاء التعديلات الجمالية
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
  navContainer: { flex: 1, overflowY: 'auto', overflowX: 'hidden', padding: '0 15px', scrollbarWidth: 'none', msOverflowStyle: 'none' },
  scrollArea: { display: 'flex', flexDirection: 'column', gap: '5px', paddingBottom: '20px' },
  logoBadge: { background: 'linear-gradient(135deg, #6366f1, #a855f7)', padding: '8px 12px', borderRadius: '12px', fontWeight: 'bold', color: '#fff' },
  brandName: { fontSize: '20px', fontWeight: '800', whiteSpace: 'nowrap', color: 'var(--text-main)' },
  avatarWrapper: { position: 'relative' },
  avatarImg: { width: '40px', height: '40px', borderRadius: '10px', objectFit: 'cover' },
  activeStatusDot: {
    position: 'absolute', bottom: '-2px', right: '-2px', width: '12px', height: '12px',
    backgroundColor: '#10b981', borderRadius: '50%', border: '2px solid var(--bg-sidebar)'
  },
  defaultAvatar: { width: '40px', height: '40px', borderRadius: '10px', backgroundColor: '#6366f1', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' },
  userName: { fontSize: '14px', fontWeight: '700', whiteSpace: 'nowrap', color: 'var(--text-main)' },
  userRole: { fontSize: '11px' },
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