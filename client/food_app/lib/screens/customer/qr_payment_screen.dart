import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import 'tracking_screen.dart';

class QrPaymentScreen extends StatefulWidget {
  final double totalAmount;
  final String outletId;
  final String outletName;
  final List<Map<String, dynamic>> items;
  final String? pickupSlot;

  const QrPaymentScreen({
    super.key,
    required this.totalAmount,
    required this.outletId,
    required this.outletName,
    required this.items,
    this.pickupSlot,
  });

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen> {
  final _utrController = TextEditingController();
  bool _isSubmitting = false;
  String? _configuredUpiId;

  @override
  void initState() {
    super.initState();
    _fetchOutletUpi();
  }

  Future<void> _fetchOutletUpi() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('outlets').doc(widget.outletId).get();
      if (doc.exists && mounted) {
        final upi = doc.data()?['upiId'] as String?;
        if (upi != null && upi.trim().isNotEmpty) {
          setState(() => _configuredUpiId = upi.trim());
        }
      }
    } catch (e) {
      debugPrint('Error fetching outlet UPI: $e');
    }
  }

  String get _shopUpiId {
    if (_configuredUpiId != null && _configuredUpiId!.isNotEmpty) {
      return _configuredUpiId!;
    }
    final cleanId = widget.outletId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return 'aurabake.$cleanId@upi';
  }

  String get _upiPaymentUrl {
    final formattedAmount = widget.totalAmount.toStringAsFixed(2);
    final note = Uri.encodeComponent('Aurabake - ${widget.outletName}');
    final name = Uri.encodeComponent(widget.outletName);
    return 'upi://pay?pa=$_shopUpiId&pn=$name&am=$formattedAmount&cu=INR&tn=$note';
  }

  void _copyUpiId() {
    Clipboard.setData(ClipboardData(text: _shopUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Copied UPI ID: $_shopUpiId', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmAndPlaceOrder() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final utr = _utrController.text.trim();
    if (utr.isEmpty || utr.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the valid UPI transaction reference (UTR) from your payment app.'),
          backgroundColor: AppTheme.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    try {
      final orderId = await FirebaseService.placeOrder(
        outletId: widget.outletId,
        outletName: widget.outletName,
        totalAmount: widget.totalAmount,
        items: widget.items,
        pickupSlot: widget.pickupSlot,
        paymentMethod: 'UPI_QR',
        paymentStatus: 'PENDING_VERIFICATION',
        transactionId: utr,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (orderId != null) {
        context.read<CartProvider>().clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)),
          (route) => route.isFirst,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order submission error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedAmount = '₹${widget.totalAmount.toStringAsFixed(0)}';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan & Pay', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: theme.dividerColor),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Outlet & Amount Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront, size: 18, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.outletName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formattedAmount,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Payable Amount · ${widget.items.length} item(s)',
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // QR Code Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('OFFICIAL CANTEEN QR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: _upiPaymentUrl,
                      version: QrVersions.auto,
                      size: 210,
                      gapless: true,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1E293B),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          'Direct Payment to Shop',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // UPI ID copy bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('UPI ID', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withOpacity(0.4), fontWeight: FontWeight.w600)),
                          Text(
                            _shopUpiId,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _copyUpiId,
                      icon: const Icon(Icons.copy, size: 14, color: AppTheme.primary),
                      label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.primary)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Supported Apps Icons/Pills
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.indigoBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.indigoBdr),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.payment, size: 16, color: AppTheme.indigo),
                        SizedBox(width: 6),
                        Text('Supported Payment Apps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.indigo)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _appBadge('Google Pay'),
                        _appBadge('PhonePe'),
                        _appBadge('Paytm'),
                        _appBadge('BHIM'),
                        _appBadge('Any UPI'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Optional UTR Reference Input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _utrController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.tag, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    labelText: 'UPI Ref / UTR No. (Optional)',
                    labelStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    hintText: 'e.g. 432198765432',
                    hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(height: 24),

              // Confirm Paid Button
              GestureDetector(
                onTap: _confirmAndPlaceOrder,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'I Have Paid · Confirm Order',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.indigoBdr),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.indigo),
      ),
    );
  }
}
