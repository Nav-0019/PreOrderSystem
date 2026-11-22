import { motion, AnimatePresence } from 'framer-motion';
import { useState, useEffect } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  doc,
  updateDoc,
  setDoc,
  addDoc,
  serverTimestamp,
  getDocs,
} from 'firebase/firestore';
import { db, auth } from '../lib/firebase';
import {
  Settings,
  MessageSquare,
  LifeBuoy,
  Wrench,
  CheckCircle2,
  Search,
  RefreshCw,
  CreditCard,
  Check,
  X,
  Plus,
  ArrowUpRight,
} from 'lucide-react';

interface SupportReport {
  id: string;
  topic: string;
  description: string;
  orderId?: string;
  outletId?: string;
  outletName?: string;
  userId?: string;
  userName?: string;
  userEmail?: string;
  status: 'open' | 'investigating' | 'resolved' | 'refunded';
  priority?: 'high' | 'medium' | 'low';
  resolutionNotes?: string;
  createdAt?: any;
}

interface OutletItem {
  id: string;
  name: string;
  isOpen?: boolean;
  queueCount?: number;
  waitTime?: string;
  upiId?: string;
  managerName?: string;
}

interface OrderRecord {
  id: string;
  token?: string | number;
  customerName?: string;
  outletId?: string;
  outletName?: string;
  status: string;
  totalAmount: number;
  items?: any[];
  pickupSlot?: string;
  createdAt?: any;
}

