import { motion, AnimatePresence } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collectionGroup, getDocs, collection, doc, updateDoc, addDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { Plus, Trash2, Search, Store, X } from 'lucide-react';

interface MenuItem {
  id: string;
  outletId: string;
  name: string;
  price: number;
  isAvailable: boolean;
  category?: string;
  prepTime?: number;
}

interface Outlet {
  id: string;
  name: string;
}

export default function MenuManagement() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [outlets, setOutlets] = useState<Outlet[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [outletFilter, setOutletFilter] = useState('ALL');

  // Modal state
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalOutletId, setModalOutletId] = useState('');
  const [modalName, setModalName] = useState('');
  const [modalPrice, setModalPrice] = useState('');
  const [modalCategory, setModalCategory] = useState('Snacks');
  const [modalPrepTime, setModalPrepTime] = useState('5');
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const outletsSnap = await getDocs(collection(db, 'outlets'));
      const outletList = outletsSnap.docs.map(d => ({ id: d.id, name: (d.data().name as string) || d.id }));
      setOutlets(outletList);
      if (outletList.length > 0 && !modalOutletId) {
        setModalOutletId(outletList[0].id);
      }

      // Fetch from root menu_items (which is open in Firestore rules)
      const snap = await getDocs(collection(db, 'menu_items'));
      const data = snap.docs.map(d => {
        const itemData = d.data();
        return {
          id: d.id,
          outletId: itemData.outletId || (outletList[0]?.id ?? '01'),
          name: itemData.name || 'Item',
          price: Number(itemData.price || 0),
          isAvailable: itemData.isAvailable ?? true,
          category: itemData.category || 'General',
          prepTime: Number(itemData.prepTime || 5),
        } as MenuItem;
      });

      // Also try collectionGroup for subcollections if rules allow
      try {
        const groupSnap = await getDocs(collectionGroup(db, 'menu_items'));
        groupSnap.docs.forEach(d => {
          if (!data.some(existing => existing.id === d.id)) {
            data.push({ id: d.id, ...d.data() } as MenuItem);
          }
        });
      } catch (_) {}

      data.sort((a, b) => (a.name || '').localeCompare(b.name || ''));
      setItems(data);
    } catch (e) {
      console.error('Error fetching menu items:', e);
    } finally {
      setLoading(false);
    }
  };

  const toggleAvailability = async (item: MenuItem) => {
    const newStatus = !item.isAvailable;
    setItems(prev => prev.map(i => i.id === item.id ? { ...i, isAvailable: newStatus } : i));

    try {
      // 1. Update in root menu_items
      await updateDoc(doc(db, 'menu_items', item.id), { isAvailable: newStatus });
      // 2. Also try updating in outlet subcollection if applicable
      if (item.outletId) {
        try {
          await updateDoc(doc(db, 'outlets', item.outletId, 'menu_items', item.id), { isAvailable: newStatus });
        } catch (_) {}
      }
    } catch (e) {
      console.error('Failed to update availability:', e);
      setItems(prev => prev.map(i => i.id === item.id ? { ...i, isAvailable: item.isAvailable } : i));
    }
  };

  const deleteItem = async (item: MenuItem) => {
    if (!window.confirm(`Delete "${item.name}" from menu?`)) return;
    setItems(prev => prev.filter(i => i.id !== item.id));
    try {
      await deleteDoc(doc(db, 'menu_items', item.id));
      if (item.outletId) {
        try {
          await deleteDoc(doc(db, 'outlets', item.outletId, 'menu_items', item.id));
        } catch (_) {}
      }
    } catch (e) {
      console.error('Failed to delete menu item:', e);
      fetchData();
    }
  };

  const handleAddItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!modalOutletId || !modalName.trim() || !modalPrice.trim()) return;

    setSubmitting(true);
    try {
      const priceNum = parseFloat(modalPrice) || 0;
      const prepNum = parseInt(modalPrepTime) || 5;

      // 1. Add to root menu_items (guaranteed write permissions)
      const docRef = await addDoc(collection(db, 'menu_items'), {
        name: modalName.trim(),
        price: priceNum,
        category: modalCategory,
        prepTime: prepNum,
        isAvailable: true,
        isApproved: true,
        approvalStatus: 'approved',
        outletId: modalOutletId,
        createdAt: serverTimestamp(),
      });

      // 2. Also try subcollection
      try {
        await addDoc(collection(db, 'outlets', modalOutletId, 'menu_items'), {
          name: modalName.trim(),
          price: priceNum,
          category: modalCategory,
          prepTime: prepNum,
          isAvailable: true,
          outletId: modalOutletId,
          createdAt: serverTimestamp(),
        });
      } catch (_) {}

      setItems(prev => [
        {
          id: docRef.id,
          name: modalName.trim(),
          price: priceNum,
          category: modalCategory,
          prepTime: prepNum,
          isAvailable: true,
          outletId: modalOutletId,
        },
        ...prev,
      ]);

      setModalName('');
      setModalPrice('');
      setIsModalOpen(false);
    } catch (e) {
      console.error('Error adding menu item:', e);
      alert('Failed to add menu item');
    } finally {
      setSubmitting(false);
    }
  };

  const filteredItems = items.filter(i => {
    const matchesSearch = (i.name || '').toLowerCase().includes(search.toLowerCase());
    const matchesOutlet = outletFilter === 'ALL' || i.outletId === outletFilter;
    return matchesSearch && matchesOutlet;
  });

  const getOutletName = (outletId: string) => {
    const o = outlets.find(x => x.id === outletId);
    return o ? o.name : outletId;
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Menu Catalog
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Cross-outlet catalog, pricing, and live availability controls.
          </p>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          className="inline-flex items-center gap-2 bg-[#18181B] hover:bg-black text-[#FACC15] px-5 py-2.5 rounded-full font-extrabold text-xs transition-colors shadow-xs"
        >
          <Plus size={15} /> Add Menu Item
        </button>
      </div>

      {/* Filter and Search Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search size={14} className="absolute left-4 top-1/2 -translate-y-1/2 text-stone-400" />
          <input
            type="text"
            placeholder="Search menu items..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 text-xs bg-white border border-[#E7DFCE] rounded-full text-stone-900 focus:outline-none focus:border-stone-800 shadow-xs"
          />
        </div>

        <select
          value={outletFilter}
          onChange={e => setOutletFilter(e.target.value)}
          className="px-4 py-2 text-xs bg-white border border-[#E7DFCE] rounded-full text-stone-800 focus:outline-none focus:border-stone-800 shadow-xs font-semibold"
        >
          <option value="ALL">All Outlets ({items.length} items)</option>
          {outlets.map(o => (
            <option key={o.id} value={o.id}>{o.name}</option>
          ))}
        </select>
      </div>

      {/* Items Grid */}
      <div className="grid gap-3">
        {loading ? (
          <div className="p-12 text-center text-stone-400 bg-white rounded-[28px] border border-[#E9DFCB]">
            <div className="w-6 h-6 border-2 border-stone-800 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
            Loading menu items...
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="p-12 text-center text-stone-400 bg-white rounded-[28px] border border-[#E9DFCB]">
            No menu items found.
          </div>
        ) : (
          filteredItems.map((item, i) => (
            <motion.div
              key={item.id}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.02 }}
              className="p-4 sm:p-5 bg-white rounded-[26px] border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.02)] flex justify-between items-center"
            >
              <div className="space-y-1">
                <div className="flex items-center gap-2">
                  <p className={`text-base font-bold ${item.isAvailable ? 'text-stone-900' : 'text-stone-400 line-through'}`}>
                    {item.name}
                  </p>
                  <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-stone-600 bg-stone-100 px-2.5 py-0.5 rounded-full">
                    <Store size={11} className="text-stone-400" />
                    {getOutletName(item.outletId)}
                  </span>
                  {item.category && (
                    <span className="text-[10px] text-stone-700 bg-[#FAF6EE] border border-[#E7DFCE] px-2 py-0.5 rounded-full font-bold">
                      {item.category}
                    </span>
                  )}
                </div>
                <div className="flex items-center gap-3 text-xs text-stone-500 font-medium">
                  <span className="font-extrabold text-stone-900">₹{item.price}</span>
                  {item.prepTime && <span>• ~{item.prepTime} mins</span>}
                </div>
              </div>

              <div className="flex items-center gap-4">
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    className="sr-only peer"
                    checked={item.isAvailable}
                    onChange={() => toggleAvailability(item)}
                  />
                  <div className="w-11 h-6 bg-stone-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-stone-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500"></div>
                </label>

                <button
                  onClick={() => deleteItem(item)}
                  className="p-2 text-stone-400 hover:text-red-500 transition-colors rounded-full hover:bg-stone-100"
                  title="Delete Item"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </motion.div>
          ))
        )}
      </div>

      {/* Add Item Modal */}
      <AnimatePresence>
        {isModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white border border-[#E9DFCB] rounded-[28px] p-6 shadow-2xl relative"
            >
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-bold text-stone-900">Add New Menu Item</h3>
                <button
                  onClick={() => setIsModalOpen(false)}
                  className="w-7 h-7 rounded-full bg-stone-100 flex items-center justify-center text-stone-500 hover:text-black transition-colors"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleAddItem} className="space-y-4 text-xs">
                <div>
                  <label className="block text-stone-600 font-bold mb-1">Target Outlet</label>
                  <select
                    value={modalOutletId}
                    onChange={e => setModalOutletId(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
                    required
                  >
                    {outlets.map(o => (
                      <option key={o.id} value={o.id}>{o.name} ({o.id})</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-stone-600 font-bold mb-1">Item Name</label>
                  <input
                    type="text"
                    placeholder="e.g. Cold Coffee, Paneer Roll"
                    value={modalName}
                    onChange={e => setModalName(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
                    required
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-stone-600 font-bold mb-1">Price (₹)</label>
                    <input
                      type="number"
                      placeholder="e.g. 50"
                      value={modalPrice}
                      onChange={e => setModalPrice(e.target.value)}
                      className="w-full px-3.5 py-2.5 bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-stone-600 font-bold mb-1">Prep Time (mins)</label>
                    <input
                      type="number"
                      placeholder="e.g. 5"
                      value={modalPrepTime}
                      onChange={e => setModalPrepTime(e.target.value)}
                      className="w-full px-3.5 py-2.5 bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-stone-600 font-bold mb-1">Category</label>
                  <select
                    value={modalCategory}
                    onChange={e => setModalCategory(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
                  >
                    {['Snacks', 'Meals', 'Beverages', 'Juices', 'Desserts', 'Other'].map(c => (
                      <option key={c} value={c}>{c}</option>
                    ))}
                  </select>
                </div>

                <div className="pt-2 flex items-center justify-end gap-2.5">
                  <button
                    type="button"
                    onClick={() => setIsModalOpen(false)}
                    className="px-4 py-2 rounded-full text-stone-500 hover:text-stone-900 font-bold transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={submitting}
                    className="px-5 py-2.5 bg-[#18181B] hover:bg-black text-[#FACC15] font-extrabold rounded-full transition-colors disabled:opacity-50 shadow-xs"
                  >
                    {submitting ? 'Adding...' : 'Add to Outlet Menu'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
