import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_theme.dart';

// Customer
import 'customer/customer_home.dart';
import 'customer/orders_screen.dart';
import 'customer/support_screen.dart';
import 'customer/profile_screen.dart';
import 'customer/cart_screen.dart';

// Faculty
import 'faculty/faculty_home.dart';

// Staff
import 'staff/baker_queue_screen.dart';
import 'staff/baker_inventory_screen.dart';
import 'staff/baker_profile_screen.dart';

// Admin
import 'admin/admin_dashboard.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<UserProvider>().role;
    final theme = Theme.of(context);

    // Admin gets a full-screen dashboard with no bottom nav
    if (role == 'admin') {
      return const AdminDashboardScreen();
    }

    // Build pages and nav items based on role
    final List<Widget> pages;
    final List<_NavItemData> navItems;

    if (role == 'staff') {
      pages = const [
        BakerQueueScreen(),
        BakerInventoryScreen(),
        BakerProfileScreen(),
      ];
      navItems = [
        _NavItemData(Icons.kitchen_outlined, 'Queue'),
        _NavItemData(Icons.inventory_2_outlined, 'Stock'),
        _NavItemData(Icons.person_outline, 'Profile'),
      ];
    } else {
      // Student & Faculty share the same nav structure
      pages = [
        role == 'faculty' ? const FacultyHome() : const CustomerHome(),
        const OrdersScreen(),
        const SupportScreen(),
        const ProfileScreen(),
      ];
      navItems = [
        _NavItemData(Icons.home_outlined, 'Home'),
        _NavItemData(Icons.receipt_long_outlined, 'Orders'),
        _NavItemData(Icons.support_agent_outlined, 'Support'),
        _NavItemData(Icons.person_outline, 'Profile'),
      ];
    }

    // Ensure index is valid when switching roles
    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Build nav items, inserting Cart button in the middle for non-staff
              ...List.generate(navItems.length, (i) {
                // For student/faculty, insert a cart button after index 1 (Orders)
                return _buildNavButton(navItems[i], i, theme);
              }),
              // Cart button for non-staff roles (between Orders and Chat)
              if (role != 'staff')
                _buildCartButton(theme),
            ]..sort((a, b) {
              // Reorder to put cart in the middle
              return 0;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(_NavItemData data, int index, ThemeData theme) {
    final isActive = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, size: 22, color: isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4)),
            const SizedBox(height: 3),
            Text(data.label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isActive ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildCartButton(ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, size: 22, color: AppTheme.primary),
            ),
            const SizedBox(height: 2),
            const Text('Cart', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  _NavItemData(this.icon, this.label);
}
