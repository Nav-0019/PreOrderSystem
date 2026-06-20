import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collection, query, where, orderBy, onSnapshot, doc, getDoc, runTransaction } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface OrderItem {
  quantity: number;
  name: string;
  menuItemId: string;
}

interface Order {
  id: string;
  status: string;
  totalAmount: number;
  userId: string;
  outletId: string;
  items: OrderItem[];
  userName?: string;
  isPremium?: boolean;
}

export default function LiveQueue() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Real-time listener — active orders only, sorted by creation time
    const q = query(
      collection(db, 'orders'),
      where('status', 'in', ['pending', 'prep', 'ready']),
      orderBy('createdAt', 'asc')
    );

    const unsub = onSnapshot(q, async (snap) => {
      const rawOrders = snap.docs.map(d => ({ id: d.id, ...d.data() } as any));

      // Enrich with user names from users collection (batch fetch unique user IDs)
      const userIds = [...new Set(rawOrders.map((o: any) => o.userId))];
      const userMap: Record<string, { name: string; isPremium: boolean }> = {};

      // Fetch user docs in parallel
      await Promise.all(
        userIds.map(async (uid) => {
          const userDoc = await getDoc(doc(db, 'users', uid as string));
          if (userDoc.exists()) {
            const data = userDoc.data();
            userMap[uid as string] = {
              name: data.name || 'Unknown',
              isPremium: data.isPremium || false,
            };
          }
        })
      );

      setOrders(rawOrders.map((o: any) => ({
        ...o,
        userName: userMap[o.userId]?.name || 'Unknown',
        isPremium: userMap[o.userId]?.isPremium || false,
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
        const currentStatus = data.status;
        const outletId = data.outletId;
        
        transaction.update(orderRef, { status: next });
        
        const wasActive = ['pending', 'prep', 'ready'].includes(currentStatus);
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
    // Firestore onSnapshot above will auto-update the UI
  };

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Live Queue</h1>
        <p className="text-zinc-400 mt-1">Real-time order tracking and management.</p>
      </div>

      <div className="grid gap-4">
        {loading ? (
          <p className="text-zinc-500">Loading live queue...</p>
        ) : orders.length === 0 ? (
          <p className="text-zinc-500">No active orders right now.</p>
        ) : orders.map((order, i) => {
          const details = order.items?.map(item => `${item.quantity}x ${item.name}`).join(', ');

          return (
            <motion.div
              key={order.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className={`p-6 bg-zinc-900/50 border rounded-2xl backdrop-blur-xl ${order.isPremium ? 'border-amber-500/30' : 'border-zinc-800'}`}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-lg font-bold">
                    #{order.id.slice(0, 6)} • {order.userName}
                    {order.isPremium && <span className="ml-2 text-amber-500 text-sm">✦ Premium</span>}
                  </p>
                  <p className="text-zinc-400 mt-1">{details || 'No items'}</p>
                  <p className="text-zinc-500 text-sm mt-1">₹{order.totalAmount}</p>
                </div>
                <button
                  onClick={() => advanceStatus(order.id, order.status)}
                  className={`px-4 py-2 rounded-lg font-semibold text-sm transition-colors hover:brightness-125 ${
                    order.status === 'prep' ? 'bg-indigo-500/10 text-indigo-400'
                    : order.status === 'ready' ? 'bg-emerald-500/10 text-emerald-400'
                    : 'bg-zinc-800 text-zinc-400'
                  }`}
                >
                  {order.status.toUpperCase()} →
                </button>
              </div>
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}
