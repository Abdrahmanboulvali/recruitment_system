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

const ProtectedRoute = ({ children, allowedRoles }) => {
  const role = localStorage.getItem('role');
  const token = localStorage.getItem('access');

  if (!token) return <Navigate to="/login" />;

  // التحقق من الدور مع مراعاة الاحتمالات الظاهرة في الصور
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
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        <Route path="/verify-otp" element={<VerifyOTP />} />
        <Route path="/unauthorized" element={<div style={{textAlign: 'center', marginTop: '50px'}}><h2>Accès non autorisé !</h2></div>} />
        <Route path="/postuler/:offreId" element={<Postuler />} />
        <Route path="/espace-candidat" element={<EspaceCandidat />} />
        <Route path="/mes-candidatures" element={<MesCandidatures />} />
        <Route path="/manage-offres" element={<ManageOffres />} />
        <Route path="/manage-candidatures" element={<ManageCandidatures />} />
        <Route path="/users" element={<Users />} />

        {/* مسار المترشح: يشمل كل صيغ كلمة Candidat */}
        <Route path="/espace-candidat" element={
            <ProtectedRoute allowedRoles={['CANDIDAT', 'Candidat']}>
              <EspaceCandidat />
            </ProtectedRoute>
        } />

        {/* مسار الإدارة: يشمل كل صيغ كلمات المسؤول والعملاء */}
        <Route path="/dashboard" element={
            <ProtectedRoute allowedRoles={['ADMIN', 'ADMINISTRATEUR', 'Administrateur', 'AGENTRH', 'AgentRH']}>
              <Dashboard />
            </ProtectedRoute>
        } />

        <Route path="/" element={<Navigate to="/login" />} />
      </Routes>
    </Router>
  );
}

export default App;