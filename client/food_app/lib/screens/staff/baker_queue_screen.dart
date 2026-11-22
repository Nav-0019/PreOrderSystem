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

class _BakerQueueScreenState extends State<BakerQueueScreen> with SingleTickerProviderStateMixin {
  bool _shiftActive = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rawOutletId = context.watch<UserProvider>().managedOutletId;
    final outletId = (rawOutletId != null && rawOutletId.trim().isNotEmpty) ? rawOutletId.trim() : null;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header
            StreamBuilder<Map<String, dynamic>?>(
              stream: outletId != null ? FirebaseService.streamOutlet(outletId) : const Stream.empty(),
              builder: (context, outletSnap) {
                final outletData = outletSnap.data;
                final dynamicOutletName = outletData?['name'] as String? ?? (outletId != null ? 'OUTLET $outletId' : 'MY OUTLET');
                final isOutletOpen = outletData?['isOpen'] as bool? ?? _shiftActive;

                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
                  color: AppTheme.darkHdr,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dynamicOutletName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                                const SizedBox(height: 4),
                                const Text('Order Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              final nextState = !isOutletOpen;
                              setState(() => _shiftActive = nextState);
                              if (outletId != null) {
                                FirebaseService.updateOutlet(outletId, {'isOpen': nextState});
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                              child: Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOutletOpen ? AppTheme.green : AppTheme.red)),
                                  const SizedBox(width: 6),
                                  Text(isOutletOpen ? 'Active' : 'Offline', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            if (outletId != null) ...[
              // Shift Metrics Ribbon
              _ShiftMetricsRibbon(outletId: outletId),

              // Tab Bar: Active vs Past Orders
              Container(
                color: theme.cardColor,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppTheme.primary,
                  indicatorWeight: 3,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Active Orders ⚡'),
                    Tab(text: 'Past Orders 📦'),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.dividerColor),
            ],

            // Content
            Expanded(
              child: outletId == null
                  ? _noOutletView(theme)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Active Orders
                        StreamBuilder<List<Map<String, dynamic>>>(
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

                        // Past Orders
                        StreamBuilder<List<Map<String, dynamic>>>(
                          stream: FirebaseService.streamOutletPastOrders(outletId),
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final pastOrders = snap.data ?? [];
                            if (pastOrders.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.history, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                    const SizedBox(height: 12),
                                    Text('No order history yet', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                                    const SizedBox(height: 4),
                                    Text('Completed & cancelled orders will be archived here', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.35))),
                                  ],
                                ),
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: pastOrders.length,
                              itemBuilder: (_, i) => _PastOrderTicket(order: pastOrders[i]),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
              'Your manager account is not linked to any outlet. Please select or set up your shop in the Profile tab.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftMetricsRibbon extends StatelessWidget {
  final String outletId;
  const _ShiftMetricsRibbon({required this.outletId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('outletId', isEqualTo: outletId).snapshots(),
      builder: (context, snap) {
        int totalOrders = 0;
        int itemsPrepared = 0;
        double revenue = 0.0;

        if (snap.hasData) {
          final docs = snap.data!.docs;
          totalOrders = docs.length;
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            if (['ready', 'completed'].contains(status)) {
              final items = (data['items'] as List<dynamic>?) ?? [];
              for (final it in items) {
                itemsPrepared += (it['quantity'] as num? ?? 1).toInt();
              }
            }
            if (status != 'cancelled') {
              revenue += (data['totalAmount'] as num? ?? 0.0).toDouble();
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _metricBox('Orders', totalOrders.toString(), Icons.receipt_long, AppTheme.primary, theme),
              ),
              Container(height: 28, width: 1, color: theme.dividerColor),
              Expanded(
                child: _metricBox('Prepared', itemsPrepared.toString(), Icons.check_circle_outline, AppTheme.green, theme),
              ),
              Container(height: 28, width: 1, color: theme.dividerColor),
              Expanded(
                child: _metricBox('Revenue', '₹${revenue.toStringAsFixed(0)}', Icons.currency_rupee, AppTheme.indigo, theme),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5))),
      ],
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
      final items = (widget.order['items'] as List<dynamic>?) ?? [];
      int maxPrepTime = 0;
      for (final item in items) {
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

  void _showPickupVerificationDialog() {
    final expectedToken = widget.order['pickupToken'] as String? ?? 
        (widget.order['id'].toString().length >= 4 
            ? widget.order['id'].toString().substring(widget.order['id'].toString().length - 4).toUpperCase() 
            : '1001');

    final tokenCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.primaryBg, shape: BoxShape.circle),
              child: const Icon(Icons.qr_code_scanner, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Verify Student Pickup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ask student to show their Pickup QR or 4-digit code on their phone screen.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryBdr),
              ),
              child: Column(
                children: [
                  const Text('STUDENT PICKUP TOKEN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: 1.1)),
                  const SizedBox(height: 4),
                  Text('#$expectedToken', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tokenCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 4,
              decoration: const InputDecoration(
                labelText: 'Enter 4-digit code to verify (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final entered = tokenCtrl.text.trim().toUpperCase();
              if (entered.isNotEmpty && entered != expectedToken.toUpperCase()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Token does not match! Please check student phone.')),
                );
                return;
              }
              Navigator.pop(ctx);
              _setStatus('completed');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Order verified and handed over successfully! ✓')),
              );
            },
            child: const Text('Confirm Handover ✓', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
          ),
        ],
      ),
    );
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
    final pickupToken = order['pickupToken'] as String? ?? '';
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
                if (pickupToken.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('PICKUP #$pickupToken', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                  ),
                ],
                if (isPremium) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.goldLight, Color(0xFFFFECB3)]),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.goldBorder, width: 0.5),
                    ),
                    child: const Text('PREMIUM ✦', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.goldDark)),
                  ),
                ],
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
                      Text('${item['quantity']}×', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
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
                    Row(
                      children: [
                        const Icon(Icons.qr_code, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        const Text('UPI QR Paid', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                        if ((order['transactionId'] as String?)?.isNotEmpty == true && order['transactionId'] != 'UPI_VERIFIED') ...[
                          const SizedBox(width: 4),
                          Text('(#${order['transactionId']})', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        ],
                      ],
                    ),
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
              child: _actionBtn('Verify Pickup & Handover ✓', AppTheme.primary, Icons.shopping_bag_outlined, _showPickupVerificationDialog),
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

class _PastOrderTicket extends StatelessWidget {
  final Map<String, dynamic> order;
  const _PastOrderTicket({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = order['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final items = (order['items'] as List<dynamic>?) ?? [];
    final total = order['totalAmount'] as num? ?? 0;
    final orderId = (order['id'] as String).substring(0, 6).toUpperCase();
    final pickupToken = order['pickupToken'] as String? ?? '';
    final createdAt = order['createdAt'];
    String formattedTime = '';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      formattedTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('#$orderId', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              if (pickupToken.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('#$pickupToken', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.green.withOpacity(0.1) : AppTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isCompleted ? '✓ Completed' : '✕ Cancelled',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isCompleted ? AppTheme.green : AppTheme.red),
                ),
              ),
              const SizedBox(width: 8),
              Text(formattedTime, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            items.map((it) => '${it['quantity']}x ${it['name']}').join(', '),
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.65)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid via UPI QR',
                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.45)),
              ),
              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}
