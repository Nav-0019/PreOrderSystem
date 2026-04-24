import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String _role = 'student';
  String _name = 'John Doe';
  String _email = 'student@college.edu';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isPremium = false;
  DateTime? _premiumExpiry;

  String get role => _role;
  String get name => _name;
  String get email => _email;
  ThemeMode get themeMode => _themeMode;
  bool get isPremium => _isPremium;
  DateTime? get premiumExpiry => _premiumExpiry;
  String get initials => _name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }

  void setUser({required String name, required String email, required String role}) {
    _name = name;
    _email = email;
    _role = role;
    notifyListeners();
  }

  void togglePremium() {
    _isPremium = !_isPremium;
    if (_isPremium) {
      _premiumExpiry = DateTime.now().add(const Duration(days: 30));
    } else {
      _premiumExpiry = null;
    }
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void logout() {
    _role = 'student';
    _name = 'John Doe';
    _email = 'student@college.edu';
    _isPremium = false;
    _premiumExpiry = null;
    notifyListeners();
  }
}
