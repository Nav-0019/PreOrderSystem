import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowUpRight,
  Play,
  Pause,
  RotateCcw,
  Clock,
  Store,
  ShoppingBag,
  CheckCircle2,
  ChevronDown,
  ChevronUp,
  Plus,
  X,
  Edit2,
  Copy,
  Check,
  Smartphone,
  Printer,
  Volume2,
  Zap,
  Coffee,
  UtensilsCrossed,
  Sparkles,
} from 'lucide-react';
import { useEffect, useState, useRef } from 'react';
import { Link } from 'react-router-dom';
import {
  collection,
  onSnapshot,
  query,
  orderBy,
  limit,
  doc,
  updateDoc,
  setDoc,
  addDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../lib/firebase';

interface ApprovalTicket {
  id: string;
  type?: string;
  status: 'pending' | 'approved' | 'rejected';
  outletId: string;
  outletName?: string;
  submittedByName?: string;
  sourceDoc?: 'menu_items' | 'approval_tickets';
  itemData: {
    name: string;
    description?: string;
    price: number;
    category?: string;
    prepTime?: number;
    photoBase64?: string;
  };
}

interface OutletItem {
  id: string;
  name: string;
  isOpen?: boolean;
  queueCount?: number;
  waitTime?: string;
  upiId?: string;
}

export default function Overview() {
  const [totalOrders, setTotalOrders] = useState(0);
  const [activeQueue, setActiveQueue] = useState(0);
  const [revenue, setRevenue] = useState(0);
  const [outlets, setOutlets] = useState<OutletItem[]>([]);
  const [avgWaitMinutes, setAvgWaitMinutes] = useState(4);
  const [pendingTickets, setPendingTickets] = useState<ApprovalTicket[]>([]);
  
  // Rush hour mode toggle
  const [isRushMode, setIsRushMode] = useState(false);

  // Time Tracker Dial State
  const [isTimerPlaying, setIsTimerPlaying] = useState(true);
  const [timerInitialSeconds, setTimerInitialSeconds] = useState(155); // 02:35
  const [timerSeconds, setTimerSeconds] = useState(155);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Accordion state for left column
  const [expandedSection, setExpandedSection] = useState<string | null>('outlets');

  // Modals state
  const [isAddOutletModalOpen, setIsAddOutletModalOpen] = useState(false);
  const [newOutletName, setNewOutletName] = useState('');
  const [newOutletId, setNewOutletId] = useState('');
  const [newOutletUpi, setNewOutletUpi] = useState('aurabake@upi');
  const [newOutletWait, setNewOutletWait] = useState('5-8 mins');
  const [isSubmittingOutlet, setIsSubmittingOutlet] = useState(false);

  // Edit UPI Modal state
  const [editingUpiOutlet, setEditingUpiOutlet] = useState<OutletItem | null>(null);
  const [editUpiValue, setEditUpiValue] = useState('');
  const [copiedUpiId, setCopiedUpiId] = useState<string | null>(null);

  // Reject Ticket Modal state
  const [rejectingTicket, setRejectingTicket] = useState<ApprovalTicket | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  // Selected Day in Dispatch Schedule
  const [selectedDayIndex, setSelectedDayIndex] = useState(0);

  // Pickup slot capacities
  const [slotCapacities, setSlotCapacities] = useState({
    slot1: 20,
    slot2: 25,
    slot3: 20,
  });

  // ─── FIRESTORE LISTENERS ────────────────────────────────────
  useEffect(() => {
    // 1. Orders listener
    const qOrders = query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(150));
    const unsubOrders = onSnapshot(qOrders, (snap) => {
      const orders = snap.docs.map(d => d.data());
      setTotalOrders(orders.length);
      const active = orders.filter(o => ['pending', 'prep', 'ready'].includes(o.status)).length;
      setActiveQueue(active);
      setAvgWaitMinutes(Math.max(2, active * 2));
      const totalRev = orders.filter(o => o.status !== 'cancelled').reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);
      setRevenue(totalRev);
    });

    // 2. Outlets listener
    const unsubOutlets = onSnapshot(collection(db, 'outlets'), (snap) => {
      setOutlets(snap.docs.map(d => ({ id: d.id, ...d.data() } as OutletItem)));
    });

    // 3. Approval Tickets listener (combining menu_items and approval_tickets)
    let rawMenuItems: ApprovalTicket[] = [];
    let rawApprovalTickets: ApprovalTicket[] = [];

    const syncPending = () => {
      const map = new Map<string, ApprovalTicket>();
      rawMenuItems.forEach(t => map.set(t.id, t));
      rawApprovalTickets.forEach(t => map.set(t.id, t));
      setPendingTickets(Array.from(map.values()).slice(0, 10));
    };

    const unsubMenu = onSnapshot(collection(db, 'menu_items'), (snap) => {
      rawMenuItems = snap.docs
        .filter(d => {
          const data = d.data();
          return data.approvalStatus === 'pending' || (data.isApproved === false && data.approvalStatus !== 'rejected');
        })
        .map(d => {
          const data = d.data();
          return {
            id: d.id,
            type: 'MENU_ITEM_ADD',
            status: 'pending',
            outletId: data.outletId || '2000',
            outletName: data.outletName || `Outlet ${data.outletId || '2000'}`,
            submittedByName: data.submittedByName || 'Outlet Manager',
            sourceDoc: 'menu_items',
            itemData: {
              name: data.name || 'Untitled Item',
              description: data.description || '',
              price: Number(data.price || 0),
              category: data.category || 'Snacks',
              prepTime: Number(data.prepTime || 5),
              photoBase64: data.photoBase64,
            },
          } as ApprovalTicket;
        });
      syncPending();
    }, () => {});

    let unsubTickets: (() => void) | null = null;
    try {
      const qTickets = query(collection(db, 'approval_tickets'), orderBy('createdAt', 'desc'), limit(15));
      unsubTickets = onSnapshot(qTickets, (snap) => {
        rawApprovalTickets = snap.docs
          .filter(d => d.data().status === 'pending')
          .map(d => ({
            id: d.id,
            sourceDoc: 'approval_tickets',
            ...d.data(),
          } as ApprovalTicket));
        syncPending();
      }, () => {});
    } catch (_) {}

    return () => {
      unsubOrders();
      unsubOutlets();
      unsubMenu();
      if (unsubTickets) unsubTickets();
    };
  }, []);

  // ─── WORKING TIME TRACKER DIAL (TICKING SECONDS) ────────────
  useEffect(() => {
    if (isTimerPlaying) {
      timerRef.current = setInterval(() => {
        setTimerSeconds((prev) => (prev > 0 ? prev - 1 : timerInitialSeconds));
      }, 1000);
    } else {
      if (timerRef.current) clearInterval(timerRef.current);
    }

    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [isTimerPlaying, timerInitialSeconds]);

  const formatTimer = (secs: number) => {
    const mins = Math.floor(secs / 60);
    const remainder = secs % 60;
    return `${mins.toString().padStart(2, '0')}:${remainder.toString().padStart(2, '0')}`;
  };

  const setTimerPreset = (seconds: number) => {
    setTimerInitialSeconds(seconds);
    setTimerSeconds(seconds);
    setIsTimerPlaying(true);
  };

  // ─── OUTLET STATUS TOGGLE (OPEN / CLOSED) ───────────────────
  const toggleOutletStatus = async (outletId: string, currentIsOpen: boolean) => {
    try {
      await updateDoc(doc(db, 'outlets', outletId), {
        isOpen: !currentIsOpen,
      });
    } catch (e) {
      console.error('Error toggling outlet status:', e);
      alert('Could not update outlet status: ' + e);
    }
  };

  // ─── ADD NEW OUTLET / STALL ─────────────────────────────────
  const handleAddOutlet = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newOutletName.trim()) return;

    setIsSubmittingOutlet(true);
    try {
      const generatedId = newOutletId.trim() || newOutletName.toLowerCase().replace(/[^a-z0-9]/g, '_');
      await setDoc(doc(db, 'outlets', generatedId), {
        name: newOutletName.trim(),
        isOpen: true,
        queueCount: 0,
        waitTime: newOutletWait.trim() || '5 mins',
        upiId: newOutletUpi.trim() || 'aurabake@upi',
        createdAt: serverTimestamp(),
      });

      setIsAddOutletModalOpen(false);
      setNewOutletName('');
      setNewOutletId('');
    } catch (e) {
      console.error('Error adding outlet:', e);
      alert('Failed to add stall: ' + e);
    } finally {
      setIsSubmittingOutlet(false);
    }
  };

  // ─── SAVE EDITED UPI ID ─────────────────────────────────────
  const handleSaveUpi = async () => {
    if (!editingUpiOutlet) return;
    try {
      await updateDoc(doc(db, 'outlets', editingUpiOutlet.id), {
        upiId: editUpiValue.trim(),
      });
      setEditingUpiOutlet(null);
    } catch (e) {
      console.error('Error updating UPI ID:', e);
      alert('Failed to update UPI ID: ' + e);
    }
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedUpiId(id);
    setTimeout(() => setCopiedUpiId(null), 2000);
  };

  // ─── QUICK APPROVE TICKET ───────────────────────────────────
  const handleQuickApprove = async (ticket: ApprovalTicket) => {
    try {
      if (ticket.sourceDoc === 'menu_items') {
        await updateDoc(doc(db, 'menu_items', ticket.id), {
          approvalStatus: 'approved',
          isApproved: true,
          isAvailable: true,
          reviewedAt: serverTimestamp(),
        });
      } else {
        await addDoc(collection(db, 'menu_items'), {
          name: ticket.itemData.name,
          price: Number(ticket.itemData.price),
          category: ticket.itemData.category || 'Snacks',
          prepTime: Number(ticket.itemData.prepTime || 5),
          isAvailable: true,
          isApproved: true,
          approvalStatus: 'approved',
          outletId: ticket.outletId,
          createdAt: serverTimestamp(),
        });

        try {
          await updateDoc(doc(db, 'approval_tickets', ticket.id), {
            status: 'approved',
            reviewedAt: serverTimestamp(),
          });
        } catch (_) {}
      }
    } catch (e) {
      console.error('Error approving ticket:', e);
    }
  };

  // ─── QUICK REJECT TICKET ────────────────────────────────────
  const handleConfirmReject = async () => {
    if (!rejectingTicket) return;
    try {
      const reason = rejectionReason.trim() || 'Menu criteria not met';
      if (rejectingTicket.sourceDoc === 'menu_items') {
        await updateDoc(doc(db, 'menu_items', rejectingTicket.id), {
          approvalStatus: 'rejected',
          isApproved: false,
          isAvailable: false,
          rejectionReason: reason,
          reviewedAt: serverTimestamp(),
        });
      } else {
        try {
          await updateDoc(doc(db, 'approval_tickets', rejectingTicket.id), {
            status: 'rejected',
            rejectionReason: reason,
            reviewedAt: serverTimestamp(),
          });
        } catch (_) {}
      }
      setRejectingTicket(null);
      setRejectionReason('');
    } catch (e) {
      console.error('Error rejecting ticket:', e);
      alert('Error rejecting ticket: ' + e);
    }
  };

  // ─── APPROVE ALL PENDING TICKETS ────────────────────────────
  const handleApproveAll = async () => {
    if (pendingTickets.length === 0) return;
    if (!window.confirm(`Approve and publish all ${pendingTickets.length} pending items to the live menu?`)) return;

    for (const ticket of pendingTickets) {
      await handleQuickApprove(ticket);
    }
  };

  const getCategoryIcon = (category?: string) => {
    const c = (category || '').toLowerCase();
    if (c.includes('beverage') || c.includes('coffee') || c.includes('juice') || c.includes('tea')) {
      return <Coffee size={14} className="text-amber-400" />;
    }
    if (c.includes('snack') || c.includes('puff') || c.includes('samosa')) {
      return <UtensilsCrossed size={14} className="text-[#FACC15]" />;
    }
    return <Sparkles size={14} className="text-emerald-400" />;
  };

  // Days list for dispatch calendar
  const scheduleDays = [
    { label: 'Mon 22', date: '2026-11-22' },
    { label: 'Tue 23', date: '2026-11-23' },
    { label: 'Wed 24', date: '2026-11-24' },
    { label: 'Thu 25', date: '2026-11-25' },
    { label: 'Fri 26', date: '2026-11-26' },
    { label: 'Sat 27', date: '2026-11-27' },
  ];

  return (
    <div className="space-y-6">
      {/* ─── HERO HEADER & HIGH-LEVEL RATIOS (CREXTIO STYLE) ─── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 pt-1">
        {/* Left: Greeting + Segmented Ratio Bar */}
        <div className="space-y-3">
          <h1 className="text-3xl sm:text-4xl font-normal tracking-tight text-stone-900">
            Welcome in, <span className="font-semibold text-black">AuraBake</span>
          </h1>

          {/* Segmented Progress Pills (Matching Crextio Top Capsule Badges) */}
          <div className="flex items-center gap-2 flex-wrap text-[11px] font-bold">
            <Link
              to="/approvals"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#18181B] hover:bg-black text-white rounded-full shadow-xs transition-colors"
            >
              <span>Approvals</span>
              <span className="text-[#FACC15]">{pendingTickets.length} pending</span>
            </Link>

            <Link
              to="/queue"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#FDE047] hover:bg-yellow-300 text-stone-950 rounded-full shadow-xs transition-colors"
            >
              <span>Active Queue</span>
              <span>{activeQueue}</span>
            </Link>

            <button
              onClick={() => setExpandedSection('outlets')}
              className="flex items-center gap-2 px-3.5 py-1.5 bg-white border border-[#E4DCB5] hover:bg-stone-50 rounded-full text-stone-700 shadow-xs transition-colors"
            >
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Campus Outlets: {outlets.filter(o => o.isOpen !== false).length}/{outlets.length} Open</span>
            </button>

            <div className="px-3.5 py-1.5 bg-white/70 border border-stone-300/80 rounded-full text-stone-600">
              Output: {totalOrders > 0 ? Math.round(((totalOrders - activeQueue) / totalOrders) * 100) : 96}%
            </div>
          </div>
        </div>

        {/* Right: Big Clean Numerical Counters */}
        <div className="flex items-center gap-8 self-start lg:self-center">
          {/* Outlets */}
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-full bg-white border border-stone-300/70 flex items-center justify-center text-stone-600 shadow-xs">
              <Store size={14} />
            </div>
            <div>
              <p className="text-3xl font-light tracking-tight text-stone-900 leading-none">
                {outlets.length}
              </p>
              <p className="text-[10px] font-bold text-stone-400 mt-1 uppercase tracking-wider">Outlets</p>
            </div>
          </div>

          {/* Active Queue */}
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-full bg-white border border-stone-300/70 flex items-center justify-center text-stone-600 shadow-xs">
              <Clock size={14} />
            </div>
            <div>
              <p className="text-3xl font-light tracking-tight text-stone-900 leading-none">
                {activeQueue}
              </p>
              <p className="text-[10px] font-bold text-stone-400 mt-1 uppercase tracking-wider">Queue</p>
            </div>
          </div>

          {/* Total Volume */}
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-full bg-[#18181B] text-[#FACC15] flex items-center justify-center shadow-xs">
              <ShoppingBag size={14} />
            </div>
            <div>
              <p className="text-3xl font-light tracking-tight text-stone-900 leading-none">
                {revenue > 1000 ? `₹${(revenue / 1000).toFixed(1)}k` : `₹${revenue.toFixed(0)}`}
              </p>
              <p className="text-[10px] font-bold text-stone-400 mt-1 uppercase tracking-wider">Volume</p>
            </div>
          </div>
        </div>
      </div>

      {/* ─── BENTO GRID LAYOUT (EXACT CREXTIO 3-COLUMN STRUCTURE) ─── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 pt-2">
        
        {/* ── LEFT COLUMN (SPAN 3) ── */}
        <div className="lg:col-span-3 space-y-5">
          {/* Spotlight Card (Profile / Executive Master - Crextio Lora Piterson equivalent) */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-[30px] p-5 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] relative overflow-hidden"
          >
            <div className="relative rounded-[22px] overflow-hidden aspect-[4/3] bg-gradient-to-tr from-stone-900 to-stone-700">
              <img
                src="https://images.unsplash.com/photo-1577219491135-ce391730fb2c?auto=format&fit=crop&q=80&w=600"
                alt="Executive Store Admin"
                className="w-full h-full object-cover mix-blend-overlay opacity-90 hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/25 to-transparent" />
              
              <div className="absolute top-3 right-3">
                <button
                  onClick={() => setIsRushMode(!isRushMode)}
                  className={`px-2.5 py-1 rounded-full text-[10px] font-black tracking-wide uppercase transition-colors shadow-sm flex items-center gap-1 ${
                    isRushMode
                      ? 'bg-amber-400 text-stone-950 animate-pulse'
                      : 'bg-white/20 backdrop-blur-md text-white border border-white/30'
                  }`}
                  title="Toggle Rush Hour Dispatch Mode"
                >
                  <Zap size={10} />
                  <span>{isRushMode ? 'Rush Mode ON' : 'Standard'}</span>
                </button>
              </div>

              <div className="absolute bottom-3.5 left-3.5 right-3.5 flex items-end justify-between text-white">
                <div>
                  <p className="text-sm font-bold">Chef Arjun Sharma</p>
                  <p className="text-[11px] text-stone-300 font-medium">Head of Operations</p>
                </div>
                <div className="px-2.5 py-1 rounded-full bg-white/20 backdrop-blur-md border border-white/30 text-[11px] font-bold">
                  ₹{revenue.toFixed(0)}
                </div>
              </div>
            </div>
          </motion.div>

          {/* Outlets & Campus System Accordion (Crextio Left Card 2) */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-[30px] p-5 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] space-y-3"
          >
            {/* Outlets Item */}
            <div className="border-b border-stone-100 pb-3">
              <div className="w-full flex items-center justify-between text-left">
                <button
                  onClick={() => setExpandedSection(expandedSection === 'outlets' ? null : 'outlets')}
                  className="flex-1 flex items-center justify-between pr-2"
                >
                  <span className="text-xs font-bold text-stone-900">Campus Outlets</span>
                  {expandedSection === 'outlets' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
                </button>
                <button
                  onClick={() => setIsAddOutletModalOpen(true)}
                  className="w-6 h-6 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] flex items-center justify-center shadow-xs transition-transform hover:scale-110"
                  title="Add New Campus Stall"
                >
                  <Plus size={13} />
                </button>
              </div>

              {expandedSection === 'outlets' && (
                <div className="mt-3 space-y-2">
                  {outlets.map((outlet) => {
                    const isOpen = outlet.isOpen !== false;
                    return (
                      <div
                        key={outlet.id}
                        className="flex items-center justify-between p-2.5 rounded-2xl bg-stone-50 border border-stone-100 text-xs hover:border-stone-200 transition-colors"
                      >
                        <div>
                          <p className="font-bold text-stone-900">{outlet.name}</p>
                          <p className="text-[10px] text-stone-400">
                            Queue: {outlet.queueCount || 0} • {outlet.waitTime || 'No wait'}
                          </p>
                        </div>
                        
                        {/* Interactive Toggle Switch */}
                        <div className="flex items-center gap-2">
                          <button
                            onClick={() => toggleOutletStatus(outlet.id, isOpen)}
                            className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${
                              isOpen ? 'bg-emerald-500' : 'bg-stone-300'
                            }`}
                            title={`Click to set ${outlet.name} ${isOpen ? 'Offline' : 'Online'}`}
                          >
                            <span
                              className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                                isOpen ? 'translate-x-4' : 'translate-x-0'
                              }`}
                            />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* UPI & Payment Config (Interactive with Copy & Edit) */}
            <div className="border-b border-stone-100 pb-3">
              <button
                onClick={() => setExpandedSection(expandedSection === 'upi' ? null : 'upi')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Payment Terminals (UPI)</span>
                {expandedSection === 'upi' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'upi' && (
                <div className="mt-2.5 space-y-2 text-xs text-stone-600">
                  {outlets.map(o => (
                    <div key={o.id} className="p-2.5 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between text-[11px]">
                      <div>
                        <p className="font-bold text-stone-900">{o.name}</p>
                        <p className="font-mono text-stone-400 text-[10px]">{o.upiId || 'aurabake@upi'}</p>
                      </div>
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => copyToClipboard(o.upiId || 'aurabake@upi', o.id)}
                          className="w-6 h-6 rounded-full bg-white border border-stone-200 flex items-center justify-center text-stone-600 hover:text-stone-900"
                          title="Copy UPI ID"
                        >
                          {copiedUpiId === o.id ? <Check size={11} className="text-emerald-600" /> : <Copy size={11} />}
                        </button>
                        <button
                          onClick={() => {
                            setEditingUpiOutlet(o);
                            setEditUpiValue(o.upiId || 'aurabake@upi');
                          }}
                          className="w-6 h-6 rounded-full bg-white border border-stone-200 flex items-center justify-center text-stone-600 hover:text-stone-900"
                          title="Edit UPI ID"
                        >
                          <Edit2 size={11} />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Pickup Slots & Capacities */}
            <div className="border-b border-stone-100 pb-3">
              <button
                onClick={() => setExpandedSection(expandedSection === 'slots' ? null : 'slots')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Pickup Slot Windows</span>
                {expandedSection === 'slots' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'slots' && (
                <div className="mt-2.5 space-y-2 text-[11px] text-stone-600">
                  <div className="flex items-center justify-between p-2 rounded-xl bg-stone-50 border border-stone-100">
                    <span>12:30 PM - 12:40 PM</span>
                    <div className="flex items-center gap-1.5 font-bold">
                      <button
                        onClick={() => setSlotCapacities(c => ({ ...c, slot1: Math.max(5, c.slot1 - 5) }))}
                        className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center"
                      >
                        -
                      </button>
                      <span className="w-6 text-center">{slotCapacities.slot1}</span>
                      <button
                        onClick={() => setSlotCapacities(c => ({ ...c, slot1: c.slot1 + 5 }))}
                        className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center"
                      >
                        +
                      </button>
                    </div>
                  </div>

                  <div className="flex items-center justify-between p-2 rounded-xl bg-stone-50 border border-stone-100">
                    <span>12:40 PM - 12:50 PM</span>
                    <div className="flex items-center gap-1.5 font-bold">
                      <button
                        onClick={() => setSlotCapacities(c => ({ ...c, slot2: Math.max(5, c.slot2 - 5) }))}
                        className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center"
                      >
                        -
                      </button>
                      <span className="w-6 text-center">{slotCapacities.slot2}</span>
                      <button
                        onClick={() => setSlotCapacities(c => ({ ...c, slot2: c.slot2 + 5 }))}
                        className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center"
                      >
                        +
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {/* Devices & Terminals (Crextio MacBook Air equivalent) */}
            <div>
              <button
                onClick={() => setExpandedSection(expandedSection === 'devices' ? null : 'devices')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Devices & Kitchen Hardware</span>
                {expandedSection === 'devices' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'devices' && (
                <div className="mt-2.5 space-y-1.5 text-xs text-stone-600">
                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Smartphone size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Baker Queue Display</p>
                        <p className="text-[9px] text-stone-400">Nothing Phone (Connected)</p>
                      </div>
                    </div>
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  </div>

                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Printer size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Receipt Printer</p>
                        <p className="text-[9px] text-stone-400">Epson TM-T82 (Ready)</p>
                      </div>
                    </div>
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  </div>

                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Volume2 size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Counter Audio Chime</p>
                        <p className="text-[9px] text-stone-400">Audio notifications active</p>
                      </div>
                    </div>
                    <span className="w-2 h-2 rounded-full bg-emerald-500" />
                  </div>
                </div>
              )}
            </div>
          </motion.div>
        </div>

        {/* ── CENTER COLUMNS (SPAN 6) ── */}
        <div className="lg:col-span-6 space-y-5">
          {/* Top Row: Progress Bar Chart & Time Tracker Gauge */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Card C: Progress / Order Velocity Bar Chart (Crextio Progress equivalent) */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 }}
              className="bg-white rounded-[30px] p-5 sm:p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-stone-500">Order Velocity</p>
                  <Link to="/analytics" className="w-6 h-6 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600 transition-colors">
                    <ArrowUpRight size={13} />
                  </Link>
                </div>

                <div className="mt-2 flex items-baseline gap-2">
                  <span className="text-3xl font-normal tracking-tight text-stone-900">
                    {activeQueue * 3 + 12}
                  </span>
                  <span className="text-xs text-stone-400 font-medium">Orders / hour</span>
                </div>
              </div>

              {/* Minimalist Bar Chart (matching Crextio Screenshot S M T W T F S) */}
              <div className="mt-6 pt-2">
                <div className="flex items-end justify-between h-28 gap-2 relative">
                  {/* Floating Rush Tag on active peak bar */}
                  <div className="absolute top-0 right-10 bg-[#FACC15] text-stone-950 font-extrabold text-[9px] px-2 py-0.5 rounded-full shadow-xs animate-bounce">
                    12:30 Rush
                  </div>

                  {/* Day/Hour bars */}
                  {[
                    { label: 'S', h: 'h-10', dot: true },
                    { label: 'M', h: 'h-16', dot: false },
                    { label: 'T', h: 'h-12', dot: false },
                    { label: 'W', h: 'h-18', dot: false },
                    { label: 'T', h: 'h-24', highlight: true }, // Peak
                    { label: 'F', h: 'h-14', dot: false },
                    { label: 'S', h: 'h-8', dot: true },
                  ].map((bar, idx) => (
                    <div key={idx} className="flex-1 flex flex-col items-center gap-2">
                      <div className="w-full flex justify-center">
                        <div
                          className={`w-3.5 rounded-full transition-all duration-300 ${
                            bar.highlight
                              ? 'bg-[#FACC15] shadow-sm'
                              : 'bg-stone-900 hover:bg-stone-700'
                          } ${bar.h}`}
                        />
                      </div>
                      <span className="text-[10px] font-bold text-stone-400">{bar.label}</span>
                    </div>
                  ))}
                </div>
              </div>
            </motion.div>

            {/* Card D: Time Tracker (Circular Dial Gauge with Working Ticking Controls) */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white rounded-[30px] p-5 sm:p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] flex flex-col justify-between"
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-bold text-stone-500">Time tracker</p>
                  <p className="text-[10px] text-stone-400 font-medium">Rush Dispatch Clock</p>
                </div>
                <Link to="/queue" className="w-6 h-6 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600 transition-colors">
                  <ArrowUpRight size={13} />
                </Link>
              </div>

              {/* Circular Dial Visual with dynamic stroke */}
              <div className="my-2 flex flex-col items-center justify-center">
                <div className="relative w-36 h-36 flex items-center justify-center">
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="#F4EEDC"
                      strokeWidth="5"
                      strokeDasharray="4 4"
                      fill="transparent"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="#FACC15"
                      strokeWidth="5.5"
                      strokeLinecap="round"
                      strokeDasharray="251.2"
                      strokeDashoffset={251.2 - (251.2 * (timerSeconds / timerInitialSeconds))}
                      fill="transparent"
                      className="transition-all duration-1000 ease-linear"
                    />
                  </svg>

                  {/* Center Time Value */}
                  <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                    <span className="text-2xl font-black tracking-tight text-stone-900 leading-none font-mono">
                      {formatTimer(timerSeconds)}
                    </span>
                    <span className="text-[10px] text-stone-400 font-bold mt-1.5 tracking-wider uppercase">
                      Work Time
                    </span>
                  </div>
                </div>

                <div className="mt-1">
                  <span className="text-[10px] font-bold text-stone-500 bg-stone-50 px-2.5 py-0.5 rounded-full border border-stone-200/60">
                    ~{avgWaitMinutes}m avg wait
                  </span>
                </div>
              </div>

              {/* Working Play / Pause / Reset Controls & Presets */}
              <div className="flex flex-col items-center gap-2 pt-1">
                <div className="flex items-center justify-center gap-3">
                  <button
                    onClick={() => setIsTimerPlaying(!isTimerPlaying)}
                    className="w-8 h-8 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] flex items-center justify-center transition-colors shadow-xs"
                    title={isTimerPlaying ? 'Pause Timer' : 'Start Timer'}
                  >
                    {isTimerPlaying ? <Pause size={12} /> : <Play size={12} className="ml-0.5" />}
                  </button>

                  <button
                    onClick={() => {
                      setTimerSeconds(timerInitialSeconds);
                      setIsTimerPlaying(false);
                    }}
                    className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-700 transition-colors"
                    title="Reset Timer"
                  >
                    <RotateCcw size={12} />
                  </button>
                </div>

                {/* Quick Preset Pills */}
                <div className="flex items-center gap-1.5 text-[9px] font-bold text-stone-500">
                  <button
                    onClick={() => setTimerPreset(120)}
                    className="px-2 py-0.5 rounded-full bg-stone-100 hover:bg-stone-200"
                  >
                    2m
                  </button>
                  <button
                    onClick={() => setTimerPreset(155)}
                    className="px-2 py-0.5 rounded-full bg-[#FACC15] text-stone-950 font-black"
                  >
                    2:35
                  </button>
                  <button
                    onClick={() => setTimerPreset(300)}
                    className="px-2 py-0.5 rounded-full bg-stone-100 hover:bg-stone-200"
                  >
                    5m
                  </button>
                </div>
              </div>
            </motion.div>
          </div>

          {/* Card E: Live Schedule & Dispatch Matrix (Crextio Bottom Calendar Strip) */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
            className="bg-white rounded-[30px] p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)]"
          >
            {/* Month Strip */}
            <div className="flex items-center justify-between text-xs font-bold text-stone-400 border-b border-stone-100 pb-3">
              <span className="text-stone-400">October</span>
              <span className="text-stone-900 font-extrabold">November 2026</span>
              <span className="text-stone-400">December</span>
            </div>

            {/* Clickable Days Row */}
            <div className="grid grid-cols-6 gap-2 text-center text-xs font-bold py-3 border-b border-stone-100">
              {scheduleDays.map((day, idx) => (
                <button
                  key={idx}
                  onClick={() => setSelectedDayIndex(idx)}
                  className={`py-1 rounded-xl transition-all ${
                    selectedDayIndex === idx
                      ? 'bg-[#18181B] text-white shadow-xs'
                      : 'text-stone-400 hover:text-stone-700'
                  }`}
                >
                  {day.label}
                </button>
              ))}
            </div>

            {/* Time Slot Dispatch Blocks */}
            <div className="mt-4 space-y-3">
              <div className="flex items-start gap-4 text-xs">
                <span className="text-stone-400 w-16 pt-1 font-semibold">11:30 am</span>
                <div className="flex-1 p-3 rounded-2xl bg-[#18181B] text-white flex items-center justify-between shadow-xs">
                  <div>
                    <p className="font-bold text-xs">Breakfast & Beverage Rush</p>
                    <p className="text-[10px] text-stone-400">Nescafe & Juice Bar Peak (38 orders)</p>
                  </div>
                  <div className="flex -space-x-1.5">
                    <div className="w-5 h-5 rounded-full bg-amber-400 text-stone-950 text-[9px] font-black flex items-center justify-center">N</div>
                    <div className="w-5 h-5 rounded-full bg-emerald-400 text-stone-950 text-[9px] font-black flex items-center justify-center">C</div>
                  </div>
                </div>
              </div>

              <div className="flex items-start gap-4 text-xs">
                <span className="text-stone-400 w-16 pt-1 font-semibold">12:30 pm</span>
                <div className="flex-1 p-3 rounded-2xl bg-[#FAF6EE] border border-[#E7DFCE] text-stone-900 flex items-center justify-between">
                  <div>
                    <p className="font-bold text-xs">Lunch Pre-Order Dispatch Window</p>
                    <p className="text-[10px] text-stone-500">Main Campus Canteen · Slot Capacity {slotCapacities.slot1}/{slotCapacities.slot1}</p>
                  </div>
                  <span className="px-2 py-0.5 rounded-full bg-[#FACC15] text-[10px] font-extrabold text-stone-950 animate-pulse">
                    Live Now
                  </span>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* ── RIGHT COLUMN (SPAN 3) ── */}
        {/* Card F: Approvals Desk & Onboarding Tasks (Tall Dark Charcoal Bento Card) */}
        <div className="lg:col-span-3">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-[#18181B] text-white rounded-[32px] p-6 shadow-2xl flex flex-col justify-between h-full min-h-[480px] border border-stone-800"
          >
            <div>
              {/* Header with Ratio & Approve All Button */}
              <div className="flex items-center justify-between pb-3 border-b border-stone-800">
                <div>
                  <h3 className="text-sm font-bold text-stone-100">Approval Desk</h3>
                  <p className="text-[10px] text-stone-400">Manager item submissions</p>
                </div>
                <div className="text-right">
                  <span className="text-xl font-normal text-[#FACC15] font-mono">
                    {pendingTickets.length}/8
                  </span>
                </div>
              </div>

              {/* Multi-segment Ratio Bar inside Dark Card (matching Crextio Onboarding 18%) */}
              <div className="my-3 flex gap-1.5 h-2">
                <div className="w-[30%] bg-[#FACC15] rounded-full" />
                <div className="w-[25%] bg-stone-700 rounded-full" />
                <div className="w-[45%] bg-stone-800 rounded-full" />
              </div>

              {/* Action Ribbon: Approve All */}
              {pendingTickets.length > 0 && (
                <div className="mb-3 flex items-center justify-between">
                  <span className="text-[10px] font-bold text-stone-400 uppercase tracking-wider">
                    Pending Review
                  </span>
                  <button
                    onClick={handleApproveAll}
                    className="text-[10px] font-bold text-[#FACC15] hover:text-yellow-300 underline"
                  >
                    Approve All ✓
                  </button>
                </div>
              )}

              {/* Tickets Checklist */}
              <div className="space-y-2.5">
                {pendingTickets.length === 0 ? (
                  <div className="py-12 text-center text-stone-500 text-xs">
                    <CheckCircle2 size={32} className="mx-auto mb-2 text-stone-600" />
                    <p className="font-semibold text-stone-300">All submissions approved</p>
                    <p className="text-[10px] text-stone-500 mt-1">No pending menu tickets</p>
                  </div>
                ) : (
                  pendingTickets.slice(0, 4).map((ticket) => (
                    <div
                      key={ticket.id}
                      className="p-3 bg-[#24242A] hover:bg-[#2A2A32] rounded-2xl border border-stone-800/80 transition-colors flex items-center justify-between gap-2.5"
                    >
                      <div className="flex items-center gap-2.5 overflow-hidden">
                        <div className="w-7 h-7 rounded-full bg-stone-800 flex items-center justify-center shrink-0">
                          {getCategoryIcon(ticket.itemData.category)}
                        </div>
                        <div className="overflow-hidden">
                          <p className="text-xs font-bold text-stone-100 truncate">
                            {ticket.itemData.name}
                          </p>
                          <p className="text-[10px] text-stone-400 truncate">
                            {ticket.outletName || ticket.outletId} • ₹{ticket.itemData.price}
                          </p>
                        </div>
                      </div>

                      {/* Dual Action Buttons: Quick Approve & Quick Reject */}
                      <div className="flex items-center gap-1.5 shrink-0">
                        <button
                          onClick={() => setRejectingTicket(ticket)}
                          className="w-7 h-7 rounded-full bg-stone-800 hover:bg-red-950 hover:text-red-400 text-stone-400 flex items-center justify-center font-bold transition-all text-xs border border-stone-700/60"
                          title="Reject Submission"
                        >
                          ✕
                        </button>
                        <button
                          onClick={() => handleQuickApprove(ticket)}
                          className="w-7 h-7 rounded-full bg-[#FACC15] hover:bg-yellow-300 text-stone-950 flex items-center justify-center font-black transition-transform hover:scale-105 shadow-sm text-xs"
                          title="Approve & Publish Item"
                        >
                          ✓
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>

            {/* Bottom Link to Full Approvals Page */}
            <div className="pt-4 border-t border-stone-800/80 mt-6">
              <Link
                to="/approvals"
                className="w-full py-2.5 px-4 rounded-full bg-[#24242A] hover:bg-stone-800 text-stone-300 hover:text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors border border-stone-700/60"
              >
                <span>View Full Approval Desk</span>
                <ArrowUpRight size={13} />
              </Link>
            </div>
          </motion.div>
        </div>

      </div>

      {/* ─── ADD STALL MODAL ─── */}
      <AnimatePresence>
        {isAddOutletModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Provision Campus Stall</h3>
                  <p className="text-xs text-stone-500">Register new vendor counter or food outlet</p>
                </div>
                <button
                  onClick={() => setIsAddOutletModalOpen(false)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleAddOutlet} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Stall Name</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Juice & Shake Hub"
                    value={newOutletName}
                    onChange={e => setNewOutletName(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Stall ID (Optional)</label>
                  <input
                    type="text"
                    placeholder="e.g. juice_hub (auto-generated if empty)"
                    value={newOutletId}
                    onChange={e => setNewOutletId(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Vendor UPI ID</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. vendor@upi"
                    value={newOutletUpi}
                    onChange={e => setNewOutletUpi(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Est. Default Prep Time</label>
                  <input
                    type="text"
                    placeholder="e.g. 5-8 mins"
                    value={newOutletWait}
                    onChange={e => setNewOutletWait(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setIsAddOutletModalOpen(false)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingOutlet}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingOutlet ? 'Saving...' : 'Create Stall'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ─── EDIT UPI MODAL ─── */}
      <AnimatePresence>
        {editingUpiOutlet && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Update UPI ID</h3>
                  <p className="text-xs text-stone-500">{editingUpiOutlet.name}</p>
                </div>
                <button
                  onClick={() => setEditingUpiOutlet(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <div>
                <label className="block text-xs font-bold text-stone-700 mb-1">New UPI Address</label>
                <input
                  type="text"
                  value={editUpiValue}
                  onChange={e => setEditUpiValue(e.target.value)}
                  className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 font-mono focus:outline-none focus:border-stone-800"
                />
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setEditingUpiOutlet(null)}
                  className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSaveUpi}
                  className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105"
                >
                  Save UPI ID
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ─── REJECT TICKET MODAL ─── */}
      <AnimatePresence>
        {rejectingTicket && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-sm bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Reject Item Submission</h3>
                  <p className="text-xs text-stone-500">{rejectingTicket.itemData.name}</p>
                </div>
                <button
                  onClick={() => setRejectingTicket(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <div>
                <label className="block text-xs font-bold text-stone-700 mb-1">Rejection Reason</label>
                <textarea
                  rows={3}
                  placeholder="e.g. Price too high, incorrect category, or image required."
                  value={rejectionReason}
                  onChange={e => setRejectionReason(e.target.value)}
                  className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                />
              </div>

              <div className="flex items-center gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setRejectingTicket(null)}
                  className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                >
                  Cancel
                </button>
                <button
                  onClick={handleConfirmReject}
                  className="flex-1 py-2.5 rounded-full bg-red-600 hover:bg-red-500 text-white text-xs font-bold shadow-xs transition-transform hover:scale-105"
                >
                  Confirm Reject
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
