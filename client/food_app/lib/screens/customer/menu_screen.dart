import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/menu_item.dart';
import '../../services/firebase_service.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final Outlet outlet;
  const MenuScreen({super.key, required this.outlet});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _selectedCat = 'All';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: FirebaseService.streamMenuItems(widget.outlet.id),
          builder: (context, snapshot) {
            final rawItems = snapshot.data ?? [];
            final List<MenuItem> liveItems = rawItems.map((m) {
              return MenuItem(
                id: m['id'] ?? '',
                name: m['name'] ?? '',
                description: m['description'] ?? '',
                price: ((m['price'] as num?) ?? 0).toDouble(),
                category: m['category'] ?? 'General',
                icon: Icons.fastfood,
                isAvailable: m['isAvailable'] as bool? ?? true,
                prepTime: m['prepTime'] as int? ?? 5,
                photoBase64: m['photoBase64'] as String?,
              );
            }).toList();

            final categories = ['All', ...{...liveItems.map((m) => m.category)}];
            final filteredItems = _selectedCat == 'All'
                ? liveItems
                : liveItems.where((m) => m.category == _selectedCat).toList();

            return Column(
              children: [
                // Header with live outlet info
                StreamBuilder<Map<String, dynamic>?>(
                  stream: FirebaseService.streamOutlet(widget.outlet.id),
                  builder: (context, outletSnap) {
                    final outletData = outletSnap.data;
                    final outletName = outletData?['name'] ?? widget.outlet.name;
                    final outletTagline = outletData?['tagline'] ?? widget.outlet.tagline;
                    final isOpen = outletData?['isOpen'] ?? widget.outlet.isOpen;

                    return Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      color: theme.cardColor,
                      child: Column(
                        children: [
                          Row(
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            outletName,
                                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isOpen ? 'Open' : 'Closed',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isOpen ? AppTheme.green : AppTheme.red,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      outletTagline,
                                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Category pills
                          SizedBox(
                            height: 38,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (ctx, i) {
                                final cat = categories[i];
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
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    );
                  },
                ),
                Divider(height: 1, color: theme.dividerColor),

                // Menu items list (Live from Firestore)
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : filteredItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 54, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No items available in this category',
                                    style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(20, 10, 20, cart.itemCount > 0 ? 110 : 24),
                              itemCount: filteredItems.length,
                              itemBuilder: (ctx, i) => _MenuItemCard(
                                item: filteredItems[i],
                                outlet: widget.outlet,
                              ),
                            ),
                ),
              ],
            );
          },
        ),
      ),
      // Floating cart bar
      bottomSheet: cart.itemCount > 0
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.scaffoldBackgroundColor.withOpacity(0), theme.scaffoldBackgroundColor],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen())),
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
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(10)),
                                alignment: Alignment.center,
                                child: Text(
                                  '${cart.itemCount}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Your Cart', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  Text(
                                    '₹${cart.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                  ),
                                ],
                              ),
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
                ),
              ),
            )
          : null,
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final Outlet outlet;
  const _MenuItemCard({required this.item, required this.outlet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartProvider>();
    final qty = cart.items[item.id]?.quantity ?? 0;
    final isAvailable = item.isAvailable;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: !isAvailable ? theme.dividerColor.withOpacity(0.4) : (qty > 0 ? AppTheme.primaryBdr : theme.dividerColor)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
      ),
      child: Row(
        children: [
          // Food image (Base64 if uploaded, else placeholder icon)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 60,
              height: 60,
              color: isAvailable ? AppTheme.primaryBg : theme.dividerColor.withOpacity(0.2),
              alignment: Alignment.center,
              child: item.photoBase64 != null && item.photoBase64!.isNotEmpty
                  ? Image.memory(base64Decode(item.photoBase64!), fit: BoxFit.cover, width: 60, height: 60)
                  : Icon(item.icon, size: 30, color: isAvailable ? AppTheme.primary : Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isAvailable ? null : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                    if (!isAvailable) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Sold Out', style: TextStyle(color: AppTheme.red, fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: isAvailable ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 3),
                    Text(
                      '~${item.prepTime} min',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Add / Stepper or Sold Out Indicator
          if (!isAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text(
                'Unavailable',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            )
          else if (qty == 0)
            GestureDetector(
              onTap: () => context.read<CartProvider>().addItem(
                    item.id,
                    item.name,
                    item.price,
                    outletId: outlet.id,
                    outletName: outlet.name,
                  ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10)],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            )
          else
            Container(
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
                    onTap: () => context.read<CartProvider>().addItem(
                          item.id,
                          item.name,
                          item.price,
                          outletId: outlet.id,
                          outletName: outlet.name,
                        ),
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
