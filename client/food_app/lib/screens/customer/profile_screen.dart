import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'premium_screen.dart';

const _kPushPref = 'pref_push_enabled';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushEnabled = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _pushEnabled = prefs.getBool(_kPushPref) ?? true);
  }

  Future<void> _togglePush(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPushPref, value);
    setState(() => _pushEnabled = value);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 70,
    );
    if (file == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await File(file.path).readAsBytes();
      await FirebaseService.updateUserProfile({'photoBase64': base64Encode(bytes)});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
            color: theme.cardColor,
            child: Column(
              children: [
                // Tappable profile photo
                GestureDetector(
                  onTap: _pickAndUploadPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: user.isPremium
                              ? const LinearGradient(colors: [AppTheme.gold, AppTheme.goldDark])
                              : null,
                          color: user.isPremium ? null : AppTheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: (user.isPremium ? AppTheme.gold : AppTheme.primary).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                if (user.studentId != null && user.studentId!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('ID: ${user.studentId}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(999)),
                      child: Text(user.role.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    ),
                    if (user.isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.goldLight, Color(0xFFFFECB3)]),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.goldBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: AppTheme.goldDark),
                            SizedBox(width: 4),
                            Text('PREMIUM ✦', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.goldDark)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Live order stats
                Text('YOUR STATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                _LiveStatsRow(),
                const SizedBox(height: 24),

                Text('SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      _settingRow(
                        Icons.workspace_premium,
                        user.isPremium ? 'Manage Premium' : 'Get Premium',
                        theme,
                        isPremiumRow: true,
                        isPremium: user.isPremium,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow(
                        theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
                        'Dark Mode',
                        theme,
                        isToggle: true,
                        value: theme.brightness == Brightness.dark,
                        onChanged: (v) => user.toggleTheme(),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow(
                        Icons.notifications_active,
                        'Push Notifications',
                        theme,
                        isToggle: true,
                        value: _pushEnabled,
                        onChanged: _togglePush,
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
                    child: const Text('Log Out Safely', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(IconData icon, String title, ThemeData theme, {
    bool isToggle = false,
    bool value = false,
    ValueChanged<bool>? onChanged,
    bool isPremiumRow = false,
    bool isPremium = false,
    VoidCallback? onTap,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: isPremiumRow ? AppTheme.gold : null),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isPremiumRow ? AppTheme.goldDark : null)),
            ],
          ),
          if (isToggle)
            SizedBox(height: 24, child: Switch(value: value, onChanged: onChanged, activeColor: AppTheme.green))
          else if (isPremiumRow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: isPremium ? AppTheme.goldLight : AppTheme.gold.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(isPremium ? 'Active' : '₹99/mo', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.goldDark)),
            )
          else
            Icon(Icons.chevron_right, size: 20, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );
    return onTap != null ? GestureDetector(onTap: onTap, child: content) : content;
  }
}

class _LiveStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: FirebaseService.streamMyOrders(),
      builder: (context, snap) {
        final orders = snap.data ?? [];
        final completed = orders.where((o) => o['status'] == 'completed').toList();
        final total = completed.fold<double>(0, (sum, o) => sum + ((o['totalAmount'] as num?)?.toDouble() ?? 0));
        return Row(
          children: [
            _stat('${orders.length}', 'Orders', theme),
            const SizedBox(width: 10),
            _stat('${completed.length}', 'Completed', theme),
            const SizedBox(width: 10),
            _stat('₹${total.toStringAsFixed(0)}', 'Spent', theme),
          ],
        );
      },
    );
  }

  Widget _stat(String value, String label, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }
}
