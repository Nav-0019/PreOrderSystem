import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
                const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _notifItem(Icons.room_service, 'Order #44 is Ready!', 'Your Masala Maggi is at Counter No. 3', '2 min ago', theme),
                _notifItem(Icons.timer, 'Queue Alert', 'Main Canteen queue dropped to 5. Good time to order!', '15 min ago', theme),
                _notifItem(Icons.new_releases, 'New Item Added', 'Snack Corner added Cheese Burst Maggi today!', '1 hr ago', theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notifItem(IconData icon, String title, String sub, String time, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBg),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
