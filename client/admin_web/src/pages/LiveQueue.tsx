import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collection, query, orderBy, onSnapshot, doc, updateDoc, getDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { QrCode, Clock, Store, Hash, XCircle, CheckCircle, Search } from 'lucide-react';

interface OrderItem {
  quantity: number;
  name: string;
  unitPrice?: number;
}

interface Order {
  id: string;
  status: string;
  totalAmount: number;
  userId: string;
  outletId: string;
  outletName?: string;
  items: OrderItem[];
  userName?: string;
  isPremium?: boolean;
  paymentMethod?: string;
  paymentStatus?: string;
  transactionId?: string;
  pickupToken?: string;
  createdAt?: any;
}

export default function LiveQueue() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('active');
  const [outletFilter, setOutletFilter] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(collection(db, 'orders'), orderBy('createdAt', 'desc'));

    const unsub = onSnapshot(q, async (snap) => {
      const rawOrders = snap.docs.map(d => ({ id: d.id, ...d.data() } as any));

      const userIds = [...new Set(rawOrders.map((o: any) => o.userId).filter(Boolean))];
      const userMap: Record<string, { name: string; isPremium: boolean }> = {};

      await Promise.all(
        userIds.map(async (uid) => {
          try {
            const userDoc = await getDoc(doc(db, 'users', uid as string));
            if (userDoc.exists()) {
              const data = userDoc.data();
              userMap[uid as string] = {
                name: data.name || 'Customer',
                isPremium: data.isPremium || false,
              };
            }
          } catch (_) {}
        })
      );

      setOrders(rawOrders.map((o: any) => ({
        ...o,
        userName: o.userName || userMap[o.userId]?.name || 'Customer',
        isPremium: o.isPremium ?? userMap[o.userId]?.isPremium ?? false,
      })));
      setLoading(false);
    }, (err) => {
      console.warn('LiveQueue snapshot error:', err);
      setLoading(false);
    });

    return () => unsub();
  }, []);

  const updateOrderStatus = async (id: string, newStatus: string) => {
    if (processingId) return;
    setProcessingId(id);

    try {
      const orderRef = doc(db, 'orders', id);
      const updateData: any = { status: newStatus };
      if (newStatus === 'completed') {
        updateData.completedAt = new Date();
        updateData.qualityChecked = true;
        updateData.qualityConfirmedAt = new Date();
      } else if (newStatus === 'prep') {
        updateData.prepStartedAt = new Date();
      }

      await updateDoc(orderRef, updateData);

      // Decrement queue count on outlet if completing or cancelling
      if (newStatus === 'completed' || newStatus === 'cancelled') {
        try {
          const snap = await getDoc(orderRef);
          const outletId = snap.data()?.outletId;
          if (outletId) {
            const outletRef = doc(db, 'outlets', outletId);
            const oSnap = await getDoc(outletRef);
            if (oSnap.exists()) {
              const current = oSnap.data().queueCount || 0;
              const newQueue = Math.max(0, current - 1);
              const newWaitTime = newQueue === 0 ? 'No wait' : `${newQueue * 2}-${newQueue * 2 + 3} mins`;
              await updateDoc(outletRef, { queueCount: newQueue, waitTime: newWaitTime });
            }
          }
        } catch (_) {}
      }
    } catch (e) {
      console.error('Error updating order:', e);
      alert('Error updating order: ' + e);
    } finally {
      setProcessingId(null);
    }
  };

  // Distinct outlets for filter
  const uniqueOutlets = Array.from(new Set(orders.map(o => o.outletName || o.outletId).filter(Boolean)));

  // Filtered orders
  const filteredOrders = orders.filter(o => {
    // Status filter
    if (statusFilter === 'active' && !['pending', 'prep', 'ready'].includes(o.status)) return false;
    if (statusFilter === 'pending' && o.status !== 'pending') return false;
    if (statusFilter === 'prep' && o.status !== 'prep') return false;
    if (statusFilter === 'ready' && o.status !== 'ready') return false;
    if (statusFilter === 'completed' && o.status !== 'completed') return false;
    if (statusFilter === 'cancelled' && o.status !== 'cancelled') return false;

    // Outlet filter
    if (outletFilter !== 'ALL' && (o.outletName || o.outletId) !== outletFilter) return false;

    // Search query
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const token = (o.pickupToken || '').toLowerCase();
      const name = (o.userName || '').toLowerCase();
      const id = o.id.toLowerCase();
      return token.includes(q) || name.includes(q) || id.includes(q);
    }

    return true;
  });

  const activeCount = orders.filter(o => ['pending', 'prep', 'ready'].includes(o.status)).length;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Live Order Dispatch
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Real-time active orders across all campus stalls with instant status actions.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold bg-white border border-[#E7DFCE] text-stone-800 shadow-xs">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            {activeCount} Active Orders
          </span>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 p-3 bg-white rounded-[24px] border border-[#E9DFCB] shadow-xs">
        {/* Status Filter Capsule Nav */}
        <div className="flex items-center gap-1 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
          {[
            { id: 'active', label: `Active (${activeCount})` },
            { id: 'pending', label: 'Pending' },
            { id: 'prep', label: 'In Prep' },
            { id: 'ready', label: 'Ready' },
            { id: 'completed', label: 'Completed' },
            { id: 'all', label: 'All History' },
          ].map(tab => (
            <button
              key={tab.id}
              onClick={() => setStatusFilter(tab.id)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
                statusFilter === tab.id
                  ? 'bg-[#18181B] text-white shadow-xs'
                  : 'text-stone-600 hover:text-stone-900 hover:bg-stone-100/60'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Right Search & Outlet Dropdown */}
        <div className="flex items-center gap-2">
          <div className="relative flex-1 sm:w-48">
            <Search size={14} className="absolute left-3 top-2.5 text-stone-400" />
            <input
              type="text"
              placeholder="Search token, user..."
              value={searchQuery}
              onChange={e => setSearchQuery(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 text-xs bg-stone-50 border border-stone-200 rounded-full text-stone-900 focus:outline-none focus:border-stone-800"
            />
          </div>

          <select
            value={outletFilter}
            onChange={e => setOutletFilter(e.target.value)}
            className="px-3 py-1.5 text-xs font-bold bg-stone-50 border border-stone-200 rounded-full text-stone-800 focus:outline-none"
          >
            <option value="ALL">All Stalls</option>
            {uniqueOutlets.map(out => (
              <option key={out} value={out}>{out}</option>
            ))}
          </select>
        </div>
      </div>

      {/* Orders List */}
      <div className="grid gap-4">
        {loading ? (
          <div className="p-12 text-center text-stone-400 bg-white rounded-[28px] border border-[#E9DFCB]">
            <div className="w-6 h-6 border-2 border-stone-800 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
            Loading live orders...
          </div>
        ) : filteredOrders.length === 0 ? (
          <div className="p-12 text-center bg-white rounded-[28px] border border-[#E9DFCB]">
            <Clock className="w-12 h-12 text-stone-300 mx-auto mb-3" />
            <p className="text-base font-bold text-stone-800">No orders match filter</p>
            <p className="text-xs text-stone-400 mt-1">Try changing status tab or stall selection.</p>
          </div>
        ) : filteredOrders.map((order, i) => {
          const details = order.items?.map(item => `${item.quantity}x ${item.name}`).join(', ');
          const pickupToken = order.pickupToken || (order.id.length >= 4 ? order.id.slice(-4).toUpperCase() : '1001');
          const isProcessing = processingId === order.id;

          return (
            <motion.div
              key={order.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.03 }}
              className="p-5 sm:p-6 bg-white rounded-[28px] border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)]"
            >
              <div className="flex flex-col md:flex-row md:items-center justify-between gap-5">
                <div className="space-y-2">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="text-lg font-bold text-stone-900">
                      #{order.id.slice(0, 6).toUpperCase()}
                    </span>
                    <span className="inline-flex items-center gap-1 px-3 py-0.5 rounded-full text-xs font-black bg-[#FAF6EE] text-stone-800 border border-[#E7DFCE]">
                      <Hash size={12} /> TOKEN: {pickupToken}
                    </span>
                    {order.isPremium && (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-[#FEF08A] text-stone-950 border border-yellow-300">
                        ⚡ Priority Member
                      </span>
                    )}
                    <span className="text-xs font-semibold text-stone-500">
                      • {order.userName}
                    </span>
                  </div>

                  <p className="text-xs text-stone-700 font-medium">
                    {details || 'No items listed'}
                  </p>

                  <div className="flex items-center gap-4 text-xs text-stone-500 flex-wrap">
                    {order.outletName && (
                      <span className="inline-flex items-center gap-1 font-semibold text-stone-600">
                        <Store size={13} className="text-stone-400" />
                        {order.outletName}
                      </span>
                    )}
                    <span className="font-extrabold text-stone-900">
                      ₹{order.totalAmount}
                    </span>
                    <span className="inline-flex items-center gap-1 text-emerald-700 font-bold bg-emerald-50 px-2.5 py-0.5 rounded-full border border-emerald-200">
                      <QrCode size={12} />
                      {order.paymentMethod || 'UPI_QR'} · {order.paymentStatus || 'PAID'}
                    </span>
                    {order.transactionId && order.transactionId !== 'UPI_VERIFIED' && (
                      <span className="text-[11px] text-stone-400 font-mono">
                        UTR: {order.transactionId}
                      </span>
                    )}
                  </div>
                </div>

                {/* Complete Action Buttons */}
                <div className="flex items-center gap-2 shrink-0 flex-wrap">
                  {order.status === 'pending' && (
                    <>
                      <button
                        onClick={() => updateOrderStatus(order.id, 'cancelled')}
                        disabled={isProcessing}
                        className="px-3.5 py-2 rounded-full font-bold text-xs bg-red-50 hover:bg-red-100 text-red-600 border border-red-200 transition-colors disabled:opacity-50"
                      >
                        Cancel ✕
                      </button>
                      <button
                        onClick={() => updateOrderStatus(order.id, 'prep')}
                        disabled={isProcessing}
                        className="px-5 py-2 rounded-full font-extrabold text-xs bg-[#FACC15] hover:bg-yellow-300 text-stone-950 shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                      >
                        Start Prep 👨‍🍳 →
                      </button>
                    </>
                  )}

                  {order.status === 'prep' && (
                    <button
                      onClick={() => updateOrderStatus(order.id, 'ready')}
                      disabled={isProcessing}
                      className="px-5 py-2 rounded-full font-extrabold text-xs bg-[#18181B] hover:bg-black text-[#FACC15] shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                    >
                      Mark Ready 🔔 →
                    </button>
                  )}

                  {order.status === 'ready' && (
                    <button
                      onClick={() => updateOrderStatus(order.id, 'completed')}
                      disabled={isProcessing}
                      className="px-5 py-2 rounded-full font-extrabold text-xs bg-emerald-600 hover:bg-emerald-500 text-white shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                    >
                      Confirm Quality & Handover ✓
                    </button>
                  )}

                  {order.status === 'completed' && (
                    <span className="inline-flex items-center gap-1 text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-200">
                      <CheckCircle size={13} /> Completed
                    </span>
                  )}

                  {order.status === 'cancelled' && (
                    <span className="inline-flex items-center gap-1 text-xs font-bold text-red-600 bg-red-50 px-3 py-1 rounded-full border border-red-200">
                      <XCircle size={13} /> Cancelled
                    </span>
                  )}
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
