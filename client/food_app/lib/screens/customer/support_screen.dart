import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqs = [
    {
      'icon': Icons.access_time,
      'q': 'How long does my order take?',
      'a': 'Preparation time is shown on the order tracking screen and updates live as the manager confirms your order.',
    },
    {
      'icon': Icons.cancel_outlined,
      'q': 'Can I cancel my order?',
      'a': 'Orders can be cancelled before the manager confirms them. Once confirmed, cancellation is not possible.',
    },
    {
      'icon': Icons.payment,
      'q': 'What payment methods are accepted?',
      'a': 'Currently only cash-on-pickup is supported. Digital payments are coming soon.',
    },
    {
      'icon': Icons.star_outline,
      'q': 'What is Premium membership?',
      'a': 'Premium gives you priority queue, exclusive deals, and a gold badge on your profile.',
    },
    {
      'icon': Icons.fastfood,
      'q': 'What if my food is wrong or missing?',
      'a': 'Tap "Report Issue" on the order in Recent Orders below. We will forward it to the outlet manager immediately.',
    },
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs.where((f) =>
      (f['q'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (f['a'] as String).toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 14),
            color: theme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 4),
                Text('How can we help you today?', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: InputDecoration(
                            hintText: 'Search FAQs...',
                            hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Recent Orders section
                Text('RECENT ORDERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirebaseService.streamMyOrders(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final orders = snap.data ?? [];
                    if (orders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
                        child: Text('No recent orders.', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      );
                    }
                    // Show last 3 orders
                    return Column(
                      children: orders.take(3).map((order) => _RecentOrderTile(order: order, theme: theme)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Support Topics
                Text('SUPPORT TOPICS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      _topicRow(context, Icons.support_agent_outlined, 'Contact Support', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _topicRow(context, Icons.account_balance_wallet_outlined, 'Payment & Refunds', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _topicRow(context, Icons.fastfood_outlined, 'Food Quality Issues', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _topicRow(context, Icons.bug_report_outlined, 'Report a Bug', theme),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // FAQs
                Text('FREQUENTLY ASKED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                if (_filteredFaqs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('No results for "$_searchQuery"', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4))),
                  )
                else
                  ..._filteredFaqs.map((faq) => _FaqTile(faq: faq, theme: theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topicRow(BuildContext context, IconData icon, String title, ThemeData theme) {
    return GestureDetector(
      onTap: () => _showReportDialog(context, title),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 14),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, String topic, {String? orderRef}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportSheet(topic: topic, orderRef: orderRef),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final ThemeData theme;
  const _RecentOrderTile({required this.order, required this.theme});

  @override
  Widget build(BuildContext context) {
    final createdAt = order['createdAt'];
    String timeStr = '';
    if (createdAt is Timestamp) {
      final diff = DateTime.now().difference(createdAt.toDate());
      if (diff.inMinutes < 60) timeStr = '${diff.inMinutes}m ago';
      else if (diff.inHours < 24) timeStr = '${diff.inHours}h ago';
      else timeStr = '${diff.inDays}d ago';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order['outletName'] ?? 'Outlet', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text('#${(order['id'] as String).substring(0, 6).toUpperCase()} · $timeStr · ₹${order['totalAmount']}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              final parentState = context.findAncestorStateOfType<_SupportScreenState>();
              parentState?._showReportDialog(context, 'Order Issue', orderRef: order['id']);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(8)),
              child: const Text('Report', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final Map<String, dynamic> faq;
  final ThemeData theme;
  const _FaqTile({required this.faq, required this.theme});

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _expanded ? AppTheme.primaryBdr : widget.theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.faq['icon'] as IconData, size: 18, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(widget.faq['q'] as String, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: widget.theme.colorScheme.onSurface.withOpacity(0.4)),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: widget.theme.dividerColor),
              const SizedBox(height: 10),
              Text(widget.faq['a'] as String, style: TextStyle(fontSize: 13, height: 1.5, color: widget.theme.colorScheme.onSurface.withOpacity(0.7))),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  final String topic;
  final String? orderRef;
  const _ReportSheet({required this.topic, this.orderRef});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _descCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe your issue')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      await FirebaseFirestore.instance.collection('support_tickets').add({
        'topic': widget.topic,
        'description': _descCtrl.text.trim(),
        'userId': user.uid,
        'userName': user.name,
        'userEmail': user.email,
        if (widget.orderRef != null) 'orderId': widget.orderRef,
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('✓ Report sent! We will follow up soon.'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.topic, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          if (widget.orderRef != null) ...[
            const SizedBox(height: 4),
            Text('Order #${widget.orderRef!.substring(0, 6).toUpperCase()}', style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 16),
          Text('Describe your issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 8),
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Tell us what happened...',
              filled: true,
              fillColor: theme.cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Send Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
