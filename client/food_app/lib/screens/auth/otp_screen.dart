import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../main_shell.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _verify() {
    final otpCode = _controllers.map((c) => c.text).join();
    if (otpCode.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the full 6-digit code.')));
      return;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Orange header
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(28, 70, 28, 70),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppTheme.primary, AppTheme.primaryDark]),
                  ),
                  child: Column(
                    children: [
                      const Text('Verify Email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                      const SizedBox(height: 6),
                      Text('Enter the 6-digit code sent to you', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75))),
                    ],
                  ),
                ),
                // Back button
                Positioned(
                  top: 50, left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34, height: 34,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.15)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),

            // White card
            Container(
              transform: Matrix4.translationValues(0, -36, 0),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
              ),
              child: Column(
                children: [
                  // Envelope icon
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryBg,
                      border: Border.all(color: AppTheme.primaryBdr, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.email_outlined, color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text('Code sent to', style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  const SizedBox(height: 2),
                  const Text('john@college.edu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 28),

                  // OTP boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) => SizedBox(
                      width: 46, height: 56,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: theme.dividerColor, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: theme.scaffoldBackgroundColor,
                        ),
                        onChanged: (v) => _onOtpChanged(v, i),
                      ),
                    )),
                  ),
                  const SizedBox(height: 28),

                  // Verify button
                  GestureDetector(
                    onTap: _verify,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryDark]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 4))],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Verify & Enter →', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A new code has been sent.')));
                    },
                    child: const Text('Resend Code', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
