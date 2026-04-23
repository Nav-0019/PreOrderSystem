import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../../models/app_data.dart';
import '../../models/menu_item.dart';
import '../customer/menu_screen.dart';
import '../customer/notifications_screen.dart';
import '../customer/profile_screen.dart';

class FacultyHome extends StatefulWidget {
  const FacultyHome({super.key});
  @override
  State<FacultyHome> createState() => _FacultyHomeState();
}

class _FacultyHomeState extends State<FacultyHome> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final filtered = kOutlets.where((o) => _searchQuery.isEmpty || o.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
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
                          const Text('Faculty\nDashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
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
                            child: Text(theme.brightness == Brightness.dark ? '☀️' : '🌙', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.indigoBg, border: Border.all(color: AppTheme.indigoBdr)),
                            alignment: Alignment.center,
                            child: const Text('🔔', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                          child: Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.indigo),
                            alignment: Alignment.center,
                            child: Text(user.initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      const Text('🔍', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(border: InputBorder.none, hintText: 'Search canteens...', hintStyle: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.4))),
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
              children: [
                Text('FACULTY QUICK ACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.indigoBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.indigoBdr)),
                          child: Column(
                            children: const [
                              Icon(Icons.flash_on, size: 24, color: AppTheme.indigo),
                              SizedBox(height: 4),
                              Text('Priority Lane', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.indigo)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
                          child: Column(
                            children: [
                              const Icon(Icons.coffee, size: 24),
                              const SizedBox(height: 4),
                              Text('Meeting Snacks', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('CAMPUS OUTLETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
                const SizedBox(height: 10),
                ...filtered.map((outlet) => _FacultyOutletCard(outlet: outlet)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FacultyOutletCard extends StatelessWidget {
  final Outlet outlet;
  const _FacultyOutletCard({required this.outlet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        if (outlet.isOpen) Navigator.push(context, MaterialPageRoute(builder: (_) => MenuScreen(outlet: outlet)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
        child: Row(
          children: [
            Hero(
              tag: 'outlet_icon_${outlet.id}',
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: outlet.isOpen ? AppTheme.indigoBg : theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(14)),
                alignment: Alignment.center,
                child: Icon(outlet.icon, size: 28, color: outlet.isOpen ? AppTheme.indigo : theme.colorScheme.onSurface.withOpacity(0.3)),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: (outlet.isOpen ? AppTheme.green : AppTheme.red).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                        child: Text(outlet.isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: outlet.isOpen ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
                      ),
                      if (outlet.isOpen) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppTheme.yellow.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                          child: Text('⏱ ${outlet.waitTime} • Priority Active', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.yellow)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (outlet.isOpen) const Icon(Icons.chevron_right, size: 20, color: AppTheme.indigo),
          ],
        ),
      ),
    );
  }
}
