import { motion } from 'framer-motion';
import { ArrowUpRight, Play, Pause, Clock, Store, ShoppingBag, CheckCircle2, ChevronDown, ChevronUp } from 'lucide-react';
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { collection, onSnapshot, query, where, orderBy, limit, doc, updateDoc, addDoc, serverTimestamp } from 'firebase/firestore';
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
  const [isTimerPlaying, setIsTimerPlaying] = useState(true);
  
  // Accordion state for left bottom card
  const [expandedSection, setExpandedSection] = useState<string | null>('outlets');

  useEffect(() => {
    // 1. Orders listener
    const qOrders = query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(100));
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
            outletId: data.outletId || '01',
            outletName: data.outletName || `Outlet ${data.outletId || '01'}`,
            submittedByName: data.submittedByName || 'Outlet Manager',
            sourceDoc: 'menu_items',
            itemData: {
              name: data.name || 'Untitled Item',
              description: data.description || '',
              price: Number(data.price || 0),
              category: data.category || 'General',
              prepTime: Number(data.prepTime || 5),
              photoBase64: data.photoBase64,
            },
          } as ApprovalTicket;
        });
      syncPending();
    }, () => {});

    let unsubTickets: (() => void) | null = null;
    try {
      const qTickets = query(collection(db, 'approval_tickets'), where('status', '==', 'pending'), limit(10));
      unsubTickets = onSnapshot(qTickets, (snap) => {
        rawApprovalTickets = snap.docs.map(d => ({
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

  const handleQuickApprove = async (ticket: ApprovalTicket) => {
    try {
      if (ticket.sourceDoc === 'menu_items') {
        // Direct update in menu_items
        await updateDoc(doc(db, 'menu_items', ticket.id), {
          approvalStatus: 'approved',
          isApproved: true,
          isAvailable: true,
          reviewedAt: serverTimestamp(),
        });
      } else {
        // Publish to menu_items
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

      // Also try publishing to outlet subcollection
      try {
        await addDoc(collection(db, 'outlets', ticket.outletId, 'menu_items'), {
          name: ticket.itemData.name,
          price: Number(ticket.itemData.price),
          category: ticket.itemData.category || 'Snacks',
          prepTime: Number(ticket.itemData.prepTime || 5),
          isAvailable: true,
          outletId: ticket.outletId,
          createdAt: serverTimestamp(),
        });
      } catch (_) {}
    } catch (e) {
      console.error('Error approving ticket:', e);
    }
  };

  return (
    <div className="space-y-6">
      {/* ─── HERO HEADER & HIGH-LEVEL RATIOS (CREXTIO STYLE) ─── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 pt-1">
        {/* Left: Greeting + Segmented Ratio Bar */}
        <div className="space-y-3">
          <h1 className="text-3xl sm:text-4xl font-normal tracking-tight text-stone-900">
            Welcome in, <span className="font-semibold text-black">AuraBake</span>
          </h1>

          {/* Segmented Progress Pills */}
          <div className="flex items-center gap-2 flex-wrap text-[11px] font-bold">
            <div className="flex items-center gap-1.5 px-3 py-1 bg-[#18181B] text-white rounded-full shadow-xs">
              <span>Approvals</span>
              <span className="text-[#FACC15]">{pendingTickets.length} pending</span>
            </div>

            <div className="flex items-center gap-1.5 px-3 py-1 bg-[#FDE047] text-stone-950 rounded-full shadow-xs">
              <span>Active Queue</span>
              <span>{activeQueue}</span>
            </div>

            <div className="flex items-center gap-2 px-3 py-1 bg-white border border-[#E4DCB5] rounded-full text-stone-700 shadow-xs">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>Campus Outlets: {outlets.filter(o => o.isOpen !== false).length} Open</span>
            </div>

            <div className="px-3 py-1 bg-white/70 border border-stone-300/80 rounded-full text-stone-500">
              Output: {totalOrders > 0 ? Math.round(((totalOrders - activeQueue) / totalOrders) * 100) : 95}%
            </div>
          </div>
        </div>

        {/* Right: Big Clean Numerical Counters */}
        <div className="flex items-center gap-8 self-start lg:self-center">
          {/* Outlets */}
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-full bg-white border border-stone-300/70 flex items-center justify-center text-stone-500 shadow-xs">
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
            <div className="w-7 h-7 rounded-full bg-white border border-stone-300/70 flex items-center justify-center text-stone-500 shadow-xs">
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
          {/* Spotlight Card (Profile / Executive Master) */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-[30px] p-5 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] relative overflow-hidden"
          >
            <div className="relative rounded-[22px] overflow-hidden aspect-[4/3] bg-gradient-to-tr from-stone-900 to-stone-700">
              <img
                src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=600"
                alt="Executive Admin"
                className="w-full h-full object-cover mix-blend-overlay opacity-90 hover:scale-105 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/20 to-transparent" />
              
              <div className="absolute bottom-3.5 left-3.5 right-3.5 flex items-end justify-between text-white">
                <div>
                  <p className="text-sm font-bold">Admin Controller</p>
                  <p className="text-[11px] text-stone-300 font-medium">Head of Operations</p>
                </div>
                <div className="px-2.5 py-1 rounded-full bg-white/20 backdrop-blur-md border border-white/30 text-[11px] font-bold">
                  ₹{revenue.toFixed(0)}
                </div>
              </div>
            </div>
          </motion.div>

          {/* Outlets & Campus System Accordion */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-[30px] p-5 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] space-y-3"
          >
            {/* Outlets Item */}
            <div className="border-b border-stone-100 pb-3">
              <button
                onClick={() => setExpandedSection(expandedSection === 'outlets' ? null : 'outlets')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Campus Outlets</span>
                {expandedSection === 'outlets' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'outlets' && (
                <div className="mt-2.5 space-y-2">
                  {outlets.map((outlet) => (
                    <div key={outlet.id} className="flex items-center justify-between p-2 rounded-xl bg-stone-50 border border-stone-100 text-xs">
                      <div>
                        <p className="font-bold text-stone-900">{outlet.name}</p>
                        <p className="text-[10px] text-stone-400">Queue: {outlet.queueCount || 0}</p>
                      </div>
                      <span className={`w-2 h-2 rounded-full ${outlet.isOpen !== false ? 'bg-emerald-500' : 'bg-red-400'}`} />
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* UPI & Payment Config */}
            <div className="border-b border-stone-100 pb-3">
              <button
                onClick={() => setExpandedSection(expandedSection === 'upi' ? null : 'upi')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Payment Terminals (UPI)</span>
                {expandedSection === 'upi' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'upi' && (
                <div className="mt-2.5 space-y-1.5 text-xs text-stone-600">
                  {outlets.map(o => (
                    <div key={o.id} className="p-2 bg-stone-50 rounded-lg text-[11px] font-mono flex justify-between">
                      <span>{o.name}</span>
                      <span className="text-stone-400">{o.upiId || 'aurabake@upi'}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Pickup Slots */}
            <div>
              <button
                onClick={() => setExpandedSection(expandedSection === 'slots' ? null : 'slots')}
                className="w-full flex items-center justify-between text-left"
              >
                <span className="text-xs font-bold text-stone-900">Pickup Slot Windows</span>
                {expandedSection === 'slots' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'slots' && (
                <div className="mt-2 text-[11px] text-stone-500 space-y-1">
                  <p>• 12:30 PM - 12:40 PM (Capacity 20)</p>
                  <p>• 12:40 PM - 12:50 PM (Capacity 20)</p>
                  <p>• 12:50 PM - 01:00 PM (Capacity 20)</p>
                </div>
              )}
            </div>
          </motion.div>
        </div>

        {/* ── CENTER COLUMNS (SPAN 6) ── */}
        <div className="lg:col-span-6 space-y-5">
          {/* Top Row: Progress Bar Chart & Time Tracker Gauge */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
            {/* Card C: Progress / Order Velocity Bar Chart */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.15 }}
              className="bg-white rounded-[30px] p-5 sm:p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] flex flex-col justify-between"
            >
              <div>
                <div className="flex items-center justify-between">
                  <p className="text-xs font-bold text-stone-500">Order Velocity</p>
                  <Link to="/queue" className="w-6 h-6 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600 transition-colors">
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

              {/* Minimalist Bar Chart (matching Crextio Screenshot) */}
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

            {/* Card D: Time Tracker (Circular Dial Gauge) */}
            <motion.div
              initial={{ opacity: 0, y: 15 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="bg-white rounded-[30px] p-5 sm:p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] flex flex-col justify-between"
            >
              <div className="flex items-center justify-between">
                <p className="text-xs font-bold text-stone-500">Live Prep Pace</p>
                <Link to="/queue" className="w-6 h-6 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600 transition-colors">
                  <ArrowUpRight size={13} />
                </Link>
              </div>

              {/* Circular Dial Visual */}
              <div className="my-3 flex items-center justify-center">
                <div className="relative w-32 h-32 flex items-center justify-center">
                  {/* Dashed outer ring */}
                  <svg className="w-full h-full -rotate-90" viewBox="0 0 100 100">
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="#F4EEDC"
                      strokeWidth="6"
                      strokeDasharray="4 4"
                      fill="transparent"
                    />
                    <circle
                      cx="50"
                      cy="50"
                      r="40"
                      stroke="#FACC15"
                      strokeWidth="6"
                      strokeLinecap="round"
                      strokeDasharray="251.2"
                      strokeDashoffset={251.2 - (251.2 * 0.65)}
                      fill="transparent"
                    />
                  </svg>

                  {/* Center Time Value */}
                  <div className="absolute text-center">
                    <p className="text-xl font-bold tracking-tight text-stone-900 leading-none">
                      0{avgWaitMinutes}:35
                    </p>
                    <p className="text-[10px] text-stone-400 font-semibold mt-1">Avg Wait</p>
                  </div>
                </div>
              </div>

              {/* Bottom Play/Pause & Clock Controls */}
              <div className="flex items-center justify-center gap-3 pt-1">
                <button
                  onClick={() => setIsTimerPlaying(!isTimerPlaying)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-700 transition-colors"
                >
                  {isTimerPlaying ? <Pause size={12} /> : <Play size={12} className="ml-0.5" />}
                </button>
                <div className="w-8 h-8 rounded-full bg-stone-100 flex items-center justify-center text-stone-700">
                  <Clock size={12} />
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
            {/* Month & Dates Strip */}
            <div className="flex items-center justify-between text-xs font-bold text-stone-400 border-b border-stone-100 pb-3">
              <span className="text-stone-400">August</span>
              <span className="text-stone-900 font-extrabold">November 2026</span>
              <span className="text-stone-400">December</span>
            </div>

            <div className="grid grid-cols-6 gap-2 text-center text-xs font-bold py-3 border-b border-stone-100">
              {['Mon 22', 'Tue 23', 'Wed 24', 'Thu 25', 'Fri 26', 'Sat 27'].map((day, idx) => (
                <div key={idx} className={idx === 0 ? 'text-black font-extrabold' : 'text-stone-400'}>
                  {day}
                </div>
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
                    <p className="text-[10px] text-stone-500">Main Campus Canteen · Slot Capacity 20/20</p>
                  </div>
                  <span className="px-2 py-0.5 rounded-full bg-[#FACC15] text-[10px] font-extrabold text-stone-950">
                    Live Now
                  </span>
                </div>
              </div>
            </div>
          </motion.div>
        </div>

        {/* ── RIGHT COLUMN (SPAN 3) ── */}
        {/* Card F: Approvals Desk & Onboarding Tasks (Tall Dark Charcoal Card) */}
        <div className="lg:col-span-3">
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
            className="bg-[#18181B] text-white rounded-[32px] p-6 shadow-2xl flex flex-col justify-between h-full min-h-[480px] border border-stone-800"
          >
            <div>
              {/* Header with Ratio */}
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

              {/* Multi-segment Ratio Bar inside Dark Card */}
              <div className="my-3 flex gap-1.5 h-2">
                <div className="w-[40%] bg-[#FACC15] rounded-full" />
                <div className="w-[30%] bg-stone-700 rounded-full" />
                <div className="w-[30%] bg-stone-800 rounded-full" />
              </div>

              {/* Tickets Checklist */}
              <div className="mt-4 space-y-2.5">
                {pendingTickets.length === 0 ? (
                  <div className="py-12 text-center text-stone-500 text-xs">
                    <CheckCircle2 size={32} className="mx-auto mb-2 text-stone-600" />
                    <p className="font-semibold text-stone-400">All submissions approved</p>
                    <p className="text-[10px] text-stone-600 mt-1">No pending menu tickets</p>
                  </div>
                ) : (
                  pendingTickets.slice(0, 4).map((ticket) => (
                    <div
                      key={ticket.id}
                      className="p-3 bg-[#24242A] hover:bg-[#2A2A32] rounded-2xl border border-stone-800/80 transition-colors flex items-center justify-between gap-2.5"
                    >
                      <div className="overflow-hidden">
                        <p className="text-xs font-bold text-stone-100 truncate">
                          {ticket.itemData.name}
                        </p>
                        <p className="text-[10px] text-stone-400 truncate">
                          {ticket.outletName || ticket.outletId} • ₹{ticket.itemData.price}
                        </p>
                      </div>

                      <button
                        onClick={() => handleQuickApprove(ticket)}
                        className="w-7 h-7 rounded-full bg-[#FACC15] hover:bg-yellow-300 text-stone-950 flex items-center justify-center font-black shrink-0 transition-transform hover:scale-105 shadow-sm"
                        title="Approve & Publish Item"
                      >
                        ✓
                      </button>
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
    </div>
  );
}
