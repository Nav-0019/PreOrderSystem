import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  bool _isYearly = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _activatePremium() {
    final user = context.read<UserProvider>();
    if (!user.isPremium) {
      user.togglePremium();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Premium membership activated! 🎉', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        backgroundColor: AppTheme.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  void _deactivatePremium() {
    final user = context.read<UserProvider>();
    if (user.isPremium) {
      user.togglePremium();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Premium membership deactivated.', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPremium = context.watch<UserProvider>().isPremium;
    final premiumExpiry = context.watch<UserProvider>().premiumExpiry;

    return Scaffold(
      body: Column(
        children: [
          // Gold gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFD4A017), Color(0xFFB8860B), Color(0xFF8B6914)],
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                        alignment: Alignment.center,
                        child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                      ),
                    ),
                    const Spacer(),
                    if (isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(999)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Active', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.workspace_premium, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text('Premium Membership', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                const SizedBox(height: 6),
                Text(
                  isPremium ? 'You\'re a Premium member!' : 'Unlock exclusive benefits',
                  style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                ),
                if (isPremium && premiumExpiry != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renews ${premiumExpiry.day}/${premiumExpiry.month}/${premiumExpiry.year}',
                    style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                // Benefits section
                Text('PREMIUM BENEFITS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 12),

                _benefitCard(Icons.bolt, 'Priority Queue', 'Your orders jump to the front of the line', AppTheme.gold, theme),
                _benefitCard(Icons.savings, '10% Discount', 'Automatically applied on every order', AppTheme.green, theme),
                _benefitCard(Icons.confirmation_num, 'Skip-the-Line', 'Walk straight to the counter when ready', AppTheme.primary, theme),
                _benefitCard(Icons.notifications_active, 'Early Access', 'Be the first to know about new items', AppTheme.indigo, theme),
                _benefitCard(Icons.card_giftcard, 'Monthly Surprise', 'A free item every month as a thank you', AppTheme.red, theme),

                const SizedBox(height: 24),

                // Pricing section
                if (!isPremium) ...[
                  Text('CHOOSE YOUR PLAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                  const SizedBox(height: 12),

                  // Plan toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(999), border: Border.all(color: theme.dividerColor)),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_isYearly ? theme.cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: !_isYearly ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Text('Monthly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: !_isYearly ? AppTheme.gold : theme.colorScheme.onSurface.withOpacity(0.5))),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _isYearly = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _isYearly ? theme.cardColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                                boxShadow: _isYearly ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Yearly', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _isYearly ? AppTheme.gold : theme.colorScheme.onSurface.withOpacity(0.5))),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppTheme.green.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('SAVE 25%', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFF16A34A))),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppTheme.goldLight, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.goldBorder, width: 1.5),
                      boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isYearly ? '₹899' : '₹99',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.goldDark),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                _isYearly ? '/year' : '/month',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.gold.withOpacity(0.7)),
                              ),
                            ),
                          ],
                        ),
                        if (_isYearly) ...[
                          const SizedBox(height: 4),
                          Text('That\'s just ₹74.9/month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A))),
                        ],
                        const SizedBox(height: 6),
                        Text('Cancel anytime · No hidden fees', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                      ],
                    ),
                  ),
                ],

                if (isPremium) ...[
                  const SizedBox(height: 8),
                  Text('MEMBERSHIP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      children: [
                        _infoRow('Status', 'Active ✓', const Color(0xFF16A34A), theme),
                        Divider(height: 20, color: theme.dividerColor),
                        _infoRow('Plan', 'Monthly', theme.colorScheme.onSurface, theme),
                        Divider(height: 20, color: theme.dividerColor),
                        _infoRow('Orders saved', '₹128 so far', AppTheme.gold, theme),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(color: theme.cardColor, border: Border(top: BorderSide(color: theme.dividerColor))),
        child: GestureDetector(
          onTap: isPremium ? _deactivatePremium : _activatePremium,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              gradient: isPremium
                  ? null
                  : const LinearGradient(colors: [AppTheme.gold, AppTheme.goldDark]),
              color: isPremium ? theme.scaffoldBackgroundColor : null,
              borderRadius: BorderRadius.circular(12),
              border: isPremium ? Border.all(color: AppTheme.red.withOpacity(0.3)) : null,
              boxShadow: isPremium
                  ? []
                  : [BoxShadow(color: AppTheme.gold.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
            ),
            alignment: Alignment.center,
            child: Text(
              isPremium ? 'Cancel Membership' : 'Activate Premium ✦',
              style: TextStyle(
                color: isPremium ? AppTheme.red : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _benefitCard(IconData icon, String title, String subtitle, Color color, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
              ],
            ),
          ),
          Icon(Icons.check_circle, size: 18, color: color.withOpacity(0.4)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, Color valueColor, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.5))),
        Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: valueColor)),
      ],
    );
  }
}
