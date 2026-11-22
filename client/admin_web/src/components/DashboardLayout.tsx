import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { auth, db } from '../lib/firebase';
import { signOut } from 'firebase/auth';
import { Settings, Bell, LogOut, ChevronDown } from 'lucide-react';
import { useEffect, useState } from 'react';
import { collection, query, where, onSnapshot } from 'firebase/firestore';
import clsx from 'clsx';

export default function DashboardLayout() {
  const navigate = useNavigate();
  const [pendingApprovalsCount, setPendingApprovalsCount] = useState(0);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);

  useEffect(() => {
    let countTickets = 0;
    let countMenu = 0;

    const updateCount = () => {
      setPendingApprovalsCount(countTickets + countMenu);
    };

    // 1. Menu items with pending approval
    const unsubMenu = onSnapshot(collection(db, 'menu_items'), (snap) => {
      countMenu = snap.docs.filter(d => {
        const data = d.data();
        return data.approvalStatus === 'pending' || (data.isApproved === false && data.approvalStatus !== 'rejected');
      }).length;
      updateCount();
    }, () => {});

    // 2. Approval tickets collection (if whitelisted)
    let unsubTickets: (() => void) | null = null;
    try {
      unsubTickets = onSnapshot(query(collection(db, 'approval_tickets'), where('status', '==', 'pending')), (snap) => {
        countTickets = snap.docs.length;
        updateCount();
      }, () => {});
    } catch (_) {}

    return () => {
      unsubMenu();
      if (unsubTickets) unsubTickets();
    };
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  const navItems = [
    { name: 'Dashboard', path: '/' },
    { name: 'Approvals', path: '/approvals', badge: pendingApprovalsCount },
    { name: 'Live Queue', path: '/queue' },
    { name: 'Menu', path: '/menu' },
    { name: 'Analytics', path: '/analytics' },
  ];

  return (
    <div className="min-h-screen bg-[#FAF5EB] text-[#18181B] flex flex-col relative selection:bg-[#FACC15]/40 overflow-x-hidden">
      {/* Warm Ambient Glows (Crextio Aesthetic) */}
      <div className="fixed top-0 right-0 w-[550px] h-[550px] bg-gradient-to-br from-[#FEF08A]/45 via-[#FDE047]/20 to-transparent blur-3xl pointer-events-none rounded-full z-0" />
      <div className="fixed bottom-0 left-0 w-[450px] h-[450px] bg-gradient-to-tr from-[#FEF9C3]/40 via-[#FAF5EB]/10 to-transparent blur-3xl pointer-events-none rounded-full z-0" />

      {/* Top Header / Capsule Navigation */}
      <header className="sticky top-0 z-40 px-6 sm:px-10 py-5 flex items-center justify-between backdrop-blur-md bg-[#FAF5EB]/80 border-b border-[#EDE6D4]/60">
        {/* Left: Pill Brand Logo */}
        <div className="flex items-center gap-3">
          <NavLink
            to="/"
            className="flex items-center px-4 py-1.5 rounded-full border border-stone-800/80 bg-white/60 hover:bg-white text-stone-900 font-extrabold text-sm tracking-tight shadow-sm transition-all"
          >
            AuraBake
          </NavLink>
        </div>

        {/* Center: Main Pill Navigation Capsule */}
        <nav className="hidden md:flex items-center gap-1 p-1 bg-white/70 backdrop-blur-sm border border-[#E7DFC9] rounded-full shadow-sm">
          {navItems.map((item) => (
            <NavLink
              key={item.name}
              to={item.path}
              className={({ isActive }) => clsx(
                "relative flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold transition-all duration-200",
                isActive
                  ? "bg-[#18181B] text-white shadow-sm"
                  : "text-stone-600 hover:text-stone-900 hover:bg-stone-100/60"
              )}
            >
              <span>{item.name}</span>
              {item.badge !== undefined && item.badge > 0 && (
                <span className={clsx(
                  "px-1.5 py-0.2 rounded-full text-[10px] font-black",
                  item.badge > 0 ? "bg-[#FACC15] text-stone-950" : "bg-stone-200 text-stone-700"
                )}>
                  {item.badge}
                </span>
              )}
            </NavLink>
          ))}
        </nav>

        {/* Right: Actions, Bell & Profile */}
        <div className="flex items-center gap-2.5">
          {/* Quick Settings Pill */}
          <NavLink
            to="/analytics"
            className="hidden sm:flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-stone-300/80 bg-white/60 hover:bg-white text-stone-700 text-xs font-semibold shadow-xs transition-colors"
          >
            <Settings size={13} className="text-stone-500" />
            <span>Setting</span>
          </NavLink>

          {/* Notifications Bell */}
          <div className="relative">
            <button
              onClick={() => navigate('/approvals')}
              className="w-8 h-8 rounded-full border border-stone-300/80 bg-white/80 hover:bg-white flex items-center justify-center text-stone-700 shadow-xs transition-colors relative"
              title="Approvals & Alerts"
            >
              <Bell size={14} />
              {pendingApprovalsCount > 0 && (
                <span className="absolute top-1 right-1 w-2 h-2 rounded-full bg-[#EAB308] ring-2 ring-white animate-pulse" />
              )}
            </button>
          </div>

          {/* User Profile Capsule */}
          <div className="relative">
            <button
              onClick={() => setProfileDropdownOpen(!profileDropdownOpen)}
              className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-full border border-stone-300/80 bg-white/80 hover:bg-white text-stone-800 transition-all shadow-xs"
            >
              <div className="w-6 h-6 rounded-full bg-[#18181B] text-white flex items-center justify-center text-[10px] font-black">
                A
              </div>
              <span className="text-xs font-bold hidden sm:inline">Admin</span>
              <ChevronDown size={12} className="text-stone-400" />
            </button>

            {profileDropdownOpen && (
              <div className="absolute right-0 mt-2 w-48 bg-white border border-stone-200 rounded-2xl p-2 shadow-xl z-50 animate-in fade-in slide-in-from-top-1">
                <div className="px-3 py-2 border-b border-stone-100">
                  <p className="text-xs font-bold text-stone-900">Administrator</p>
                  <p className="text-[11px] text-stone-400 truncate">admin@aurabake.app</p>
                </div>
                <button
                  onClick={handleLogout}
                  className="flex items-center gap-2 w-full px-3 py-2 text-xs font-semibold text-red-600 hover:bg-red-50 rounded-xl transition-colors mt-1"
                >
                  <LogOut size={13} />
                  Sign Out
                </button>
              </div>
            )}
          </div>
        </div>
      </header>

      {/* Main Screen Content */}
      <main className="flex-1 px-6 sm:px-10 py-6 max-w-[1500px] w-full mx-auto relative z-10">
        <Outlet />
      </main>
    </div>
  );
}
