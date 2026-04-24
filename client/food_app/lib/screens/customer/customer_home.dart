import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../models/menu_item.dart';
import 'menu_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'premium_screen.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});
  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  List<Outlet> get _filtered => kOutlets.where((o) =>
    _searchQuery.isEmpty ||
    o.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
    o.tagline.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final cartCount = context.watch<CartProvider>().itemCount;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 16),
            color: theme.cardColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_greeting(), style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                          const Text('What would you\nlike to eat?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.read<UserProvider>().toggleTheme(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.scaffoldBackgroundColor, border: Border.all(color: theme.dividerColor)),
                            alignment: Alignment.center,
                            child: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode, size: 16, color: theme.colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                              child: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryBg, border: Border.all(color: AppTheme.primaryBdr)),
                                alignment: Alignment.center,
                                child: const Icon(Icons.notifications_none, size: 18, color: AppTheme.primary),
                              ),
                            ),
                            Positioned(
                              top: 0, right: 0,
                              child: Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.red, border: Border.all(color: theme.cardColor, width: 1.5)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primary,
                              border: user.isPremium ? Border.all(color: AppTheme.gold, width: 2.5) : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Search canteens or dishes...',
                            hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                          ),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.close, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),
          // Scrollable body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              children: [
                // Premium membership banner
                _buildPremiumBanner(user, theme),
                const SizedBox(height: 16),

                // Live stats
                Row(
                  children: [
                    _statCard('${_filtered.where((o) => o.isOpen).length}', 'Open now', theme),
                    const SizedBox(width: 10),
                    _statCard('${_filtered.fold(0, (sum, o) => sum + o.queueCount)}', 'In queue', theme),
                    const SizedBox(width: 10),
                    _statCard(user.isPremium ? '~4m' : '8m', 'Avg wait', theme),
                  ],
                ),
                const SizedBox(height: 20),

                Text('CAMPUS OUTLETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),

                ..._filtered.map((outlet) => _OutletCard(outlet: outlet, isPremium: user.isPremium)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner(UserProvider user, ThemeData theme) {
    if (user.isPremium) {
      // Active premium strip
      return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.goldBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.gold.withOpacity(0.15),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.workspace_premium, size: 20, color: AppTheme.gold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Premium Active ✦', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.goldDark)),
                    Text('Priority queue · 10% off all orders', style: TextStyle(fontSize: 11, color: AppTheme.gold.withOpacity(0.8))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppTheme.gold),
            ],
          ),
        ),
      );
    }

    // Upgrade CTA banner
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD4A017), Color(0xFFB8860B)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppTheme.gold.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.workspace_premium, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Go Premium ✦', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 3),
                  Text('Priority queue, 10% off, skip-the-line & more', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: const Text('₹99/mo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.goldDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String value, String label, ThemeData theme) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
}

class _OutletCard extends StatelessWidget {
  final Outlet outlet;
  final bool isPremium;
  const _OutletCard({required this.outlet, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (outlet.isOpen) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(outlet: outlet)));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'outlet_icon_${outlet.id}',
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: outlet.isOpen ? AppTheme.primaryBg : theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(outlet.icon, size: 28, color: outlet.isOpen ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.3)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(outlet.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(outlet.tagline, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _chip(Icons.storefront, outlet.isOpen ? 'Open' : 'Closed', outlet.isOpen ? AppTheme.green : AppTheme.red),
                      const SizedBox(width: 8),
                      if (outlet.isOpen) _chip(Icons.timer, isPremium ? '~${_reducedWait(outlet.waitTime)}' : outlet.waitTime, isPremium ? AppTheme.gold : AppTheme.yellow),
                      if (outlet.isOpen && isPremium) ...[
                        const SizedBox(width: 8),
                        _chip(Icons.bolt, 'Priority', AppTheme.gold),
                      ],
                      if (outlet.isOpen && !isPremium) ...[
                        const SizedBox(width: 8),
                        _chip(Icons.people, '${outlet.queueCount}', theme.colorScheme.onSurface.withOpacity(0.5)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (outlet.isOpen)
              const Icon(Icons.chevron_right, size: 20, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  String _reducedWait(String wait) {
    // Simple mock: reduce displayed wait for premium
    if (wait.contains('8')) return '4–6m';
    if (wait.contains('3')) return '1–2m';
    return wait;
  }

  Widget _chip(IconData icon, String text, Color color) {
    final displayColor = color == AppTheme.green ? const Color(0xFF16A34A) 
                       : color == AppTheme.red ? const Color(0xFFDC2626) 
                       : color == AppTheme.gold ? AppTheme.goldDark
                       : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: displayColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: displayColor)),
        ],
      ),
    );
  }
}
