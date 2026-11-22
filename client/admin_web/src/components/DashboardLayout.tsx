import { Outlet, NavLink, useNavigate } from 'react-router-dom';
import { auth, db } from '../lib/firebase';
import { signOut } from 'firebase/auth';
import { Settings, Bell, LogOut, ChevronDown, X, Save } from 'lucide-react';
import { useEffect, useState } from 'react';
import { collection, query, where, onSnapshot, doc, getDoc, setDoc } from 'firebase/firestore';
import { motion, AnimatePresence } from 'framer-motion';
import clsx from 'clsx';

export default function DashboardLayout() {
  const navigate = useNavigate();
  const [pendingApprovalsCount, setPendingApprovalsCount] = useState(0);
  const [openReportsCount, setOpenReportsCount] = useState(0);
  const [profileDropdownOpen, setProfileDropdownOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);

  // Settings Modal State
  const [isSettingsModalOpen, setIsSettingsModalOpen] = useState(false);
  const [brandName, setBrandName] = useState('AuraBake Campus Pre-Order');
  const [masterUpi, setMasterUpi] = useState('aurabake@upi');
  const [openTime, setOpenTime] = useState('08:00 AM');
  const [closeTime, setCloseTime] = useState('10:00 PM');
  const [convenienceFee, setConvenienceFee] = useState('5.00');
  const [autoApproveItems, setAutoApproveItems] = useState(false);
  const [storeStatus, setStoreStatus] = useState<'open' | 'paused'>('open');
  const [isSavingSettings, setIsSavingSettings] = useState(false);
  const [settingsSavedToast, setSettingsSavedToast] = useState(false);

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

    // 2. Approval tickets collection
    let unsubTickets: (() => void) | null = null;
    try {
      unsubTickets = onSnapshot(query(collection(db, 'approval_tickets'), where('status', '==', 'pending')), (snap) => {
        countTickets = snap.docs.length;
        updateCount();
      }, () => {});
    } catch (_) {}

    // 3. Customer support reports listener
    const unsubReports = onSnapshot(collection(db, 'support_reports'), (snap) => {
      setOpenReportsCount(snap.docs.filter(d => d.data().status === 'open').length);
    }, () => {});

    // 4. Fetch existing system settings
    const loadSettings = async () => {
      try {
        const snap = await getDoc(doc(db, 'system_settings', 'config'));
        if (snap.exists()) {
          const data = snap.data();
          if (data.brandName) setBrandName(data.brandName);
          if (data.masterUpi) setMasterUpi(data.masterUpi);
          if (data.openTime) setOpenTime(data.openTime);
          if (data.closeTime) setCloseTime(data.closeTime);
          if (data.convenienceFee) setConvenienceFee(data.convenienceFee.toString());
          if (data.autoApproveItems !== undefined) setAutoApproveItems(data.autoApproveItems);
          if (data.storeStatus) setStoreStatus(data.storeStatus);
        }
      } catch (_) {}
    };
    loadSettings();

    return () => {
      unsubMenu();
      unsubReports();
      if (unsubTickets) unsubTickets();
    };
  }, []);

  const handleLogout = async () => {
    await signOut(auth);
    navigate('/login');
  };

  const handleSaveSettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingSettings(true);
    try {
      await setDoc(doc(db, 'system_settings', 'config'), {
        brandName: brandName.trim(),
        masterUpi: masterUpi.trim(),
        openTime: openTime.trim(),
        closeTime: closeTime.trim(),
        convenienceFee: parseFloat(convenienceFee) || 5.0,
        autoApproveItems,
        storeStatus,
        updatedAt: new Date(),
      }, { merge: true });

      setSettingsSavedToast(true);
      setTimeout(() => {
        setSettingsSavedToast(false);
        setIsSettingsModalOpen(false);
      }, 1200);
    } catch (e) {
      console.error('Failed to save settings:', e);
      alert('Could not save settings: ' + e);
    } finally {
      setIsSavingSettings(false);
    }
  };

  const navItems = [
    { name: 'Dashboard', path: '/' },
    { name: 'Approvals', path: '/approvals', badge: pendingApprovalsCount },
    { name: 'Live Queue', path: '/queue' },
    { name: 'Menu', path: '/menu' },
    { name: 'Analytics', path: '/analytics' },
    { name: 'Settings & Hub', path: '/settings', badge: openReportsCount },
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
          {/* Settings Hub Pill Button */}
          <button
            onClick={() => navigate('/settings')}
            className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-full border border-stone-300/80 bg-white/70 hover:bg-white text-stone-800 text-xs font-bold shadow-xs transition-all hover:scale-[1.02] active:scale-[0.98] relative"
            title="Operations, Customer Queries, Manager Governance & Settings Hub"
          >
            <Settings size={13} className="text-stone-600" />
            <span>Setting</span>
            {openReportsCount > 0 && (
              <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse ml-0.5" />
            )}
          </button>

          {/* Notifications Bell with Interactive Dropdown */}
          <div className="relative">
            <button
              onClick={() => {
                setNotificationsOpen(!notificationsOpen);
                setProfileDropdownOpen(false);
              }}
              className="w-8 h-8 rounded-full border border-stone-300/80 bg-white/80 hover:bg-white flex items-center justify-center text-stone-700 shadow-xs transition-colors relative"
              title="Notifications & Alerts"
            >
              <Bell size={14} />
              {(pendingApprovalsCount > 0 || openReportsCount > 0) && (
                <span className="absolute top-1 right-1 w-2.5 h-2.5 rounded-full bg-[#EAB308] ring-2 ring-white animate-pulse" />
              )}
            </button>

            {notificationsOpen && (
              <div className="absolute right-0 mt-2 w-80 bg-white border border-stone-200 rounded-2xl p-3 shadow-xl z-50 animate-in fade-in slide-in-from-top-1 text-left">
                <div className="flex items-center justify-between pb-2 border-b border-stone-100">
                  <span className="text-xs font-bold text-stone-900">Notifications</span>
                  <div className="flex items-center gap-1">
                    {pendingApprovalsCount > 0 && (
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-[#FACC15] text-stone-950 font-black">
                        {pendingApprovalsCount} new
                      </span>
                    )}
                    {openReportsCount > 0 && (
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-red-500 text-white font-black">
                        {openReportsCount} issues
                      </span>
                    )}
                  </div>
                </div>

                <div className="py-2 space-y-2">
                  {/* Customer Support Issues */}
                  {openReportsCount > 0 && (
                    <div
                      onClick={() => {
                        setNotificationsOpen(false);
                        navigate('/settings?tab=queries');
                      }}
                      className="p-2.5 rounded-xl bg-red-50/80 border border-red-200/70 hover:bg-red-100 cursor-pointer transition-colors"
                    >
                      <div className="flex items-center justify-between">
                        <p className="text-xs font-bold text-red-950 flex items-center gap-1.5">
                          <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
                          <span>Customer Issue Reports</span>
                        </p>
                        <span className="text-[9px] px-1.5 py-0.2 bg-red-600 text-white rounded-full font-bold">
                          {openReportsCount} Action Required
                        </span>
                      </div>
                      <p className="text-[10px] text-red-800 mt-1">
                        Active refund or service disputes reported by students.
                      </p>
                    </div>
                  )}

                  {/* Menu Approvals */}
                  {pendingApprovalsCount > 0 ? (
                    <div
                      onClick={() => {
                        setNotificationsOpen(false);
                        navigate('/approvals');
                      }}
                      className="p-2 rounded-xl bg-amber-50/70 border border-amber-200/60 hover:bg-amber-100/60 cursor-pointer transition-colors"
                    >
                      <p className="text-xs font-bold text-stone-900">Pending Menu Submissions</p>
                      <p className="text-[10px] text-stone-600">
                        {pendingApprovalsCount} new item{pendingApprovalsCount > 1 ? 's' : ''} submitted by stall managers awaiting review.
                      </p>
                    </div>
                  ) : (
                    openReportsCount === 0 && (
                      <p className="text-xs text-stone-400 py-1 text-center">No pending alerts</p>
                    )
                  )}

                  <div
                    onClick={() => {
                      setNotificationsOpen(false);
                      navigate('/queue');
                    }}
                    className="p-2 rounded-xl bg-stone-50 border border-stone-100 hover:bg-stone-100 cursor-pointer transition-colors"
                  >
                    <p className="text-xs font-bold text-stone-900">Live Kitchen Queue</p>
                    <p className="text-[10px] text-stone-500">Live order fulfillment and dispatch tracker.</p>
                  </div>
                </div>

                <div className="pt-2 border-t border-stone-100 flex items-center justify-between text-[11px]">
                  <button
                    onClick={() => {
                      setNotificationsOpen(false);
                      navigate('/settings?tab=queries');
                    }}
                    className="text-stone-900 font-bold hover:underline"
                  >
                    Support & Reports Hub →
                  </button>
                  <button
                    onClick={() => setNotificationsOpen(false)}
                    className="text-stone-400 hover:text-stone-700"
                  >
                    Close
                  </button>
                </div>
              </div>
            )}
          </div>

          {/* User Profile Capsule */}
          <div className="relative">
            <button
              onClick={() => {
                setProfileDropdownOpen(!profileDropdownOpen);
                setNotificationsOpen(false);
              }}
              className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-full border border-stone-300/80 bg-white/80 hover:bg-white text-stone-800 transition-all shadow-xs"
            >
              <div className="w-6 h-6 rounded-full bg-[#18181B] text-white flex items-center justify-center text-[10px] font-black">
                A
              </div>
              <span className="text-xs font-bold hidden sm:inline">Admin</span>
              <ChevronDown size={12} className="text-stone-400" />
            </button>

            {profileDropdownOpen && (
              <div className="absolute right-0 mt-2 w-56 bg-white border border-stone-200 rounded-2xl p-2 shadow-xl z-50 animate-in fade-in slide-in-from-top-1">
                <div className="px-3 py-2 border-b border-stone-100">
                  <div className="flex items-center justify-between">
                    <p className="text-xs font-bold text-stone-900">Administrator</p>
                    <span className="text-[9px] bg-stone-100 px-1.5 py-0.5 rounded text-stone-600 font-semibold">Master</span>
                  </div>
                  <p className="text-[11px] text-stone-400 truncate mt-0.5">
                    {auth.currentUser?.email || 'admin@aurabake.app'}
                  </p>
                </div>
                <button
                  onClick={() => {
                    setProfileDropdownOpen(false);
                    navigate('/settings');
                  }}
                  className="flex items-center gap-2 w-full px-3 py-2 text-xs font-semibold text-stone-700 hover:bg-stone-50 rounded-xl transition-colors mt-1"
                >
                  <Settings size={13} />
                  Operations & Settings Hub
                </button>
                <button
                  onClick={handleLogout}
                  className="flex items-center gap-2 w-full px-3 py-2 text-xs font-semibold text-red-600 hover:bg-red-50 rounded-xl transition-colors"
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

      {/* ─── FILLABLE STORE & SYSTEM SETTINGS MODAL ─── */}
      <AnimatePresence>
        {isSettingsModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-xl bg-white rounded-[32px] p-6 sm:p-8 shadow-2xl border border-[#E9DFCB] space-y-5"
            >
              {/* Header */}
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-lg font-bold text-stone-900">System & Store Settings</h3>
                  <p className="text-xs text-stone-500">Configure campus pre-ordering rules, master UPI, and operating hours</p>
                </div>
                <button
                  onClick={() => setIsSettingsModalOpen(false)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              {settingsSavedToast && (
                <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-center gap-2 text-emerald-800 text-xs font-bold">
                  <Save size={14} className="text-emerald-600" />
                  <span>Settings updated successfully! ✓</span>
                </div>
              )}

              <form onSubmit={handleSaveSettings} className="space-y-4">
                {/* Store Status Toggle */}
                <div className="p-3.5 bg-stone-50 rounded-2xl border border-stone-100 flex items-center justify-between">
                  <div>
                    <p className="text-xs font-bold text-stone-900">Store Master Status</p>
                    <p className="text-[10px] text-stone-500">Temporarily pause all campus student pre-orders</p>
                  </div>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => setStoreStatus(storeStatus === 'open' ? 'paused' : 'open')}
                      className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out ${
                        storeStatus === 'open' ? 'bg-emerald-500' : 'bg-red-400'
                      }`}
                    >
                      <span
                        className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                          storeStatus === 'open' ? 'translate-x-5' : 'translate-x-0'
                        }`}
                      />
                    </button>
                    <span className="text-xs font-bold text-stone-700 w-16">
                      {storeStatus === 'open' ? 'Open 🟢' : 'Paused 🔴'}
                    </span>
                  </div>
                </div>

                {/* Brand Name & Master UPI */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Campus App Brand</label>
                    <input
                      type="text"
                      required
                      value={brandName}
                      onChange={e => setBrandName(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Master Merchant UPI ID</label>
                    <input
                      type="text"
                      required
                      value={masterUpi}
                      onChange={e => setMasterUpi(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 font-mono focus:outline-none focus:border-stone-800"
                    />
                  </div>
                </div>

                {/* Operating Schedule */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Kitchen Open Time</label>
                    <input
                      type="text"
                      value={openTime}
                      onChange={e => setOpenTime(e.target.value)}
                      placeholder="e.g. 08:00 AM"
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Kitchen Close Time</label>
                    <input
                      type="text"
                      value={closeTime}
                      onChange={e => setCloseTime(e.target.value)}
                      placeholder="e.g. 10:00 PM"
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>
                </div>

                {/* Platform Fee & Auto Approve */}
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Packaging / Platform Fee (₹)</label>
                    <input
                      type="number"
                      step="0.5"
                      value={convenienceFee}
                      onChange={e => setConvenienceFee(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div className="flex flex-col justify-center pt-2">
                    <label className="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        checked={autoApproveItems}
                        onChange={e => setAutoApproveItems(e.target.checked)}
                        className="w-4 h-4 rounded text-stone-900 focus:ring-0"
                      />
                      <span className="text-xs font-bold text-stone-800">Auto-Approve Menu Additions</span>
                    </label>
                    <p className="text-[10px] text-stone-400 pl-6">Skip manual review for trusted managers</p>
                  </div>
                </div>

                {/* Footer Buttons */}
                <div className="flex items-center gap-3 pt-3 border-t border-stone-100">
                  <button
                    type="button"
                    onClick={() => setIsSettingsModalOpen(false)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSavingSettings}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSavingSettings ? 'Saving...' : 'Save Settings'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
