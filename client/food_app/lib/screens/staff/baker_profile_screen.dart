import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'edit_baker_profile_screen.dart';

class BakerProfileScreen extends StatefulWidget {
  const BakerProfileScreen({super.key});

  @override
  State<BakerProfileScreen> createState() => _BakerProfileScreenState();
}

class _BakerProfileScreenState extends State<BakerProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 300, maxHeight: 300, imageQuality: 70);
    if (file == null) return;
    if (!mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await File(file.path).readAsBytes();
      final base64Str = base64Encode(bytes);
      await FirebaseService.updateUserProfile({'photoBase64': base64Str});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            color: theme.cardColor,
            child: Column(
              children: [
                // Profile photo
                GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.darkHdr),
                        clipBehavior: Clip.antiAlias,
                        child: _uploadingPhoto
                            ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : user.photoBase64 != null
                                ? Image.memory(base64Decode(user.photoBase64!), fit: BoxFit.cover)
                                : Center(child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900))),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Outlet Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                ),
                if (user.registeredNumber != null) ...[
                  const SizedBox(height: 6),
                  Text('Baker Reg. No. ${user.registeredNumber}',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5), fontWeight: FontWeight.w600)),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditBakerProfileScreen())),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
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
                Text('SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      _settingRow('🌙', 'Dark Mode', theme, isToggle: true, value: theme.brightness == Brightness.dark, onChanged: (v) => user.toggleTheme()),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow('🔔', 'Order Alerts', theme, isToggle: true, value: true, onChanged: (_) {}),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text('ACCOUNT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      _infoRow(Icons.phone_outlined, 'Phone', user.phone ?? '—', theme),
                      Divider(height: 1, color: theme.dividerColor),
                      _infoRow(
                        Icons.store_outlined, 
                        'Outlet ID', 
                        user.managedOutletId ?? '—', 
                        theme,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () {
                    user.logout();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.red.withOpacity(0.3)),
                    ),
                    alignment: Alignment.center,
                    child: const Text('Sign Out', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, ThemeData theme, {VoidCallback? onTap}) {
    Widget row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.45)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.55), fontWeight: FontWeight.w500)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis, textAlign: TextAlign.right)),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 14, color: AppTheme.primary),
          ]
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(onTap: onTap, child: row);
    }
    return row;
  }

  Widget _settingRow(String emoji, String title, ThemeData theme, {bool isToggle = false, bool value = false, ValueChanged<bool>? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          if (isToggle)
            SizedBox(
              height: 24,
              child: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.green),
            ),
        ],
      ),
    );
  }
}
