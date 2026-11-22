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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            StreamBuilder<Map<String, dynamic>?>(
              stream: outletId != null ? FirebaseService.streamOutlet(outletId) : const Stream.empty(),
              builder: (context, outletSnap) {
                final outletData = outletSnap.data;
                final dynamicOutletName = outletData?['name'] as String? ?? (outletId != null ? 'OUTLET $outletId' : 'MY OUTLET');

                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  color: AppTheme.darkHdr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dynamicOutletName.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary, letterSpacing: 1.2)),
                            const SizedBox(height: 4),
                            const Text('Menu & Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
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
                );
              },
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
                        
                        return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            // Pending & Rejected Approval Tickets Tracker
                            _PendingTicketsBanner(outletId: outletId),
                            const SizedBox(height: 12),

                            Text(
                              'Live Inventory — toggle availability, edit prices, or remove sold-out dishes.',
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 16),

                            if (items.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.restaurant_menu, size: 56, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                                      const SizedBox(height: 12),
                                      Text('No live menu items yet', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('Tap "+ Add Item" to submit an item for approval', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                                    ],
                                  ),
                                ),
                              )
                            else
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
              'Your manager account is not linked to any outlet yet. Please select or set up your shop in the Profile tab.',
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

class _PendingTicketsBanner extends StatelessWidget {
  final String outletId;
  const _PendingTicketsBanner({required this.outletId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.streamOutletApprovalTickets(outletId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final tickets = snap.data ?? [];
        final pending = tickets.where((t) => t['status'] == 'pending').toList();
        final rejected = tickets.where((t) => t['status'] == 'rejected').toList();

        if (pending.isEmpty && rejected.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pending.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.yellow.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.goldBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hourglass_top, color: AppTheme.goldDark, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${pending.length} Item(s) Awaiting Admin Approval',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.goldDark)),
                          const SizedBox(height: 2),
                          Text(
                            pending.map((p) => p['itemData']?['name'] ?? 'Item').join(', '),
                            style: TextStyle(fontSize: 11, color: AppTheme.goldDark.withOpacity(0.85)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (rejected.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppTheme.red, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${rejected.length} Item Submission(s) Rejected by Admin',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.red)),
                          const SizedBox(height: 2),
                          Text(
                            rejected.map((r) => '${r['itemData']?['name']}: ${r['rejectionReason'] ?? "Denied"}').join(' • '),
                            style: TextStyle(fontSize: 11, color: AppTheme.red.withOpacity(0.85)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _InventoryItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final String outletId;

  const _InventoryItemTile({required this.item, required this.outletId});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: Text('Are you sure you want to delete "${item['name']}" from your menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseService.deleteMenuItem(outletId, item['id']);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deleted "${item['name']}"')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditItemSheet(outletId: outletId, item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = item['isAvailable'] as bool? ?? true;
    final photoBase64 = item['photoBase64'] as String?;
    final prepTime = item['prepTime'] as int? ?? 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
              width: 54,
              height: 54,
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
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.8))),
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
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            tooltip: 'Edit item',
            onPressed: () => _showEditSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppTheme.red.withOpacity(0.7),
            tooltip: 'Delete item',
            onPressed: () => _confirmDelete(context),
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
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300, imageQuality: 50);
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
      final user = context.read<UserProvider>();
      final itemData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'category': _category,
        'prepTime': int.tryParse(_prepCtrl.text.trim()) ?? 5,
        if (_photoBase64 != null) 'photoBase64': _photoBase64,
      };

      // 1. Submit approval ticket for Admin verification
      await FirebaseService.submitMenuItemApprovalTicket(
        outletId: widget.outletId,
        outletName: user.name.isNotEmpty ? user.name : 'Outlet ${widget.outletId}',
        itemData: itemData,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Approval ticket sent to Admin! ✓ Admin can confirm or reject in portal.'),
            backgroundColor: AppTheme.primary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission error: $e')));
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Submit Item for Approval', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted items generate an approval ticket for the Admin to confirm or reject.',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.55)),
            ),
            const SizedBox(height: 16),

            // Photo picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBdr),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBase64 != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                onPressed: () => setState(() => _photoBase64 = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 32),
                          const SizedBox(height: 6),
                          Text('Tap to add food photo', style: TextStyle(color: AppTheme.primary.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
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
                    : const Text('Send Approval Ticket to Admin ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
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

class _EditItemSheet extends StatefulWidget {
  final String outletId;
  final Map<String, dynamic> item;
  const _EditItemSheet({required this.outletId, required this.item});

  @override
  State<_EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<_EditItemSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _prepCtrl;
  late String _category;
  String? _photoBase64;
  bool _isLoading = false;

  final _categories = ['Snacks', 'Meals', 'Beverages', 'Juices', 'Desserts', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item['name'] ?? '');
    _descCtrl = TextEditingController(text: widget.item['description'] ?? '');
    _priceCtrl = TextEditingController(text: (widget.item['price'] as num?)?.toString() ?? '0');
    _prepCtrl = TextEditingController(text: (widget.item['prepTime'] as num?)?.toString() ?? '5');
    final cat = widget.item['category'] as String?;
    _category = (_categories.contains(cat)) ? cat! : 'Snacks';
    _photoBase64 = widget.item['photoBase64'] as String?;
  }

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
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300, imageQuality: 50);
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
      final newPrice = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      final updateData = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': newPrice,
        'category': _category,
        'prepTime': int.tryParse(_prepCtrl.text.trim()) ?? 5,
      };
      if (_photoBase64 != null && _photoBase64!.isNotEmpty) {
        updateData['photoBase64'] = _photoBase64;
      }

      await FirebaseService.updateMenuItem(widget.outletId, widget.item['id'], updateData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated "${_nameCtrl.text.trim()}" successfully! (₹${newPrice.toStringAsFixed(0)})'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating item: $e')));
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Edit Menu Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 16),

            // Photo picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryBdr),
                ),
                clipBehavior: Clip.antiAlias,
                child: _photoBase64 != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(base64Decode(_photoBase64!), fit: BoxFit.cover),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.close, size: 14, color: Colors.white),
                                onPressed: () => setState(() => _photoBase64 = null),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.primary, size: 32),
                          const SizedBox(height: 6),
                          Text('Tap to change food photo', style: TextStyle(color: AppTheme.primary.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
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
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
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
