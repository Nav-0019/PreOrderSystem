import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface OrderItem {
  quantity: number;
  menu_items: { name: string };
}

interface Order {
  id: string;
  status: string;
  total_amount: number;
  users: { name: string; is_premium: boolean };
  order_items: OrderItem[];
}

export default function LiveQueue() {
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchOrders();

    const channel = supabase.channel('public:orders')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'orders' }, payload => {
        console.log('Order change received!', payload);
        fetchOrders(); // Refetch to get joined data easily, or manually update state
      })
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  const fetchOrders = async () => {
    const { data, error } = await supabase
      .from('orders')
      .select(`
        id,
        status,
        total_amount,
        users (name, is_premium),
        order_items (
          quantity,
          menu_items (name)
        )
      `)
      .neq('status', 'completed')
      .neq('status', 'cancelled')
      .order('created_at', { ascending: true });

    if (error) {
      console.error('Error fetching orders:', error);
    } else {
      setOrders(data as any);
    }
    setLoading(false);
  };

  const advanceStatus = async (id: string, currentStatus: string) => {
    const statusMap: Record<string, string> = {
      'pending': 'prep',
      'prep': 'ready',
      'ready': 'completed'
    };
    const next = statusMap[currentStatus];
    if (!next) return;

    const { error } = await supabase.from('orders').update({ status: next }).eq('id', id);
    if (error) console.error('Error updating status', error);
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
          const isPremium = order.users?.is_premium;
          const details = order.order_items?.map(oi => `${oi.quantity}x ${oi.menu_items?.name}`).join(', ');

          return (
            <motion.div
              key={order.id}
              initial={{ opacity: 0, x: -20 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: i * 0.1 }}
              className={`p-6 bg-zinc-900/50 border rounded-2xl backdrop-blur-xl ${isPremium ? 'border-amber-500/30' : 'border-zinc-800'}`}
            >
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-lg font-bold">
                    #{order.id.split('-')[0]} • {order.users?.name || 'Unknown'} 
                    {isPremium && <span className="ml-2 text-amber-500 text-sm">✦ Premium</span>}
                  </p>
                  <p className="text-zinc-400 mt-1">{details || 'No items'}</p>
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
