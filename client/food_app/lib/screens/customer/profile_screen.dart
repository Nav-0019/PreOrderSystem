import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';
import 'premium_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                // Avatar with premium ring
                Container(
                  width: 76, height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: user.isPremium
                        ? const LinearGradient(colors: [AppTheme.gold, AppTheme.goldDark])
                        : null,
                    color: user.isPremium ? null : AppTheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (user.isPremium ? AppTheme.gold : AppTheme.primary).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: user.isPremium ? const EdgeInsets.all(3) : null,
                  child: user.isPremium
                      ? Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary,
                            border: Border.all(color: theme.cardColor, width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                        )
                      : Center(
                          child: Text(user.initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                        ),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                const SizedBox(height: 4),
                Text(user.email, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
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
                Text('YOUR STATS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statCard('12', 'Orders', theme),
                    const SizedBox(width: 10),
                    _statCard('4.8', 'Rating', theme),
                    const SizedBox(width: 10),
                    _statCard(user.isPremium ? '₹712' : '₹840', 'Spent', theme),
                  ],
                ),
                if (user.isPremium) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text('You saved ₹128 with Premium!', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                  ),
                ],
                const SizedBox(height: 24),

                Text('SETTINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                  child: Column(
                    children: [
                      // Premium membership row
                      _settingRow(
                        Icons.workspace_premium,
                        user.isPremium ? 'Manage Premium' : 'Get Premium',
                        theme,
                        isPremiumRow: true,
                        isPremium: user.isPremium,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
                      ),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, 'Dark Mode', theme, isToggle: true, value: theme.brightness == Brightness.dark, onChanged: (v) => user.toggleTheme()),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow(Icons.notifications_active, 'Push Notifications', theme, isToggle: true, value: true, onChanged: (v){}),
                      Divider(height: 1, color: theme.dividerColor),
                      _settingRow(Icons.credit_card, 'Saved Payment Methods', theme),
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

  Widget _statCard(String value, String label, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
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
              Icon(icon, size: 20, color: isPremiumRow ? AppTheme.gold : theme.colorScheme.onSurface),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isPremiumRow ? AppTheme.goldDark : null)),
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
            )
          else if (isPremiumRow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isPremium ? AppTheme.goldLight : AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isPremium ? 'Active' : '₹99/mo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.goldDark),
              ),
            )
          else
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.3)),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: content);
    }
    return content;
  }
}
