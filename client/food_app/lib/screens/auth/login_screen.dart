import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRole = 'student';
  bool _obscurePassword = true;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final List<Map<String, dynamic>> _roles = [
    {'id': 'student', 'label': 'STUDENT', 'icon': Icons.school},
    {'id': 'staff', 'label': 'STAFF', 'icon': Icons.kitchen},
    {'id': 'admin', 'label': 'ADMIN', 'icon': Icons.admin_panel_settings},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_nameController.text.trim().isEmpty || _emailController.text.trim().isEmpty || _idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill out all fields.')));
      return;
    }
    
    final email = _emailController.text.trim();
    if (_selectedRole == 'student') {
      if (!email.toLowerCase().endsWith('@college.edu')) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration requires a valid @college.edu email.')));
        return;
      }
    }

    // In a real app, this would hit an API.
    context.read<UserProvider>().setUser(
      name: _nameController.text.trim(), 
      email: email, 
      role: _selectedRole
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpScreen()));
  }

  void _doLogin() {
    if (_loginEmailController.text.trim().isEmpty || _loginPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter email and password.')));
      return;
    }

    final email = _loginEmailController.text.trim().toLowerCase();
    final password = _loginPasswordController.text.trim();

    String role = 'student';
    bool isPremium = false;
    // Strict dummy verification instead of wildcard matching
    if (email == 'admin@aurabake.com' && password == 'admin123') {
      role = 'admin';
    } else if (email == 'staff@aurabake.com' && password == 'staff123') {
      role = 'staff';
    } else if (email == 'premium@college.edu' && password == 'premium123') {
      role = 'student';
      isPremium = true;
    } else if (email.endsWith('@college.edu')) {
      role = 'student';
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid username or password.')));
      return;
    }

    // In a real app, this would hit an API and validate credentials.
    final userProvider = context.read<UserProvider>();
    userProvider.setUser(
      name: role == 'admin' ? 'ADMIN' : role == 'staff' ? 'STAFF' : isPremium ? 'Premium User' : role.toUpperCase(), 
      email: email, 
      role: role
    );
    if (isPremium) {
      userProvider.togglePremium();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const OtpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Orange gradient header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 70, 28, 70),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 86, height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/branding/AuraBake_logo.png', fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: const Text('AB', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26, color: AppTheme.primary)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aurabake', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.3)),
                      const SizedBox(height: 4),
                      Text('Your college canteen,\npre-ordered', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85), height: 1.3)),
                    ],
                  ),
                ],
              ),
            ),

            // White card sheet
            Container(
              transform: Matrix4.translationValues(0, -36, 0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primary,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.4),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    tabs: const [Tab(text: 'Login'), Tab(text: 'Sign Up')],
                  ),

                  SizedBox(
                    height: 520,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginPanel(theme),
                        _buildSignUpPanel(theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.08)),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_person_outlined, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 10),
          Text('Enter your credentials to access your dashboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 20),
          _buildField(Icons.email_outlined, 'Email (e.g. admin@aurabake.com)', _loginEmailController),
          const SizedBox(height: 12),
          _buildField(Icons.lock_outline, 'Password (admin123)', _loginPasswordController, isPassword: true),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {},
              child: const Text('Forgot password?', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),
          _buildGradientButton('Sign In →', _doLogin),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don't have an account? ", style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
              GestureDetector(
                onTap: () => _tabController.animateTo(1),
                child: const Text('Sign Up', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.08)),
              alignment: Alignment.center,
              child: const Icon(Icons.shield_outlined, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 10),
            Text('Select your role to register:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 16),

            // Role selector circles
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _roles.map((r) => _buildRoleCircle(r, theme)).toList(),
            ),
            const SizedBox(height: 24),

            _buildField(Icons.person_outline, 'Full Name', _nameController),
            const SizedBox(height: 12),
            _buildField(Icons.email_outlined, 'College Email', _emailController),
            const SizedBox(height: 12),
            _buildField(Icons.badge_outlined, 'College ID / Roll Number', _idController),
            const SizedBox(height: 20),
            _buildGradientButton('Continue →', _submitForm),
            const SizedBox(height: 14),
            Text('Need a different role? Tap to select above.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCircle(Map<String, dynamic> role, ThemeData theme) {
    final isSelected = _selectedRole == role['id'];
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role['id']),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primary.withOpacity(0.08) : theme.dividerColor.withOpacity(0.3),
                border: Border.all(color: isSelected ? AppTheme.primary : theme.dividerColor, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Icon(role['icon'], size: 28, color: isSelected ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4)),
            ),
            const SizedBox(height: 6),
            Text(role['label'], style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700, letterSpacing: 0.06, color: isSelected ? AppTheme.primary : theme.colorScheme.onSurface.withOpacity(0.4))),
          ],
        ),
      ),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController controller, {bool isPassword = false}) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
        color: theme.cardColor,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscurePassword,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              ),
            ),
          ),
          if (isPassword)
            GestureDetector(
              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.02)),
      ),
    );
  }
}
