import { motion, AnimatePresence } from 'framer-motion';
import { useEffect, useState } from 'react';
import { collection, query, onSnapshot, doc, updateDoc, addDoc, serverTimestamp, orderBy } from 'firebase/firestore';
import { db } from '../lib/firebase';
import { CheckCircle2, XCircle, Clock, Store, Tag, AlertCircle, ShieldCheck } from 'lucide-react';

interface ApprovalTicket {
  id: string;
  type: string;
  status: 'pending' | 'approved' | 'rejected';
  outletId: string;
  outletName?: string;
  submittedByUid?: string;
  submittedByName?: string;
  createdAt?: any;
  reviewedAt?: any;
  rejectionReason?: string;
  itemData: {
    name: string;
    description?: string;
    price: number;
    category: string;
    prepTime: number;
    photoBase64?: string;
  };
}

export default function Approvals() {
  const [tickets, setTickets] = useState<ApprovalTicket[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'pending' | 'approved' | 'rejected'>('pending');
  
  // Rejection modal
  const [rejectingTicket, setRejectingTicket] = useState<ApprovalTicket | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    const q = query(
      collection(db, 'approval_tickets'),
      orderBy('createdAt', 'desc')
    );

    const unsub = onSnapshot(q, (snap) => {
      const data = snap.docs.map(d => ({ id: d.id, ...d.data() } as ApprovalTicket));
      setTickets(data);
      setLoading(false);
    }, (err) => {
      console.error('Error fetching tickets:', err);
      setLoading(false);
    });

    return () => unsub();
  }, []);

  const handleApprove = async (ticket: ApprovalTicket) => {
    if (processingId) return;
    setProcessingId(ticket.id);

    try {
      const itemRef = await addDoc(
        collection(db, 'outlets', ticket.outletId, 'menu_items'),
        {
          name: ticket.itemData.name,
          description: ticket.itemData.description || '',
          price: Number(ticket.itemData.price),
          category: ticket.itemData.category || 'Snacks',
          prepTime: Number(ticket.itemData.prepTime || 5),
          isAvailable: true,
          outletId: ticket.outletId,
          ticketId: ticket.id,
          photoBase64: ticket.itemData.photoBase64 || null,
          createdAt: serverTimestamp(),
        }
      );

      await updateDoc(doc(db, 'approval_tickets', ticket.id), {
        status: 'approved',
        publishedItemId: itemRef.id,
        reviewedAt: serverTimestamp(),
      });
    } catch (e) {
      console.error('Error approving ticket:', e);
      alert('Failed to approve ticket: ' + e);
    } finally {
      setProcessingId(null);
    }
  };

  const handleRejectConfirm = async () => {
    if (!rejectingTicket || processingId) return;
    setProcessingId(rejectingTicket.id);

    try {
      await updateDoc(doc(db, 'approval_tickets', rejectingTicket.id), {
        status: 'rejected',
        rejectionReason: rejectReason.trim() || 'Rejected by Administrator',
        reviewedAt: serverTimestamp(),
      });
      setRejectingTicket(null);
      setRejectReason('');
    } catch (e) {
      console.error('Error rejecting ticket:', e);
      alert('Failed to reject ticket');
    } finally {
      setProcessingId(null);
    }
  };

  const filteredTickets = tickets.filter(t => t.status === filter);
  const pendingCount = tickets.filter(t => t.status === 'pending').length;

  return (
    <div className="space-y-6">
      {/* Header & Tabs */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-white border border-[#E7DFCE] text-[#18181B] rounded-full flex items-center justify-center shadow-xs">
              <ShieldCheck size={20} />
            </div>
            <div>
              <h1 className="text-3xl font-normal tracking-tight text-stone-900">
                Approval Desk
              </h1>
              <p className="text-xs text-stone-500 mt-0.5">
                Review and approve new menu items submitted by campus outlet managers.
              </p>
            </div>
          </div>
        </div>

        {/* Status Filter Capsule Nav */}
        <div className="flex items-center gap-1 p-1 bg-white border border-[#E7DFCE] rounded-full shadow-xs">
          <button
            onClick={() => setFilter('pending')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              filter === 'pending'
                ? 'bg-[#18181B] text-white shadow-xs'
                : 'text-stone-600 hover:text-stone-900'
            }`}
          >
            <Clock size={12} />
            Pending ({pendingCount})
          </button>
          <button
            onClick={() => setFilter('approved')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              filter === 'approved'
                ? 'bg-[#18181B] text-white shadow-xs'
                : 'text-stone-600 hover:text-stone-900'
            }`}
          >
            <CheckCircle2 size={12} />
            Approved
          </button>
          <button
            onClick={() => setFilter('rejected')}
            className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all flex items-center gap-1.5 ${
              filter === 'rejected'
                ? 'bg-[#18181B] text-white shadow-xs'
                : 'text-stone-600 hover:text-stone-900'
            }`}
          >
            <XCircle size={12} />
            Rejected
          </button>
        </div>
      </div>

      {/* Tickets List */}
      <div className="grid gap-4">
        {loading ? (
          <div className="p-12 text-center text-stone-400 bg-white rounded-[28px] border border-[#E9DFCB]">
            <div className="w-6 h-6 border-2 border-stone-800 border-t-transparent rounded-full animate-spin mx-auto mb-2" />
            Loading approval tickets...
          </div>
        ) : filteredTickets.length === 0 ? (
          <div className="p-12 text-center bg-white rounded-[28px] border border-[#E9DFCB]">
            <AlertCircle className="w-12 h-12 text-stone-300 mx-auto mb-3" />
            <p className="text-base font-bold text-stone-800">
              {filter === 'pending' ? 'No pending approval requests' : `No ${filter} tickets`}
            </p>
            <p className="text-xs text-stone-400 mt-1">
              {filter === 'pending'
                ? 'When an outlet manager submits a new dish, their approval ticket will appear here.'
                : 'Archived tickets will be listed here for record keeping.'}
            </p>
          </div>
        ) : (
          filteredTickets.map((ticket, i) => {
            const isPending = ticket.status === 'pending';
            const item = ticket.itemData;

            return (
              <motion.div
                key={ticket.id}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: i * 0.04 }}
                className="p-5 sm:p-6 bg-white rounded-[28px] border border-[#E9DFCB] shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)]"
              >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-6">
                  {/* Item Image + Details */}
                  <div className="flex items-start gap-4">
                    {/* Thumbnail */}
                    <div className="w-20 h-20 rounded-[20px] bg-stone-100 border border-stone-200 flex items-center justify-center overflow-hidden shrink-0">
                      {item.photoBase64 ? (
                        <img
                          src={`data:image/jpeg;base64,${item.photoBase64}`}
                          alt={item.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <Tag className="w-7 h-7 text-stone-400" />
                      )}
                    </div>

                    <div className="space-y-1.5">
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="text-lg font-bold text-stone-900">{item.name}</span>
                        <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-[#FAF6EE] text-stone-700 border border-[#E7DFCE]">
                          {item.category || 'General'}
                        </span>
                        <span className="inline-flex items-center gap-1 text-xs text-stone-500 font-medium">
                          <Store size={13} className="text-stone-400" />
                          {ticket.outletName || ticket.outletId}
                        </span>
                      </div>

                      {item.description && (
                        <p className="text-xs text-stone-500 max-w-xl">{item.description}</p>
                      )}

                      <div className="flex items-center gap-4 text-xs text-stone-600 font-medium pt-1">
                        <span className="font-extrabold text-stone-900 text-sm">₹{item.price}</span>
                        <span>• ~{item.prepTime || 5} min prep</span>
                        <span className="text-stone-400 font-normal">
                          Submitted by {ticket.submittedByName || 'Manager'}
                        </span>
                      </div>

                      {ticket.rejectionReason && (
                        <div className="mt-2 text-xs text-red-600 bg-red-50 px-3 py-1 rounded-xl border border-red-200/80">
                          Rejection Reason: {ticket.rejectionReason}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Actions */}
                  {isPending ? (
                    <div className="flex items-center gap-2.5 shrink-0">
                      <button
                        onClick={() => {
                          setRejectingTicket(ticket);
                          setRejectReason('');
                        }}
                        disabled={processingId === ticket.id}
                        className="px-4 py-2 rounded-full font-bold text-xs bg-stone-100 hover:bg-stone-200 text-stone-700 border border-stone-200 transition-colors disabled:opacity-50"
                      >
                        Reject ✕
                      </button>
                      <button
                        onClick={() => handleApprove(ticket)}
                        disabled={processingId === ticket.id}
                        className="px-5 py-2 rounded-full font-extrabold text-xs bg-[#18181B] hover:bg-black text-[#FACC15] shadow-xs transition-all disabled:opacity-50 flex items-center gap-1.5"
                      >
                        <CheckCircle2 size={13} />
                        {processingId === ticket.id ? 'Publishing...' : 'Approve & Publish ✓'}
                      </button>
                    </div>
                  ) : (
                    <div className="shrink-0">
                      <span className={`inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-full text-xs font-bold ${
                        ticket.status === 'approved'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-red-50 text-red-700 border border-red-200'
                      }`}>
                        {ticket.status === 'approved' ? <CheckCircle2 size={12} /> : <XCircle size={12} />}
                        {ticket.status.toUpperCase()}
                      </span>
                    </div>
                  )}
                </div>
              </motion.div>
            );
          })
        )}
      </div>

      {/* Reject Modal */}
      <AnimatePresence>
        {rejectingTicket && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              exit={{ opacity: 0, scale: 0.95 }}
              className="w-full max-w-md bg-white border border-[#E9DFCB] rounded-[28px] p-6 shadow-2xl"
            >
              <h3 className="text-lg font-bold text-stone-900 mb-2">Reject Menu Submission</h3>
              <p className="text-xs text-stone-500 mb-4">
                State the reason why "{rejectingTicket.itemData.name}" is being rejected. This feedback will be displayed to the outlet manager.
              </p>

              <textarea
                rows={3}
                placeholder="e.g. Price exceeds campus cap, duplicate item, low resolution photo..."
                value={rejectReason}
                onChange={e => setRejectReason(e.target.value)}
                className="w-full p-3 text-xs bg-stone-50 border border-stone-200 rounded-2xl text-stone-900 focus:outline-none focus:border-stone-800"
              />

              <div className="mt-4 flex items-center justify-end gap-2 text-xs">
                <button
                  onClick={() => setRejectingTicket(null)}
                  className="px-4 py-2 rounded-full text-stone-600 hover:text-stone-900 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleRejectConfirm}
                  disabled={processingId !== null}
                  className="px-5 py-2 bg-red-600 hover:bg-red-500 text-white font-bold rounded-full transition-colors disabled:opacity-50"
                >
                  Confirm Rejection
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
