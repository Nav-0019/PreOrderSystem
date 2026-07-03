import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

const _kThemeKey = 'pref_dark_mode';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── State ────────────────────────────────────────────────
  User? _firebaseUser;
  String _role = 'student';
  String _name = '';
  String _email = '';
  String? _phone;
  String? _studentId;
  String? _managedOutletId;
  String? _registeredNumber;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isPremium = false;
  DateTime? _premiumExpiry;
  bool _isLoading = true;
  String? _photoBase64;

  // ── Getters ──────────────────────────────────────────────
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _firebaseUser != null;
  String get uid => _firebaseUser?.uid ?? '';
  String get role => _role;
  String get name => _name;
  String get email => _email;
  String? get phone => _phone;
  String? get studentId => _studentId;
  String? get managedOutletId => _managedOutletId;
  String? get registeredNumber => _registeredNumber;
  ThemeMode get themeMode => _themeMode;
  bool get isPremium => _isPremium;
  DateTime? get premiumExpiry => _premiumExpiry;
  String? get photoBase64 => _photoBase64;
  String get initials {
    if (_name.trim().isEmpty) return '??';
    return _name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  UserProvider() {
    _loadPrefs();
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  StreamSubscription<DocumentSnapshot>? _userDocSub;

  // ── Internal: handle auth state changes ─────────────────
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;
    await _userDocSub?.cancel();

    if (user != null) {
      _userDocSub = _db.collection('users').doc(user.uid).snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data() as Map<String, dynamic>;
          final fetchedName = data['name'] as String?;
          _name = (fetchedName != null && fetchedName.trim().isNotEmpty) ? fetchedName.trim() : (user.displayName ?? 'Student');
          _email = data['email'] ?? user.email ?? '';
          _role = data['role'] ?? 'student';
          _isPremium = data['isPremium'] ?? false;
          _phone = data['phone'];
          _studentId = data['studentId'];
          _managedOutletId = data['managedOutletId'];
          _registeredNumber = data['registeredNumber'];
          _photoBase64 = data['photoBase64'];
        } else {
          // Profile doc doesn't exist yet (Cloud Function may be delayed or still writing)
          _name = user.displayName ?? 'Student';
          _email = user.email ?? '';
          _role = 'student';
          _isPremium = false;
          _phone = null;
          _studentId = null;
          _managedOutletId = null;
          _registeredNumber = null;
          _photoBase64 = null;
        }
        _isLoading = false;
        notifyListeners();
      }, onError: (e) {
        debugPrint('Error listening to user profile: $e');
        _isLoading = false;
        notifyListeners();
      });
    } else {
      _resetToDefaults();
      _isLoading = false;
      notifyListeners();
    }
  }

  void _resetToDefaults() {
    _role = 'student';
    _name = '';
    _email = '';
    _phone = null;
    _studentId = null;
    _managedOutletId = null;
    _registeredNumber = null;
    _isPremium = false;
    _premiumExpiry = null;
    _photoBase64 = null;
  }

  // ── Public API ───────────────────────────────────────────
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

  void toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeKey, _themeMode == ThemeMode.dark);
    notifyListeners();
  }

  Future<void> logout() async {
    await _userDocSub?.cancel();
    await _auth.signOut();
    _resetToDefaults();
    notifyListeners();
  }
}
