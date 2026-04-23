import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class BakerQueueScreen extends StatefulWidget {
  const BakerQueueScreen({super.key});

  @override
  State<BakerQueueScreen> createState() => _BakerQueueScreenState();
}

class _BakerQueueScreenState extends State<BakerQueueScreen> {
  bool _isTickets = true;
  bool _shiftActive = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: AppTheme.darkHdr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MAIN CANTEEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    const Text('Kitchen Queue', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                GestureDetector(
                  onTap: () => setState(() => _shiftActive = !_shiftActive),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _shiftActive ? AppTheme.green : AppTheme.red)),
                        const SizedBox(width: 6),
                        Text(_shiftActive ? 'Active' : 'Offline', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppTheme.indigoBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.indigoBdr)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Slot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.indigo)),
                          const SizedBox(height: 2),
                          Text('12:30–12:40 PM · 4/20 orders', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        ],
                      ),
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.indigo, width: 3)),
                        alignment: Alignment.center,
                        child: const Text('20%', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppTheme.indigo)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Toggle tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.dividerColor)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTickets = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: _isTickets ? theme.cardColor : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                            alignment: Alignment.center,
                            child: Text('Tickets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _isTickets ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.5))),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isTickets = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(color: !_isTickets ? theme.cardColor : Colors.transparent, borderRadius: BorderRadius.circular(999)),
                            alignment: Alignment.center,
                            child: Text('Bulk Prep', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: !_isTickets ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.5))),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (_isTickets) ...[
                  _ticket('#44', '1× Masala Maggi', '3 mins ago', true, theme),
                  _ticket('#45', '2× Veg Thali, 1× Cold Coffee', 'Just now', false, theme),
                ] else ...[
                  _bulkItem('Masala Maggi', 5, theme),
                  _bulkItem('Veg Thali', 12, theme),
                  _bulkItem('Cold Coffee', 3, theme),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticket(String id, String content, String time, bool priority, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: priority ? AppTheme.indigoBdr : theme.dividerColor),
        boxShadow: priority ? [BoxShadow(color: AppTheme.indigo.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))] : [],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(id, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    const SizedBox(width: 8),
                    if (priority)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.indigoBg, borderRadius: BorderRadius.circular(4)),
                        child: const Text('FACULTY', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.indigo)),
                      ),
                  ],
                ),
                Text(time, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(child: Text(content, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppTheme.green, borderRadius: BorderRadius.circular(10)),
                  child: const Text('Mark Ready', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bulkItem(String name, int qty, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          Text('$qty x', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primary)),
        ],
      ),
    );
  }
}
