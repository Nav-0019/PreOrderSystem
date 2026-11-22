import { motion, AnimatePresence } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collectionGroup, getDocs, collection, doc, updateDoc, addDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import {
  Plus,
  Trash2,
  Search,
  Store,
  X,
  Edit3,
  Clock,
  Coffee,
  UtensilsCrossed,
  Sparkles,
  Cake,
} from 'lucide-react';

interface MenuItem {
  id: string;
  outletId: string;
  name: string;
  price: number;
  isAvailable: boolean;
  category?: string;
  prepTime?: number;
  description?: string;
  photoBase64?: string;
}

interface Outlet {
  id: string;
  name: string;
  isOpen?: boolean;
}

export default function MenuManagement() {
  const [items, setItems] = useState<MenuItem[]>([]);
  const [outlets, setOutlets] = useState<Outlet[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [selectedOutlet, setSelectedOutlet] = useState<string>('ALL');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');

  // Add Item Modal state
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [addOutletId, setAddOutletId] = useState('');
  const [addName, setAddName] = useState('');
  const [addPrice, setAddPrice] = useState('');
  const [addCategory, setAddCategory] = useState('Snacks');
  const [addPrepTime, setAddPrepTime] = useState('5');
  const [addDescription, setAddDescription] = useState('');
  const [isSubmittingAdd, setIsSubmittingAdd] = useState(false);

  // Edit Item Modal state
  const [editingItem, setEditingItem] = useState<MenuItem | null>(null);
  const [editName, setEditName] = useState('');
  const [editPrice, setEditPrice] = useState('');
  const [editCategory, setEditCategory] = useState('Snacks');
  const [editPrepTime, setEditPrepTime] = useState('5');
  const [editOutletId, setEditOutletId] = useState('');
  const [editDescription, setEditDescription] = useState('');
  const [editIsAvailable, setEditIsAvailable] = useState(true);
  const [isSubmittingEdit, setIsSubmittingEdit] = useState(false);

  const categories = ['ALL', 'Snacks', 'Beverages', 'Bakery', 'Meals', 'Desserts'];

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      const outletsSnap = await getDocs(collection(db, 'outlets'));
      const outletList = outletsSnap.docs.map(d => ({
        id: d.id,
        name: (d.data().name as string) || d.id,
        isOpen: d.data().isOpen !== false,
      }));
      setOutlets(outletList);
      if (outletList.length > 0 && !addOutletId) {
        setAddOutletId(outletList[0].id);
      }

      // Fetch from root menu_items
      const snap = await getDocs(collection(db, 'menu_items'));
      const data = snap.docs.map(d => {
        const itemData = d.data();
        return {
          id: d.id,
          outletId: itemData.outletId || (outletList[0]?.id ?? '2000'),
          name: itemData.name || 'Item',
          price: Number(itemData.price || 0),
          isAvailable: itemData.isAvailable ?? true,
          category: itemData.category || 'Snacks',
          prepTime: Number(itemData.prepTime || 5),
          description: itemData.description || '',
          photoBase64: itemData.photoBase64,
        } as MenuItem;
      });

      // Also deduplicate with collectionGroup if any subcollection items exist
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
      await updateDoc(doc(db, 'menu_items', item.id), { isAvailable: newStatus });
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

  // Open Edit Modal with Pre-filled Data
  const openEditModal = (item: MenuItem) => {
    setEditingItem(item);
    setEditName(item.name);
    setEditPrice(item.price.toString());
    setEditCategory(item.category || 'Snacks');
    setEditPrepTime((item.prepTime || 5).toString());
    setEditOutletId(item.outletId);
    setEditDescription(item.description || '');
    setEditIsAvailable(item.isAvailable);
  };

  // Save Edit Changes
  const handleSaveEdit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingItem || !editName.trim() || !editPrice.trim()) return;

    setIsSubmittingEdit(true);
    try {
      const priceNum = parseFloat(editPrice) || 0;
      const prepNum = parseInt(editPrepTime) || 5;

      const updateData = {
        name: editName.trim(),
        price: priceNum,
        category: editCategory,
        prepTime: prepNum,
        outletId: editOutletId,
        description: editDescription.trim(),
        isAvailable: editIsAvailable,
        updatedAt: serverTimestamp(),
      };

      await updateDoc(doc(db, 'menu_items', editingItem.id), updateData);
      if (editingItem.outletId) {
        try {
          await updateDoc(doc(db, 'outlets', editingItem.outletId, 'menu_items', editingItem.id), updateData);
        } catch (_) {}
      }

      setItems(prev => prev.map(i => i.id === editingItem.id ? { ...i, ...updateData } : i));
      setEditingItem(null);
    } catch (e) {
      console.error('Error updating menu item:', e);
      alert('Failed to update menu item: ' + e);
    } finally {
      setIsSubmittingEdit(false);
    }
  };

  // Add Item Submit
  const handleAddItem = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!addOutletId || !addName.trim() || !addPrice.trim()) return;

    setIsSubmittingAdd(true);
    try {
      const priceNum = parseFloat(addPrice) || 0;
      const prepNum = parseInt(addPrepTime) || 5;

      const docRef = await addDoc(collection(db, 'menu_items'), {
        name: addName.trim(),
        price: priceNum,
        category: addCategory,
        prepTime: prepNum,
        description: addDescription.trim(),
        isAvailable: true,
        isApproved: true,
        approvalStatus: 'approved',
        outletId: addOutletId,
        createdAt: serverTimestamp(),
      });

      try {
        await addDoc(collection(db, 'outlets', addOutletId, 'menu_items'), {
          name: addName.trim(),
          price: priceNum,
          category: addCategory,
          prepTime: prepNum,
          description: addDescription.trim(),
          isAvailable: true,
          outletId: addOutletId,
          createdAt: serverTimestamp(),
        });
      } catch (_) {}

      setItems(prev => [
        {
          id: docRef.id,
          name: addName.trim(),
          price: priceNum,
          category: addCategory,
          prepTime: prepNum,
          description: addDescription.trim(),
          isAvailable: true,
          outletId: addOutletId,
        },
        ...prev,
      ]);

      setAddName('');
      setAddPrice('');
      setAddDescription('');
      setIsAddModalOpen(false);
    } catch (e) {
      console.error('Error adding menu item:', e);
      alert('Failed to add menu item');
    } finally {
      setIsSubmittingAdd(false);
    }
  };

  // Filter items by search, vendor/outlet, and category
  const filteredItems = items.filter(i => {
    const matchesSearch =
      (i.name || '').toLowerCase().includes(search.toLowerCase()) ||
      (i.description || '').toLowerCase().includes(search.toLowerCase());
    const matchesOutlet = selectedOutlet === 'ALL' || i.outletId === selectedOutlet;
    const matchesCategory = selectedCategory === 'ALL' || (i.category || 'General').toLowerCase() === selectedCategory.toLowerCase();
    return matchesSearch && matchesOutlet && matchesCategory;
  });

  const getOutletName = (outletId: string) => {
    const o = outlets.find(x => x.id === outletId);
    return o ? o.name : `Outlet ${outletId}`;
  };

  const getCategoryIcon = (category?: string) => {
    const c = (category || '').toLowerCase();
    if (c.includes('beverage') || c.includes('coffee') || c.includes('tea') || c.includes('juice')) {
      return <Coffee size={15} className="text-amber-500" />;
    }
    if (c.includes('snack') || c.includes('puff') || c.includes('samosa') || c.includes('burger')) {
      return <UtensilsCrossed size={15} className="text-[#EAB308]" />;
    }
    if (c.includes('bakery') || c.includes('cake') || c.includes('dessert') || c.includes('pastry')) {
      return <Cake size={15} className="text-pink-500" />;
    }
    return <Sparkles size={15} className="text-emerald-500" />;
  };

  return (
    <div className="space-y-6">
      {/* ─── PAGE HEADER ─── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-3xl font-normal tracking-tight text-stone-900">
            Menu Catalog
          </h1>
          <p className="text-xs text-stone-500 mt-0.5">
            Cross-outlet vendor menus, live price controls, and item configuration.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="inline-flex items-center gap-2 bg-[#18181B] hover:bg-black text-[#FACC15] px-5 py-2.5 rounded-full font-extrabold text-xs transition-transform hover:scale-105 shadow-xs"
          >
            <Plus size={15} /> Add Menu Item
          </button>
        </div>
      </div>

      {/* ─── VENDOR / SHOP CAPSULE TABS ─── */}
      <div className="p-3 bg-white rounded-[26px] border border-[#E9DFCB] shadow-xs space-y-3">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold text-stone-400 uppercase tracking-wider pl-1">
            Shop Vendors ({outlets.length})
          </span>
          <span className="text-[11px] font-bold text-stone-500">
            {filteredItems.length} items shown
          </span>
        </div>

        {/* Horizontal Vendor Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none">
          <button
            onClick={() => setSelectedOutlet('ALL')}
            className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all flex items-center gap-2 ${
              selectedOutlet === 'ALL'
                ? 'bg-[#18181B] text-white shadow-xs'
                : 'bg-stone-50 text-stone-600 hover:text-stone-900 hover:bg-stone-100 border border-stone-200/70'
            }`}
          >
            <Store size={13} />
            <span>All Stalls</span>
            <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${selectedOutlet === 'ALL' ? 'bg-[#FACC15] text-stone-950 font-black' : 'bg-stone-200 text-stone-700'}`}>
              {items.length}
            </span>
          </button>

          {outlets.map(outlet => {
            const count = items.filter(i => i.outletId === outlet.id).length;
            const isSelected = selectedOutlet === outlet.id;
            return (
              <button
                key={outlet.id}
                onClick={() => setSelectedOutlet(outlet.id)}
                className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all flex items-center gap-2 ${
                  isSelected
                    ? 'bg-[#18181B] text-white shadow-xs'
                    : 'bg-stone-50 text-stone-600 hover:text-stone-900 hover:bg-stone-100 border border-stone-200/70'
                }`}
              >
                <span className={`w-2 h-2 rounded-full ${outlet.isOpen !== false ? 'bg-emerald-500' : 'bg-red-400'}`} />
                <span>{outlet.name}</span>
                <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${isSelected ? 'bg-[#FACC15] text-stone-950 font-black' : 'bg-stone-200 text-stone-700'}`}>
                  {count}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* ─── SEARCH & CATEGORY FILTER BAR ─── */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3">
        {/* Category Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
          {categories.map(cat => (
            <button
              key={cat}
              onClick={() => setSelectedCategory(cat)}
              className={`px-3.5 py-1.5 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
                selectedCategory === cat
                  ? 'bg-[#FACC15] text-stone-950 shadow-xs'
                  : 'bg-white text-stone-600 hover:text-stone-900 border border-[#E7DFCE]'
              }`}
            >
              {cat === 'ALL' ? 'All Categories' : cat}
            </button>
          ))}
        </div>

        {/* Search Input */}
        <div className="relative flex-1 sm:max-w-xs">
          <Search size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-stone-400" />
          <input
            type="text"
            placeholder="Search items, description..."
            value={search}
            onChange={e => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 text-xs bg-white border border-[#E7DFCE] rounded-full text-stone-900 focus:outline-none focus:border-stone-800 shadow-xs"
          />
        </div>
      </div>

      {/* ─── ITEMS BENTO CARD GRID (CREXTIO FORMAT) ─── */}
      <div>
        {loading ? (
          <div className="p-16 text-center text-stone-400 bg-white rounded-[32px] border border-[#E9DFCB]">
            <div className="w-7 h-7 border-2 border-stone-800 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
            <p className="text-xs font-bold text-stone-600">Loading catalog items...</p>
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="p-16 text-center bg-white rounded-[32px] border border-[#E9DFCB] shadow-xs">
            <Store className="w-12 h-12 text-stone-300 mx-auto mb-3" />
            <p className="text-base font-bold text-stone-800">No items match your filter</p>
            <p className="text-xs text-stone-400 mt-1">Try selecting another stall or category.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filteredItems.map((item, i) => {
              const outletName = getOutletName(item.outletId);
              return (
                <motion.div
                  key={item.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: i * 0.02 }}
                  className="p-5 bg-white rounded-[28px] border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] flex flex-col justify-between hover:border-stone-400 transition-all group"
                >
                  <div className="space-y-3">
                    {/* Top Row: Category Icon & Badges */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-8 h-8 rounded-full bg-stone-50 border border-stone-200/60 flex items-center justify-center">
                          {getCategoryIcon(item.category)}
                        </div>
                        <span className="text-[10px] font-bold text-stone-700 bg-[#FAF6EE] border border-[#E7DFCE] px-2.5 py-0.5 rounded-full">
                          {item.category || 'General'}
                        </span>
                      </div>

                      {/* Outlet / Vendor Tag */}
                      <span className="inline-flex items-center gap-1 text-[10px] font-bold text-stone-600 bg-stone-100 px-2.5 py-0.5 rounded-full border border-stone-200/50">
                        <Store size={10} className="text-stone-400" />
                        <span className="truncate max-w-[110px]">{outletName}</span>
                      </span>
                    </div>

                    {/* Item Name & Description */}
                    <div>
                      <h3 className={`text-base font-bold tracking-tight ${item.isAvailable ? 'text-stone-900' : 'text-stone-400 line-through'}`}>
                        {item.name}
                      </h3>
                      {item.description ? (
                        <p className="text-xs text-stone-500 line-clamp-2 mt-0.5 font-normal">
                          {item.description}
                        </p>
                      ) : (
                        <p className="text-xs text-stone-400 italic mt-0.5">
                          Freshly prepared on campus.
                        </p>
                      )}
                    </div>

                    {/* Price & Prep Time Tags */}
                    <div className="flex items-center gap-3 pt-1">
                      <span className="text-xl font-normal text-stone-900">
                        ₹{item.price}
                      </span>
                      {item.prepTime && (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-stone-500 bg-stone-50 px-2 py-0.5 rounded-lg border border-stone-200/50">
                          <Clock size={11} className="text-stone-400" />
                          <span>~{item.prepTime}m prep</span>
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Bottom Controls Row: Availability Switch, Edit Button, Delete Button */}
                  <div className="pt-4 mt-4 border-t border-stone-100 flex items-center justify-between">
                    {/* Availability Switch */}
                    <label className="flex items-center gap-2 cursor-pointer select-none">
                      <div className="relative inline-flex items-center">
                        <input
                          type="checkbox"
                          className="sr-only peer"
                          checked={item.isAvailable}
                          onChange={() => toggleAvailability(item)}
                        />
                        <div className="w-9 h-5 bg-stone-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-stone-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-emerald-500" />
                      </div>
                      <span className={`text-[10px] font-bold ${item.isAvailable ? 'text-emerald-700' : 'text-stone-400'}`}>
                        {item.isAvailable ? 'In Stock' : 'Sold Out'}
                      </span>
                    </label>

                    {/* Edit & Delete Action Buttons */}
                    <div className="flex items-center gap-1.5">
                      {/* Fully Functional Edit Button */}
                      <button
                        onClick={() => openEditModal(item)}
                        className="inline-flex items-center gap-1 px-3 py-1.5 rounded-full bg-stone-100 hover:bg-stone-200 text-stone-700 text-xs font-bold transition-colors shadow-2xs"
                        title="Edit Menu Item Details"
                      >
                        <Edit3 size={12} />
                        <span>Edit</span>
                      </button>

                      {/* Delete Button */}
                      <button
                        onClick={() => deleteItem(item)}
                        className="w-7 h-7 rounded-full bg-stone-100 hover:bg-red-50 text-stone-400 hover:text-red-500 flex items-center justify-center transition-colors"
                        title="Delete Item"
                      >
                        <Trash2 size={13} />
                      </button>
                    </div>
                  </div>
                </motion.div>
              );
            })}
          </div>
        )}
      </div>

      {/* ─── FILLABLE EDIT MENU ITEM MODAL ─── */}
      <AnimatePresence>
        {editingItem && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-lg bg-white rounded-[32px] p-6 sm:p-7 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-lg font-bold text-stone-900">Edit Menu Item</h3>
                  <p className="text-xs text-stone-500">Update item pricing, category, and vendor details</p>
                </div>
                <button
                  onClick={() => setEditingItem(null)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleSaveEdit} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Item Name</label>
                    <input
                      type="text"
                      required
                      value={editName}
                      onChange={e => setEditName(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Price (₹)</label>
                    <input
                      type="number"
                      step="1"
                      required
                      value={editPrice}
                      onChange={e => setEditPrice(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Category</label>
                    <select
                      value={editCategory}
                      onChange={e => setEditCategory(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    >
                      {categories.filter(c => c !== 'ALL').map(c => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Prep Time (mins)</label>
                    <input
                      type="number"
                      min="1"
                      value={editPrepTime}
                      onChange={e => setEditPrepTime(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Stall Vendor</label>
                    <select
                      value={editOutletId}
                      onChange={e => setEditOutletId(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800 font-medium"
                    >
                      {outlets.map(o => (
                        <option key={o.id} value={o.id}>{o.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Item Description</label>
                  <textarea
                    rows={3}
                    placeholder="Describe ingredients, taste profile, or special options..."
                    value={editDescription}
                    onChange={e => setEditDescription(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="flex items-center justify-between p-3 bg-stone-50 rounded-2xl border border-stone-100">
                  <div>
                    <p className="text-xs font-bold text-stone-900">Item Availability</p>
                    <p className="text-[10px] text-stone-500">Allow customers to add this item to cart</p>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={editIsAvailable}
                      onChange={e => setEditIsAvailable(e.target.checked)}
                      className="sr-only peer"
                    />
                    <div className="w-10 h-6 bg-stone-200 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-stone-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-emerald-500" />
                  </label>
                </div>

                <div className="flex items-center gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setEditingItem(null)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingEdit}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingEdit ? 'Saving...' : 'Save Changes'}
                  </button>
                </div>
              </form>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* ─── FILLABLE ADD MENU ITEM MODAL ─── */}
      <AnimatePresence>
        {isAddModalOpen && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-lg bg-white rounded-[32px] p-6 sm:p-7 shadow-2xl border border-[#E9DFCB] space-y-4"
            >
              <div className="flex items-center justify-between pb-3 border-b border-stone-100">
                <div>
                  <h3 className="text-lg font-bold text-stone-900">Add New Menu Item</h3>
                  <p className="text-xs text-stone-500">Create new catalog item and publish to stall</p>
                </div>
                <button
                  onClick={() => setIsAddModalOpen(false)}
                  className="w-8 h-8 rounded-full bg-stone-100 hover:bg-stone-200 flex items-center justify-center text-stone-600"
                >
                  <X size={15} />
                </button>
              </div>

              <form onSubmit={handleAddItem} className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Item Name</label>
                    <input
                      type="text"
                      required
                      placeholder="e.g. Masala Chai, Veg Roll"
                      value={addName}
                      onChange={e => setAddName(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Price (₹)</label>
                    <input
                      type="number"
                      step="1"
                      required
                      placeholder="e.g. 25"
                      value={addPrice}
                      onChange={e => setAddPrice(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Category</label>
                    <select
                      value={addCategory}
                      onChange={e => setAddCategory(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    >
                      {categories.filter(c => c !== 'ALL').map(c => (
                        <option key={c} value={c}>{c}</option>
                      ))}
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Prep Time (mins)</label>
                    <input
                      type="number"
                      min="1"
                      value={addPrepTime}
                      onChange={e => setAddPrepTime(e.target.value)}
                      className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-stone-700 mb-1">Stall Vendor</label>
                    <select
                      value={addOutletId}
                      onChange={e => setAddOutletId(e.target.value)}
                      className="w-full px-3 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800 font-medium"
                    >
                      {outlets.map(o => (
                        <option key={o.id} value={o.id}>{o.name}</option>
                      ))}
                    </select>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-stone-700 mb-1">Description</label>
                  <textarea
                    rows={3}
                    placeholder="Short description of the item..."
                    value={addDescription}
                    onChange={e => setAddDescription(e.target.value)}
                    className="w-full px-3.5 py-2 text-xs bg-stone-50 border border-stone-200 rounded-xl text-stone-900 focus:outline-none focus:border-stone-800"
                  />
                </div>

                <div className="flex items-center gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setIsAddModalOpen(false)}
                    className="flex-1 py-2.5 rounded-full border border-stone-300 text-xs font-bold text-stone-700 hover:bg-stone-50"
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingAdd}
                    className="flex-1 py-2.5 rounded-full bg-[#18181B] hover:bg-black text-[#FACC15] text-xs font-bold shadow-xs transition-transform hover:scale-105 disabled:opacity-50"
                  >
                    {isSubmittingAdd ? 'Adding...' : 'Add Item'}
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
