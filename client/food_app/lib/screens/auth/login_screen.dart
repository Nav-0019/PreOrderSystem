import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../models/menu_item.dart';
import '../main_shell.dart';

const _kSavedEmail = 'pref_saved_email';
const _kRememberMe = 'pref_remember_me';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;

  final _loginFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _registeredNumberController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _outletIdController = TextEditingController();

  final List<Map<String, dynamic>> _roles = [
    {'id': 'student', 'label': 'STUDENT', 'icon': Icons.school},
    {'id': 'manager', 'label': 'MANAGER', 'icon': Icons.manage_accounts},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_kRememberMe) ?? false;
    final savedEmail = prefs.getString(_kSavedEmail) ?? '';
    if (remember && savedEmail.isNotEmpty) {
      setState(() {
        _rememberMe = true;
        _loginEmailController.text = savedEmail;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _registeredNumberController.dispose();
    _registerPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _outletIdController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_signUpFormKey.currentState!.validate()) return;

    if (_selectedRole == 'manager' && _outletIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the Outlet ID provided by your admin.')));
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _registerPasswordController.text.trim();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final studentId = _studentIdController.text.trim();
    final registeredNumber = _registeredNumberController.text.trim();

    if (_selectedRole == 'student' && !email.endsWith('@presidencyuniversity.in')) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration requires a valid @presidencyuniversity.in email.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await credential.user?.updateDisplayName(name);

      final userData = {
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': _selectedRole,
        'isPremium': false,
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      if (_selectedRole == 'student') {
        userData['studentId'] = studentId;
      } else if (_selectedRole == 'manager') {
        userData['registeredNumber'] = registeredNumber;
        userData['managedOutletId'] = _outletIdController.text.trim();
      }

      // 1. Create the user document FIRST
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      // 2. Then attempt to auto-create the outlet (if manager)
      if (_selectedRole == 'manager') {
        final outletId = _outletIdController.text.trim();
        try {
          final outletDoc = await FirebaseFirestore.instance.collection('outlets').doc(outletId).get();
          if (!outletDoc.exists) {
            await FirebaseFirestore.instance.collection('outlets').doc(outletId).set({
              'name': 'Outlet $outletId',
              'tagline': 'Newly registered outlet',
              'isOpen': true,
              'queueCount': 0,
              'waitTime': 'No wait',
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('Could not auto-create outlet (likely permission denied due to Firestore rules): $e');
        }
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _doLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;

    final email = _loginEmailController.text.trim().toLowerCase();
    final password = _loginPasswordController.text.trim();

    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      // Save or clear email based on Remember Me
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_kSavedEmail, email);
        await prefs.setBool(_kRememberMe, true);
      } else {
        await prefs.remove(_kSavedEmail);
        await prefs.setBool(_kRememberMe, false);
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Login failed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _loginEmailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email address first.'),
            behavior: SnackBarBehavior.floating,
          ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Password reset email sent! Check your inbox.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Could not send reset email.'),
            behavior: SnackBarBehavior.floating,
          ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
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
                        height: 580,
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
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          ),
      ],
    );
  }

  Widget _buildLoginPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginFormKey,
        child: Column(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary.withOpacity(0.08)),
              alignment: Alignment.center,
              child: const Icon(Icons.lock_person_outlined, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(height: 10),
            Text('Login to your meal of the day!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 20),
            _buildField(
              icon: Icons.email_outlined, 
              hint: 'Email', 
              controller: _loginEmailController,
              validator: (v) => v!.isEmpty ? 'Enter email' : null,
            ),
            const SizedBox(height: 12),
            _buildField(
              icon: Icons.lock_outline, 
              hint: 'Password', 
              controller: _loginPasswordController, 
              isPassword: true,
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 12),
            // Remember Me row
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Remember my email', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.7), fontWeight: FontWeight.w500)),
                const Spacer(),
                GestureDetector(
                  onTap: _forgotPassword,
                  child: const Text('Forgot password?', style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                ),
              ],
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
      ),
    );
  }

  Widget _buildSignUpPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signUpFormKey,
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

              _buildField(
                icon: Icons.person_outline, 
                hint: 'Full Name', 
                controller: _nameController,
                validator: (v) => v!.isEmpty ? 'Enter full name' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                icon: Icons.email_outlined, 
                hint: _selectedRole == 'student' ? 'College Email (@presidencyuniversity.in)' : 'Email', 
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v!.isEmpty) return 'Enter email';
                  if (_selectedRole == 'student' && !v.endsWith('@presidencyuniversity.in')) return 'Must use @presidencyuniversity.in';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildField(
                icon: Icons.phone_outlined, 
                hint: 'Phone Number', 
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 12),
              
              if (_selectedRole == 'student') ...[
                _buildField(
                  icon: Icons.badge_outlined, 
                  hint: 'Student ID', 
                  controller: _studentIdController,
                  validator: (v) => v!.isEmpty ? 'Enter Student ID' : null,
                ),
                const SizedBox(height: 12),
              ] else ...[
                _buildField(
                  icon: Icons.badge_outlined, 
                  hint: 'Registered Baker Number', 
                  controller: _registeredNumberController,
                  validator: (v) => v!.isEmpty ? 'Enter Baker Number' : null,
                ),
                const SizedBox(height: 12),
                _buildField(
                  icon: Icons.store_mall_directory_outlined, 
                  hint: 'Outlet ID (provided by Admin)', 
                  controller: _outletIdController,
                  validator: (v) => v!.isEmpty ? 'Enter Outlet ID' : null,
                ),
                const SizedBox(height: 12),
              ],

              _buildField(
                icon: Icons.lock_outline, 
                hint: 'Create Password', 
                controller: _registerPasswordController, 
                isPassword: true,
                validator: (v) => v!.length < 6 ? 'Password must be at least 6 chars' : null,
              ),
              const SizedBox(height: 20),
              _buildGradientButton('Sign Up →', _submitForm),
              const SizedBox(height: 14),
              Text('Need a different role? Tap to select above.', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.4))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCircle(Map<String, dynamic> role, ThemeData theme) {
    final isSelected = _selectedRole == role['id'];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = role['id'];
          // Clear role-specific fields
          _studentIdController.clear();
          _registeredNumberController.clear();
          _outletIdController.clear();
        });
      },
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

  Widget _buildField({
    required IconData icon, 
    required String hint, 
    required TextEditingController controller, 
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      style: const TextStyle(fontSize: 14),
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.4)),
        prefixIcon: Icon(icon, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
        suffixIcon: isPassword
            ? GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: theme.colorScheme.onSurface.withOpacity(0.4)),
              )
            : null,
        filled: true,
        fillColor: theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
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
