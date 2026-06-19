import { motion } from 'framer-motion';
import { TrendingUp, Users, Clock, DollarSign } from 'lucide-react';
import { useEffect, useState } from 'react';
import { collection, onSnapshot } from 'firebase/firestore';
import { db } from '../lib/firebase';

export default function Overview() {
  const [totalOrders, setTotalOrders] = useState(0);
  const [activeQueue, setActiveQueue] = useState(0);
  const [revenue, setRevenue] = useState(0);
  const [outlets, setOutlets] = useState<any[]>([]);
  const [avgWait, setAvgWait] = useState('0 min');

  useEffect(() => {
    // Real-time listener for orders
    const ordersUnsub = onSnapshot(collection(db, 'orders'), (snap) => {
      const orders = snap.docs.map(d => d.data());
      setTotalOrders(orders.length);
      const active = orders.filter(o => !['completed', 'cancelled'].includes(o.status)).length;
      setActiveQueue(active);
      setAvgWait(`${active * 2} min`);
      const totalRev = orders.reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);
      setRevenue(totalRev);
    });

    // Real-time listener for outlets
    const outletsUnsub = onSnapshot(collection(db, 'outlets'), (snap) => {
      setOutlets(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });

    return () => { ordersUnsub(); outletsUnsub(); };
  }, []);

  const stats = [
    { label: 'Total Orders', value: totalOrders.toString(), change: 'Lifetime', icon: Users, color: 'text-indigo-400', bg: 'bg-indigo-500/10' },
    { label: 'Active Queue', value: activeQueue.toString(), change: 'Live now', icon: TrendingUp, color: 'text-emerald-400', bg: 'bg-emerald-500/10' },
    { label: 'Avg Wait', value: avgWait, change: 'Estimated', icon: Clock, color: 'text-amber-400', bg: 'bg-amber-500/10' },
    { label: 'Revenue', value: `₹${revenue.toFixed(0)}`, change: 'Lifetime', icon: DollarSign, color: 'text-blue-400', bg: 'bg-blue-500/10' },
  ];

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Overview</h1>
        <p className="text-zinc-400 mt-1">Here's what's happening today across all outlets.</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {stats.map((stat, i) => (
          <motion.div
            key={stat.label}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.1 }}
            className="p-6 bg-zinc-900/50 border border-zinc-800 rounded-2xl backdrop-blur-xl hover:border-zinc-700 transition-colors"
          >
            <div className="flex items-start justify-between">
              <div>
                <p className="text-sm font-medium text-zinc-400">{stat.label}</p>
                <p className="text-3xl font-bold mt-2">{stat.value}</p>
              </div>
              <div className={`p-3 rounded-xl ${stat.bg} ${stat.color}`}>
                <stat.icon size={20} />
              </div>
            </div>
            <div className="mt-4 flex items-center gap-2">
              <span className={`text-sm font-medium ${stat.change.includes('Live') ? 'text-emerald-400' : 'text-indigo-400'}`}>
                {stat.change}
              </span>
            </div>
          </motion.div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="p-6 bg-zinc-900/50 border border-zinc-800 rounded-2xl backdrop-blur-xl"
        >
          <h2 className="text-lg font-bold mb-4">Outlet Status</h2>
          <div className="space-y-4">
            {outlets.length === 0 ? <p className="text-zinc-500">Loading outlets...</p> : outlets.map(outlet => (
              <div key={outlet.id} className="flex items-center justify-between p-4 bg-zinc-950/50 rounded-xl border border-zinc-800/50">
                <div>
                  <p className="font-semibold">{outlet.name}</p>
                  <p className="text-sm text-zinc-400">Queue: {outlet.queueCount} • Wait: {outlet.waitTime}</p>
                </div>
                <div className={`px-3 py-1 text-xs font-semibold rounded-full ${outlet.isOpen ? 'bg-emerald-500/10 text-emerald-400' : 'bg-red-500/10 text-red-400'}`}>
                  {outlet.isOpen ? 'Open' : 'Closed'}
                </div>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </div>
  );
}
