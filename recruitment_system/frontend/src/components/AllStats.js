import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { FiBriefcase, FiUsers, FiHome, FiUserCheck, FiTrendingUp, FiActivity, FiBarChart2 } from 'react-icons/fi';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import '../App.css';

const AllStats = () => {
    const [stats, setStats] = useState({
        total_enterprises: 0,
        total_users: 0,
        total_candidates: 0,
        total_offers: 0
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('access') || localStorage.getItem('token');
        axios.get('http://127.0.0.1:8000/api/stats/', {
            headers: { 'Authorization': `Bearer ${token}` }
        })
        .then(res => {
            setStats({
                total_enterprises: res.data.total_enterprises || 0,
                total_users: res.data.total_users || 0,
                total_candidates: res.data.total_candidates || res.data.total_candidatures || 0,
                total_offers: res.data.total_offers || res.data.total_offres || 0
            });
            setLoading(false);
        })
        .catch(err => {
            console.error("Erreur stats:", err);
            setLoading(false);
        });
    }, []);

    const chartData = [
        { name: 'Entreprises', value: stats.total_enterprises, color: '#6366f1' },
        { name: 'Utilisateurs', value: stats.total_users, color: '#10b981' },
        { name: 'Offres', value: stats.total_offers, color: '#f59e0b' },
        { name: 'Candidats', value: stats.total_candidates, color: '#ec4899' },
    ];

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen" style={{ backgroundColor: 'var(--bg-main)' }}>
                <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-indigo-500 mb-4"></div>
                <p style={{ color: 'var(--text-muted)' }} className="animate-pulse text-xl font-bold italic tracking-widest">Initialisation...</p>
            </div>
        );
    }

    return (
        <div className="p-4 md:p-8 max-w-7xl mx-auto min-h-screen transition-colors duration-300" style={{ backgroundColor: 'var(--bg-main)', color: 'var(--text-main)' }}>
            {/* Header */}
            <div className="flex flex-col md:flex-row md:items-center justify-between mb-8 md:mb-12 gap-4">
                <div>
                    <h1 className="text-2xl md:text-4xl font-black tracking-tight flex items-center gap-3">
                        <FiActivity className="text-indigo-500" /> Dashboard Analytics
                    </h1>
                    <p style={{ color: 'var(--text-muted)' }} className="mt-1 md:mt-2 text-[10px] md:text-sm font-bold uppercase tracking-[0.2em] md:tracking-[0.3em]">
                        Performance Insight System
                    </p>
                </div>
                <div className="hidden sm:block border px-4 py-2 md:px-6 md:py-3 rounded-2xl" style={{ backgroundColor: 'rgba(99, 102, 241, 0.05)', borderColor: 'rgba(99, 102, 241, 0.2)' }}>
                    <div className="flex items-center gap-3">
                        <span className="relative flex h-3 w-3">
                            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                            <span className="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                        </span>
                        <span className="text-indigo-500 text-[10px] md:text-xs font-black uppercase tracking-tighter">Live System</span>
                    </div>
                </div>
            </div>

            {/* Stat Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 md:gap-8 mb-8 md:mb-12">
                <StatCard title="Entreprises" count={stats.total_enterprises} icon={<FiHome size={24}/>} gradient="from-indigo-600 to-blue-700" />
                <StatCard title="Utilisateurs" count={stats.total_users} icon={<FiUsers size={24}/>} gradient="from-emerald-500 to-teal-700" />
                <StatCard title="Offres" count={stats.total_offers} icon={<FiBriefcase size={24}/>} gradient="from-amber-500 to-orange-700" />
                <StatCard title="Candidats" count={stats.total_candidates} icon={<FiUserCheck size={24}/>} gradient="from-pink-600 to-rose-800" />
            </div>

            {/* Visual Section */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
                <div className="lg:col-span-2 border rounded-[1.5rem] md:rounded-[2.5rem] p-4 md:p-8 shadow-2xl backdrop-blur-sm" style={{ backgroundColor: 'var(--bg-sidebar)', borderColor: 'rgba(128,128,128,0.1)' }}>
                    <h2 className="text-lg md:text-xl font-bold mb-6 md:mb-8 flex items-center gap-2">
                        <FiBarChart2 className="text-indigo-400" /> Visualisation des Data
                    </h2>
                    <div className="h-[250px] md:h-[350px] w-full">
                        <ResponsiveContainer width="100%" height="100%">
                            <BarChart data={chartData}>
                                <CartesianGrid strokeDasharray="3 3" stroke="rgba(128,128,128,0.2)" vertical={false} />
                                <XAxis dataKey="name" stroke="var(--text-muted)" fontSize={10} axisLine={false} tickLine={false} />
                                <YAxis stroke="var(--text-muted)" fontSize={10} axisLine={false} tickLine={false} />
                                <Tooltip
                                    contentStyle={{ backgroundColor: 'var(--bg-sidebar)', border: '1px solid rgba(128,128,128,0.2)', borderRadius: '12px', color: 'var(--text-main)' }}
                                    itemStyle={{ color: 'var(--text-main)' }}
                                    cursor={{fill: 'rgba(128,128,128,0.05)'}}
                                />
                                <Bar dataKey="value" radius={[5, 5, 0, 0]} barSize={40}>
                                    {chartData.map((entry, index) => (
                                        <Cell key={index} fill={entry.color} />
                                    ))}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </div>

                <div className="border rounded-[1.5rem] md:rounded-[2.5rem] p-6 md:p-8 flex flex-col justify-center items-center text-center" style={{ background: 'linear-gradient(to bottom right, var(--bg-sidebar), var(--bg-main))', borderColor: 'rgba(128,128,128,0.1)' }}>
                    <div className="w-16 h-16 md:w-20 md:h-20 bg-indigo-600/20 rounded-2xl md:rounded-3xl flex items-center justify-center mb-4 md:mb-6 border border-indigo-600/30">
                        <FiTrendingUp className="text-indigo-400 text-3xl md:text-4xl" />
                    </div>
                    <h3 className="font-black text-base md:text-lg mb-2 tracking-tight">Analyse de Performance</h3>
                    <p style={{ color: 'var(--text-muted)' }} className="text-xs md:text-sm mb-6 md:mb-8">
                        Ratio actuel: <span className="text-indigo-400 font-bold">
                            {(stats.total_candidates / (stats.total_offers || 1)).toFixed(1)}
                        </span> candidats/offre.
                    </p>
                    <button className="w-full py-3 md:py-4 bg-indigo-600 hover:bg-indigo-500 text-white rounded-xl md:rounded-2xl font-black transition-all transform active:scale-95 shadow-xl shadow-indigo-600/20 uppercase text-[10px] tracking-widest">
                        Générer Rapport
                    </button>
                </div>
            </div>
        </div>
    );
};

