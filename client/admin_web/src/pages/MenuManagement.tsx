import { motion } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collectionGroup, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';

interface MenuItem {
  id: string;
  outletId: string;
  name: string;
  price: number;
  isAvailable: boolean;
}

export default function MenuManagement() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchMenu();
  }, []);

  const fetchMenu = async () => {
    // collectionGroup queries across all outlets' menu_items subcollections
    const snap = await getDocs(collectionGroup(db, 'menu_items'));
    const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as MenuItem));
    data.sort((a, b) => a.name.localeCompare(b.name));
    setItems(data);
    setLoading(false);
  };

  const toggleAvailability = async (item: MenuItem) => {
    const newStatus = !item.isAvailable;
    // Optimistic UI update
    setItems(prev => prev.map(i => i.id === item.id ? { ...i, isAvailable: newStatus } : i));

    try {
      // Path: outlets/{outletId}/menu_items/{itemId}
      await updateDoc(
        doc(db, 'outlets', item.outletId, 'menu_items', item.id),
        { isAvailable: newStatus }
      );
    } catch (e) {
      console.error('Failed to update availability:', e);
      // Revert on error
      setItems(prev => prev.map(i => i.id === item.id ? { ...i, isAvailable: item.isAvailable } : i));
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
              <p className={`text-lg font-semibold ${item.isAvailable ? 'text-white' : 'text-zinc-500 line-through'}`}>
                {item.name}
              </p>
              <p className="text-zinc-400">₹{item.price}</p>
            </div>
            <label className="relative inline-flex items-center cursor-pointer">
              <input
                type="checkbox"
                className="sr-only peer"
                checked={item.isAvailable}
                onChange={() => toggleAvailability(item)}
              />
              <div className="w-11 h-6 bg-zinc-800 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-indigo-500"></div>
            </label>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
