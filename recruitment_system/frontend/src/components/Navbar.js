import React from 'react';
import { Link, useNavigate } from 'react-router-dom';

const Navbar = () => {
    const navigate = useNavigate();
    const isAuthenticated = localStorage.getItem('access'); // التحقق من وجود التوكن

    const handleLogout = () => {
        localStorage.removeItem('access');
        localStorage.removeItem('refresh');
        navigate('/login');
    };

    return (
        <nav style={{ padding: '10px', backgroundColor: '#333', color: '#fff', display: 'flex', justifyContent: 'space-between' }}>
            <div>
                <Link to="/" style={{ color: '#fff', marginRight: '15px', textDecoration: 'none' }}>Accueil</Link>
                {isAuthenticated && (
                    <Link to="/dashboard" style={{ color: '#fff', marginRight: '15px', textDecoration: 'none' }}>Dashboard</Link>
                )}
            </div>
            <div>
                {isAuthenticated ? (
                    <button onClick={handleLogout} style={{ background: 'none', border: 'none', color: '#fff', cursor: 'pointer' }}>
                        Déconnexion
                    </button>
                ) : (
                    <>
                        <Link to="/login" style={{ color: '#fff', marginRight: '15px', textDecoration: 'none' }}>Connexion</Link>
                        <Link to="/register" style={{ color: '#fff', textDecoration: 'none' }}>Inscription</Link>
                    </>
                )}
            </div>
        </nav>
    );
};

export default Navbar;