import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import EspaceCandidat from './components/EspaceCandidat';
import Register from './components/Register';
import Navbar from './components/Navbar';
import Postuler from './components/Postuler';
import MesCandidatures from './components/MesCandidatures';
import ManageOffres from './components/ManageOffres';
import ManageCandidatures from './components/ManageCandidatures';
import Users from './components/Users';
import VerifyOTP from './components/VerifyOTP';
import AddAgent from './components/AddAgent';

// مكون الحماية المطور
const ProtectedRoute = ({ children, allowedRoles }) => {
  const role = localStorage.getItem('role');
  const token = localStorage.getItem('access');

  if (!token) return <Navigate to="/espace-candidat" />;

  // التحقق من أن دور المستخدم موجود ضمن القائمة المسموحة لهذا المسار
  if (!allowedRoles.includes(role)) {
    return <Navigate to="/unauthorized" />;
  }

  return children;
};

function App() {
  return (
    <Router>
      <Navbar />
      <Routes>
        {/* المسارات العامة */}
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/verify-otp" element={<VerifyOTP />} />
        <Route path="/unauthorized" element={<div style={{textAlign: 'center', marginTop: '50px'}}><h2>Accès non autorisé !</h2></div>} />
        <Route path="/espace-candidat" element={<EspaceCandidat />} />
        {/* مسارات المترشح (Candidat) */}
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


        {/* مسارات مشتركة لإدارة العمليات: مسموح للمدير والوكيل */}
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

        {/* مسارات حصرية للمدير العام فقط (هنا نمنع الوكيل) */}
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
    </Router>
  );
}

export default App;