import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
class BakerInventoryScreen extends StatelessWidget {
  const BakerInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final rawOutletId = userProvider.managedOutletId;
    final outletId = (rawOutletId != null && rawOutletId.trim().isNotEmpty) ? rawOutletId.trim() : null;
    final theme = Theme.of(context);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: AppTheme.darkHdr,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MY OUTLET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                    SizedBox(height: 4),
                    Text('Menu & Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  ],
                ),
                Material(
                  color: outletId != null ? AppTheme.primary : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      if (outletId == null) {
                        _showCreateOutletDialog(context);
                      } else {
                        _showAddItemDialog(context, outletId);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text('+ Add Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
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
                    stream: FirebaseService.streamMenuItems(outletId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final items = snap.data ?? [];
                      if (items.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_menu, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              Text('No menu items yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('Tap "+ Add Item" to get started', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                            ],
                          ),
                        );
                      }
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'Toggle availability — sold-out items are hidden from students automatically.',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                          ),
                          const SizedBox(height: 16),
                          ...items.map((item) => _InventoryItemTile(
                            item: item,
                            outletId: outletId,
                          )),
                        ],
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
              'Your manager account is not linked to any outlet yet. Please contact admin to set up your shop.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, String outletId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(outletId: outletId),
    );
  }

  void _showCreateOutletDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Your Shop'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your manager account needs a shop before you can add menu items.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Shop Name (e.g. Campus Canteen)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final newId = await FirebaseService.createOutlet(nameCtrl.text.trim(), 'Campus Food');
              if (newId != null) {
                final user = context.read<UserProvider>();
                if (user.uid.isNotEmpty) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'managedOutletId': newId});
                }
              }
            },
            child: const Text('Create Shop'),
          ),
        ],
      ),
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String outletId;

  const _InventoryItemTile({required this.item, required this.outletId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = item['isAvailable'] as bool? ?? true;
    final photoBase64 = item['photoBase64'] as String?;
    final prepTime = item['prepTime'] as int? ?? 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isAvailable ? theme.dividerColor : AppTheme.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Food image / placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: AppTheme.primaryBg,
              child: photoBase64 != null
                  ? Image.memory(base64Decode(photoBase64), fit: BoxFit.cover)
                  : const Icon(Icons.fastfood, color: AppTheme.primary, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('₹${(item['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                    const SizedBox(width: 8),
                    Icon(Icons.timer_outlined, size: 12, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                    const SizedBox(width: 2),
                    Text('~$prepTime min', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  ],
                ),
                if (!isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Marked as sold out', style: TextStyle(fontSize: 10, color: AppTheme.red.withOpacity(0.8), fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (v) => FirebaseService.updateMenuItemAvailability(outletId, item['id'], v),
            activeColor: AppTheme.green,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: theme.dividerColor,
          ),
        ],
      ),
    );
  }
}

class _AddItemSheet extends StatefulWidget {
  final String outletId;
  const _AddItemSheet({required this.outletId});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _prepCtrl = TextEditingController(text: '5');
  String _category = 'Snacks';
  String? _photoBase64;
  bool _isLoading = false;

  final _categories = ['Snacks', 'Meals', 'Beverages', 'Juices', 'Desserts', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _prepCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400, maxHeight: 400, imageQuality: 60);
    if (file == null) return;
    final bytes = await File(file.path).readAsBytes();
    if (!mounted) return;
    setState(() => _photoBase64 = base64Encode(bytes));
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _priceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in name and price')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseService.addMenuItem(widget.outletId, {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'category': _category,
        'prepTime': int.tryParse(_prepCtrl.text.trim()) ?? 5,
        if (_photoBase64 != null) 'photoBase64': _photoBase64,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add Menu Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),

            // Photo picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBdr),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBase64 != null
                    ? Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover)
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 36),
                          const SizedBox(height: 6),
                          Text('Tap to add food photo', style: TextStyle(color: AppTheme.primary.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),

            _field('Food Name *', _nameCtrl, theme),
            const SizedBox(height: 12),
            _field('Description', _descCtrl, theme),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('Price (₹) *', _priceCtrl, theme, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field('Avg Prep Time (min)', _prepCtrl, theme, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),

            // Category dropdown
            Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _category,
                  isExpanded: true,
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Add to Menu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, ThemeData theme, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