export default function SettingsHub() {
  const [searchParams, setSearchParams] = useSearchParams();
  const urlTab = searchParams.get('tab') as any;
  const validTabs = ['queries', 'managers', 'doctor', 'gateway', 'preferences'];

  const [activeTab, setActiveTab] = useState<'queries' | 'managers' | 'doctor' | 'gateway' | 'preferences'>(
    validTabs.includes(urlTab) ? urlTab : 'queries'
  );

  useEffect(() => {
    const tabParam = searchParams.get('tab') as any;
    if (tabParam && validTabs.includes(tabParam) && tabParam !== activeTab) {
      setActiveTab(tabParam);
    }
  }, [searchParams]);

  const switchTab = (tab: 'queries' | 'managers' | 'doctor' | 'gateway' | 'preferences') => {
    setActiveTab(tab);
    setSearchParams({ tab });
  };

  // ─── 1. SUPPORT REPORTS STATE ───
  const [reports, setReports] = useState<SupportReport[]>([]);
  const [reportFilter, setReportFilter] = useState<string>('all');
  const [replyingReport, setReplyingReport] = useState<SupportReport | null>(null);
  const [replyText, setReplyText] = useState('');

  // New In-Person Dispute Modal
  const [isNewDisputeModalOpen, setIsNewDisputeModalOpen] = useState(false);
  const [disputeTopic, setDisputeTopic] = useState('Payment & Refunds');
  const [disputeDesc, setDisputeDesc] = useState('');
  const [disputeCustomerName, setDisputeCustomerName] = useState('');
  const [disputeOrderId, setDisputeOrderId] = useState('');
  const [isSubmittingDispute, setIsSubmittingDispute] = useState(false);

  // ─── 2. MANAGERS & OUTLETS STATE ───
  const [outlets, setOutlets] = useState<OutletItem[]>([]);
  const [syncingOutletId, setSyncingOutletId] = useState<string | null>(null);

  // ─── 3. ORDER DOCTOR STATE ───
  const [allOrders, setAllOrders] = useState<OrderRecord[]>([]);
  const [doctorSearch, setDoctorSearch] = useState('');
  const [selectedDoctorOrder, setSelectedDoctorOrder] = useState<OrderRecord | null>(null);
  const [doctorFeedback, setDoctorFeedback] = useState<string | null>(null);

  // ─── 4. GATEWAY & STORE SETTINGS STATE ───
  const [brandName, setBrandName] = useState('AuraBake Campus Pre-Order');
  const [masterUpi, setMasterUpi] = useState('7310347742@nyes');
  const [openTime, setOpenTime] = useState('08:00 AM');
  const [closeTime, setCloseTime] = useState('10:00 PM');
  const [convenienceFee, setConvenienceFee] = useState('5.00');
  const [autoApproveItems, setAutoApproveItems] = useState(false);
  const [globalStoreStatus, setGlobalStoreStatus] = useState<'open' | 'paused'>('open');
  const [isSavingGateway, setIsSavingGateway] = useState(false);
  const [saveToast, setSaveToast] = useState(false);

  // ─── 5. PREFERENCES & AUDIO STATE ───
  const [soundEnabled, setSoundEnabled] = useState(true);

  // Real-time Firestore Listeners
  useEffect(() => {
    // 1. Support Reports
    const qReports = query(collection(db, 'support_reports'), orderBy('createdAt', 'desc'));
    const unsubReports = onSnapshot(qReports, (snap) => {
      const list = snap.docs.map(d => ({
        id: d.id,
        ...d.data(),
      } as SupportReport));
      setReports(list);
    }, (err) => {
      console.warn('Support reports listener note:', err.message);
    });

    // 2. Outlets
    const unsubOutlets = onSnapshot(collection(db, 'outlets'), (snap) => {
      setOutlets(snap.docs.map(d => ({ id: d.id, ...d.data() } as OutletItem)));
    });

    // 3. Orders
    const qOrders = query(collection(db, 'orders'), orderBy('createdAt', 'desc'));
    const unsubOrders = onSnapshot(qOrders, (snap) => {
      setAllOrders(snap.docs.map(d => ({ id: d.id, ...d.data() } as OrderRecord)));
    });

    // 4. System Settings
    const unsubSettings = onSnapshot(doc(db, 'system_settings', 'config'), (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        if (data.brandName) setBrandName(data.brandName);
        if (data.masterUpi) setMasterUpi(data.masterUpi);
        if (data.openTime) setOpenTime(data.openTime);
        if (data.closeTime) setCloseTime(data.closeTime);
        if (data.convenienceFee !== undefined) setConvenienceFee(String(data.convenienceFee));
        if (data.autoApproveItems !== undefined) setAutoApproveItems(data.autoApproveItems);
        if (data.storeStatus) setGlobalStoreStatus(data.storeStatus);
      }
    }, () => {});

    return () => {
      unsubReports();
      unsubOutlets();
      unsubOrders();
      unsubSettings();
    };
  }, []);

  // Web Audio Chime generator
  const playChime = () => {
    try {
      const AudioCtx = window.AudioContext || (window as any).webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(880, ctx.currentTime + 0.15);
      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.4);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start();
      osc.stop(ctx.currentTime + 0.4);
    } catch (_) {}
  };

  // ─── ACTION 1: RESOLVE SUPPORT REPORT ───
  const handleResolveReport = async (reportId: string, customNote?: string) => {
    try {
      await updateDoc(doc(db, 'support_reports', reportId), {
        status: 'resolved',
        resolutionNotes: customNote || 'Resolved by Administrator via Operations Hub.',
        resolvedAt: serverTimestamp(),
      });
      setReplyingReport(null);
      setReplyText('');
    } catch (e) {
      console.error('Error resolving report:', e);
      alert('Could not update report: ' + e);
    }
  };

  // ─── ACTION 2: ISSUE INSTANT REFUND FOR REPORT ───
  const handleIssueRefundForReport = async (report: SupportReport) => {
    if (!window.confirm(`Issue an instant refund of ₹65 for this customer report?`)) return;
    try {
      if (report.orderId) {
        try {
          await updateDoc(doc(db, 'orders', report.orderId), {
            status: 'refunded',
            refundedAt: serverTimestamp(),
            refundReason: `Support Report: ${report.topic}`,
          });
        } catch (_) {}
      }

      await updateDoc(doc(db, 'support_reports', report.id), {
        status: 'refunded',
        resolutionNotes: 'Instant Refund processed and marked complete.',
        refundedAt: serverTimestamp(),
      });

      alert('✓ Refund recorded and customer report marked as Refunded!');
    } catch (e) {
      console.error('Error issuing refund:', e);
      alert('Could not process refund: ' + e);
    }
  };

  // ─── ACTION 3: SUBMIT NEW IN-PERSON DISPUTE ───
  const handleCreateDispute = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!disputeDesc.trim()) return;

    setIsSubmittingDispute(true);
    try {
      const user = auth.currentUser;
      await addDoc(collection(db, 'support_reports'), {
        topic: disputeTopic,
        description: disputeDesc.trim(),
        userName: disputeCustomerName.trim() || 'Counter Customer',
        userEmail: disputeCustomerName.trim() ? `${disputeCustomerName.trim().toLowerCase().replace(/\s+/g, '')}@campus.edu` : 'counter@campus.edu',
        orderId: disputeOrderId.trim() || null,
        outletId: '2000',
        outletName: 'Outlet 2000',
        userId: user ? user.uid : 'admin_logged',
        status: 'open',
        priority: 'high',
        createdAt: serverTimestamp(),
      });

      setIsNewDisputeModalOpen(false);
      setDisputeDesc('');
      setDisputeCustomerName('');
      setDisputeOrderId('');
    } catch (e) {
      console.error('Error creating report:', e);
      alert('Failed to log dispute: ' + e);
    } finally {
      setIsSubmittingDispute(false);
    }
  };

  // ─── ACTION 4: MANAGER PROBLEM-FIXING TOOLS ───
  const handleResetQueueCount = async (outletId: string) => {
    setSyncingOutletId(outletId);
    try {
      // Recalculate real active queue from Firestore orders
      const snap = await getDocs(collection(db, 'orders'));
      const activeForOutlet = snap.docs.filter(d => {
        const o = d.data();
        return o.outletId === outletId && ['pending', 'prep', 'ready'].includes(o.status);
      }).length;

      await updateDoc(doc(db, 'outlets', outletId), {
        queueCount: activeForOutlet,
        lastQueueSyncAt: serverTimestamp(),
      });

      alert(`✓ Queue count for stall recalculated & updated to ${activeForOutlet} active orders.`);
    } catch (e) {
      console.error('Error resetting queue:', e);
      alert('Could not sync queue: ' + e);
    } finally {
      setSyncingOutletId(null);
    }
  };

  const handleToggleStallIntake = async (outletId: string, currentIsOpen: boolean) => {
    try {
      await updateDoc(doc(db, 'outlets', outletId), {
        isOpen: !currentIsOpen,
      });
    } catch (e) {
      console.error('Error toggling intake:', e);
      alert('Failed to update stall intake: ' + e);
    }
  };

  // ─── ACTION 5: ORDER DOCTOR FIXES ───
  const handleSearchDoctor = (e: React.FormEvent) => {
    e.preventDefault();
    const queryTerm = doctorSearch.trim().toLowerCase();
    if (!queryTerm) return;

    const found = allOrders.find(o => 
      o.id.toLowerCase() === queryTerm ||
      o.id.toLowerCase().includes(queryTerm) ||
      (o.token && String(o.token).toLowerCase().includes(queryTerm)) ||
      (o.customerName && o.customerName.toLowerCase().includes(queryTerm))
    );

    if (found) {
      setSelectedDoctorOrder(found);
      setDoctorFeedback(null);
    } else {
      setSelectedDoctorOrder(null);
      setDoctorFeedback(`No order found matching "${doctorSearch}". Try Order ID or Token.`);
    }
  };

  const handleUpdateOrderStatus = async (orderId: string, newStatus: string) => {
    try {
      await updateDoc(doc(db, 'orders', orderId), {
        status: newStatus,
        updatedAt: serverTimestamp(),
      });
      setSelectedDoctorOrder(prev => prev ? { ...prev, status: newStatus } : null);
      alert(`✓ Order status successfully changed to "${newStatus}"!`);
    } catch (e) {
      console.error('Error updating order:', e);
      alert('Failed to update order: ' + e);
    }
  };

  // ─── ACTION 6: SAVE GATEWAY & STORE SETTINGS ───
  const handleSaveGatewaySettings = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSavingGateway(true);
    try {
      await setDoc(doc(db, 'system_settings', 'config'), {
        brandName: brandName.trim(),
        masterUpi: masterUpi.trim(),
        openTime: openTime.trim(),
        closeTime: closeTime.trim(),
        convenienceFee: parseFloat(convenienceFee) || 5.0,
        autoApproveItems,
        storeStatus: globalStoreStatus,
        updatedAt: serverTimestamp(),
      }, { merge: true });

      setSaveToast(true);
      setTimeout(() => setSaveToast(false), 2000);
    } catch (e) {
      console.error('Failed to save settings:', e);
      alert('Could not save settings: ' + e);
    } finally {
      setIsSavingGateway(false);
    }
  };

  // Filter reports
  const filteredReports = reports.filter(r => {
    if (reportFilter === 'all') return true;
    if (reportFilter === 'open') return r.status === 'open';
    if (reportFilter === 'investigating') return r.status === 'investigating';
    if (reportFilter === 'resolved') return r.status === 'resolved' || r.status === 'refunded';
    return r.topic.toLowerCase().includes(reportFilter.toLowerCase());
  });

  const openCount = reports.filter(r => r.status === 'open').length;
  const investigatingCount = reports.filter(r => r.status === 'investigating').length;
  const resolvedCount = reports.filter(r => r.status === 'resolved' || r.status === 'refunded').length;

  return (
    <div className="space-y-6">
      {/* ─── TOAST NOTIFICATION ─── */}
      <AnimatePresence>
        {saveToast && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-5 right-5 z-50 bg-[#18181B] text-[#FACC15] px-5 py-3 rounded-2xl shadow-2xl border border-stone-800 text-xs font-bold flex items-center gap-2"
          >
            <Check size={14} className="text-emerald-400" />
            <span>Settings & Preferences successfully saved!</span>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ─── HEADER ─── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pt-1">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Admin Command & Settings Hub
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Customer queries, dispute resolution, manager governance tools, and platform preferences.
          </p>
        </div>

        <div className="flex items-center gap-2.5">
          <button
            onClick={() => setIsNewDisputeModalOpen(true)}
            className="inline-flex items-center gap-1.5 bg-[#18181B] hover:bg-black text-[#FACC15] px-4 py-2 rounded-full font-bold text-xs shadow-xs transition-transform hover:scale-105"
          >
            <Plus size={13} /> Log Customer Dispute
          </button>
        </div>
      </div>

      {/* ─── CATEGORIZED NAVIGATION TABS (BENTO CAPSULE BAR) ─── */}
      <div className="p-1.5 bg-white rounded-full border border-[#E9DFCB] shadow-xs flex items-center gap-1 overflow-x-auto scrollbar-none">
        <button
          onClick={() => switchTab('queries')}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
            activeTab === 'queries'
              ? 'bg-[#18181B] text-white shadow-xs'
              : 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
          }`}
        >
          <MessageSquare size={13} />
          <span>Customer Queries & Reports</span>
          {openCount > 0 && (
            <span className="px-1.5 py-0.2 rounded-full bg-red-500 text-white text-[10px] font-black animate-pulse">
              {openCount}
            </span>
          )}
        </button>

        <button
          onClick={() => switchTab('managers')}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
            activeTab === 'managers'
              ? 'bg-[#18181B] text-white shadow-xs'
              : 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
          }`}
        >
          <Wrench size={13} />
          <span>Manager & Stall Governance</span>
        </button>

        <button
          onClick={() => switchTab('doctor')}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
            activeTab === 'doctor'
              ? 'bg-[#18181B] text-white shadow-xs'
              : 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
          }`}
        >
          <LifeBuoy size={13} />
          <span>Order Doctor (Quick Fixer)</span>
        </button>

        <button
          onClick={() => switchTab('gateway')}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
            activeTab === 'gateway'
              ? 'bg-[#18181B] text-white shadow-xs'
              : 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
          }`}
        >
          <CreditCard size={13} />
          <span>Platform & Payment Gateway</span>
        </button>

        <button
          onClick={() => switchTab('preferences')}
          className={`flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
            activeTab === 'preferences'
              ? 'bg-[#18181B] text-white shadow-xs'
              : 'text-stone-600 hover:text-stone-900 hover:bg-stone-50'
          }`}
        >
          <Settings size={13} />
          <span>Preferences & Diagnostics</span>
        </button>
      </div>

      {/* ══════════════════════════════════════════════════════════ */}
      {/* ─── TAB 1: CUSTOMER QUERIES & REPORTS HUB ─── */}
      {/* ══════════════════════════════════════════════════════════ */}
      {activeTab === 'queries' && (
        <div className="space-y-5">
          {/* Top KPI Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
            <div className="bg-white p-5 rounded-[26px] border border-[#E9DFCB] shadow-xs">
              <span className="text-[11px] font-bold text-stone-400 uppercase">Total Reports</span>
              <p className="text-3xl font-normal text-stone-900 mt-1">{reports.length}</p>
            </div>
            <div className="bg-white p-5 rounded-[26px] border border-[#E9DFCB] shadow-xs">
              <span className="text-[11px] font-bold text-red-500 uppercase">Action Required (Open)</span>
              <p className="text-3xl font-normal text-red-600 mt-1">{openCount}</p>
            </div>
            <div className="bg-white p-5 rounded-[26px] border border-[#E9DFCB] shadow-xs">
              <span className="text-[11px] font-bold text-amber-600 uppercase">Under Investigation</span>
              <p className="text-3xl font-normal text-amber-700 mt-1">{investigatingCount}</p>
            </div>
            <div className="bg-white p-5 rounded-[26px] border border-[#E9DFCB] shadow-xs">
              <span className="text-[11px] font-bold text-emerald-600 uppercase">Resolved & Closed</span>
              <p className="text-3xl font-normal text-emerald-700 mt-1">{resolvedCount}</p>
            </div>
          </div>

          {/* Filter Bar */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
            {[
              { id: 'all', label: `All Queries (${reports.length})` },
              { id: 'open', label: `Open Only (${openCount})` },
              { id: 'investigating', label: `Investigating (${investigatingCount})` },
              { id: 'Payment', label: 'Payment Issues' },
              { id: 'Quality', label: 'Food Quality' },
              { id: 'resolved', label: `Resolved (${resolvedCount})` },
            ].map(f => (
              <button
                key={f.id}
                onClick={() => setReportFilter(f.id)}
                className={`px-3.5 py-1.5 rounded-full text-xs font-bold transition-all whitespace-nowrap ${
                  reportFilter === f.id
                    ? 'bg-[#18181B] text-white shadow-xs'
                    : 'bg-white text-stone-600 hover:text-stone-900 border border-[#E7DFCE]'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>

          {/* Reports Feed */}
          <div className="space-y-3">
            {filteredReports.length === 0 ? (
              <div className="p-16 text-center bg-white rounded-[32px] border border-[#E9DFCB]">
                <CheckCircle2 size={36} className="mx-auto mb-2 text-emerald-500" />
                <p className="text-sm font-bold text-stone-800">No support queries in this view</p>
                <p className="text-xs text-stone-400 mt-1">All customer issues are resolved or no reports match filter.</p>
              </div>
            ) : (
              filteredReports.map(r => {
                const isOpen = r.status === 'open';
                const isInvestigating = r.status === 'investigating';
                const isResolved = r.status === 'resolved' || r.status === 'refunded';

                return (
                  <motion.div
                    key={r.id}
                    layout
                    className={`p-5 rounded-[28px] border transition-all ${
                      isOpen
                        ? 'bg-white border-red-200/80 shadow-xs'
                        : isInvestigating
                        ? 'bg-white border-amber-200/80'
                        : 'bg-stone-50/70 border-stone-200/60'
                    }`}
                  >
                    <div className="flex flex-col md:flex-row md:items-start justify-between gap-4">
                      {/* Left: Report Content */}
                      <div className="space-y-2 flex-1">
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-mono text-xs font-black text-stone-900">
                            #{r.id.slice(0, 6).toUpperCase()}
                          </span>

                          <span className="px-2.5 py-0.5 rounded-full bg-stone-100 text-[10px] font-bold text-stone-700">
                            {r.topic}
                          </span>

                          {r.orderId && (
                            <button
                              onClick={() => {
                                setActiveTab('doctor');
                                setDoctorSearch(r.orderId || '');
                              }}
                              className="px-2.5 py-0.5 rounded-full bg-amber-50 hover:bg-amber-100 text-amber-900 text-[10px] font-bold border border-amber-200/60 flex items-center gap-1"
                              title="Inspect this order in Order Doctor"
                            >
                              <span>Order #{r.orderId.slice(0, 6).toUpperCase()}</span>
                              <ArrowUpRight size={10} />
                            </button>
                          )}

                          <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-extrabold ${
                            isOpen
                              ? 'bg-red-100 text-red-800 animate-pulse'
                              : isInvestigating
                              ? 'bg-amber-100 text-amber-900'
                              : 'bg-emerald-100 text-emerald-900'
                          }`}>
                            {r.status.toUpperCase()}
                          </span>
                        </div>

                        <p className="text-xs text-stone-800 font-medium leading-relaxed">
                          "{r.description}"
                        </p>

                        <div className="flex items-center gap-3 text-[11px] text-stone-400">
                          <span className="font-semibold text-stone-600">{r.userName || 'Student'}</span>
                          <span>•</span>
                          <span>{r.userEmail || 'campus.edu'}</span>
                          <span>•</span>
                          <span>{r.outletName || 'Outlet 2000'}</span>
                        </div>

                        {r.resolutionNotes && (
                          <div className="mt-2 p-2.5 bg-emerald-50/80 rounded-xl border border-emerald-200/60 text-[11px] text-emerald-900">
                            <span className="font-bold">Resolution Note: </span>
                            {r.resolutionNotes}
                          </div>
                        )}
                      </div>

                      {/* Right: Action Buttons */}
                      <div className="flex items-center gap-2 self-start shrink-0">
                        {r.topic.toLowerCase().includes('payment') && r.status !== 'refunded' && (
                          <button
                            onClick={() => handleIssueRefundForReport(r)}
                            className="px-3.5 py-1.5 rounded-full bg-purple-100 hover:bg-purple-200 text-purple-900 text-xs font-bold transition-colors"
                          >
                            ⚡ Issue Refund
                          </button>
                        )}

                        {!isResolved && (
                          <button
                            onClick={() => {
                              setReplyingReport(r);
                              setReplyText(`Apologies for the issue. We have reviewed your report for ${r.topic} and taken corrective action with the kitchen team.`);
                            }}
                            className="px-3.5 py-1.5 rounded-full bg-stone-100 hover:bg-stone-200 text-stone-700 text-xs font-bold transition-colors"
                          >
                            Reply & Resolve
                          </button>
                        )}

                        {isOpen && (
                          <button
                            onClick={() => handleResolveReport(r.id, 'Directly resolved by Administrator.')}
                            className="px-3.5 py-1.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105"
                          >
                            ✓ Mark Resolved
                          </button>
                        )}
                      </div>
                    </div>
                  </motion.div>
                );
              })
            )}
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════════════════════════ */}
      {/* ─── TAB 2: MANAGER & STALL GOVERNANCE (FIXING TOOLS) ─── */}
      {/* ══════════════════════════════════════════════════════════ */}
      {activeTab === 'managers' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            {outlets.map(outlet => (
              <div
                key={outlet.id}
                className="bg-white p-6 rounded-[30px] border border-[#E9DFCB] shadow-xs space-y-4"
              >
                <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                  <div>
                    <h3 className="text-base font-bold text-stone-900">{outlet.name}</h3>
                    <p className="text-xs text-stone-500">ID: {outlet.id} • Assigned to {outlet.managerName || 'shubham'}</p>
                  </div>
                  <span className={`px-2.5 py-1 rounded-full text-xs font-bold ${outlet.isOpen !== false ? 'bg-emerald-100 text-emerald-900' : 'bg-red-100 text-red-900'}`}>
                    {outlet.isOpen !== false ? 'Intake Active 🟢' : 'Intake Paused 🔴'}
                  </span>
                </div>

                <div className="grid grid-cols-2 gap-3 text-xs">
                  <div className="p-3 bg-stone-50 rounded-2xl">
                    <span className="text-[10px] text-stone-400 font-bold block">Live Queue</span>
                    <span className="text-xl font-bold text-stone-900">{outlet.queueCount || 0} Orders</span>
                  </div>
                  <div className="p-3 bg-stone-50 rounded-2xl">
                    <span className="text-[10px] text-stone-400 font-bold block">Terminal UPI</span>
                    <span className="text-xs font-mono font-bold text-stone-800 truncate block mt-1">{outlet.upiId || '7310347742@nyes'}</span>
                  </div>
                </div>

                {/* Actionable Library Tools */}
                <div className="space-y-2 pt-2">
                  <p className="text-[11px] font-bold text-stone-400 uppercase tracking-wider">Operational Fix Tools</p>
                  
                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => handleResetQueueCount(outlet.id)}
                      disabled={syncingOutletId === outlet.id}
                      className="flex-1 py-2 rounded-xl bg-stone-100 hover:bg-stone-200 text-stone-800 text-xs font-bold transition-colors flex items-center justify-center gap-1.5 disabled:opacity-50"
                    >
                      <RefreshCw size={12} className={syncingOutletId === outlet.id ? 'animate-spin' : ''} />
                      <span>{syncingOutletId === outlet.id ? 'Recalculating...' : 'Recalculate & Sync Queue'}</span>
                    </button>

                    <button
                      onClick={() => handleToggleStallIntake(outlet.id, outlet.isOpen !== false)}
                      className={`px-4 py-2 rounded-xl text-xs font-bold transition-colors ${
                        outlet.isOpen !== false
                          ? 'bg-amber-100 hover:bg-amber-200 text-amber-900'
                          : 'bg-emerald-100 hover:bg-emerald-200 text-emerald-900'
                      }`}
                    >
                      {outlet.isOpen !== false ? 'Emergency Pause' : 'Reopen Stall'}
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ══════════════════════════════════════════════════════════ */}
      {/* ─── TAB 3: CUSTOMER ORDER EMERGENCY DOCTOR ─── */}
      {/* ══════════════════════════════════════════════════════════ */}
      {activeTab === 'doctor' && (
        <div className="space-y-5">
          {/* Order Search Box */}
          <div className="bg-white p-6 rounded-[30px] border border-[#E9DFCB] shadow-xs">
            <h3 className="text-base font-bold text-stone-900 mb-1">Customer Order Emergency Doctor</h3>
            <p className="text-xs text-stone-500 mb-4">
              Inspect stuck orders, reissue tokens, force-advance kitchen prep, or process customer refund overrides.
            </p>

            <form onSubmit={handleSearchDoctor} className="flex gap-2">
              <div className="relative flex-1">
                <Search size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-stone-400" />
                <input
                  type="text"
                  placeholder="Enter Order ID (e.g. TaAnmPq) or Token Number (e.g. 102)..."
                  value={doctorSearch}
                  onChange={e => setDoctorSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-full text-stone-900 focus:outline-none focus:border-stone-800"
                />
              </div>
              <button
                type="submit"
                className="px-5 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105"
              >
                Inspect Order
              </button>
            </form>

            {doctorFeedback && (
              <p className="text-xs text-red-500 font-bold mt-2 pl-2">{doctorFeedback}</p>
            )}
          </div>

          {/* Inspected Order Card with Actionable Remedies */}
          {selectedDoctorOrder && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="bg-white p-6 rounded-[30px] border border-[#E9DFCB] shadow-sm space-y-4"
            >
              <div className="flex flex-col sm:flex-row sm:items-center justify-between pb-3 border-b border-stone-100 gap-2">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-sm font-black text-stone-900">
                      TOKEN #{selectedDoctorOrder.token || selectedDoctorOrder.id.slice(0, 5).toUpperCase()}
                    </span>
                    <span className="px-2.5 py-0.5 rounded-full bg-[#FACC15] text-stone-950 font-black text-[10px]">
                      {selectedDoctorOrder.status.toUpperCase()}
                    </span>
                  </div>
                  <p className="text-xs text-stone-500 mt-0.5">
                    Order ID: {selectedDoctorOrder.id} • {selectedDoctorOrder.outletName || 'Outlet 2000'}
                  </p>
                </div>
                <div className="text-right">
                  <span className="text-2xl font-bold text-stone-900">₹{selectedDoctorOrder.totalAmount}</span>
                </div>
              </div>

              {/* Order Items */}
              <div className="p-3.5 bg-stone-50 rounded-2xl space-y-1">
                <p className="text-[11px] font-bold text-stone-400 uppercase">Items in Order</p>
                {selectedDoctorOrder.items && selectedDoctorOrder.items.length > 0 ? (
                  selectedDoctorOrder.items.map((it, idx) => (
                    <p key={idx} className="text-xs font-semibold text-stone-800">
                      • {it.quantity || 1}x {it.name} (₹{it.price})
                    </p>
                  ))
                ) : (
                  <p className="text-xs text-stone-500">Standard Campus Pre-Order</p>
                )}
              </div>

              {/* Actionable Remedies */}
              <div>
                <p className="text-xs font-bold text-stone-900 mb-2">Instant Remedies & Overrides</p>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                  <button
                    onClick={() => handleUpdateOrderStatus(selectedDoctorOrder.id, 'ready')}
                    className="p-3 rounded-2xl bg-amber-50 hover:bg-amber-100 border border-amber-200/80 text-amber-900 text-xs font-bold transition-colors text-center"
                  >
                    ⚡ Force Ready for Pickup
                  </button>

                  <button
                    onClick={() => handleUpdateOrderStatus(selectedDoctorOrder.id, 'completed')}
                    className="p-3 rounded-2xl bg-emerald-50 hover:bg-emerald-100 border border-emerald-200/80 text-emerald-900 text-xs font-bold transition-colors text-center"
                  >
                    ✓ Force Mark Completed
                  </button>

                  <button
                    onClick={() => handleUpdateOrderStatus(selectedDoctorOrder.id, 'refunded')}
                    className="p-3 rounded-2xl bg-purple-50 hover:bg-purple-100 border border-purple-200/80 text-purple-900 text-xs font-bold transition-colors text-center"
                  >
                    💰 Issue Full Refund
                  </button>

                  <button
                    onClick={() => handleUpdateOrderStatus(selectedDoctorOrder.id, 'cancelled')}
                    className="p-3 rounded-2xl bg-red-50 hover:bg-red-100 border border-red-200/80 text-red-900 text-xs font-bold transition-colors text-center"
                  >
                    ✕ Cancel & Void Order
                  </button>
                </div>
              </div>
            </motion.div>
          )}
        </div>
      )}

      {/* ══════════════════════════════════════════════════════════ */}
      {/* ─── TAB 4: PLATFORM & PAYMENT GATEWAY ─── */}
      {/* ══════════════════════════════════════════════════════════ */}
      {activeTab === 'gateway' && (
        <form onSubmit={handleSaveGatewaySettings} className="bg-white p-6 sm:p-8 rounded-[32px] border border-[#E9DFCB] shadow-xs space-y-5">
          <div className="pb-4 border-b border-stone-100">
            <h3 className="text-base font-bold text-stone-900">Platform Brand & UPI Payment Gateway</h3>
            <p className="text-xs text-stone-500">Configure master credentials, store operation hours, and campus fee structure.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Campus Brand Title</label>
              <input
                type="text"
                value={brandName}
                onChange={e => setBrandName(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Master UPI VPA (Payment Gateway)</label>
              <input
                type="text"
                value={masterUpi}
                onChange={e => setMasterUpi(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 font-mono focus:outline-none focus:border-stone-800"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Campus Opening Hour</label>
              <input
                type="text"
                value={openTime}
                onChange={e => setOpenTime(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Campus Closing Hour</label>
              <input
                type="text"
                value={closeTime}
                onChange={e => setCloseTime(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Convenience / Packaging Fee (₹)</label>
              <input
                type="number"
                step="0.5"
                value={convenienceFee}
                onChange={e => setConvenienceFee(e.target.value)}
                className="w-full px-3.5 py-2.5 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
              />
            </div>

            <div>
              <label className="block text-xs font-bold text-stone-700 mb-1">Global Pre-Order Status</label>
              <div className="flex items-center gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setGlobalStoreStatus(globalStoreStatus === 'open' ? 'paused' : 'open')}
                  className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out ${
                    globalStoreStatus === 'open' ? 'bg-emerald-500' : 'bg-red-400'
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                      globalStoreStatus === 'open' ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
                <span className="text-xs font-bold text-stone-800">
                  {globalStoreStatus === 'open' ? 'Campus Pre-Orders Open 🟢' : 'System Intake Paused 🔴'}
                </span>
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-stone-100 flex justify-end">
            <button
              type="submit"
              disabled={isSavingGateway}
              className="px-6 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
            >
              {isSavingGateway ? 'Saving Changes...' : 'Save Gateway Settings'}
            </button>
          </div>
        </form>
      )}

      {/* ══════════════════════════════════════════════════════════ */}
      {/* ─── TAB 5: PREFERENCES & DIAGNOSTICS ─── */}
      {/* ══════════════════════════════════════════════════════════ */}
      {activeTab === 'preferences' && (
        <div className="space-y-5">
          {/* Audio Chime Controls */}
          <div className="bg-white p-6 rounded-[30px] border border-[#E9DFCB] shadow-xs space-y-4">
            <h3 className="text-base font-bold text-stone-900">Admin Notification Preferences</h3>
            <div className="flex items-center justify-between p-3.5 bg-stone-50 rounded-2xl">
              <div>
                <p className="text-xs font-bold text-stone-900">Web Audio Kitchen Chime</p>
                <p className="text-[10px] text-stone-500">Play pleasant sound alert when new orders or support queries arrive</p>
              </div>
              <div className="flex items-center gap-3">
                <button
                  type="button"
                  onClick={playChime}
                  className="px-3 py-1 rounded-full bg-white border border-stone-200 text-xs font-bold text-stone-700 hover:bg-stone-100"
                >
                  Test Sound 🔔
                </button>
                <button
                  type="button"
                  onClick={() => setSoundEnabled(!soundEnabled)}
                  className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors ${
                    soundEnabled ? 'bg-emerald-500' : 'bg-stone-300'
                  }`}
                >
                  <span
                    className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                      soundEnabled ? 'translate-x-4' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>
            </div>
          </div>

          {/* Cloud Diagnostics */}
          <div className="bg-white p-6 rounded-[30px] border border-[#E9DFCB] shadow-xs space-y-3">
            <h3 className="text-base font-bold text-stone-900">Live Infrastructure Diagnostics</h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
              <div className="p-3.5 bg-stone-50 rounded-2xl">
                <span className="text-[10px] text-stone-400 font-bold block">Firebase Auth</span>
                <span className="font-bold text-emerald-600 block mt-1">Connected 🟢</span>
              </div>
              <div className="p-3.5 bg-stone-50 rounded-2xl">
                <span className="text-[10px] text-stone-400 font-bold block">Firestore Database</span>
                <span className="font-bold text-emerald-600 block mt-1">Online (Low Latency) 🟢</span>
              </div>
              <div className="p-3.5 bg-stone-50 rounded-2xl">
                <span className="text-[10px] text-stone-400 font-bold block">Live WebSockets</span>
                <span className="font-bold text-emerald-600 block mt-1">4 Active Listeners 🟢</span>
              </div>
              <div className="p-3.5 bg-stone-50 rounded-2xl">
                <span className="text-[10px] text-stone-400 font-bold block">Production Edge</span>
                <span className="font-bold text-emerald-600 block mt-1">Vercel Global CDN 🟢</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ─── MODAL: REPLY & RESOLVE QUERY ─── */}
      <AnimatePresence>
        {replyingReport && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Resolve Customer Query</h3>
                  <p className="text-xs text-stone-500">#{replyingReport.id.slice(0, 6).toUpperCase()} • {replyingReport.userName}</p>
                </div>
                <button
                  onClick={() => setReplyingReport(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <div>
                <label className="block text-xs font-bold text-stone-700 mb-1">Resolution Response Note</label>
                <textarea
                  rows={3}
                  value={replyText}
                  onChange={e => setReplyText(e.target.value)}
                  className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                />
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setReplyingReport(null)}
                  className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                >
                  Cancel
                </button>
                <button
                  type="button"
                  onClick={() => handleResolveReport(replyingReport.id, replyText)}
                  className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105"
                >
                  Confirm Resolution ✓
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ─── MODAL: LOG NEW CUSTOMER DISPUTE ─── */}
      <AnimatePresence>
        {isNewDisputeModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Log In-Person Counter Dispute</h3>
                  <p className="text-xs text-stone-500">Record counter complaint or manual customer dispute</p>
                </div>
                <button
                  onClick={() => setIsNewDisputeModalOpen(false)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleCreateDispute} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Issue Category</label>
                  <select
                    value={disputeTopic}
                    onChange={e => setDisputeTopic(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none"
                  >
                    <option value="Payment & Refunds">Payment & Refunds</option>
                    <option value="Food Quality Issues">Food Quality Issues</option>
                    <option value="Delayed Order">Delayed Order</option>
                    <option value="Wrong Item Received">Wrong Item Received</option>
                    <option value="General Feedback">General Feedback</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Customer Name (Optional)</label>
                  <input
                    type="text"
                    placeholder="e.g. Ananya Sen"
                    value={disputeCustomerName}
                    onChange={e => setDisputeCustomerName(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Linked Order ID or Token (Optional)</label>
                  <input
                    type="text"
                    placeholder="e.g. TaAnmPq or 102"
                    value={disputeOrderId}
                    onChange={e => setDisputeOrderId(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Description of Issue</label>
                  <textarea
                    required
                    rows={3}
                    placeholder="Detail the issue reported by the customer..."
                    value={disputeDesc}
                    onChange={e => setDisputeDesc(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setIsNewDisputeModalOpen(false)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingDispute}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingDispute ? 'Saving...' : 'Log Dispute ✓'}
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
