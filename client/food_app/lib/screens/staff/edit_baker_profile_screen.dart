import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class EditBakerProfileScreen extends StatefulWidget {
  const EditBakerProfileScreen({super.key});

  @override
  State<EditBakerProfileScreen> createState() => _EditBakerProfileScreenState();
}

class _EditBakerProfileScreenState extends State<EditBakerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _outletIdCtrl;
  late TextEditingController _outletNameCtrl;
  late TextEditingController _upiIdCtrl;
  late TextEditingController _regNoCtrl;
  
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableOutlets = [];
  bool _fetchingOutlets = true;
  String? _selectedOutletId;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
    _outletIdCtrl = TextEditingController(text: user.managedOutletId ?? '');
    _outletNameCtrl = TextEditingController();
    _upiIdCtrl = TextEditingController();
    _regNoCtrl = TextEditingController(text: user.registeredNumber ?? '');
    _selectedOutletId = user.managedOutletId;

    _loadOutletsAndShopData();
  }

  Future<void> _loadOutletsAndShopData() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('outlets').get();
      final outlets = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      setState(() {
        _availableOutlets = outlets;
        _fetchingOutlets = false;
      });

      // If manager already has an outlet, load its UPI and name
      if (_selectedOutletId != null && _selectedOutletId!.isNotEmpty) {
        final current = outlets.firstWhere(
          (o) => o['id'] == _selectedOutletId,
          orElse: () => {},
        );
        if (current.isNotEmpty) {
          _outletNameCtrl.text = current['name'] as String? ?? '';
          _upiIdCtrl.text = current['upiId'] as String? ?? '';
        } else {
          // Outlet not in list, fetch directly
          final doc = await FirebaseFirestore.instance.collection('outlets').doc(_selectedOutletId).get();
          if (doc.exists) {
            _outletNameCtrl.text = doc.data()?['name'] as String? ?? '';
            _upiIdCtrl.text = doc.data()?['upiId'] as String? ?? '';
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading outlets: $e');
      if (mounted) setState(() => _fetchingOutlets = false);
    }
  }

  void _onOutletChanged(String? val) {
    setState(() {
      _selectedOutletId = val;
      if (val != null && val != 'NEW_OUTLET') {
        _outletIdCtrl.text = val;
        final outlet = _availableOutlets.firstWhere((o) => o['id'] == val, orElse: () => {});
        if (outlet.isNotEmpty) {
          _outletNameCtrl.text = outlet['name'] as String? ?? '';
          _upiIdCtrl.text = outlet['upiId'] as String? ?? '';
        }
      } else if (val == 'NEW_OUTLET') {
        _outletIdCtrl.text = '';
        _outletNameCtrl.text = '';
        _upiIdCtrl.text = '';
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _outletIdCtrl.dispose();
    _outletNameCtrl.dispose();
    _upiIdCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final user = context.read<UserProvider>();
      String targetOutletId = _outletIdCtrl.text.trim();

      // If user selected from dropdown
      if (_selectedOutletId != null && _selectedOutletId != 'NEW_OUTLET') {
        targetOutletId = _selectedOutletId!;
      }

      // If manager typed a new outlet name or id
      if (targetOutletId.isEmpty && _outletNameCtrl.text.trim().isNotEmpty) {
        // Auto-generate outlet id from name
        targetOutletId = _outletNameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        if (targetOutletId.isEmpty) targetOutletId = 'outlet_${DateTime.now().millisecondsSinceEpoch}';
      }

      // 1. Update user document
      await FirebaseService.updateUserProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'managedOutletId': targetOutletId,
        'registeredNumber': _regNoCtrl.text.trim(),
      });

      // 2. Update or create outlet document
      if (targetOutletId.isNotEmpty) {
        final outletRef = FirebaseFirestore.instance.collection('outlets').doc(targetOutletId);
        final outletDoc = await outletRef.get();

        final upiVal = _upiIdCtrl.text.trim().isNotEmpty
            ? _upiIdCtrl.text.trim()
            : 'aurabake.${targetOutletId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase()}@upi';

        final outletName = _outletNameCtrl.text.trim().isNotEmpty
            ? _outletNameCtrl.text.trim()
            : 'Outlet $targetOutletId';

        if (!outletDoc.exists) {
          await outletRef.set({
            'name': outletName,
            'tagline': 'Campus Food Outlet',
            'isOpen': true,
            'queueCount': 0,
            'waitTime': 'No wait',
            'upiId': upiVal,
            'merchantName': outletName,
            'managerId': user.uid,
            'managerName': _nameCtrl.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          await outletRef.update({
            if (_outletNameCtrl.text.trim().isNotEmpty) 'name': _outletNameCtrl.text.trim(),
            'upiId': upiVal,
            'merchantName': outletName,
            'managerId': user.uid,
            'managerName': _nameCtrl.text.trim(),
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manager profile and shop setup updated successfully! ✓')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile & Shop Setup', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: theme.cardColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MANAGER DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildField('Full Name', _nameCtrl, theme, icon: Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneCtrl, theme, icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildField('Baker Registration No.', _regNoCtrl, theme, icon: Icons.badge_outlined),
              
              const SizedBox(height: 32),
              Text('OUTLET LINKING & SHOP SETUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
              const SizedBox(height: 16),

              // Outlet dropdown selector
              Text('Select Assigned Outlet', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              if (_fetchingOutlets)
                const LinearProgressIndicator()
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _availableOutlets.any((o) => o['id'] == _selectedOutletId)
                          ? _selectedOutletId
                          : (_selectedOutletId == 'NEW_OUTLET' ? 'NEW_OUTLET' : null),
                      hint: const Text('Select your outlet...'),
                      items: [
                        ..._availableOutlets.map((o) => DropdownMenuItem<String>(
                          value: o['id'] as String,
                          child: Text('${o['name'] ?? o['id']} (ID: ${o['id']})'),
                        )),
                        const DropdownMenuItem<String>(
                          value: 'NEW_OUTLET',
                          child: Text('➕ Create / Link Custom Outlet ID', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700)),
                        ),
                      ],
                      onChanged: _onOutletChanged,
                    ),
                  ),
                ),

              if (_selectedOutletId == 'NEW_OUTLET' || (_selectedOutletId == null && _availableOutlets.isEmpty)) ...[
                const SizedBox(height: 16),
                _buildField('Custom Outlet ID', _outletIdCtrl, theme, icon: Icons.store_outlined, helperText: 'e.g. nescafe, canteen, juice_bar'),
              ],

              const SizedBox(height: 16),
              _buildField('Outlet Display Name', _outletNameCtrl, theme, icon: Icons.storefront, helperText: 'Shown to students in their app.'),

              const SizedBox(height: 24),
              Text('SHOP PAYMENT & UPI QR SETUP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Text(
                'Enter your stall UPI ID (VPA). The student app generates dynamic QR codes tied to this ID so payments go directly to your shop.',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              ),
              const SizedBox(height: 14),
              _buildField('Shop UPI ID (VPA)', _upiIdCtrl, theme, icon: Icons.qr_code_2, helperText: 'e.g. nescafe@okaxis, canteen@upi, 9876543210@paytm'),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Profile & Shop Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, ThemeData theme, {IconData? icon, TextInputType? keyboardType, String? helperText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: (val) {
            if (label == 'Full Name' && (val == null || val.trim().isEmpty)) {
              return 'Name cannot be empty';
            }
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.4)) : null,
            filled: true,
            fillColor: theme.cardColor,
            helperText: helperText,
            helperMaxLines: 2,
            helperStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
