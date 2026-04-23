import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_item.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final Outlet outlet;
  const MenuScreen({super.key, required this.outlet});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCat = 'All';

  List<String> get _categories {
    final cats = ['All', ...{...widget.outlet.menu.map((m) => m.category)}];
    return cats;
  }

  List<MenuItem> get _filteredItems => _selectedCat == 'All'
      ? widget.outlet.menu
      : widget.outlet.menu.where((m) => m.category == _selectedCat).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
            color: theme.cardColor,
            child: Column(
              children: [
                Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.outlet.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text(widget.outlet.tagline, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Category pills
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final active = cat == _selectedCat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCat = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? AppTheme.primary : theme.cardColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: active ? AppTheme.primary : theme.dividerColor, width: 1.5),
                          ),
                          child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          // Menu items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(20, 4, 20, cart.itemCount > 0 ? 110 : 24),
              itemCount: _filteredItems.length,
              itemBuilder: (ctx, i) => _MenuItemCard(item: _filteredItems[i]),
            ),
          ),
        ],
      ),
      // Floating cart bar
      bottomSheet: cart.itemCount > 0
          ? GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [theme.scaffoldBackgroundColor.withOpacity(0), theme.scaffoldBackgroundColor]),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBdr),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${cart.itemCount} item${cart.itemCount > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          Text('₹${cart.totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                        child: const Text('View Cart →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final qty = cart.items[item.id]?.quantity ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: qty > 0 ? AppTheme.primaryBdr : theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'outlet_icon_${item.id}',
            child: Container(
              width: 60, height: 60,
              decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Icon(item.icon, size: 32, color: AppTheme.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(item.description, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                const SizedBox(height: 6),
                Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              ],
            ),
          ),
          // Add / Stepper
          qty == 0
              ? GestureDetector(
                  onTap: () => context.read<CartProvider>().addItem(item.id, item.name, item.price),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10)]),
                    alignment: Alignment.center,
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => context.read<CartProvider>().removeItem(item.id),
                        child: const SizedBox(width: 36, height: 36, child: Icon(Icons.remove, color: Colors.white, size: 16)),
                      ),
                      Text('$qty', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                      GestureDetector(
                        onTap: () => context.read<CartProvider>().addItem(item.id, item.name, item.price),
                        child: const SizedBox(width: 36, height: 36, child: Icon(Icons.add, color: Colors.white, size: 16)),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
