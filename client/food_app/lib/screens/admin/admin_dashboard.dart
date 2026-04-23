import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 52, 20, 0),
            color: theme.cardColor,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aurabake', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                        const Text('Admin Dashboard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.green)),
                            const SizedBox(width: 6),
                            const Text('Online', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A))),
                          ],
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => user.toggleTheme(),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: theme.scaffoldBackgroundColor, border: Border.all(color: theme.dividerColor)),
                            alignment: Alignment.center,
                            child: Text(theme.brightness == Brightness.dark ? '☀️' : '🌙', style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            user.logout();
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                          },
                          child: const Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.red)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tabs
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _adminTab('Overview', 0, theme),
                      _adminTab('Live Queue', 1, theme),
                      _adminTab('Menu', 2, theme),
                      _adminTab('Analytics', 3, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Divider(height: 1, color: theme.dividerColor),

          Expanded(
            child: _tabIndex == 0 ? _buildOverview(theme) 
                 : _tabIndex == 1 ? _buildLiveQueue(theme)
                 : _tabIndex == 2 ? _buildMenu(theme)
                 : _buildAnalytics(theme),
          ),
        ],
      ),
    );
  }

  Widget _adminTab(String label, int index, ThemeData theme) {
    bool active = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6))),
      ),
    );
  }

  Widget _buildOverview(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Grid
        Row(
          children: [
            Expanded(child: _statCard('Total Orders', '156', '+12% today', AppTheme.green, theme)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Active Queue', '23', 'Live now', AppTheme.primary, theme)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Avg Wait', '8 min', '-2 from avg', AppTheme.green, theme)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Revenue', '₹12.4k', '+18% today', AppTheme.green, theme)),
          ],
        ),
        const SizedBox(height: 24),

        Text('OUTLET STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _outletRow('Main Canteen', 'Queue: 23 · Wait: 8–12 min', true, theme),
        _outletRow('Snack Corner', 'Queue: 7 · Wait: 3–5 min', true, theme),
        _outletRow('Juice Bar', 'Queue: 0 · Closed until 4PM', false, theme),
        _outletRow('Hot Meals Hub', 'Queue: 15 · Wait: 10–15 min', true, theme),
      ],
    );
  }

  Widget _statCard(String label, String value, String sub, Color subCol, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subCol)),
        ],
      ),
    );
  }

  Widget _outletRow(String title, String sub, bool open, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: open ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5))),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: (open ? AppTheme.green : AppTheme.red).withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
            child: Text(open ? 'Open' : 'Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: open ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveQueue(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('ACTIVE TICKETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        _ticketRow('#45 • John Doe', 'Main Canteen: 2x Thali, 1x Coke', 'In Progress', AppTheme.yellow, theme),
        _ticketRow('#46 • Faculty Meet', 'Snack Corner: 10x Samosa, 5x Tea', 'Priority', AppTheme.red, theme),
        _ticketRow('#47 • Jane Smith', 'Main Canteen: 1x Masala Maggi', 'Pending', theme.colorScheme.onSurface.withOpacity(0.5), theme),
      ],
    );
  }

  Widget _ticketRow(String title, String detail, String status, Color statusCol, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusCol)),
            ],
          ),
          const SizedBox(height: 6),
          Text(detail, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildMenu(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('MENU MANAGEMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
            const Text('+ Add Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ],
        ),
        const SizedBox(height: 10),
        _menuItemRow('Veg Thali', '₹80', true, theme),
        _menuItemRow('Masala Maggi', '₹45', true, theme),
        _menuItemRow('Cheese Sandwich', '₹65', false, theme),
      ],
    );
  }

  Widget _menuItemRow(String name, String price, bool stock, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: theme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$name  •  $price', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: stock ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4))),
          Switch(value: stock, onChanged: (v){}, activeColor: AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildAnalytics(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('WEEKLY PERFORMANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withOpacity(0.4), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          height: 200,
          decoration: BoxDecoration(color: theme.cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: theme.dividerColor)),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: theme.colorScheme.onSurface.withOpacity(0.1)),
              const SizedBox(height: 8),
              Text('Sales chart plotted here', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
