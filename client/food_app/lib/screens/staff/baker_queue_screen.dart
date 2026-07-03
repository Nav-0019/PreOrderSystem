import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class BakerQueueScreen extends StatefulWidget {
  const BakerQueueScreen({super.key});

  @override
  State<BakerQueueScreen> createState() => _BakerQueueScreenState();
}

class _BakerQueueScreenState extends State<BakerQueueScreen> {
  bool _shiftActive = true;

  @override
  Widget build(BuildContext context) {
    final rawOutletId = context.watch<UserProvider>().managedOutletId;
    final outletId = (rawOutletId != null && rawOutletId.trim().isNotEmpty) ? rawOutletId.trim() : null;
    const outletName = 'MY OUTLET';
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: AppTheme.darkHdr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(outletName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                    const SizedBox(height: 4),
                    const Text('Order Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _shiftActive = !_shiftActive);
                    if (outletId != null) {
                      FirebaseService.updateOutlet(outletId, {'isOpen': !_shiftActive == false ? true : false});
                    }
                  },
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
            child: outletId == null
                ? _noOutletView(theme)
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService.streamOutletOrders(outletId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final orders = snap.data ?? [];
                      if (orders.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('No active orders', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                              const SizedBox(height: 4),
                              Text('New orders will appear here in real-time', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.35))),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: orders.length,
                        itemBuilder: (_, i) => _OrderTicket(order: orders[i], outletId: outletId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _noOutletView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('No Outlet Assigned', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Your manager account is not linked to any outlet. Please complete your shop setup.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTicket extends StatefulWidget {
  final Map<String, dynamic> order;
  final String outletId;

  const _OrderTicket({required this.order, required this.outletId});

  @override
  State<_OrderTicket> createState() => _OrderTicketState();
}

class _OrderTicketState extends State<_OrderTicket> {
  Timer? _timer;
  Duration? _remaining;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startCountdownIfPrep();
  }

  @override
  void didUpdateWidget(_OrderTicket oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.order['status'] != widget.order['status']) {
      _timer?.cancel();
      _startCountdownIfPrep();
    }
  }

  void _startCountdownIfPrep() {
    final status = widget.order['status'] as String?;
    if (status != 'prep') return;

    final prepStartedAt = widget.order['prepStartedAt'];
    final prepTime = widget.order['prepTime'] as int? ?? 10;

    DateTime? startTime;
    if (prepStartedAt is Timestamp) {
      startTime = prepStartedAt.toDate();
    }
    if (startTime == null) return;

    final endTime = startTime.add(Duration(minutes: prepTime));
    _updateRemaining(endTime);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining(endTime);
    });
  }

  void _updateRemaining(DateTime endTime) {
    final now = DateTime.now();
    final diff = endTime.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _setStatus(String newStatus) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (newStatus == 'prep') {
      // Compute prep time as the max prepTime of all ordered items
      final items = (widget.order['items'] as List<dynamic>?) ?? [];
      int maxPrepTime = 0;
      for (final item in items) {
        // Fetch the menu item's prepTime from Firestore
        try {
          final menuItemId = item['menuItemId'] as String?;
          if (menuItemId != null) {
            final doc = await FirebaseFirestore.instance
                .collection('outlets')
                .doc(widget.outletId)
                .collection('menu_items')
                .doc(menuItemId)
                .get();
            final pt = doc.data()?['prepTime'] as int? ?? 5;
            if (pt > maxPrepTime) maxPrepTime = pt;
          }
        } catch (_) {}
      }
      if (maxPrepTime == 0) maxPrepTime = 10;

      // Write status + prepStartedAt + prepTime
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.order['id'])
          .update({
        'status': 'prep',
        'prepStartedAt': FieldValue.serverTimestamp(),
        'prepTime': maxPrepTime,
      });
    } else {
      await FirebaseService.updateOrderStatus(widget.order['id'], newStatus);
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final status = order['status'] as String? ?? 'pending';
    final isPremium = order['isPremium'] as bool? ?? false;
    final items = (order['items'] as List<dynamic>?) ?? [];
    final total = order['totalAmount'] as num? ?? 0;
    final orderId = (order['id'] as String).substring(0, 6).toUpperCase();
    final createdAt = order['createdAt'];
    String timeAgo = '';
    if (createdAt is Timestamp) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inMinutes < 1) {
        timeAgo = 'Just now';
      } else {
        timeAgo = '${diff.inMinutes}m ago';
      }
    }

    Color borderColor = theme.dividerColor;
    if (status == 'pending') borderColor = AppTheme.yellow.withOpacity(0.5);
    if (status == 'prep') borderColor = AppTheme.indigoBdr;
    if (status == 'ready') borderColor = AppTheme.green.withOpacity(0.5);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Text('#$orderId', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                const SizedBox(width: 8),
                if (isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.goldLight, Color(0xFFFFECB3)]),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.goldBorder, width: 0.5),
                    ),
                    child: const Text('PREMIUM ✦', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.goldDark)),
                  ),
                const Spacer(),
                _statusBadge(status),
                const SizedBox(width: 8),
                Text(timeAgo, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor),

          // Items list
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('${item['quantity']}×', style: TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      Text('₹${((item['unitPrice'] as num? ?? 0) * (item['quantity'] as num? ?? 1)).toStringAsFixed(0)}',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    ],
                  ),
                )),
                const Divider(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                    Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
                  ],
                ),
              ],
            ),
          ),

          // Countdown for prep orders
          if (status == 'prep' && _remaining != null)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.indigoBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.indigoBdr),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: AppTheme.indigo),
                  const SizedBox(width: 6),
                  Text(
                    _remaining!.inSeconds <= 0
                        ? 'Should be ready!'
                        : 'Est. ready in ${_remaining!.inMinutes}m ${_remaining!.inSeconds % 60}s',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.indigo),
                  ),
                ],
              ),
            ),

          // Action buttons
          if (status == 'pending')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _actionBtn('Reject', AppTheme.red, Icons.close, () => _setStatus('cancelled')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _actionBtn('Confirm & Start', AppTheme.primary, Icons.check_circle_outline, () => _setStatus('prep')),
                  ),
                ],
              ),
            ),
          if (status == 'prep')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _actionBtn('Mark Ready 🎉', AppTheme.green, Icons.done_all, () => _setStatus('ready')),
            ),
          if (status == 'ready')
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _actionBtn('Mark Collected ✓', AppTheme.primary, Icons.shopping_bag_outlined, () => _setStatus('completed')),
            ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'pending':
        color = AppTheme.yellow;
        label = '⏳ Pending';
        break;
      case 'prep':
        color = AppTheme.indigo;
        label = '🔥 In Prep';
        break;
      case 'ready':
        color = AppTheme.green;
        label = '✅ Ready';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color == AppTheme.yellow ? AppTheme.goldDark : color)),
    );
  }
}
