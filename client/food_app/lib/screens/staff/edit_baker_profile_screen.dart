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
  late TextEditingController _regNoCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>();
    _nameCtrl = TextEditingController(text: user.name);
    _phoneCtrl = TextEditingController(text: user.phone ?? '');
    _outletIdCtrl = TextEditingController(text: user.managedOutletId ?? '');
    _regNoCtrl = TextEditingController(text: user.registeredNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _outletIdCtrl.dispose();
    _regNoCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      final newOutletId = _outletIdCtrl.text.trim();
      
      await FirebaseService.updateUserProfile({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'managedOutletId': newOutletId,
        'registeredNumber': _regNoCtrl.text.trim(),
      });

      if (newOutletId.isNotEmpty) {
        try {
          final outletDoc = await FirebaseFirestore.instance.collection('outlets').doc(newOutletId).get();
          if (!outletDoc.exists) {
            await FirebaseFirestore.instance.collection('outlets').doc(newOutletId).set({
              'name': 'Outlet $newOutletId',
              'tagline': 'Newly registered outlet',
              'isOpen': true,
              'queueCount': 0,
              'waitTime': 'No wait',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('Could not auto-create outlet: $e');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
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
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
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
              Text('OUTLET LINKING', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface.withOpacity(0.5), letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildField('Outlet ID', _outletIdCtrl, theme, icon: Icons.store_outlined, helperText: 'Enter your assigned outlet ID to manage its menu and orders.'),
              
              const SizedBox(height: 48),
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
                      : const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
