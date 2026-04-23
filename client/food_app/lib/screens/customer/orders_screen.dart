import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: theme.cardColor,
            child: const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Active order
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackingScreen())),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.primaryBdr)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order in Progress', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary)),
                            const SizedBox(height: 2),
                            Text('Tap to track · Counter No. 3', style: TextStyle(fontSize: 12, color: AppTheme.primary.withOpacity(0.7))),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
                          child: const Text('Preparing', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                        ),
                      ],
                    ),
                  ),
                ),

                Text('PAST ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
                const SizedBox(height: 12),

                _PastOrderCard(canteen: 'Main Canteen', info: '12 Apr · 12:30 PM · #44', items: '1× Masala Maggi, 1× Cold Coffee', total: '₹85', theme: theme),
                _PastOrderCard(canteen: 'Snack Corner', info: '10 Apr · 1:15 PM · #31', items: '2× Samosa (2pc)', total: '₹40', theme: theme),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  final String canteen, info, items, total;
  final ThemeData theme;
  const _PastOrderCard({required this.canteen, required this.info, required this.items, required this.total, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(canteen, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(info, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                child: const Text('Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          Text(items, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(total, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(8)),
                child: const Text('Reorder', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
