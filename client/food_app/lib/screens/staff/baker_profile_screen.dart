import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class BakerProfileScreen extends StatelessWidget {
  const BakerProfileScreen({super.key});

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
                Container(
                  width: 72, height: 72,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.darkHdr),
                  alignment: Alignment.center,
                  child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryBg, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Baker / Staff', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary)),
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
                      _settingRow('🔔', 'Order Alerts', theme, isToggle: true, value: true, onChanged: (v){}),
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
                    child: const Text('End Shift & Log Out', style: TextStyle(color: AppTheme.red, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.green,
              ),
            ),
        ],
      ),
    );
  }
}
