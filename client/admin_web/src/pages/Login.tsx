import { useState } from 'react';
import { auth, db } from '../lib/firebase';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Loader2, ArrowRight } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const userCredential = await signInWithEmailAndPassword(auth, email.trim(), password);

      // Verify Role
      const userDocRef = doc(db, 'users', userCredential.user.uid);
      const docSnap = await getDoc(userDocRef);

      if (!docSnap.exists() || docSnap.data().role !== 'admin') {
        await auth.signOut();
        throw new Error('Access Denied. Administrator only.');
      }
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#FAF5EB] flex flex-col items-center justify-center p-6 relative overflow-hidden text-stone-900 selection:bg-[#FACC15]/40 font-['Plus_Jakarta_Sans',sans-serif]">
      {/* Warm Ambient Glows */}
      <div className="fixed top-0 right-0 w-[550px] h-[550px] bg-gradient-to-br from-[#FEF08A]/45 via-[#FDE047]/20 to-transparent blur-3xl pointer-events-none rounded-full z-0" />
      <div className="fixed bottom-0 left-0 w-[450px] h-[450px] bg-gradient-to-tr from-[#FEF9C3]/40 via-[#FAF5EB]/10 to-transparent blur-3xl pointer-events-none rounded-full z-0" />

      {/* Brand Pill */}
      <motion.div
        initial={{ opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        className="mb-8 z-10"
      >
        <span className="px-5 py-2 rounded-full border border-stone-800 bg-white/70 text-stone-900 font-extrabold text-sm tracking-tight shadow-sm">
          AuraBake
        </span>
      </motion.div>

      {/* High-Contrast Charcoal Login Bento Card */}
      <motion.div
        initial={{ opacity: 0, scale: 0.96 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.25 }}
        className="w-full max-w-md bg-[#18181B] text-white rounded-[32px] p-8 sm:p-10 shadow-2xl border border-stone-800 relative z-10"
      >
        <div className="text-center mb-8">
          <h1 className="text-2xl sm:text-3xl font-normal tracking-tight text-white">
            Welcome back, <span className="font-bold text-[#FACC15]">Admin</span>
          </h1>
          <p className="text-xs text-stone-400 mt-2 font-medium">
            Sign in to access the executive dispatch & approval desk
          </p>
        </div>

        <form onSubmit={handleLogin} className="space-y-4">
          {error && (
            <div className="p-3 bg-red-500/15 border border-red-500/30 text-red-300 text-xs rounded-2xl font-medium">
              {error}
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider pl-1">Admin Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-[#24242A] border border-stone-700/80 focus:border-[#FACC15] rounded-2xl px-4 py-3 text-sm text-white outline-none transition-colors"
              placeholder="admin@aurabake.app"
              required
            />
          </div>

          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider pl-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full bg-[#24242A] border border-stone-700/80 focus:border-[#FACC15] rounded-2xl px-4 py-3 text-sm text-white outline-none transition-colors"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-[#FACC15] hover:bg-yellow-300 text-stone-950 font-extrabold py-3.5 rounded-full transition-all flex items-center justify-center gap-2 mt-6 text-sm shadow-md disabled:opacity-60"
          >
            {loading ? <Loader2 className="animate-spin" size={18} /> : (
              <>
                <span>Sign In to Dashboard</span>
                <ArrowRight size={15} />
              </>
            )}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-stone-800 text-center text-[11px] text-stone-500">
          <p>Master Account: <span className="font-mono text-stone-300">admin@aurabake.app</span></p>
        </div>
      </motion.div>
    </div>
  );
}
