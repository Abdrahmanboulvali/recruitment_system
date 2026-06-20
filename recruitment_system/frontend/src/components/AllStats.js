import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { FiBriefcase, FiUsers, FiHome, FiUserCheck, FiTrendingUp, FiActivity, FiBarChart2, FiPieChart, FiDollarSign } from 'react-icons/fi';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell, PieChart, Pie, AreaChart, Area } from 'recharts';
import '../App.css';

const AllStats = () => {
    const [stats, setStats] = useState({
        total_enterprises: 0,
        total_users: 0,
        total_candidates: 0,
        total_offers: 0,
        distribution: { Fortement: 0, Pertinente: 0, Faiblement: 0 },
        sectors_activities: { Tech: 0, Santé: 0, Finance: 0, Droit: 0 },
        financial_flux: [0, 0, 0, 0, 0, 0]
    });
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const token = localStorage.getItem('access') || localStorage.getItem('token');
        axios.get('http://127.0.0.1:8000/api/stats/', {
            headers: { 'Authorization': `Bearer ${token}` }
        })
        .then(res => {
            setStats(res.data);
            setLoading(false);
        })
        .catch(err => {
            console.error("Erreur stats:", err);
            setLoading(false);
        });
    }, []);

    // تحضير البيانات للرسوم
    const barData = [
        { name: 'Fortement', value: stats.distribution.Fortement, color: '#10b981' },
        { name: 'Pertinente', value: stats.distribution.Pertinente, color: '#f59e0b' },
        { name: 'Faiblement', value: stats.distribution.Faiblement, color: '#ef4444' },
    ];

    const pieData = Object.entries(stats.sectors_activities).map(([key, value]) => ({ name: key, value }));
    const financialData = stats.financial_flux.map((val, idx) => ({ name: `M${idx + 1}`, value: val }));

    if (loading) {
        return (
            <div className="flex flex-col items-center justify-center min-h-screen" style={{ backgroundColor: 'var(--bg-main)' }}>
                <div className="animate-spin rounded-full h-16 w-16 border-t-4 border-indigo-500 mb-4"></div>
                <p style={{ color: 'var(--text-muted)' }} className="animate-pulse text-xl font-bold italic tracking-widest">Chargement...</p>
            </div>
        );
    }

    return (
        <div className="p-4 md:p-8 max-w-7xl mx-auto min-h-screen transition-colors duration-300" style={{ backgroundColor: 'var(--bg-main)', color: 'var(--text-main)' }}>

            {/* Header */}
            <div className="mb-10">
                <h1 className="text-3xl font-black tracking-tight flex items-center gap-3">
                    <FiActivity className="text-indigo-500" /> Admin Dashboard
                </h1>
                <p style={{ color: 'var(--text-muted)' }} className="mt-2 text-sm font-bold uppercase tracking-[0.3em]">Super Admin Control Center</p>
            </div>

            {/* Stat Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6 mb-8">
                <StatCard title="Entreprises" count={stats.total_enterprises} icon={<FiHome size={24}/>} gradient="from-indigo-600 to-blue-700" />
                <StatCard title="Utilisateurs" count={stats.total_users} icon={<FiUsers size={24}/>} gradient="from-emerald-500 to-teal-700" />
                <StatCard title="Offres" count={stats.total_offers} icon={<FiBriefcase size={24}/>} gradient="from-amber-500 to-orange-700" />
                <StatCard title="Candidats" count={stats.total_candidates} icon={<FiUserCheck size={24}/>} gradient="from-pink-600 to-rose-800" />
            </div>

            {/* Main Charts Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
                {/* Distribution Chart */}
                <div className="border rounded-[2.5rem] p-8 shadow-xl" style={{ backgroundColor: 'var(--bg-sidebar)', borderColor: 'rgba(128,128,128,0.1)' }}>
                    <h2 className="text-lg font-bold mb-6 flex items-center gap-2"><FiBarChart2 className="text-indigo-400" /> Distribution des Scores</h2>
                    <ResponsiveContainer width="100%" height={300}>
                        <BarChart data={barData}>
                            <XAxis dataKey="name" stroke="var(--text-muted)" fontSize={12} />
                            <Tooltip contentStyle={{ borderRadius: '12px' }} />
                            <Bar dataKey="value" radius={[10, 10, 0, 0]}>
                                {barData.map((e, i) => <Cell key={i} fill={e.color} />)}
                            </Bar>
                        </BarChart>
                    </ResponsiveContainer>
                </div>

                {/* Sectors Chart */}
                <div className="border rounded-[2.5rem] p-8 shadow-xl" style={{ backgroundColor: 'var(--bg-sidebar)', borderColor: 'rgba(128,128,128,0.1)' }}>
                    <h2 className="text-lg font-bold mb-6 flex items-center gap-2"><FiPieChart className="text-indigo-400" /> Secteurs d'activité</h2>
                    <ResponsiveContainer width="100%" height={300}>
                        <PieChart>
                            <Pie data={pieData} innerRadius={60} outerRadius={100} paddingAngle={5} dataKey="value">
                                {pieData.map((entry, index) => <Cell key={index} fill={['#6366f1', '#10b981', '#f59e0b', '#ec4899'][index % 4]} />)}
                            </Pie>
                            <Tooltip />
                        </PieChart>
                    </ResponsiveContainer>
                </div>
            </div>

            {/* Financial Section */}
            <div className="border rounded-[2.5rem] p-8 shadow-xl" style={{ backgroundColor: 'var(--bg-sidebar)', borderColor: 'rgba(128,128,128,0.1)' }}>
                <h2 className="text-lg font-bold mb-6 flex items-center gap-2"><FiDollarSign className="text-green-500" /> Flux Financier (Derniers 6 mois)</h2>
                <ResponsiveContainer width="100%" height={250}>
                    <AreaChart data={financialData}>
                        <defs>
                            <linearGradient id="colorVal" x1="0" y1="0" x2="0" y2="1">
                                <stop offset="5%" stopColor="#10b981" stopOpacity={0.3}/>
                                <stop offset="95%" stopColor="#10b981" stopOpacity={0}/>
                            </linearGradient>
                        </defs>
                        <XAxis dataKey="name" stroke="var(--text-muted)" />
                        <YAxis stroke="var(--text-muted)" />
                        <Tooltip contentStyle={{ borderRadius: '12px' }} />
                        <Area type="monotone" dataKey="value" stroke="#10b981" fillOpacity={1} fill="url(#colorVal)" />
                    </AreaChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
};

const StatCard = ({ title, count, icon, gradient }) => (
    <div className={`bg-gradient-to-br ${gradient} p-[1px] rounded-[2.2rem] shadow-lg`}>
        <div className="h-full w-full rounded-[2.2rem] p-6 relative overflow-hidden" style={{ backgroundColor: 'var(--bg-main)' }}>
            <div className="flex justify-between items-start z-10">
                <div className={`p-3 rounded-2xl bg-gradient-to-br ${gradient} text-white`}>{icon}</div>
                <div className="text-right">
                    <span style={{ color: 'var(--text-muted)' }} className="text-[10px] font-black uppercase tracking-widest">{title}</span>
                    <h4 className="text-3xl font-black mt-1 tracking-tighter">{count.toLocaleString()}</h4>
                </div>
            </div>
        </div>
    </div>
);

export default AllStats;