import { motion } from 'framer-motion';
import { BarChart3 } from 'lucide-react';

export default function Analytics() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-normal tracking-tight text-stone-900">
          Campus Analytics & Trends
        </h1>
        <p className="text-xs text-stone-500 mt-0.5">
          Order volumes, outlet efficiency, and revenue reporting.
        </p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-5">
        <div className="p-6 bg-white rounded-[28px] border border-[#E9DFCB] shadow-xs">
          <p className="text-xs font-bold text-stone-400 uppercase tracking-wider">Peak Hour</p>
          <p className="text-3xl font-normal text-stone-900 mt-2">12:30 PM</p>
          <p className="text-xs text-emerald-600 font-bold mt-1">● 68% of daily rush</p>
        </div>
        <div className="p-6 bg-white rounded-[28px] border border-[#E9DFCB] shadow-xs">
          <p className="text-xs font-bold text-stone-400 uppercase tracking-wider">Top Stall</p>
          <p className="text-3xl font-normal text-stone-900 mt-2">Nescafe</p>
          <p className="text-xs text-stone-500 font-semibold mt-1">42 orders fulfilled today</p>
        </div>
        <div className="p-6 bg-white rounded-[28px] border border-[#E9DFCB] shadow-xs">
          <p className="text-xs font-bold text-stone-400 uppercase tracking-wider">Average Pickup Time</p>
          <p className="text-3xl font-normal text-stone-900 mt-2">4.2 min</p>
          <p className="text-xs text-[#EAB308] font-bold mt-1">⚡ 98% on-time fulfillment</p>
        </div>
      </div>

      <motion.div
        initial={{ opacity: 0, scale: 0.98 }}
        animate={{ opacity: 1, scale: 1 }}
        className="h-[360px] bg-white border border-[#E9DFCB] rounded-[32px] p-8 flex flex-col items-center justify-center text-stone-400 shadow-[0_4px_20px_-4px_rgba(0,0,0,0.03)] text-center"
      >
        <div className="w-16 h-16 rounded-full bg-stone-100 flex items-center justify-center text-stone-400 mb-4">
          <BarChart3 size={32} />
        </div>
        <h3 className="text-base font-bold text-stone-800">Weekly Performance Reporting</h3>
        <p className="text-xs text-stone-500 max-w-sm mt-1">
          Real-time aggregated hourly breakdowns, revenue graphs, and customer retention metrics will populate as order volume increases.
        </p>
      </motion.div>
    </div>
  );
}
