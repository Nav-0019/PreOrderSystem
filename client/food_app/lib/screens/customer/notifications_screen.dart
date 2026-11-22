import 'package:flutter/material.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import 'tracking_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              color: theme.cardColor,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.chevron_left, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Notifications & Updates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FirebaseService.streamMyOrders(),
                builder: (context, snap) {
                  final orders = snap.data ?? [];

                  if (orders.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _notifItem(
                          icon: Icons.info_outline,
                          title: 'Welcome to AuraBake!',
                          sub: 'Place your food pre-orders to get real-time preparation & pickup notifications here.',
                          time: 'Just now',
                          theme: theme,
                        ),
                        _notifItem(
                          icon: Icons.storefront,
                          title: 'Canteens are Live',
                          sub: 'Explore open campus stalls and browse freshly approved menu dishes.',
                          time: 'Today',
                          theme: theme,
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      final status = (o['status'] as String? ?? 'pending').toLowerCase();
                      final outlet = o['outletName'] ?? 'Campus Stall';
                      final token = o['pickupToken'] ?? (o['id'].toString().length >= 4 ? o['id'].toString().substring(o['id'].toString().length - 4).toUpperCase() : '1001');

                      IconData icon;
                      String title;
                      String sub;
                      Color iconColor = AppTheme.primary;

                      switch (status) {
                        case 'ready':
                          icon = Icons.check_circle_outline;
                          iconColor = AppTheme.green;
                          title = 'Order #$token is READY for Pickup! 🔔';
                          sub = 'Your food is ready at $outlet counter. Tap to view your pickup QR.';
                          break;
                        case 'prep':
                          icon = Icons.soup_kitchen_outlined;
                          iconColor = AppTheme.yellow;
                          title = 'Order #$token is being Prepared 👨‍🍳';
                          sub = '$outlet has accepted your order and started cooking.';
                          break;
                        case 'completed':
                          icon = Icons.task_alt;
                          iconColor = AppTheme.green;
                          title = 'Order #$token Picked Up Successfully ✓';
                          sub = 'Enjoy your meal from $outlet!';
                          break;
                        case 'cancelled':
                          icon = Icons.cancel_outlined;
                          iconColor = AppTheme.red;
                          title = 'Order #$token was Cancelled';
                          sub = 'Your order with $outlet was cancelled.';
                          break;
                        default:
                          icon = Icons.receipt_long;
                          title = 'Order #$token Placed & Waiting in Queue ⚡';
                          sub = 'Payment confirmed. $outlet will begin preparation shortly.';
                      }

                      return GestureDetector(
                        onTap: () {
                          if (status != 'completed' && status != 'cancelled') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: o['id'])));
                          }
                        },
                        child: _notifItem(
                          icon: icon,
                          title: title,
                          sub: sub,
                          time: 'Order #$token',
                          theme: theme,
                          iconColor: iconColor,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifItem({
    required IconData icon,
    required String title,
    required String sub,
    required String time,
    required ThemeData theme,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.dividerColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (iconColor ?? AppTheme.primary).withOpacity(0.12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: iconColor ?? AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 3),
                Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65), height: 1.3)),
                const SizedBox(height: 5),
                Text(time, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
