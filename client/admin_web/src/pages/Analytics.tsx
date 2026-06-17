import { motion } from 'framer-motion';
import { BarChart3 } from 'lucide-react';

export default function Analytics() {
  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Analytics</h1>
        <p className="text-zinc-400 mt-1">Weekly performance and trends.</p>
      </div>

      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="h-[400px] bg-zinc-900/50 border border-zinc-800 rounded-2xl backdrop-blur-xl flex flex-col items-center justify-center text-zinc-500"
      >
        <BarChart3 size={64} className="opacity-20 mb-4" />
        <p>Detailed sales charts will be rendered here</p>
      </motion.div>
    </div>
  );
}
