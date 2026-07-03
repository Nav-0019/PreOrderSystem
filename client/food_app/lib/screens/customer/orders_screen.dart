import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import 'tracking_screen.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late final Stream<List<Map<String, dynamic>>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = FirebaseService.streamMyOrders();
  }

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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _ordersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final _orders = snapshot.data ?? [];
                final activeOrders = _orders.where((o) => o['status'] != 'completed' && o['status'] != 'cancelled').toList();
                final pastOrders = _orders.where((o) => o['status'] == 'completed' || o['status'] == 'cancelled').toList();

                if (_orders.isEmpty) {
                  return const Center(child: Text('No orders yet.'));
                }

                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (activeOrders.isNotEmpty) ...[
                      Text('ACTIVE ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      ...activeOrders.map((o) => _ActiveOrderCard(order: o)),
                      const SizedBox(height: 20),
                    ],

                    if (pastOrders.isNotEmpty) ...[
                      Text('PAST ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      ...pastOrders.map((o) => _PastOrderCard(order: o, theme: theme)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final dynamic order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id']))),
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
                Text('Order at ${order['outletName'] ?? 'Outlet'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text('Tap to track · #${order['id'].toString().substring(0,6)}', style: TextStyle(fontSize: 12, color: AppTheme.primary.withOpacity(0.7))),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(999)),
              child: Text((order['status'] as String).toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  final dynamic order;
  final ThemeData theme;
  const _PastOrderCard({required this.order, required this.theme});

  @override
  Widget build(BuildContext context) {
    final createdAt = order['createdAt'];
    final date = createdAt != null ? (createdAt as Timestamp).toDate().toLocal() : DateTime.now();
    final formattedDate = DateFormat('dd MMM · hh:mm a').format(date);
    
    final itemsList = (order['items'] as List?)?.map((i) {
      return '${i['quantity']}× ${i['name']}';
    }).join(', ') ?? '';

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['outletName'] ?? 'Outlet', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('$formattedDate · #${order['id'].toString().substring(0,6)}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order['status'] == 'completed' ? AppTheme.green.withOpacity(0.1) : AppTheme.red.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(999)
                ),
                child: Text(
                  order['status'] == 'completed' ? 'Delivered' : 'Cancelled', 
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: order['status'] == 'completed' ? const Color(0xFF16A34A) : const Color(0xFFDC2626))
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          Text(itemsList, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 12),
          Text('₹${order['totalAmount']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ],
      ),
    );
  }
}
