import React, { useState } from 'react';
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

const ProtectedRoute = ({ children, allowedRoles }) => {
  const role = localStorage.getItem('role');
  const token = localStorage.getItem('access');
  if (!token) return <Navigate to="/espace-candidat" />;
  if (!allowedRoles.includes(role)) return <Navigate to="/unauthorized" />;
  return children;
};

function App() {
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

  // التحقق من حالة الدخول لضبط تمدد المحتوى
  const token = localStorage.getItem('access');
  const role = localStorage.getItem('role');
  const isAuthenticated = token && role;

  return (
    <Router>
      <div style={{
        display: 'flex',
        minHeight: '100vh',
        backgroundColor: 'var(--bg-main)',
        transition: 'background-color 0.3s ease'
      }}>
        <Sidebar isOpen={isSidebarOpen} toggleSidebar={toggleSidebar} />

        <main style={{
          flex: 1,
          // التعديل: تصفير الهامش وتوسيع العرض إذا لم يكن مسجلاً للدخول
          marginLeft: isAuthenticated ? (isSidebarOpen ? '260px' : '0px') : '0px',
          padding: isAuthenticated ? '20px' : '0px', // إلغاء البادينج في العرض العام لجمالية التصميم
          transition: 'all 0.4s cubic-bezier(0.4, 0, 0.2, 1)',
          width: isAuthenticated ? (isSidebarOpen ? 'calc(100% - 260px)' : '100%') : '100%',
          backgroundColor: 'var(--bg-main)',
          color: 'var(--text-main)',
          overflowX: 'hidden'
        }}>
          <Routes>
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/verify-otp" element={<VerifyOTP />} />
            <Route path="/unauthorized" element={
              <div style={{textAlign: 'center', marginTop: '50px', color: 'var(--text-main)'}}>
                <h2>Accès non autorisé !</h2>
              </div>
            } />
            <Route path="/espace-candidat" element={<EspaceCandidat />} />
            <Route path="/profile" element={<Profile />} />

            <Route path="/postuler/:offreId" element={
                <ProtectedRoute allowedRoles={['CANDIDAT', 'Candidat']}>
                  <Postuler />
                </ProtectedRoute>
            } />
            <Route path="/mes-candidatures" element={
                <ProtectedRoute allowedRoles={['CANDIDAT', 'Candidat']}>
                  <MesCandidatures />
                </ProtectedRoute>
            } />

            <Route path="/manage-offres" element={
                <ProtectedRoute allowedRoles={['Directeur Général', 'DG', 'ADMIN', 'Responsable RH']}>
                  <ManageOffres />
                </ProtectedRoute>
            } />
            <Route path="/manage-candidatures" element={
                <ProtectedRoute allowedRoles={['Directeur Général', 'DG', 'ADMIN', 'Responsable RH']}>
                  <ManageCandidatures />
                </ProtectedRoute>
            } />

            <Route path="/dashboard" element={
                <ProtectedRoute allowedRoles={['Directeur Général', 'DG']}>
                  <Dashboard />
                </ProtectedRoute>
            } />
            <Route path="/users" element={
                <ProtectedRoute allowedRoles={['Directeur Général', 'DG']}>
                  <Users />
                </ProtectedRoute>
            } />
            <Route path="/add-agent" element={
                <ProtectedRoute allowedRoles={['Directeur Général', 'DG']}>
                  <AddAgent />
                </ProtectedRoute>
            } />

            <Route path="/" element={<Navigate to="/espace-candidat" />} />
          </Routes>
        </main>
      </div>
    </Router>
  );
}

export default App;