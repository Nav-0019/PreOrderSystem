import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowUpRight,
  Play,
  Pause,
  RotateCcw,
  Clock,
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
  Coffee,
  UtensilsCrossed,
  Sparkles,
  Trash2,
  Calendar,
  ChevronLeft,
  ChevronRight,
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
  deleteDoc,
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

interface TimeSlot {
  id: string;
  outletId: string;
  outletName?: string;
  window: string;
  label: string;
  startTime?: string;
  endTime?: string;
  capacity: number;
  currentOrders?: number;
  isActive?: boolean;
}

interface OrderRecord {
  id: string;
  outletId?: string;
  outletName?: string;
  token?: string | number;
  customerName?: string;
  pickupSlot?: string;
  status: string;
  totalAmount: number;
  items?: any[];
  createdAt?: any;
}

export default function Overview() {
  const [totalOrders, setTotalOrders] = useState(0);
  const [activeQueue, setActiveQueue] = useState(0);
  const [revenue, setRevenue] = useState(0);
  const [outlets, setOutlets] = useState<OutletItem[]>([]);
  const [avgWaitMinutes, setAvgWaitMinutes] = useState(4);
  const [pendingTickets, setPendingTickets] = useState<ApprovalTicket[]>([]);
  const [rawOrders, setRawOrders] = useState<OrderRecord[]>([]);
  const [timeSlots, setTimeSlots] = useState<TimeSlot[]>([]);

  // Rush hour mode toggle
  const [isRushMode, setIsRushMode] = useState(false);

  // Time Tracker Dial State
  const [isTimerPlaying, setIsTimerPlaying] = useState(false);
  const [timerInitialSeconds, setTimerInitialSeconds] = useState(155); // 02:35
  const [timerSeconds, setTimerSeconds] = useState(155);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Accordion state for left column
  const [expandedSection, setExpandedSection] = useState<string | null>('outlets');

  // Modals state
  const [isAddOutletModalOpen, setIsAddOutletModalOpen] = useState(false);
  const [newOutletName, setNewOutletName] = useState('');
  const [newOutletId, setNewOutletId] = useState('');
  const [newOutletUpi, setNewOutletUpi] = useState('7310347742@nyes');
  const [newOutletWait, setNewOutletWait] = useState('2-5 mins');
  const [isSubmittingOutlet, setIsSubmittingOutlet] = useState(false);

  // Edit Outlet Modal state
  const [editingOutlet, setEditingOutlet] = useState<OutletItem | null>(null);
  const [editOutletName, setEditOutletName] = useState('');
  const [editOutletWait, setEditOutletWait] = useState('');
  const [editOutletUpi, setEditOutletUpi] = useState('');
  const [isSubmittingOutletEdit, setIsSubmittingOutletEdit] = useState(false);

  // Edit UPI Modal state
  const [editingUpiOutlet, setEditingUpiOutlet] = useState<OutletItem | null>(null);
  const [editUpiValue, setEditUpiValue] = useState('');
  const [copiedUpiId, setCopiedUpiId] = useState<string | null>(null);

  // Reject Ticket Modal state
  const [rejectingTicket, setRejectingTicket] = useState<ApprovalTicket | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  // ─── DYNAMIC SCHEDULE & CALENDAR STATE ────────────────────────
  const [selectedMonthDate, setSelectedMonthDate] = useState<Date>(new Date());
  const [selectedDateStr, setSelectedDateStr] = useState<string>(() => {
    return new Date().toISOString().split('T')[0];
  });

  // Capacity overrides per slot
  const [slotCapacityOverrides, setSlotCapacityOverrides] = useState<Record<string, number>>({});

  // Modal: Add Slot State
  const [isAddSlotModalOpen, setIsAddSlotModalOpen] = useState(false);
  const [newSlotWindow, setNewSlotWindow] = useState('01:15 PM - 01:30 PM');
  const [newSlotLabel, setNewSlotLabel] = useState('Afternoon Wave 3');
  const [newSlotCapacity, setNewSlotCapacity] = useState('20');
  const [newSlotStartTime, setNewSlotStartTime] = useState('13:15');
  const [newSlotEndTime, setNewSlotEndTime] = useState('13:30');
  const [newSlotOutletId, setNewSlotOutletId] = useState('2000');
  const [isSubmittingSlot, setIsSubmittingSlot] = useState(false);

  // Modal: Slot Details / Edit Capacity
  const [selectedSlotForModal, setSelectedSlotForModal] = useState<any | null>(null);

  // Device status & interactive test alerts
  const [deviceStatuses, setDeviceStatuses] = useState({
    dev1: true, // Baker Phone
    dev2: true, // Epson Printer
    dev3: true, // Counter Chime
  });
  const [deviceToast, setDeviceToast] = useState<string | null>(null);

  // ─── FIRESTORE REAL-TIME LISTENERS ───────────────────────────
  useEffect(() => {
    // 1. Orders listener
    const qOrders = query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(200));
    const unsubOrders = onSnapshot(qOrders, (snap) => {
      const orders: OrderRecord[] = snap.docs.map(d => ({
        id: d.id,
        ...d.data(),
      } as OrderRecord));

      setRawOrders(orders);

      // Filter active orders (only non-cancelled, active outlets)
      const validOrders = orders.filter(o => o.status !== 'cancelled');
      setTotalOrders(validOrders.length);

      const active = validOrders.filter(o => ['pending', 'prep', 'ready'].includes(o.status)).length;
      setActiveQueue(active);
      setAvgWaitMinutes(Math.max(2, active * 2));

      const totalRev = validOrders.reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);
      setRevenue(totalRev);
    });

    // 2. Outlets listener
    const unsubOutlets = onSnapshot(collection(db, 'outlets'), (snap) => {
      setOutlets(snap.docs.map(d => ({ id: d.id, ...d.data() } as OutletItem)));
    });

    // 3. Time Slots listener
    const unsubSlots = onSnapshot(collection(db, 'time_slots'), (snap) => {
      const slots: TimeSlot[] = snap.docs.map(d => ({
        id: d.id,
        ...d.data(),
      } as TimeSlot));
      setTimeSlots(slots);
    });

    // 4. Approval Tickets listener
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
      unsubSlots();
      unsubMenu();
      if (unsubTickets) unsubTickets();
    };
  }, []);

  // ─── WORKING KITCHEN TIME TRACKER ───────────────────────────
  useEffect(() => {
    if (isTimerPlaying) {
      timerRef.current = setInterval(() => {
        setTimerSeconds(prev => {
          if (prev <= 1) {
            playChime();
            setDeviceToast('🔔 Dispatch Timer Elapsed: Next pickup wave ready!');
            return timerInitialSeconds;
          }
          return prev - 1;
        });
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

  // Play browser audio chime
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

  // ─── MONTH NAVIGATION ───────────────────────────────────────
  const handlePrevMonth = () => {
    setSelectedMonthDate(prev => new Date(prev.getFullYear(), prev.getMonth() - 1, 1));
  };

  const handleNextMonth = () => {
    setSelectedMonthDate(prev => new Date(prev.getFullYear(), prev.getMonth() + 1, 1));
  };

  const getMonthName = (date: Date, offset = 0) => {
    const d = new Date(date.getFullYear(), date.getMonth() + offset, 1);
    return d.toLocaleString('en-US', { month: 'long' });
  };

  const getFullMonthYear = (date: Date) => {
    return date.toLocaleString('en-US', { month: 'long', year: 'numeric' });
  };

  // Generate 7 days for the selected week around the selected date
  const generateDaysRow = () => {
    const curr = new Date(selectedMonthDate);
    const dayOfWeek = curr.getDay(); // 0 is Sunday
    const diffToMonday = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;
    const monday = new Date(curr);
    monday.setDate(curr.getDate() + diffToMonday);

    const days = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);
      const dayStr = d.toISOString().split('T')[0];
      const dayName = d.toLocaleString('en-US', { weekday: 'short' });
      const dayNum = d.getDate();
      days.push({
        dateStr: dayStr,
        label: `${dayName} ${dayNum}`,
        isToday: dayStr === new Date().toISOString().split('T')[0],
      });
    }
    return days;
  };

  const currentWeekDays = generateDaysRow();

  // ─── DAY-BY-DAY OPERATIONAL SCHEDULES (MON-SAT DISTINCT CAPACITIES & RUSHES) ──
  const dayNamesFull = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  const WEEKDAY_SCHEDULE_TEMPLATES: Record<number, {
    window: string;
    label: string;
    startTime: string;
    endTime: string;
    defaultCapacity: number;
    baseOrders: number;
    isPeak?: boolean;
  }[]> = {
    1: [ // Monday
      { window: '11:30 AM - 11:45 AM', label: 'Morning Kickstart Window', startTime: '11:30', endTime: '11:45', defaultCapacity: 25, baseOrders: 12 },
      { window: '12:30 PM - 12:45 PM', label: 'Lunch Rush Wave 1 (Fastest)', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 18, isPeak: true },
      { window: '12:45 PM - 01:00 PM', label: 'Lunch Pre-Order Wave 2', startTime: '12:45', endTime: '13:00', defaultCapacity: 20, baseOrders: 14 },
      { window: '01:00 PM - 01:15 PM', label: 'Afternoon Wave 1', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 7 },
      { window: '04:30 PM - 04:45 PM', label: 'Evening Chai & Snack Rush', startTime: '16:30', endTime: '16:45', defaultCapacity: 25, baseOrders: 11 },
    ],
    2: [ // Tuesday
      { window: '11:30 AM - 11:45 AM', label: 'Morning Beverage & Puff Window', startTime: '11:30', endTime: '11:45', defaultCapacity: 25, baseOrders: 9 },
      { window: '12:30 PM - 12:45 PM', label: 'Lunch Pre-Order Dispatch Window', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 16, isPeak: true },
      { window: '12:45 PM - 01:00 PM', label: 'Afternoon Wave 1', startTime: '12:45', endTime: '13:00', defaultCapacity: 20, baseOrders: 11 },
      { window: '01:00 PM - 01:15 PM', label: 'Afternoon Wave 2', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 5 },
      { window: '05:00 PM - 05:15 PM', label: 'Campus Evening Quick-Bite', startTime: '17:00', endTime: '17:15', defaultCapacity: 25, baseOrders: 8 },
    ],
    3: [ // Wednesday (Midweek peak)
      { window: '11:30 AM - 11:45 AM', label: 'Midweek Breakfast & Juice Rush', startTime: '11:30', endTime: '11:45', defaultCapacity: 25, baseOrders: 16 },
      { window: '12:30 PM - 12:45 PM', label: 'Midweek Peak Lunch Dispatch', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 20, isPeak: true },
      { window: '12:45 PM - 01:00 PM', label: 'Lunch Wave 2', startTime: '12:45', endTime: '13:00', defaultCapacity: 20, baseOrders: 17 },
      { window: '01:00 PM - 01:15 PM', label: 'Afternoon Dispatch', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 10 },
      { window: '04:45 PM - 05:00 PM', label: 'Evening Refreshment Wave', startTime: '16:45', endTime: '17:00', defaultCapacity: 25, baseOrders: 14 },
    ],
    4: [ // Thursday
      { window: '11:30 AM - 11:45 AM', label: 'Morning Dispatch Window', startTime: '11:30', endTime: '11:45', defaultCapacity: 25, baseOrders: 11 },
      { window: '12:30 PM - 12:45 PM', label: 'Lunch Pre-Order Dispatch (Peak)', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 19, isPeak: true },
      { window: '12:45 PM - 01:00 PM', label: 'Afternoon Wave 1', startTime: '12:45', endTime: '13:00', defaultCapacity: 20, baseOrders: 13 },
      { window: '01:00 PM - 01:15 PM', label: 'Afternoon Wave 2', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 6 },
      { window: '05:15 PM - 05:30 PM', label: 'Evening Campus Rush', startTime: '17:15', endTime: '17:30', defaultCapacity: 25, baseOrders: 12 },
    ],
    5: [ // Friday (Weekend Eve Bonanza)
      { window: '11:30 AM - 11:45 AM', label: 'Friday Brunch Window', startTime: '11:30', endTime: '11:45', defaultCapacity: 25, baseOrders: 15 },
      { window: '12:30 PM - 12:45 PM', label: 'Friday Big Lunch Wave', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 19, isPeak: true },
      { window: '12:45 PM - 01:00 PM', label: 'Lunch Wave 2', startTime: '12:45', endTime: '13:00', defaultCapacity: 20, baseOrders: 16 },
      { window: '01:00 PM - 01:15 PM', label: 'Afternoon Wave', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 12 },
      { window: '04:00 PM - 04:30 PM', label: 'Weekend Eve Snack Bonanza', startTime: '16:00', endTime: '16:30', defaultCapacity: 25, baseOrders: 23, isPeak: true },
    ],
    6: [ // Saturday
      { window: '12:00 PM - 12:15 PM', label: 'Weekend Special Brunch Window', startTime: '12:00', endTime: '12:15', defaultCapacity: 20, baseOrders: 8 },
      { window: '01:00 PM - 01:15 PM', label: 'Weekend Lunch Dispatch', startTime: '13:00', endTime: '13:15', defaultCapacity: 20, baseOrders: 14, isPeak: true },
      { window: '02:00 PM - 02:15 PM', label: 'Afternoon Leisure Wave', startTime: '14:00', endTime: '14:15', defaultCapacity: 20, baseOrders: 6 },
      { window: '05:30 PM - 05:45 PM', label: 'Evening Campus Hangout Window', startTime: '17:30', endTime: '17:45', defaultCapacity: 25, baseOrders: 15 },
    ],
    0: [ // Sunday
      { window: '12:30 PM - 12:45 PM', label: 'Sunday Special Lunch Pre-Order', startTime: '12:30', endTime: '12:45', defaultCapacity: 20, baseOrders: 7 },
      { window: '01:30 PM - 01:45 PM', label: 'Sunday Afternoon Wave', startTime: '13:30', endTime: '13:45', defaultCapacity: 20, baseOrders: 5 },
      { window: '06:00 PM - 06:15 PM', label: 'Sunday Night Pre-Order Dispatch', startTime: '18:00', endTime: '18:15', defaultCapacity: 25, baseOrders: 10 },
    ],
  };

  // Helper: Get day of week index from YYYY-MM-DD
  const getDayOfWeek = (dateStr: string) => {
    const parts = dateStr.split('-');
    if (parts.length === 3) {
      const d = new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2]));
      return d.getDay();
    }
    return new Date().getDay();
  };

  // Build the day's active slots with unique values and order counts
  const currentDayOfWeekIdx = getDayOfWeek(selectedDateStr);
  const currentDayTemplate = WEEKDAY_SCHEDULE_TEMPLATES[currentDayOfWeekIdx] || WEEKDAY_SCHEDULE_TEMPLATES[1];

  // If timeSlots exist in Firestore, prioritize them; otherwise use the day's distinct schedule with 100% real order counts
  const activeDaySlots = (timeSlots.length > 0
    ? timeSlots.map((ts) => {
        const capacity = slotCapacityOverrides[ts.id] || ts.capacity || 20;
        const realCount = rawOrders.filter(o => o.pickupSlot === ts.window).length;
        return {
          id: ts.id,
          window: ts.window,
          label: ts.label,
          startTime: ts.startTime || '12:00',
          endTime: ts.endTime || '12:15',
          capacity,
          ordersCount: realCount,
          outletName: ts.outletName || (outlets.find(o => o.id === ts.outletId)?.name || 'Campus Stall'),
          isPeak: realCount >= (capacity * 0.75),
        };
      })
    : currentDayTemplate.map((tpl) => {
        const slotKey = `${selectedDateStr}_${tpl.startTime.replace(':', '')}`;
        const capacity = slotCapacityOverrides[slotKey] || tpl.defaultCapacity;
        // Count real orders matched to this slot window
        const realCount = rawOrders.filter(o => o.pickupSlot === tpl.window).length;

        return {
          id: slotKey,
          window: tpl.window,
          label: tpl.label,
          startTime: tpl.startTime,
          endTime: tpl.endTime,
          capacity,
          ordersCount: realCount,
          outletName: outlets[0]?.name || 'Campus Stall',
          isPeak: tpl.isPeak || realCount >= (capacity * 0.75),
        };
      })
  );

  const totalDayOrders = activeDaySlots.reduce((sum, s) => sum + s.ordersCount, 0);

  // ─── DATE-AWARE SLOT STATUS HELPER ──────────────────────────
  const getSlotStatus = (slot: { startTime: string; endTime: string }) => {
    const now = new Date();
    const todayStr = now.toISOString().split('T')[0];

    if (selectedDateStr < todayStr) return 'closed';
    if (selectedDateStr > todayStr) return 'upcoming';

    if (!slot.startTime || !slot.endTime) return 'upcoming';
    const currentMin = now.getHours() * 60 + now.getMinutes();

    const [startH, startM] = slot.startTime.split(':').map(Number);
    const [endH, endM] = slot.endTime.split(':').map(Number);
    const slotStart = (startH || 0) * 60 + (startM || 0);
    const slotEnd = (endH || 0) * 60 + (endM || 0);

    if (currentMin >= slotStart && currentMin <= slotEnd) return 'live';
    if (currentMin < slotStart) return 'upcoming';
    return 'closed';
  };

  // ─── SLOT ACTIONS: ADJUST CAPACITY & DELETE ──────────────────
  const handleAdjustCapacity = async (slotId: string, currentCap: number, delta: number) => {
    const newCap = Math.max(5, currentCap + delta);
    setSlotCapacityOverrides(prev => ({ ...prev, [slotId]: newCap }));
    if (selectedSlotForModal && selectedSlotForModal.id === slotId) {
      setSelectedSlotForModal((prev: any) => prev ? { ...prev, capacity: newCap } : null);
    }
    try {
      await updateDoc(doc(db, 'time_slots', slotId), { capacity: newCap });
    } catch (_) {}
  };

  const handleDeleteSlot = async (slotId: string) => {
    if (!window.confirm('Delete this pickup slot?')) return;
    try {
      await deleteDoc(doc(db, 'time_slots', slotId));
      setSelectedSlotForModal(null);
    } catch (e) {
      console.error('Error deleting slot:', e);
      alert('Failed to delete slot: ' + e);
    }
  };

  const getOrdersForModal = (slot: any) => {
    if (!slot) return [];
    const real = rawOrders.filter(o => o.pickupSlot === slot.window);
    return real.map(o => ({
      id: o.id,
      token: o.token || o.id.slice(0, 5).toUpperCase(),
      customerName: o.customerName || 'Campus Customer',
      summary: o.items && o.items.length > 0 ? o.items.map((it: any) => `${it.quantity || 1}x ${it.name}`).join(', ') : 'Campus Pre-Order',
      total: o.totalAmount || 50,
      status: o.status,
    }));
  };

  const handleAddSlotSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newSlotWindow.trim() || !newSlotLabel.trim()) return;

    setIsSubmittingSlot(true);
    try {
      const outlet = outlets.find(o => o.id === newSlotOutletId) || outlets[0];
      await addDoc(collection(db, 'time_slots'), {
        outletId: newSlotOutletId,
        outletName: outlet ? outlet.name : `Outlet ${newSlotOutletId}`,
        window: newSlotWindow.trim(),
        label: newSlotLabel.trim(),
        startTime: newSlotStartTime,
        endTime: newSlotEndTime,
        capacity: parseInt(newSlotCapacity) || 20,
        currentOrders: 0,
        isActive: true,
        createdAt: serverTimestamp(),
      });
      setIsAddSlotModalOpen(false);
      setNewSlotWindow('');
      setNewSlotLabel('');
    } catch (e) {
      console.error('Error adding slot:', e);
      alert('Failed to add slot: ' + e);
    } finally {
      setIsSubmittingSlot(false);
    }
  };

  // ─── ORDER VELOCITY METRICS & BAR CHART CALCULATION ─────────
  const weeklyDayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  const weeklyCounts = [0, 0, 0, 0, 0, 0, 0];

  rawOrders.forEach(o => {
    if (o.status !== 'cancelled' && o.createdAt) {
      let d: Date | null = null;
      if (typeof o.createdAt.toDate === 'function') {
        d = o.createdAt.toDate();
      } else if (o.createdAt.seconds) {
        d = new Date(o.createdAt.seconds * 1000);
      } else {
        d = new Date(o.createdAt);
      }
      if (d && !isNaN(d.getTime())) {
        weeklyCounts[d.getDay()] += 1;
      }
    }
  });

  // Calculate realistic peak day
  const maxWeeklyCount = Math.max(...weeklyCounts, 1);
  const peakDayIdx = weeklyCounts.indexOf(Math.max(...weeklyCounts));
  const velocityPerHour = Math.max(1, activeQueue * 2 + Math.min(weeklyCounts[new Date().getDay()], 15));

  // ─── OUTLET STATUS TOGGLE ────────────────────────────────────
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

  // ─── ADD NEW OUTLET ──────────────────────────────────────────
  const handleAddOutlet = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newOutletName.trim()) return;

    setIsSubmittingOutlet(true);
    try {
      const targetId = newOutletId.trim() || newOutletName.toLowerCase().replace(/[^a-z0-9]/g, '_');
      const outletData = {
        name: newOutletName.trim(),
        isOpen: true,
        queueCount: 0,
        waitTime: newOutletWait || '2-5 mins',
        upiId: newOutletUpi || '7310347742@nyes',
        createdAt: serverTimestamp(),
      };

      if (newOutletId.trim()) {
        await setDoc(doc(db, 'outlets', targetId), outletData);
      } else {
        await addDoc(collection(db, 'outlets'), outletData);
      }

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

  // ─── EDIT OUTLET DETAILS ─────────────────────────────────────
  const openEditOutletModal = (o: OutletItem) => {
    setEditingOutlet(o);
    setEditOutletName(o.name);
    setEditOutletWait(o.waitTime || '2-5 mins');
    setEditOutletUpi(o.upiId || '7310347742@nyes');
  };

  const handleSaveOutletEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingOutlet || !editOutletName.trim()) return;

    setIsSubmittingOutletEdit(true);
    try {
      await updateDoc(doc(db, 'outlets', editingOutlet.id), {
        name: editOutletName.trim(),
        waitTime: editOutletWait.trim() || '2-5 mins',
        upiId: editOutletUpi.trim(),
      });
      setEditingOutlet(null);
    } catch (e) {
      console.error('Error updating outlet:', e);
      alert('Failed to update stall details: ' + e);
    } finally {
      setIsSubmittingOutletEdit(false);
    }
  };

  const handleDeleteOutlet = async (outletId: string, outletName: string) => {
    if (!window.confirm(`Permanently delete stall "${outletName}"? This cannot be undone.`)) return;
    try {
      await deleteDoc(doc(db, 'outlets', outletId));
    } catch (e) {
      console.error('Error deleting outlet:', e);
      alert('Failed to delete stall: ' + e);
    }
  };

  const handleResetCanonicalOutlets = async () => {
    if (!window.confirm("Purge deprecated test outlets and restore canonical campus stalls (Nescafe Center, Campus Canteen, Juice Bar)?")) return;
    try {
      for (const o of outlets) {
        if (!['o1', 'o2', 'o3'].includes(o.id)) {
          try {
            await deleteDoc(doc(db, 'outlets', o.id));
          } catch (_) {}
        }
      }
      const canonicals = [
        { id: 'o1', name: 'Nescafe Center', isOpen: true, queueCount: 0, waitTime: 'No wait', upiId: '7310347742@nyes' },
        { id: 'o2', name: 'Campus Canteen', isOpen: true, queueCount: 0, waitTime: 'No wait', upiId: '7310347742@nyes' },
        { id: 'o3', name: 'Juice Bar', isOpen: false, queueCount: 0, waitTime: 'Closed', upiId: '7310347742@nyes' },
      ];
      for (const c of canonicals) {
        await setDoc(doc(db, 'outlets', c.id), c, { merge: true });
      }
      alert('Canonical campus stalls restored successfully! ✓');
    } catch (e) {
      console.error('Failed to reset stalls:', e);
      alert('Failed to reset stalls: ' + e);
    }
  };

  // ─── SAVE UPI ────────────────────────────────────────────────
  const handleSaveUpi = async () => {
    if (!editingUpiOutlet || !editUpiValue.trim()) return;
    try {
      await updateDoc(doc(db, 'outlets', editingUpiOutlet.id), {
        upiId: editUpiValue.trim(),
      });
      setEditingUpiOutlet(null);
    } catch (e) {
      console.error('Error updating UPI:', e);
      alert('Failed to update UPI ID');
    }
  };

  const copyToClipboard = (text: string, id: string) => {
    navigator.clipboard.writeText(text);
    setCopiedUpiId(id);
    setTimeout(() => setCopiedUpiId(null), 2000);
  };

  // ─── QUICK APPROVE TICKET ────────────────────────────────────
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
          ...ticket.itemData,
          outletId: ticket.outletId,
          outletName: ticket.outletName,
          isAvailable: true,
          isApproved: true,
          approvalStatus: 'approved',
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

  // ─── APPROVE ALL TICKETS ────────────────────────────────────
  const handleApproveAll = async () => {
    if (pendingTickets.length === 0) return;
    if (!window.confirm(`Approve all ${pendingTickets.length} pending items to the live menu?`)) return;

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

  return (
    <div className="space-y-6">
      {/* ─── TOAST NOTIFICATION ─── */}
      <AnimatePresence>
        {deviceToast && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            className="fixed top-5 right-5 z-50 bg-[#18181B] text-[#FACC15] px-4 py-3 rounded-2xl shadow-2xl border border-stone-800 text-xs font-bold flex items-center gap-2"
          >
            <span>{deviceToast}</span>
            <button
              onClick={() => setDeviceToast(null)}
              className="ml-2 text-stone-400 hover:text-white"
            >
              <X size={12} />
            </button>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ─── HERO HEADER & HIGH-LEVEL RATIOS ─── */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6 pt-1">
        <div className="space-y-3">
          <h1 className="text-3xl sm:text-4xl font-normal tracking-tight text-stone-900">
            Welcome in, <span className="font-semibold text-black">AuraBake</span>
          </h1>

          <div className="flex items-center gap-2 flex-wrap text-[11px] font-bold">
            <Link
              to="/approvals"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-[#18181B] hover:bg-black text-white rounded-full shadow-xs transition-colors"
            >
              <span>Approvals</span>
              <span className="text-[#FACC15]">{pendingTickets.length} pending</span>
            </Link>

            <Link
              to="/menu"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-stone-100 hover:bg-stone-200 text-stone-700 rounded-full transition-colors"
            >
              <span>Catalog</span>
              <span className="text-stone-900 font-extrabold">{outlets.length} Outlets</span>
            </Link>

            <Link
              to="/queue"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-amber-50 hover:bg-amber-100 text-amber-900 rounded-full border border-amber-200/60 transition-colors"
            >
              <Clock size={11} className="text-amber-700" />
              <span>Wait ~{avgWaitMinutes}m</span>
            </Link>

            <Link
              to="/queue"
              className="flex items-center gap-1.5 px-3.5 py-1.5 bg-stone-100 hover:bg-stone-200 text-stone-700 rounded-full transition-colors"
            >
              <span>Total Orders</span>
              <span className="text-stone-900 font-extrabold">{totalOrders}</span>
            </Link>
          </div>
        </div>

        {/* Global Rush Mode Toggle */}
        <div className="flex items-center gap-3 bg-white px-4 py-2.5 rounded-full border border-[#E9DFCB] shadow-xs self-start lg:self-auto">
          <div className="flex items-center gap-2">
            <span className={`w-2.5 h-2.5 rounded-full ${isRushMode ? 'bg-[#FACC15] animate-ping' : 'bg-emerald-500'}`} />
            <span className="text-xs font-bold text-stone-800">
              {isRushMode ? 'Rush Mode Active ⚡' : 'Normal Flow 🟢'}
            </span>
          </div>
          <button
            onClick={() => setIsRushMode(!isRushMode)}
            className={`relative inline-flex h-5 w-9 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out ${
              isRushMode ? 'bg-[#18181B]' : 'bg-stone-200'
            }`}
          >
            <span
              className={`pointer-events-none inline-block h-4 w-4 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                isRushMode ? 'translate-x-4' : 'translate-x-0'
              }`}
            />
          </button>
        </div>
      </div>

      {/* ─── CREXTIO BENTO GRID LAYOUT ─── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 items-start">
        
        {/* ── LEFT COLUMN (SPAN 3) ── */}
        <div className="lg:col-span-3 space-y-5">
          {/* Card A: Gross Revenue Card */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            className="bg-white rounded-[30px] p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)]"
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-stone-500">Live Campus Revenue</span>
              <Link to="/analytics" className="w-6 h-6 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600 transition-colors">
                <ArrowUpRight size={13} />
              </Link>
            </div>

            <div className="mt-4">
              <div className="flex items-baseline gap-1">
                <span className="text-3xl sm:text-4xl font-normal tracking-tight text-stone-900">
                  ₹{revenue.toLocaleString('en-IN')}
                </span>
                <span className="text-xs font-extrabold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full ml-1">
                  +18.4%
                </span>
              </div>
              <p className="text-[11px] text-stone-400 mt-1">Settled & in-kitchen orders</p>
            </div>
          </motion.div>

          {/* Card B: Left Control Accordions */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.1 }}
            className="bg-white rounded-[30px] p-5 sm:p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] space-y-4"
          >
            {/* Campus Outlets Accordion */}
            <div className="border-b border-stone-100 pb-3">
              <div className="flex items-center justify-between">
                <button
                  onClick={() => setExpandedSection(expandedSection === 'outlets' ? null : 'outlets')}
                  className="flex items-center gap-1.5 text-xs font-bold text-stone-900 text-left"
                >
                  <span>Campus Outlets ({outlets.length})</span>
                  {expandedSection === 'outlets' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
                </button>
                <button
                  onClick={() => setIsAddOutletModalOpen(true)}
                  className="w-5 h-5 rounded-full bg-stone-900 hover:bg-black text-[#FACC15] flex items-center justify-center text-xs shadow-xs"
                  title="Add Stall"
                >
                  <Plus size={11} />
                </button>
              </div>

              {expandedSection === 'outlets' && (
                <div className="mt-3 space-y-2.5">
                  {outlets.length === 0 ? (
                    <p className="text-[11px] text-stone-400 py-2">No active stalls found.</p>
                  ) : (
                    outlets.map((outlet) => (
                      <div
                        key={outlet.id}
                        className="p-2.5 bg-stone-50 rounded-2xl border border-stone-100 flex items-center justify-between"
                      >
                        <div className="flex-1 pr-2">
                          <p className="text-xs font-bold text-stone-900 truncate">{outlet.name}</p>
                          <p className="text-[10px] text-stone-400">
                            Queue: {outlet.queueCount || 0} • {outlet.waitTime || '2-5 mins'}
                          </p>
                        </div>

                        <div className="flex items-center gap-1.5 shrink-0">
                          <button
                            onClick={() => openEditOutletModal(outlet)}
                            className="w-6 h-6 rounded-full bg-white border border-stone-200 flex items-center justify-center text-stone-500 hover:text-stone-900 shadow-2xs"
                            title="Edit Stall"
                          >
                            <Edit2 size={11} />
                          </button>

                          <button
                            onClick={() => handleDeleteOutlet(outlet.id, outlet.name)}
                            className="w-6 h-6 rounded-full bg-white border border-stone-200 flex items-center justify-center text-stone-400 hover:text-red-600 shadow-2xs"
                            title="Delete Stall"
                          >
                            <Trash2 size={11} />
                          </button>

                          <button
                            onClick={() => toggleOutletStatus(outlet.id, outlet.isOpen !== false)}
                            className={`relative inline-flex h-4 w-7 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out ${
                              outlet.isOpen !== false ? 'bg-emerald-500' : 'bg-stone-300'
                            }`}
                            title={outlet.isOpen !== false ? 'Stall Open' : 'Stall Closed'}
                          >
                            <span
                              className={`pointer-events-none inline-block h-3 w-3 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${
                                outlet.isOpen !== false ? 'translate-x-3' : 'translate-x-0'
                              }`}
                            />
                          </button>
                        </div>
                      </div>
                    ))
                  )}

                  <button
                    onClick={handleResetCanonicalOutlets}
                    className="w-full py-2 px-3 mt-1 rounded-xl bg-stone-100 hover:bg-stone-200 text-stone-700 hover:text-stone-900 text-[10px] font-bold transition-colors flex items-center justify-center gap-1.5 border border-stone-200/60"
                    title="Clean up test stalls and ensure canonical stalls (Nescafe, Canteen, Juice Bar) are active"
                  >
                    <RotateCcw size={11} className="text-stone-500" />
                    <span>Restore Canonical Stalls / Purge Legacy</span>
                  </button>
                </div>
              )}
            </div>

            {/* Payment Terminals (UPI) */}
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
                        <p className="font-mono text-stone-400 text-[10px]">{o.upiId || '7310347742@nyes'}</p>
                      </div>
                      <div className="flex items-center gap-1">
                        <button
                          onClick={() => copyToClipboard(o.upiId || '7310347742@nyes', o.id)}
                          className="w-6 h-6 rounded-full bg-white border border-stone-200 flex items-center justify-center text-stone-600 hover:text-stone-900"
                          title="Copy UPI ID"
                        >
                          {copiedUpiId === o.id ? <Check size={11} className="text-emerald-600" /> : <Copy size={11} />}
                        </button>
                        <button
                          onClick={() => {
                            setEditingUpiOutlet(o);
                            setEditUpiValue(o.upiId || '7310347742@nyes');
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

            {/* Pickup Slot Windows (Connected to Firestore) */}
            <div className="border-b border-stone-100 pb-3">
              <button
                onClick={() => setExpandedSection(expandedSection === 'slots' ? null : 'slots')}
                className="w-full flex items-center justify-between text-left"
              >
                <div className="flex items-center gap-1.5">
                  <span className="text-xs font-bold text-stone-900">Pickup Slot Windows</span>
                  <span className="text-[10px] px-1.5 py-0.2 bg-stone-100 rounded-full font-bold text-stone-600">
                    {timeSlots.length}
                  </span>
                </div>
                {expandedSection === 'slots' ? <ChevronUp size={14} className="text-stone-400" /> : <ChevronDown size={14} className="text-stone-400" />}
              </button>

              {expandedSection === 'slots' && (
                <div className="mt-2.5 space-y-2 text-[11px] text-stone-600">
                  {timeSlots.map(slot => (
                    <div key={slot.id} className="flex items-center justify-between p-2 rounded-xl bg-stone-50 border border-stone-100">
                      <div>
                        <p className="font-bold text-stone-800 text-[11px]">{slot.window}</p>
                        <p className="text-[9px] text-stone-400">{slot.label}</p>
                      </div>
                      <div className="flex items-center gap-1.5 font-bold">
                        <button
                          onClick={() => handleAdjustCapacity(slot.id, slot.capacity, -5)}
                          className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center hover:bg-stone-100"
                          title="Reduce Capacity (-5)"
                        >
                          -
                        </button>
                        <span className="w-6 text-center">{slot.capacity}</span>
                        <button
                          onClick={() => handleAdjustCapacity(slot.id, slot.capacity, 5)}
                          className="w-5 h-5 rounded-md bg-white border border-stone-200 text-stone-700 flex items-center justify-center hover:bg-stone-100"
                          title="Increase Capacity (+5)"
                        >
                          +
                        </button>
                      </div>
                    </div>
                  ))}

                  <button
                    onClick={() => setIsAddSlotModalOpen(true)}
                    className="w-full py-1.5 rounded-xl border border-dashed border-stone-300 hover:border-stone-400 text-stone-600 text-[10px] font-bold flex items-center justify-center gap-1 mt-1 transition-colors"
                  >
                    <Plus size={11} /> Add New Slot
                  </button>
                </div>
              )}
            </div>

            {/* Devices & Kitchen Hardware */}
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
                  {/* Phone */}
                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Smartphone size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Baker Queue Display</p>
                        <p className="text-[9px] text-stone-400">Nothing Phone (Connected)</p>
                      </div>
                    </div>
                    <button
                      onClick={() => {
                        setDeviceStatuses(p => ({ ...p, dev1: !p.dev1 }));
                        setDeviceToast(`Baker Phone set to ${!deviceStatuses.dev1 ? 'Online 🟢' : 'Standby 🟡'}`);
                      }}
                      className={`w-2.5 h-2.5 rounded-full transition-colors ${deviceStatuses.dev1 ? 'bg-emerald-500' : 'bg-amber-400'}`}
                      title="Toggle Connection"
                    />
                  </div>

                  {/* Printer */}
                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Printer size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Receipt Printer</p>
                        <p className="text-[9px] text-stone-400">Epson TM-T82 (Ready)</p>
                      </div>
                    </div>
                    <button
                      onClick={() => setDeviceToast('🖨️ Test Receipt Sent: Order #2000 - Samosa x2 - ₹50 printed!')}
                      className="px-2 py-0.5 rounded-full bg-white border border-stone-200 text-[9px] font-bold text-stone-700 hover:bg-stone-100"
                    >
                      Test
                    </button>
                  </div>

                  {/* Audio */}
                  <div className="p-2 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Volume2 size={14} className="text-stone-500" />
                      <div>
                        <p className="font-bold text-[11px] text-stone-900">Counter Audio Chime</p>
                        <p className="text-[9px] text-stone-400">Web audio alerts active</p>
                      </div>
                    </div>
                    <button
                      onClick={() => {
                        playChime();
                        setDeviceToast('🔊 Audio Chime Tested Successfully!');
                      }}
                      className="px-2 py-0.5 rounded-full bg-white border border-stone-200 text-[9px] font-bold text-stone-700 hover:bg-stone-100"
                    >
                      Ping
                    </button>
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
            {/* Card C: Order Velocity Bar Chart (Real dynamic orders) */}
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
                    {velocityPerHour}
                  </span>
                  <span className="text-xs text-stone-400 font-medium">Orders / hour</span>
                </div>
              </div>

              {/* Dynamic Bar Chart Sunday-Saturday */}
              <div className="mt-6 pt-2">
                <div className="flex items-end justify-between h-28 gap-2 relative">
                  {/* Floating Rush Tag on active peak bar */}
                  <div
                    className="absolute -top-3 bg-[#FACC15] text-stone-950 font-extrabold text-[9px] px-2 py-0.5 rounded-full shadow-xs"
                    style={{ left: `${(peakDayIdx / 7) * 100}%` }}
                  >
                    Peak {weeklyCounts[peakDayIdx]}
                  </div>

                  {weeklyDayLabels.map((label, idx) => {
                    const count = weeklyCounts[idx];
                    const isPeak = idx === peakDayIdx;
                    const heightPercent = Math.max(16, Math.round((count / maxWeeklyCount) * 100));

                    return (
                      <div key={idx} className="flex-1 flex flex-col items-center gap-2">
                        <div className="w-full flex justify-center items-end h-20">
                          <div
                            style={{ height: `${heightPercent}%` }}
                            className={`w-3.5 rounded-full transition-all duration-300 ${
                              isPeak ? 'bg-[#FACC15] shadow-sm' : 'bg-stone-900 hover:bg-stone-700'
                            }`}
                            title={`${label}: ${count} orders`}
                          />
                        </div>
                        <span className="text-[10px] font-bold text-stone-400">{label}</span>
                      </div>
                    );
                  })}
                </div>
              </div>
            </motion.div>

            {/* Card D: Kitchen Rush Time Tracker Dial */}
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

                {/* Quick Preset Pills (Dynamic Active State) */}
                <div className="flex items-center gap-1.5 text-[9px] font-bold">
                  {[
                    { label: '2m', secs: 120 },
                    { label: '2:35', secs: 155 },
                    { label: '5m', secs: 300 },
                  ].map(p => (
                    <button
                      key={p.label}
                      onClick={() => setTimerPreset(p.secs)}
                      className={`px-2 py-0.5 rounded-full transition-all ${
                        timerInitialSeconds === p.secs
                          ? 'bg-[#FACC15] text-stone-950 font-black shadow-xs'
                          : 'bg-stone-100 hover:bg-stone-200 text-stone-600'
                      }`}
                    >
                      {p.label}
                    </button>
                  ))}
                  <button
                    onClick={() => setTimerSeconds(s => Math.max(10, s - 30))}
                    className="px-1.5 py-0.5 rounded bg-stone-100 hover:bg-stone-200 text-stone-500"
                    title="Decrease 30s"
                  >
                    -30s
                  </button>
                  <button
                    onClick={() => setTimerSeconds(s => s + 30)}
                    className="px-1.5 py-0.5 rounded bg-stone-100 hover:bg-stone-200 text-stone-500"
                    title="Increase 30s"
                  >
                    +30s
                  </button>
                </div>
              </div>
            </motion.div>
          </div>

          {/* Card E: Live Schedule & Dispatch Matrix (Real Dynamic Firestore Data) */}
          <motion.div
            initial={{ opacity: 0, y: 15 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 }}
            className="bg-white rounded-[30px] p-6 border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)]"
          >
            {/* Dynamic Month Strip with Working Navigation */}
            <div className="flex items-center justify-between text-xs font-bold text-stone-400 border-b border-stone-100 pb-3">
              <button
                onClick={handlePrevMonth}
                className="flex items-center gap-1 text-stone-500 hover:text-stone-900 px-2 py-1 rounded-lg hover:bg-stone-50 transition-colors"
              >
                <ChevronLeft size={13} />
                <span>{getMonthName(selectedMonthDate, -1)}</span>
              </button>

              <div className="flex items-center gap-2">
                <Calendar size={13} className="text-[#EAB308]" />
                <span className="text-stone-900 font-extrabold text-sm">
                  {getFullMonthYear(selectedMonthDate)}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={handleNextMonth}
                  className="flex items-center gap-1 text-stone-500 hover:text-stone-900 px-2 py-1 rounded-lg hover:bg-stone-50 transition-colors"
                >
                  <span>{getMonthName(selectedMonthDate, 1)}</span>
                  <ChevronRight size={13} />
                </button>

                <button
                  onClick={() => setIsAddSlotModalOpen(true)}
                  className="hidden sm:inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-[10px] font-bold shadow-xs transition-transform hover:scale-105"
                >
                  <Plus size={11} /> Add Slot
                </button>
              </div>
            </div>

            {/* Clickable Days Row (Dynamic Current Week) */}
            <div className="grid grid-cols-7 gap-1.5 text-center text-xs font-bold py-3 border-b border-stone-100">
              {currentWeekDays.map((day, idx) => {
                const isSelected = selectedDateStr === day.dateStr;
                return (
                  <button
                    key={idx}
                    onClick={() => setSelectedDateStr(day.dateStr)}
                    className={`py-1.5 rounded-xl transition-all relative ${
                      isSelected
                        ? 'bg-[#18181B] text-white shadow-xs'
                        : 'text-stone-500 hover:text-stone-900 hover:bg-stone-50'
                    }`}
                  >
                    <span>{day.label}</span>
                    {day.isToday && !isSelected && (
                      <span className="absolute bottom-1 left-1/2 -translate-x-1/2 w-1 h-1 rounded-full bg-[#EAB308]" />
                    )}
                  </button>
                );
              })}
            </div>

            {/* Day Header with Order Total & Peak Indicator */}
            <div className="flex items-center justify-between px-1 pt-3 pb-1 border-b border-stone-100/80">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-stone-900">
                  {dayNamesFull[currentDayOfWeekIdx]} Dispatch Matrix
                </span>
                {currentDayOfWeekIdx === 3 && (
                  <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-900 text-[10px] font-extrabold">
                    ⚡ Midweek Peak Rush
                  </span>
                )}
                {currentDayOfWeekIdx === 5 && (
                  <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-900 text-[10px] font-extrabold">
                    🎉 Weekend Eve Bonanza
                  </span>
                )}
              </div>
              <span className="text-[11px] font-bold text-stone-500">
                {totalDayOrders} Pre-Orders Scheduled
              </span>
            </div>

            {/* Dynamic Time Slot Dispatch Blocks for the Selected Day */}
            <div className="mt-4 space-y-3">
              {activeDaySlots.map(slot => {
                const status = getSlotStatus(slot);
                const isLive = status === 'live';

                return (
                  <div key={slot.id} className="flex items-start gap-4 text-xs">
                    <span className="text-stone-400 w-16 pt-2 font-semibold">
                      {slot.startTime || slot.window.split(' ')[0]}
                    </span>

                    <div
                      onClick={() => setSelectedSlotForModal(slot)}
                      className={`flex-1 p-3.5 rounded-2xl cursor-pointer transition-all border ${
                        isLive
                          ? 'bg-[#FAF6EE] border-[#E7DFCE] text-stone-900 hover:shadow-sm'
                          : 'bg-[#18181B] border-stone-800 text-white hover:bg-black'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div>
                          <div className="flex items-center gap-2">
                            <p className="font-bold text-xs">{slot.label}</p>
                            {slot.isPeak && (
                              <span className="px-1.5 py-0.2 rounded bg-amber-400/20 text-amber-300 text-[9px] font-bold">
                                PEAK
                              </span>
                            )}
                          </div>
                          <p className={`text-[10px] mt-0.5 ${isLive ? 'text-stone-500' : 'text-stone-400'}`}>
                            {slot.outletName} • Slot Capacity {slot.ordersCount}/{slot.capacity}
                          </p>
                        </div>

                        <div className="flex items-center gap-2">
                          {isLive ? (
                            <span className="px-2.5 py-0.5 rounded-full bg-[#FACC15] text-[10px] font-extrabold text-stone-950 animate-pulse">
                              Live Now
                            </span>
                          ) : (
                            <span className="px-2 py-0.5 rounded-full bg-stone-800 text-[10px] font-bold text-stone-400">
                              {status === 'closed' ? 'Passed' : 'Upcoming'}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          </motion.div>
        </div>

        {/* ── RIGHT COLUMN (SPAN 3) ── */}
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
                    {pendingTickets.length}
                  </span>
                </div>
              </div>

              {/* Segmented Ratio Bar */}
              <div className="my-3 flex gap-1.5 h-2">
                <div className="w-[35%] bg-[#FACC15] rounded-full" />
                <div className="w-[25%] bg-stone-700 rounded-full" />
                <div className="w-[40%] bg-stone-800 rounded-full" />
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

      {/* ─── MODAL: SLOT DETAILS & CAPACITY MANAGEMENT ─── */}
      <AnimatePresence>
        {selectedSlotForModal && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">{selectedSlotForModal.label}</h3>
                  <p className="text-xs text-stone-500">{selectedSlotForModal.window} • {selectedSlotForModal.outletName || 'Outlet 2000'}</p>
                </div>
                <button
                  onClick={() => setSelectedSlotForModal(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              {/* Slot Capacity Control */}
              <div className="p-4 bg-stone-50 rounded-2xl border border-stone-100 flex items-center justify-between">
                <div>
                  <p className="text-xs font-bold text-stone-900">Slot Pre-Order Capacity</p>
                  <p className="text-[10px] text-stone-500">Max concurrent orders accepted</p>
                </div>
                <div className="flex items-center gap-2">
                  <button
                    onClick={() => handleAdjustCapacity(selectedSlotForModal.id, selectedSlotForModal.capacity, -5)}
                    className="w-8 h-8 rounded-full bg-white border border-stone-200 text-stone-900 font-bold flex items-center justify-center hover:bg-stone-100"
                  >
                    -
                  </button>
                  <span className="w-8 text-center font-bold text-base text-stone-900">
                    {selectedSlotForModal.capacity}
                  </span>
                  <button
                    onClick={() => handleAdjustCapacity(selectedSlotForModal.id, selectedSlotForModal.capacity, 5)}
                    className="w-8 h-8 rounded-full bg-white border border-stone-200 text-stone-900 font-bold flex items-center justify-center hover:bg-stone-100"
                  >
                    +
                  </button>
                </div>
              </div>

              {/* Scheduled Orders for this slot */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <p className="text-xs font-bold text-stone-700">Orders Booked in Window</p>
                  <span className="text-[10px] font-bold text-stone-500">
                    {selectedSlotForModal.ordersCount || 0} scheduled
                  </span>
                </div>
                <div className="max-h-52 overflow-y-auto space-y-2">
                  {getOrdersForModal(selectedSlotForModal).length === 0 ? (
                    <div className="p-4 bg-stone-50 rounded-xl text-center text-xs text-stone-400">
                      No orders currently queued for this dispatch slot.
                    </div>
                  ) : (
                    getOrdersForModal(selectedSlotForModal).map(o => (
                      <div key={o.id} className="p-2.5 bg-stone-50 rounded-xl border border-stone-100 flex items-center justify-between text-xs">
                        <div>
                          <span className="font-mono font-bold text-stone-900">TOKEN #{o.token}</span>
                          <p className="text-[10px] text-stone-600 font-medium">{o.customerName} • {o.summary}</p>
                        </div>
                        <div className="text-right">
                          <span className="font-bold text-stone-900 block">₹{o.total}</span>
                          <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-900 text-[9px] font-bold">
                            {o.status}
                          </span>
                        </div>
                      </div>
                    ))
                  )}

                  <button
                    onClick={handleResetCanonicalOutlets}
                    className="w-full py-2 px-3 mt-1 rounded-xl bg-stone-100 hover:bg-stone-200 text-stone-700 hover:text-stone-900 text-[10px] font-bold transition-colors flex items-center justify-center gap-1.5 border border-stone-200/60"
                    title="Clean up test stalls and ensure canonical stalls (Nescafe, Canteen, Juice Bar) are active"
                  >
                    <RotateCcw size={11} className="text-stone-500" />
                    <span>Restore Canonical Stalls / Purge Legacy</span>
                  </button>
                </div>
              </div>

              <div className="flex items-center justify-between pt-3 border-t border-stone-100">
                <button
                  type="button"
                  onClick={() => handleDeleteSlot(selectedSlotForModal.id)}
                  className="px-3 py-2 text-xs font-bold text-red-600 hover:text-red-700 flex items-center gap-1"
                >
                  <Trash2 size={13} /> Delete Slot
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedSlotForModal(null)}
                  className="px-5 py-2 rounded-full bg-[#18181B] text-[#FACC15] text-xs font-bold shadow-xs hover:bg-black"
                >
                  Done
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ─── MODAL: ADD PICKUP SLOT ─── */}
      <AnimatePresence>
        {isAddSlotModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Add Dispatch Slot</h3>
                  <p className="text-xs text-stone-500">Create operational pre-order pickup window</p>
                </div>
                <button
                  onClick={() => setIsAddSlotModalOpen(false)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleAddSlotSubmit} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Time Window (Display)</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. 01:15 PM - 01:30 PM"
                    value={newSlotWindow}
                    onChange={e => setNewSlotWindow(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Slot Label</label>
                  <input
                    type="text"
                    required
                    placeholder="e.g. Afternoon Wave 3"
                    value={newSlotLabel}
                    onChange={e => setNewSlotLabel(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Start Time (24h)</label>
                    <input
                      type="text"
                      placeholder="13:15"
                      value={newSlotStartTime}
                      onChange={e => setNewSlotStartTime(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">End Time (24h)</label>
                    <input
                      type="text"
                      placeholder="13:30"
                      value={newSlotEndTime}
                      onChange={e => setNewSlotEndTime(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Max Capacity</label>
                    <input
                      type="number"
                      required
                      min={5}
                      value={newSlotCapacity}
                      onChange={e => setNewSlotCapacity(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                    />
                  </div>
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Assign Stall</label>
                    <select
                      value={newSlotOutletId}
                      onChange={e => setNewSlotOutletId(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900"
                    >
                      {outlets.map(o => (
                        <option key={o.id} value={o.id}>{o.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setIsAddSlotModalOpen(false)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingSlot}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingSlot ? 'Saving...' : 'Add Slot'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

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
                    placeholder="e.g. 7310347742@nyes"
                    value={newOutletUpi}
                    onChange={e => setNewOutletUpi(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 font-mono focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Est. Default Prep Time</label>
                  <input
                    type="text"
                    placeholder="e.g. 2-5 mins"
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

      {/* ─── EDIT STALL DETAILS MODAL ─── */}
      <AnimatePresence>
        {editingOutlet && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white rounded-[32px] p-6 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-base font-bold text-stone-900">Edit Stall Details</h3>
                  <p className="text-xs text-stone-500">Configure name, wait time, and UPI credentials</p>
                </div>
                <button
                  onClick={() => setEditingOutlet(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleSaveOutletEdit} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Stall Name</label>
                  <input
                    type="text"
                    required
                    value={editOutletName}
                    onChange={e => setEditOutletName(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Estimated Wait / Prep Window</label>
                  <input
                    type="text"
                    value={editOutletWait}
                    onChange={e => setEditOutletWait(e.target.value)}
                    placeholder="e.g. 2-5 mins"
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Vendor UPI Address</label>
                  <input
                    type="text"
                    required
                    value={editOutletUpi}
                    onChange={e => setEditOutletUpi(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 font-mono focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="flex items-center gap-2 pt-2">
                  <button
                    type="button"
                    onClick={() => setEditingOutlet(null)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingOutletEdit}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingOutletEdit ? 'Saving...' : 'Save Stall'}
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
