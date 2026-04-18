import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import EspaceCandidat from './components/EspaceCandidat';
import Register from './components/Register';
import Sidebar from './components/Sidebar';
import Postuler from './components/Postuler';
import MesCandidatures from './components/MesCandidatures';
import ManageOffres from './components/ManageOffres';
import ManageCandidatures from './components/ManageCandidatures';
import Users from './components/Users';
import VerifyOTP from './components/VerifyOTP';
import AddAgent from './components/AddAgent';
import Profile from './components/Profile';
import ManageEnterprises from './components/ManageEnterprises';
import AllStats from './components/AllStats';
import ProfileEntreprise from './components/ProfileEntreprise';
import ForgotPassword from './components/ForgotPassword';
import ManagePayments from './components/ManagePayments';
import Subscriptions from './components/Subscriptions';

// مصفوفة الرتب الإدارية لضمان وصول جميع أنواع رجال الأعمال للخدمات
const DG_ROLES = ['DG', 'DG_BUSINESS', 'DG_GOV', 'HOMME D\'AFFAIRES', 'PROPRIÉTAIRE D\'ENTREPRISE'];

const ProtectedRoute = ({ children, allowedRoles }) => {
  const role = localStorage.getItem('role');
  const token = localStorage.getItem('access');
  if (!token) return <Navigate to="/espace-candidat" />;
  const userRole = (role || "").toUpperCase().trim();
  const upperAllowedRoles = allowedRoles.map(r => r.toUpperCase().trim());
  if (!upperAllowedRoles.includes(userRole)) return <Navigate to="/unauthorized" />;
  return children;
};

function App() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

  const token = localStorage.getItem('access');
  const role = (localStorage.getItem('role') || "").toUpperCase().trim();
  const isAuthenticated = !!token;

  useEffect(() => {
    const root = document.documentElement;
    const updateTheme = () => {
        const currentTheme = localStorage.getItem('theme') || 'dark';
        if (currentTheme === 'light') {
            // متغيرات App.js الأصلية
            root.style.setProperty('--bg-main', '#f1f5f9');
            root.style.setProperty('--bg-card', '#ffffff');
            root.style.setProperty('--bg-input', '#ffffff');
            root.style.setProperty('--bg-table-header', '#f8fafc');
            root.style.setProperty('--text-main', '#1e293b');
            root.style.setProperty('--text-sub', '#64748b');
            root.style.setProperty('--border-color', '#e2e8f0');

            // إضافات ضرورية للربط مع app.css والمكونات الأخرى
            root.style.setProperty('--bg-sidebar', '#ffffff');
            root.style.setProperty('--text-muted', '#64748b');
        } else {
            // متغيرات App.js الأصلية
            root.style.setProperty('--bg-main', '#0f172a');
            root.style.setProperty('--bg-card', '#1e293b');
            root.style.setProperty('--bg-input', '#1e293b');
            root.style.setProperty('--bg-table-header', '#334155');
            root.style.setProperty('--text-main', '#ffffff');
            root.style.setProperty('--text-sub', '#94a3b8');
            root.style.setProperty('--border-color', '#334155');

            // إضافات ضرورية للربط مع app.css والمكونات الأخرى
            root.style.setProperty('--bg-sidebar', '#1e293b');
            root.style.setProperty('--text-muted', '#94a3b8');
        }
    };
    updateTheme();
    window.addEventListener('storage', updateTheme);
    // إضافة مستمع لحدث مخصص في حال تغيير الثيم من داخل التطبيق بدون إعادة تحميل
    window.addEventListener('themeChanged', updateTheme);

    return () => {
        window.removeEventListener('storage', updateTheme);
        window.removeEventListener('themeChanged', updateTheme);
    };
  }, []);

  return (
    <Router>
      <div style={{ display: 'flex', minHeight: '100vh', backgroundColor: 'var(--bg-main)', color: 'var(--text-main)', transition: 'all 0.3s ease' }}>
        <Sidebar isOpen={isSidebarOpen} toggleSidebar={toggleSidebar} />

        <main style={{
          flex: 1,
          marginLeft: isAuthenticated ? (isSidebarOpen ? '260px' : '0px') : '0px',
          padding: isAuthenticated ? '25px' : '0px',
          transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          width: isAuthenticated ? (isSidebarOpen ? 'calc(100% - 260px)' : '100%') : '100%',
          backgroundColor: 'var(--bg-main)',
          color: 'var(--text-main)',
          overflowX: 'hidden'
        }}>
          <Routes>
            <Route path="/" element={
              isAuthenticated ? (
                role === 'SUPER_ADMIN'
                ? <Navigate to="/AllStats" replace /> // توجيه المدير العام لصفحة الإحصائيات
                : (role === 'ADMIN' ? <Navigate to="/manage-offres" replace /> :
                  (DG_ROLES.includes(role) ? <Navigate to="/dashboard" replace /> : <Navigate to="/espace-candidat" replace />))
              ) : (
                <Navigate to="/espace-candidat" replace />
              )
            } />

            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/verify-otp" element={<VerifyOTP />} />
            <Route path="/unauthorized" element={<div style={{textAlign: 'center', marginTop: '50px'}}><h2>Accès non autorisé !</h2></div>} />

            <Route path="/manage-payments" element={
              <ProtectedRoute allowedRoles={['SUPER_ADMIN']}>
                <ManagePayments />
              </ProtectedRoute>
            } />

            <Route path="/subscriptions" element={
              <ProtectedRoute allowedRoles={[...DG_ROLES]}>
                <Subscriptions />
              </ProtectedRoute>
            } />

            {/* تم فصل الـ Dashboard لضمان استقرار العرض */}
            <Route path="/dashboard" element={
              <ProtectedRoute allowedRoles={[...DG_ROLES]}>
                <Dashboard />
              </ProtectedRoute>
            } />

            <Route path="/espace-candidat" element={<EspaceCandidat />} />
            <Route path="/profile" element={<Profile />} />
            <Route path="/manage-enterprises" element={<ProtectedRoute allowedRoles={['SUPER_ADMIN']}><ManageEnterprises /></ProtectedRoute>} />

            {/* توحيد رابط الإحصائيات مع الـ Sidebar */}
            <Route path="/AllStats" element={<ProtectedRoute allowedRoles={['SUPER_ADMIN']}><AllStats /></ProtectedRoute>} />
            <Route path="/all-stats" element={<Navigate to="/AllStats" replace />} />

            <Route path="/postuler/:offreId" element={<ProtectedRoute allowedRoles={['CANDIDAT']}><Postuler /></ProtectedRoute>} />
            <Route path="/mes-candidatures" element={<ProtectedRoute allowedRoles={['CANDIDAT']}><MesCandidatures /></ProtectedRoute>} />

            <Route path="/manage-offres" element={<ProtectedRoute allowedRoles={[...DG_ROLES, 'ADMIN', 'RESPONSABLE RH']}><ManageOffres /></ProtectedRoute>} />
            <Route path="/manage-candidatures" element={<ProtectedRoute allowedRoles={[...DG_ROLES, 'ADMIN', 'RESPONSABLE RH']}><ManageCandidatures /></ProtectedRoute>} />

            <Route path="/users" element={<ProtectedRoute allowedRoles={[...DG_ROLES, 'SUPER_ADMIN']}><Users /></ProtectedRoute>} />
            <Route path="/add-agent" element={<ProtectedRoute allowedRoles={[...DG_ROLES]}><AddAgent /></ProtectedRoute>} />
            <Route path="/entreprises/:id" element={<ProfileEntreprise />} />
            <Route path="/forgot-password" element={<ForgotPassword />} />

            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;