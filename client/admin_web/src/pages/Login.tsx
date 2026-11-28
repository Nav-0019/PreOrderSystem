import { useState } from 'react';
import { auth, db } from '../lib/firebase';
import { signInWithEmailAndPassword, sendPasswordResetEmail } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { motion } from 'framer-motion';
import { Loader2, ArrowRight, CheckCircle2 } from 'lucide-react';

export default function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [resetSent, setResetSent] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setResetSent(false);

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
      if (err.code === 'auth/invalid-credential') {
        setError('Invalid email or password. Please verify your credentials or contact system support.');
      } else {
        setError(err.message || 'Login failed');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async () => {
    if (!email.trim()) {
      setError('Please enter your administrator email address above to receive a password reset link.');
      return;
    }
    try {
      setLoading(true);
      await sendPasswordResetEmail(auth, email.trim());
      setResetSent(true);
      setError(null);
    } catch (err: any) {
      setError(err.message || 'Failed to send reset email.');
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
            <div className="p-3 bg-red-500/15 border border-red-500/30 text-red-300 text-xs rounded-2xl font-medium leading-relaxed">
              {error}
            </div>
          )}

          {resetSent && (
            <div className="p-3 bg-emerald-500/15 border border-emerald-500/30 text-emerald-300 text-xs rounded-2xl font-medium flex items-center gap-2">
              <CheckCircle2 size={16} />
              <span>Password reset link sent to {email || 'your email'}! Check your inbox.</span>
            </div>
          )}

          <div className="space-y-1.5">
            <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider pl-1">Admin Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-[#24242A] border border-stone-700/80 focus:border-[#FACC15] rounded-2xl px-4 py-3 text-sm text-white outline-none transition-colors"
              placeholder="shubhamchauhan0019@gmail.com"
              required
            />
          </div>

          <div className="space-y-1.5">
            <div className="flex items-center justify-between pl-1">
              <label className="text-[11px] font-bold text-stone-400 uppercase tracking-wider">Password</label>
              <button
                type="button"
                onClick={handleResetPassword}
                className="text-[11px] text-[#FACC15] hover:underline"
              >
                Forgot password?
              </button>
            </div>
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
            className="w-full bg-[#FACC15] hover:bg-yellow-300 text-stone-950 font-extrabold py-3.5 rounded-full transition-all flex items-center justify-center gap-2 mt-6 text-sm shadow-md disabled:opacity-60 cursor-pointer"
          >
            {loading ? <Loader2 className="animate-spin" size={18} /> : (
              <>
                <span>Sign In to Dashboard</span>
                <ArrowRight size={15} />
              </>
            )}
          </button>
        </form>

        {/* Administrator Security & Account Help */}
        <div className="mt-6 pt-5 border-t border-stone-800 flex items-center justify-between text-xs text-stone-400">
          <span>Need access or forgot password?</span>
          <button
            type="button"
            onClick={handleResetPassword}
            disabled={loading}
            className="text-[#FACC15] hover:underline font-bold transition-colors cursor-pointer"
          >
            Reset Password
          </button>
        </div>
      </motion.div>
    </div>
  );
}
