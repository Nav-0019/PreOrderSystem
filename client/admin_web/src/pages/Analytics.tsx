import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collection, onSnapshot, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { BarChart3, Download, TrendingUp, DollarSign, ShoppingBag, Clock, Store, QrCode } from 'lucide-react';

interface Order {
  id: string;
  totalAmount: number;
  status: string;
  outletId: string;
  outletName?: string;
  userName?: string;
  paymentMethod?: string;
  paymentStatus?: string;
  transactionId?: string;
  pickupToken?: string;
  createdAt?: any;
}

interface OutletStat {
  id: string;
  name: string;
  orderCount: number;
  revenue: number;
}

export default function Analytics() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'orders'), orderBy('createdAt', 'desc'), limit(150));
    const unsub = onSnapshot(q, (snap) => {
      const data = snap.docs.map(d => ({
        id: d.id,
        ...d.data(),
      } as Order));
      setOrders(data);
      setLoading(false);
    }, (err) => {
      console.warn('Analytics order listener:', err);
      setLoading(false);
    });

    return () => unsub();
  }, []);

  // Compute live aggregates
  const completedOrders = orders.filter(o => o.status === 'completed');
  const activeOrders = orders.filter(o => ['pending', 'prep', 'ready'].includes(o.status));
  const cancelledOrders = orders.filter(o => o.status === 'cancelled');

  const totalRevenue = orders
    .filter(o => o.status !== 'cancelled')
    .reduce((sum, o) => sum + Number(o.totalAmount || 0), 0);

  const avgOrderValue = orders.length > 0
    ? totalRevenue / Math.max(1, orders.filter(o => o.status !== 'cancelled').length)
    : 0;

  // Stall breakdown
  const outletStatsMap: Record<string, OutletStat> = {};
  orders.forEach(o => {
    const outId = o.outletId || 'unknown';
    const outName = o.outletName || `Outlet ${outId}`;
    if (!outletStatsMap[outId]) {
      outletStatsMap[outId] = { id: outId, name: outName, orderCount: 0, revenue: 0 };
    }
    outletStatsMap[outId].orderCount += 1;
    if (o.status !== 'cancelled') {
      outletStatsMap[outId].revenue += Number(o.totalAmount || 0);
    }
  });
  const outletStats = Object.values(outletStatsMap).sort((a, b) => b.revenue - a.revenue);

  // CSV Export
  const exportCSV = () => {
    if (orders.length === 0) {
      alert('No orders available to export.');
      return;
    }

    const headers = ['Order ID', 'Pickup Token', 'Customer', 'Outlet', 'Amount (INR)', 'Status', 'Payment Method', 'Payment Status', 'Transaction UTR', 'Created At'];
    const rows = orders.map(o => [
      o.id,
      o.pickupToken || '',
      o.userName || 'Customer',
      o.outletName || o.outletId,
      o.totalAmount,
      o.status,
      o.paymentMethod || 'UPI_QR',
      o.paymentStatus || 'PAID',
      o.transactionId || '',
      o.createdAt?.toDate ? o.createdAt.toDate().toISOString() : '',
    ]);

    const csvContent = 'data:text/csv;charset=utf-8,' + [headers.join(','), ...rows.map(e => e.map(val => `"${val}"`).join(','))].join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `aurabake_orders_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Campus Analytics & Financials
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Real-time transaction tracking, outlet velocity, and order volume intelligence.
          </p>
        </div>

        <button
          onClick={exportCSV}
          className="inline-flex items-center gap-2 px-5 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] font-extrabold text-xs shadow-xs transition-transform hover:scale-105"
        >
          <Download size={14} />
          <span>Export Orders CSV</span>
        </button>
      </div>

      {/* KPI Cards Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Gross Revenue */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="p-5 bg-white rounded-[26px] border border-[#E9DFCB] shadow-xs"
        >
          <div className="flex items-center justify-between text-stone-400">
            <span className="text-[11px] font-bold uppercase tracking-wider">Gross Volume</span>
            <DollarSign size={16} className="text-[#EAB308]" />
          </div>
          <p className="text-3xl font-normal text-stone-900 mt-2">
            ₹{totalRevenue.toFixed(0)}
          </p>
          <p className="text-xs text-emerald-600 font-bold mt-1 flex items-center gap-1">
            <TrendingUp size={12} />
            <span>Active transactions</span>
          </p>
        </motion.div>

        {/* Total Orders */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.05 }}
          className="p-5 bg-white rounded-[26px] border border-[#E9DFCB] shadow-xs"
        >
          <div className="flex items-center justify-between text-stone-400">
            <span className="text-[11px] font-bold uppercase tracking-wider">Total Orders</span>
            <ShoppingBag size={16} className="text-stone-600" />
          </div>
          <p className="text-3xl font-normal text-stone-900 mt-2">
            {orders.length}
          </p>
          <p className="text-xs text-stone-500 font-medium mt-1">
            {completedOrders.length} completed • {activeOrders.length} active • {cancelledOrders.length} cancelled
          </p>
        </motion.div>

        {/* Active Queue */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="p-5 bg-white rounded-[26px] border border-[#E9DFCB] shadow-xs"
        >
          <div className="flex items-center justify-between text-stone-400">
            <span className="text-[11px] font-bold uppercase tracking-wider">Active Queue</span>
            <Clock size={16} className="text-[#EAB308]" />
          </div>
          <p className="text-3xl font-normal text-stone-900 mt-2">
            {activeOrders.length}
          </p>
          <p className="text-xs text-[#EAB308] font-bold mt-1">
            ⚡ ~{Math.max(2, activeOrders.length * 2)} min average prep
          </p>
        </motion.div>

        {/* Average Order Value */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.15 }}
          className="p-5 bg-white rounded-[26px] border border-[#E9DFCB] shadow-xs"
        >
          <div className="flex items-center justify-between text-stone-400">
            <span className="text-[11px] font-bold uppercase tracking-wider">Avg Order Value</span>
            <BarChart3 size={16} className="text-stone-600" />
          </div>
          <p className="text-3xl font-normal text-stone-900 mt-2">
            ₹{avgOrderValue.toFixed(0)}
          </p>
          <p className="text-xs text-stone-400 font-medium mt-1">
            Across {outletStats.length} active stalls
          </p>
        </motion.div>
      </div>

      {/* Outlets Performance Table */}
      <div className="bg-white rounded-[28px] border border-[#E9DFCB] p-6 shadow-xs space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Store size={18} className="text-stone-500" />
            <h2 className="text-lg font-bold text-stone-900">Campus Stalls Performance</h2>
          </div>
          <span className="text-xs text-stone-400 font-medium">{outletStats.length} registered outlets</span>
        </div>

        {outletStats.length === 0 ? (
          <p className="text-xs text-stone-400 py-4">No outlet sales recorded yet.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-stone-100 text-stone-400 font-bold uppercase text-[10px]">
                  <th className="py-2.5">Stall Name</th>
                  <th className="py-2.5">Total Orders</th>
                  <th className="py-2.5">Gross Revenue</th>
                  <th className="py-2.5">Fulfillment Share</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-50">
                {outletStats.map(stat => {
                  const share = totalRevenue > 0 ? ((stat.revenue / totalRevenue) * 100).toFixed(0) : '0';
                  return (
                    <tr key={stat.id} className="hover:bg-stone-50/60 transition-colors">
                      <td className="py-3 font-bold text-stone-900 flex items-center gap-2">
                        <span className="w-2 h-2 rounded-full bg-emerald-500" />
                        {stat.name}
                      </td>
                      <td className="py-3 font-semibold text-stone-700">{stat.orderCount} orders</td>
                      <td className="py-3 font-extrabold text-stone-900">₹{stat.revenue.toFixed(0)}</td>
                      <td className="py-3 text-stone-500">
                        <div className="flex items-center gap-2">
                          <div className="w-24 bg-stone-100 rounded-full h-1.5 overflow-hidden">
                            <div className="bg-[#FACC15] h-full rounded-full" style={{ width: `${share}%` }} />
                          </div>
                          <span className="font-bold text-[11px] text-stone-700">{share}%</span>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Live Transaction Ledger */}
      <div className="bg-white rounded-[28px] border border-[#E9DFCB] p-6 shadow-xs space-y-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <QrCode size={18} className="text-stone-500" />
            <h2 className="text-lg font-bold text-stone-900">Transaction & Order Log</h2>
          </div>
          <span className="text-xs text-stone-400 font-medium">Real-time ledger ({orders.length} entries)</span>
        </div>

        {loading ? (
          <div className="py-12 text-center text-stone-400">Loading ledger...</div>
        ) : orders.length === 0 ? (
          <div className="py-12 text-center text-stone-400">
            <p className="font-bold">No transactions found</p>
            <p className="text-xs mt-1">Orders placed by customers will populate in this ledger.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-stone-100 text-stone-400 font-bold uppercase text-[10px]">
                  <th className="py-2.5">Order ID</th>
                  <th className="py-2.5">Pickup Token</th>
                  <th className="py-2.5">Customer</th>
                  <th className="py-2.5">Outlet</th>
                  <th className="py-2.5">Amount</th>
                  <th className="py-2.5">Payment</th>
                  <th className="py-2.5">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-stone-50">
                {orders.map((o) => {
                  const token = o.pickupToken || (o.id.length >= 4 ? o.id.slice(-4).toUpperCase() : '1001');
                  return (
                    <tr key={o.id} className="hover:bg-stone-50/60 transition-colors">
                      <td className="py-3 font-mono font-bold text-stone-900">#{o.id.slice(0, 6).toUpperCase()}</td>
                      <td className="py-3 font-black text-stone-800">#{token}</td>
                      <td className="py-3 font-medium text-stone-700">{o.userName || 'Student'}</td>
                      <td className="py-3 text-stone-600 font-medium">{o.outletName || o.outletId}</td>
                      <td className="py-3 font-black text-stone-900">₹{o.totalAmount}</td>
                      <td className="py-3">
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                          {o.paymentMethod || 'UPI_QR'} · {o.paymentStatus || 'PAID'}
                        </span>
                      </td>
                      <td className="py-3">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-black ${
                          o.status === 'completed'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : o.status === 'ready'
                            ? 'bg-blue-50 text-blue-700 border border-blue-200'
                            : o.status === 'prep'
                            ? 'bg-amber-50 text-amber-700 border border-amber-200'
                            : o.status === 'cancelled'
                            ? 'bg-red-50 text-red-700 border border-red-200'
                            : 'bg-stone-100 text-stone-700 border border-stone-200'
                        }`}>
                          {o.status.toUpperCase()}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
