import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';

interface MenuItem {
  id: string;
  name: string;
  price: number;
  is_available: boolean;
}

export default function MenuManagement() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMenu();
  }, []);

  const fetchMenu = async () => {
    const { data, error } = await supabase.from('menu_items').select('*').order('name');
    if (error) {
      console.error('Error fetching menu:', error);
    } else {
      setItems(data || []);
    }
    setLoading(false);
  };

  const toggleAvailability = async (id: string, currentStatus: boolean) => {
    const newStatus = !currentStatus;
    // Optimistic update
    setItems(items.map(item => item.id === id ? { ...item, is_available: newStatus } : item));
    
    const { error } = await supabase.from('menu_items').update({ is_available: newStatus }).eq('id', id);
    if (error) {
      console.error('Error updating availability:', error);
      // Revert on error
      setItems(items.map(item => item.id === id ? { ...item, is_available: currentStatus } : item));
    }
  };

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Menu Management</h1>
          <p className="text-zinc-400 mt-1">Manage items, pricing, and availability.</p>
        </div>
        <button className="bg-indigo-500 hover:bg-indigo-600 text-white px-4 py-2 rounded-lg font-medium transition-colors">
          + Add Item
        </button>
      </div>

      <div className="grid gap-4">
        {loading ? (
          <p className="text-zinc-500">Loading menu...</p>
        ) : items.map((item, i) => (
          <motion.div
            key={item.id}
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05 }}
            className="p-6 bg-zinc-900/50 border border-zinc-800 rounded-2xl backdrop-blur-xl flex justify-between items-center"
          >
            <div>
              <p className={`text-lg font-semibold ${item.is_available ? 'text-white' : 'text-zinc-500 line-through'}`}>{item.name}</p>
              <p className="text-zinc-400">₹{item.price}</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input 
                type="checkbox" 
                className="sr-only peer" 
                checked={item.is_available} 
                onChange={() => toggleAvailability(item.id, item.is_available)}
              />
              <div className="w-11 h-6 bg-zinc-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
