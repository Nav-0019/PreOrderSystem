import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collection, query, where, orderBy, onSnapshot, doc, getDoc, runTransaction } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { QrCode, Clock, Store, Hash } from 'lucide-react';

interface OrderItem {
  quantity: number;
  name: string;
  menuItemId?: string;
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

  useEffect(() => {
    const q = query(
      collection(db, 'orders'),
      where('status', 'in', ['pending', 'prep', 'ready']),
      orderBy('createdAt', 'asc')
    );

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
    });

    return () => unsub();
  }, []);

  const advanceStatus = async (id: string, currentStatus: string) => {
    const statusMap: Record<string, string> = {
      pending: 'prep',
      prep: 'ready',
      ready: 'completed',
    };
    const next = statusMap[currentStatus];
    if (!next) return;
    try {
      await runTransaction(db, async (transaction) => {
        const orderRef = doc(db, 'orders', id);
        const orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists()) return;
        
        const data = orderSnap.data();
        const prevStatus = data.status;
        const outletId = data.outletId;
        
        transaction.update(orderRef, { status: next });
        
        const wasActive = ['pending', 'prep', 'ready'].includes(prevStatus);
        const isNowActive = ['pending', 'prep', 'ready'].includes(next);
        
        if (wasActive && !isNowActive && outletId) {
          const outletRef = doc(db, 'outlets', outletId);
          const outletSnap = await transaction.get(outletRef);
          if (outletSnap.exists()) {
            const currentQueue = outletSnap.data().queueCount || 0;
            const newQueue = currentQueue > 0 ? currentQueue - 1 : 0;
            const newWaitTime = newQueue === 0 ? 'No wait' : `${newQueue * 2}-${newQueue * 2 + 3} mins`;
            transaction.update(outletRef, { queueCount: newQueue, waitTime: newWaitTime });
          }
        }
      });
    } catch (e) {
      console.error('Error updating order:', e);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Live Order Dispatch
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Real-time active orders across all campus stalls.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-bold bg-white border border-[#E7DFCE] text-stone-800 shadow-xs">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            {orders.length} Active Orders
          </span>
        </div>
      </div>

      <div className="grid gap-4">
        {loading ? (
          <div className="p-12 text-center text-stone-400 bg-white rounded-[28px] border border-[#E9DFCB]">
            <div className="w-6 h-6 border-2 border-stone-800 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
            Loading live orders...
          </div>
        ) : orders.length === 0 ? (
          <div className="p-12 text-center bg-white rounded-[28px] border border-[#E9DFCB]">
            <Clock className="w-12 h-12 text-stone-300 mx-auto mb-3" />
            <p className="text-base font-bold text-stone-800">Queue is clear</p>
            <p className="text-xs text-stone-400 mt-1">No pending or in-prep orders at the moment.</p>
          </div>
        ) : orders.map((order, i) => {
          const details = order.items?.map(item => `${item.quantity}x ${item.name}`).join(', ');
          const pickupToken = order.pickupToken || (order.id.length >= 4 ? order.id.slice(-4).toUpperCase() : '1001');

          return (
            <motion.div
              key={order.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.04 }}
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

                <div className="flex items-center gap-2.5 shrink-0">
                  <button
                    onClick={() => advanceStatus(order.id, order.status)}
                    className={`px-5 py-2.5 rounded-full font-extrabold text-xs tracking-wider transition-all shadow-xs ${
                      order.status === 'pending'
                        ? 'bg-[#FACC15] hover:bg-yellow-300 text-stone-950'
                        : order.status === 'prep'
                        ? 'bg-[#18181B] hover:bg-black text-[#FACC15]'
                        : 'bg-emerald-600 hover:bg-emerald-500 text-white'
                    }`}
                  >
                    {order.status === 'pending' && 'START PREP →'}
                    {order.status === 'prep' && 'MARK READY 🎉 →'}
                    {order.status === 'ready' && 'HANDOVER DONE ✓'}
                  </button>
                </div>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
