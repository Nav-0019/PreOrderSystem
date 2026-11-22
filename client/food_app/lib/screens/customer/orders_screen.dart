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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _ordersStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];
            final activeOrders = orders.where((o) => !['completed', 'cancelled'].contains(o['status'])).toList();
            final pastOrders = orders.where((o) => ['completed', 'cancelled'].contains(o['status'])).toList();

            return DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    color: theme.cardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Your Orders', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
                        const SizedBox(height: 4),
                        Text('Categorized stall pre-orders & pickup tokens',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const SizedBox(height: 14),
                        TabBar(
                          indicatorColor: AppTheme.primary,
                          indicatorWeight: 3,
                          labelColor: AppTheme.primary,
                          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          tabs: [
                            Tab(text: 'Active Orders ⚡ (${activeOrders.length})'),
                            Tab(text: 'Past Orders 📦 (${pastOrders.length})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: theme.dividerColor),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Tab 1: Active Orders
                        activeOrders.isEmpty
                            ? _buildEmptyState(theme, 'No active orders', 'Orders you place will appear here with live tracking.')
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: activeOrders.length,
                                itemBuilder: (context, i) => _ActiveOrderCard(order: activeOrders[i]),
                              ),

                        // Tab 2: Past Orders
                        pastOrders.isEmpty
                            ? _buildEmptyState(theme, 'No order history', 'Completed and cancelled orders will be archived here.')
                            : ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: pastOrders.length,
                                itemBuilder: (context, i) => _PastOrderCard(order: pastOrders[i], theme: theme),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 14),
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _ActiveOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final outletName = order['outletName'] as String? ?? 'Campus Stall';
    final total = order['totalAmount'] as num? ?? 0;
    final token = order['pickupToken'] as String? ?? 
      (order['id'].toString().length >= 4 ? order['id'].toString().substring(order['id'].toString().length - 4).toUpperCase() : '1001');
    final items = (order['items'] as List<dynamic>?) ?? [];
    final isReady = status == 'ready';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TrackingScreen(orderId: order['id']))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isReady ? const Color(0xFF16A34A) : AppTheme.primaryBdr, width: isReady ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: isReady ? const Color(0xFF16A34A).withOpacity(0.08) : AppTheme.primary.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor & Token Header Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isReady ? const Color(0xFFDCFCE7) : AppTheme.primaryBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isReady ? const Color(0xFF16A34A) : AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          outletName,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isReady ? const Color(0xFF166534) : AppTheme.primary,
                          ),
                        ),
                        Text(
                          'Order #${order['id'].toString().substring(0, 6)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: (isReady ? const Color(0xFF166534) : AppTheme.primary).withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pickup Token Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: isReady ? const Color(0xFF16A34A) : AppTheme.primaryBdr),
                    ),
                    child: Text(
                      'TOKEN #$token',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isReady ? const Color(0xFF16A34A) : AppTheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Item details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...items.map((it) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text('${it['quantity']}×', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(it['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        Text('₹${((it['price'] as num? ?? 0) * (it['quantity'] as num? ?? 1)).toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                  )),

                  const Divider(height: 16),

                  // Bottom Total & Status CTA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600)),
                          Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isReady ? const Color(0xFF16A34A) : AppTheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(isReady ? Icons.qr_code : Icons.navigation, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              isReady ? 'Collect Food ➔' : 'Track Order ➔',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastOrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final ThemeData theme;
  const _PastOrderCard({required this.order, required this.theme});

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final createdAt = order['createdAt'];
    final date = createdAt != null ? (createdAt as Timestamp).toDate().toLocal() : DateTime.now();
    final formattedDate = DateFormat('dd MMM · hh:mm a').format(date);
    final total = order['totalAmount'] as num? ?? 0;
    final items = (order['items'] as List<dynamic>?) ?? [];

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
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.storefront, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(order['outletName'] ?? 'Campus Stall', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? '✓ Completed' : '✕ Cancelled',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isCompleted ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$formattedDate · #${order['id'].toString().substring(0, 6).toUpperCase()}',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: theme.dividerColor),
          ),
          Text(
            items.map((i) => '${i['quantity']}× ${i['name']}').join(', '),
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Paid via UPI QR', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.45))),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
