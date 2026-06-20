import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String get initials => _name
      .split(' ')
      .map((w) => w.isNotEmpty ? w[0] : '')
      .take(2)
      .join()
      .toUpperCase();

  UserProvider() {
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  // ── Internal: handle auth state changes ─────────────────
  Future<void> _onAuthStateChanged(User? user) async {
    _firebaseUser = user;

    if (user != null) {
      // Load extra profile data from Firestore
      await _loadUserProfile(user.uid);
    } else {
      _resetToDefaults();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        _name = data['name'] ?? _firebaseUser?.displayName ?? 'Student';
        _email = data['email'] ?? _firebaseUser?.email ?? '';
        _role = data['role'] ?? 'student';
        _isPremium = data['isPremium'] ?? false;
        _phone = data['phone'];
        _studentId = data['studentId'];
        _managedOutletId = data['managedOutletId'];
        _registeredNumber = data['registeredNumber'];
      } else {
        // Profile doc doesn't exist yet (Cloud Function may be delayed)
        // Use data directly from Firebase Auth
        _name = _firebaseUser?.displayName ?? 'Student';
        _email = _firebaseUser?.email ?? '';
        _role = 'student';
        _isPremium = false;
        _phone = null;
        _studentId = null;
        _managedOutletId = null;
        _registeredNumber = null;
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
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

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _resetToDefaults();
    notifyListeners();
  }
}