const StatCard = ({ title, count, icon, gradient }) => (
    <div className={`bg-gradient-to-br ${gradient} p-[1px] rounded-[1.5rem] md:rounded-[2.2rem] shadow-2xl transition-all duration-300 hover:-translate-y-1 group`}>
        <div className="backdrop-blur-xl h-full w-full rounded-[1.5rem] md:rounded-[2.2rem] p-4 md:p-6 lg:p-8 relative overflow-hidden" style={{ backgroundColor: 'var(--bg-main)' }}>
            <div className="absolute -right-2 -bottom-2 w-16 h-16 bg-white/5 rounded-full blur-3xl"></div>
            <div className="flex justify-between items-start relative z-10 gap-2">
                <div className={`p-3 md:p-4 rounded-xl md:rounded-2xl bg-gradient-to-br ${gradient} text-white shadow-lg shrink-0`}>
                    {icon}
                </div>
                <div className="text-right min-w-0">
                    <span style={{ color: 'var(--text-muted)' }} className="text-[8px] md:text-[10px] font-black uppercase tracking-widest leading-none block truncate">{title}</span>
                    <h4 style={{ color: 'var(--text-main)' }} className="text-xl md:text-2xl lg:text-3xl xl:text-4xl font-black mt-1 md:mt-2 group-hover:scale-105 transition-transform origin-right tracking-tighter truncate">
                        {count.toLocaleString()}
                    </h4>
                </div>
            </div>
            <div className="mt-4 md:mt-6 flex items-center gap-2 text-[8px] md:text-[10px] font-bold text-emerald-400 uppercase tracking-[0.2em]">
                <FiTrendingUp className="animate-pulse shrink-0" /> <span className="truncate">Live Tracking</span>
            </div>
        </div>
    </div>
);

export default AllStats;