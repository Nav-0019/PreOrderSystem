import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../models/menu_item.dart';

class BakerInventoryScreen extends StatefulWidget {
  const BakerInventoryScreen({super.key});

  @override
  State<BakerInventoryScreen> createState() => _BakerInventoryScreenState();
}

class _BakerInventoryScreenState extends State<BakerInventoryScreen> {
  late List<MenuItem> _items;

  @override
  void initState() {
    super.initState();
    // Use Main Canteen's items for demo
    _items = kOutlets[0].menu.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: AppTheme.darkHdr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MAIN CANTEEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Live Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Text('+ Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Toggle availability — sold-out items are hidden from students automatically.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 16),

                ..._items.map((item) => _inventoryItem(item, theme)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inventoryItem(MenuItem item, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 24, color: AppTheme.primary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('₹${item.price.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
          Switch(
            value: item.isAvailable,
            onChanged: (v) => setState(() => item.isAvailable = v),
            activeColor: AppTheme.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: theme.dividerColor,
          ),
        ],
      ),
    );
  }
}
