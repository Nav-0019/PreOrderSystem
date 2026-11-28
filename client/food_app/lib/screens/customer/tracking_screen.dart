import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _step = 0; // 0:Ordered/Pending, 1:In Queue/Prep, 2:Preparing/Prep, 3:Ready
  String _currentStatus = 'pending';
  String _pickupToken = '';
  String _outletName = 'Campus Stall';
  String _transactionId = '';
  String _paymentStatus = 'PENDING_VERIFICATION';
  bool _isLoading = true;
  bool _isCancelling = false;
  late final Stream<List<Map<String, dynamic>>> _orderStream;

  @override
  void initState() {
    super.initState();
    _orderStream = FirebaseService.streamSingleOrder(widget.orderId);

    _orderStream.listen((data) {
      if (data.isNotEmpty && mounted) {
        final orderData = data[0];
        final status = (orderData['status'] as String?) ?? 'pending';
        final token = (orderData['pickupToken'] as String?) ??
            (widget.orderId.length >= 4
                ? widget.orderId.substring(widget.orderId.length - 4).toUpperCase()
                : '1001');

        setState(() {
          _currentStatus = status;
          _pickupToken = token;
          _outletName = orderData['outletName'] ?? 'Campus Stall';
          _transactionId = orderData['transactionId'] ?? '';
          _paymentStatus = (orderData['paymentStatus'] as String?) ?? 'PENDING_VERIFICATION';

          if (status == 'pending') {
            _step = 1; // Ordered -> In Queue
          } else if (status == 'prep') {
            _step = 2; // Preparing
          } else if (status == 'ready') {
            _step = 3; // Ready
          } else if (status == 'completed') {
            _step = 3;
          } else if (status == 'cancelled') {
            _step = 0;
          }
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _handleCancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No, Keep Order')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.red),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);
    final success = await FirebaseService.cancelOrder(widget.orderId);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order cancelled successfully.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order could not be cancelled. It may already be preparing.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = _currentStatus == 'cancelled';
    final isCompleted = _currentStatus == 'completed';

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
                  const Text('Order Status & Pickup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Payment status badge with accurate verification state
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _paymentStatus == 'PAID'
                                ? const Color(0xFFF0FDF4)
                                : (_paymentStatus == 'VERIFICATION_REJECTED'
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFFFFBEB)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _paymentStatus == 'PAID'
                                  ? const Color(0xFFBBF7D0)
                                  : (_paymentStatus == 'VERIFICATION_REJECTED'
                                      ? const Color(0xFFFECACA)
                                      : const Color(0xFFFDE68A)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _paymentStatus == 'PAID'
                                    ? Icons.check_circle
                                    : (_paymentStatus == 'VERIFICATION_REJECTED'
                                        ? Icons.cancel
                                        : Icons.hourglass_top),
                                size: 18,
                                color: _paymentStatus == 'PAID'
                                    ? const Color(0xFF16A34A)
                                    : (_paymentStatus == 'VERIFICATION_REJECTED'
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFFD97706)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _paymentStatus == 'PAID'
                                      ? (_transactionId.isNotEmpty
                                          ? 'Paid via Shop QR · Verified ✓ (Ref: $_transactionId)'
                                          : 'Paid via Shop QR · Verified ✓')
                                      : (_paymentStatus == 'VERIFICATION_REJECTED'
                                          ? 'Payment Reference Rejected · Verify with counter'
                                          : (_transactionId.isNotEmpty
                                              ? 'Payment Ref Submitted · Awaiting Verification (Ref: $_transactionId)'
                                              : 'Awaiting Payment Verification')),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _paymentStatus == 'PAID'
                                        ? const Color(0xFF16A34A)
                                        : (_paymentStatus == 'VERIFICATION_REJECTED'
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFD97706)),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Stepper (if not cancelled)
                        if (!isCancelled) ...[
                          Row(
                            children: [
                              _buildStep(0, 'Ordered'),
                              _buildLine(0),
                              _buildStep(1, 'In Queue'),
                              _buildLine(1),
                              _buildStep(2, 'Preparing'),
                              _buildLine(2),
                              _buildStep(3, isCompleted ? 'Collected' : 'Ready'),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Main Status Card
                        if (isCancelled)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.red.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.cancel_outlined, size: 52, color: AppTheme.red),
                                SizedBox(height: 8),
                                Text('Order Cancelled', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.red)),
                                SizedBox(height: 4),
                                Text('This order was cancelled and removed from the queue.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          )
                        else if (isCompleted)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: const Column(
                              children: [
                                Icon(Icons.task_alt, size: 56, color: Color(0xFF16A34A)),
                                SizedBox(height: 8),
                                Text('Order Collected ✓', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF16A34A))),
                                SizedBox(height: 4),
                                Text('Thank you! Enjoy your meal.', style: TextStyle(fontSize: 13, color: Color(0xFF16A34A))),
                              ],
                            ),
                          )
                        else if (_currentStatus == 'ready')
                          // ORDER READY: DISPLAY PICKUP VERIFICATION QR
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryBdr, width: 2),
                            ),
                            child: Column(
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.celebration, color: AppTheme.primary, size: 28),
                                    SizedBox(width: 8),
                                    Text('Order Ready for Pickup!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Counter staff will scan this QR to verify handover', style: TextStyle(fontSize: 12, color: AppTheme.primary.withOpacity(0.8))),
                                const SizedBox(height: 18),

                                // Pickup Verification QR Code
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                                  ),
                                  child: QrImageView(
                                    data: 'AURABAKE_PICKUP:${widget.orderId}:$_pickupToken',
                                    version: QrVersions.auto,
                                    size: 180,
                                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0F172A)),
                                    dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // 4-Digit Pickup Token Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'PICKUP TOKEN: #$_pickupToken',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // In Queue or Preparing
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              children: [
                                Text('Your order at $_outletName is active', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                                const SizedBox(height: 6),
                                Text(
                                  _currentStatus == 'pending' ? 'In Queue' : 'Preparing',
                                  style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: AppTheme.primary, height: 1),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _currentStatus == 'pending' ? 'Waiting for kitchen confirmation' : 'The chef is preparing your meal',
                                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // Info cards
                        Row(
                          children: [
                            Expanded(
                              child: _infoCard(
                                'Est. Pickup',
                                isCompleted
                                    ? 'Done'
                                    : _currentStatus == 'ready'
                                        ? 'Now'
                                        : _currentStatus == 'prep'
                                            ? '~5 min'
                                            : '~10 min',
                                theme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _infoCard('Token', '#$_pickupToken', theme),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Cancel Order button (if still pending)
                        if (_currentStatus == 'pending') ...[
                          OutlinedButton.icon(
                            onPressed: _isCancelling ? null : _handleCancelOrder,
                            icon: const Icon(Icons.cancel_outlined, size: 18, color: AppTheme.red),
                            label: _isCancelling
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Cancel Order', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: AppTheme.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          child: Text('Back to Orders', style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
            ),
          ],
        ),
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done || active ? AppTheme.primary : theme.scaffoldBackgroundColor,
              border: done || active ? null : Border.all(color: theme.dividerColor, width: 2),
            ),
            alignment: Alignment.center,
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(active ? '✓' : '${s + 1}',
                    style: TextStyle(
                      color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: done || active ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
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
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
