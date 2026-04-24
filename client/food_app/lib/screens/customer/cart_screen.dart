import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'tracking_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _selectedSlot = '12:30 PM – 12:40 PM  (Fastest)';

  void _placeOrder() {
    final cart = context.read<CartProvider>();
    cart.clear();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TrackingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final user = context.watch<UserProvider>();
    final items = cart.items.values.toList();
    final isPremium = user.isPremium;
    final discount = isPremium ? cart.totalAmount * 0.10 : 0.0;
    final total = cart.totalAmount - discount + 5;

    return Scaffold(
      body: Column(
        children: [
          // Header
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
                const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                if (isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.goldLight, Color(0xFFFFECB3)]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.goldBorder),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt, size: 12, color: AppTheme.goldDark),
                        SizedBox(width: 2),
                        Text('Priority', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.goldDark)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          Expanded(
            child: cart.itemCount == 0
                ? _buildEmptyCart(theme)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                    children: [
                      // Premium priority banner
                      if (isPremium)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.goldLight, Color(0xFFFFECB3)]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.goldBorder),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.bolt, size: 16, color: AppTheme.goldDark),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('⚡ Priority Order — Your order will be prepared first!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.goldDark)),
                              ),
                            ],
                          ),
                        ),

                      // Cart items
                      Container(
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                        child: Column(
                          children: items.map((item) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => cart.removeItem(item.id),
                                          child: const SizedBox(width: 36, height: 36, child: Icon(Icons.remove, color: Colors.white, size: 16)),
                                        ),
                                        Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                                        GestureDetector(
                                          onTap: () => cart.addItem(item.id, item.name, item.price),
                                          child: const SizedBox(width: 36, height: 36, child: Icon(Icons.add, color: Colors.white, size: 16)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Time slot
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: AppTheme.indigoBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.indigoBdr)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('🕐 Select Pickup Slot', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.indigo)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(999)),
                                  child: Text(isPremium ? '⚡ Priority' : 'Capacity: 3/20', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isPremium ? AppTheme.goldDark : AppTheme.primary)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.indigoBdr)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _selectedSlot,
                                  icon: const Icon(Icons.expand_more, size: 20),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                                  dropdownColor: theme.cardColor,
                                  onChanged: (v) { if (v != null) setState(() => _selectedSlot = v); },
                                  items: [
                                    '12:30 PM – 12:40 PM  (Fastest)',
                                    '12:40 PM – 12:50 PM',
                                    '12:50 PM – 01:00 PM',
                                    '01:00 PM – 01:10 PM',
                                  ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isPremium ? 'Premium members get priority preparation within their slot.' : 'Orders fulfilled strictly in slot window to prevent queue overlap.',
                              style: const TextStyle(fontSize: 10, color: AppTheme.indigo, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Order summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                        child: Column(
                          children: [
                            _summaryRow('Subtotal', '₹${cart.totalAmount.toStringAsFixed(0)}', theme),
                            const SizedBox(height: 8),
                            if (isPremium) ...[
                              _summaryRow('Premium Discount (10%)', '-₹${discount.toStringAsFixed(0)}', theme, valueColor: const Color(0xFF16A34A)),
                              const SizedBox(height: 8),
                            ],
                            _summaryRow('Platform fee', '₹5', theme),
                            Divider(height: 24, color: theme.dividerColor),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                                Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomSheet: cart.itemCount > 0
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
              child: GestureDetector(
                onTap: _placeOrder,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                  ),
                  alignment: Alignment.center,
                  child: Text(isPremium ? '⚡ Pay & Place Priority Order' : 'Pay & Place Order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmptyCart(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🛒', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('Cart is empty', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Add items from the menu', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Go to Menu', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, ThemeData theme, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}
