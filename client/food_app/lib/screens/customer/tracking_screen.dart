import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _step = 2; // 0:Ordered, 1:In Queue, 2:Preparing, 3:Ready

  void _simulateReady() {
    setState(() => _step = 3);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: theme.cardColor,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: theme.dividerColor)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.chevron_left, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Steps
                Row(
                  children: [
                    _buildStep(0, 'Ordered'), _buildLine(0),
                    _buildStep(1, 'In Queue'), _buildLine(1),
                    _buildStep(2, 'Preparing'), _buildLine(2),
                    _buildStep(3, 'Ready'),
                  ],
                ),
                const SizedBox(height: 24),

                // Position
                if (_step < 3)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                    child: Column(
                      children: [
                        Text('Your queue position', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                        const SizedBox(height: 6),
                        const Text('#4', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: AppTheme.primary, height: 1)),
                        const SizedBox(height: 8),
                        Text('3 orders ahead of you', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                      ],
                    ),
                  ),
                if (_step == 3)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryBdr)),
                    child: Column(
                      children: [
                        const Icon(Icons.celebration, size: 52, color: AppTheme.primary),
                        const SizedBox(height: 8),
                        const Text('Order Ready!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        const SizedBox(height: 4),
                        Text('Please collect it from Counter No. 3', style: TextStyle(fontSize: 13, color: AppTheme.primary.withOpacity(0.8))),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(child: _infoCard('Est. Pickup', _step == 3 ? 'Now' : '~12 min', theme)),
                    const SizedBox(width: 12),
                    Expanded(child: _infoCard('Counter', 'No. 3', theme)),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _step == 3 ? 'Enjoy your meal!' : 'Your food is being prepared now!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                ),

                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), side: BorderSide(color: theme.dividerColor)),
                  child: Text('Back to Home', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int s, String label) {
    bool done = _step > s;
    bool active = _step == s;
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: done || active ? AppTheme.primary : theme.scaffoldBackgroundColor, border: done || active ? null : Border.all(color: theme.dividerColor, width: 2)),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(active ? '✓' : '${s + 1}', style: TextStyle(color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w800, fontSize: 13)),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: done || active ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4))),
        ],
      ),
    );
  }

  Widget _buildLine(int s) {
    bool done = _step > s;
    return Expanded(
      child: Container(
        height: 2,
        color: done ? AppTheme.primary : Theme.of(context).dividerColor,
      ),
    );
  }

  Widget _infoCard(String label, String val, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 4),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
