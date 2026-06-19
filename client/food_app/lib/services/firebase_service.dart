import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';

/// FirebaseService replaces the old SupabaseService.
/// All data comes from Firestore; real-time updates use onSnapshot streams.
class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Outlets ───────────────────────────────────────────────

  /// One-time fetch: get all outlets with their menu items.
  static Future<List<Outlet>> getOutlets() async {
    try {
      final snapshot = await _db.collection('outlets').get();
      final List<Outlet> outlets = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final menuSnapshot =
            await doc.reference.collection('menu_items').get();

        final menuItems = menuSnapshot.docs.map((m) {
          final md = m.data();
          return MenuItem(
            id: m.id,
            name: md['name'] ?? '',
            description: md['description'] ?? '',
            price: (md['price'] as num).toDouble(),
            category: md['category'] ?? 'General',
            icon: Icons.fastfood,
            isAvailable: md['isAvailable'] ?? true,
          );
        }).toList();

        outlets.add(Outlet(
          id: doc.id,
          name: data['name'] ?? '',
          tagline: data['tagline'] ?? '',
          icon: Icons.store,
          isOpen: data['isOpen'] ?? true,
          queueCount: data['queueCount'] ?? 0,
          waitTime: data['waitTime'] ?? '10 mins',
          menu: menuItems,
        ));
      }

      return outlets;
    } catch (e) {
      debugPrint('Error fetching outlets: $e');
      return [];
    }
  }

  /// Real-time stream: outlets update live as queueCount changes.
  static Stream<List<Outlet>> streamOutlets() {
    return _db.collection('outlets').snapshots().asyncMap((snapshot) async {
      final List<Outlet> outlets = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final menuSnapshot =
            await doc.reference.collection('menu_items').get();

        final menuItems = menuSnapshot.docs.map((m) {
          final md = m.data();
          return MenuItem(
            id: m.id,
            name: md['name'] ?? '',
            description: md['description'] ?? '',
            price: (md['price'] as num).toDouble(),
            category: md['category'] ?? 'General',
            icon: Icons.fastfood,
            isAvailable: md['isAvailable'] ?? true,
          );
        }).toList();

        outlets.add(Outlet(
          id: doc.id,
          name: data['name'] ?? '',
          tagline: data['tagline'] ?? '',
          icon: Icons.store,
          isOpen: data['isOpen'] ?? true,
          queueCount: data['queueCount'] ?? 0,
          waitTime: data['waitTime'] ?? '10 mins',
          menu: menuItems,
        ));
      }

      return outlets;
    });
  }

  // ── Orders ────────────────────────────────────────────────

  /// Place an order — writes to Firestore.
  /// The Cloud Function onOrderWrite will auto-update the outlet queue.
  static Future<String?> placeOrder({
    required String outletId,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('placeOrder: user not logged in');
        return null;
      }

      // Create the order document
      final orderRef = await _db.collection('orders').add({
        'userId': user.uid,
        'outletId': outletId,
        'totalAmount': totalAmount,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'items': items.map((item) => {
          'menuItemId': item['id'],
          'name': item['name'],
          'quantity': item['quantity'],
          'unitPrice': item['price'],
        }).toList(),
      });

      debugPrint('Order placed: ${orderRef.id}');
      return orderRef.id;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }

  /// Stream of current user's orders (most recent first).
  static Stream<List<Map<String, dynamic>>> streamMyOrders() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('orders')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// Stream ALL orders for a given outlet (for staff/admin).
  static Stream<List<Map<String, dynamic>>> streamOutletOrders(String outletId) {
    return _db
        .collection('orders')
        .where('outletId', isEqualTo: outletId)
        .where('status', whereIn: ['pending', 'prep', 'ready'])
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  /// Update order status (staff/admin).
  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _db.collection('orders').doc(orderId).update({'status': status});
  }

  // ── Menu Management (admin) ───────────────────────────────

  static Future<void> addMenuItem(
      String outletId, Map<String, dynamic> item) async {
    await _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .add({...item, 'outletId': outletId});
  }

  static Future<void> updateMenuItem(
      String outletId, String itemId, Map<String, dynamic> data) async {
    await _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .doc(itemId)
        .update(data);
  }

  static Future<void> deleteMenuItem(String outletId, String itemId) async {
    await _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .doc(itemId)
        .delete();
  }
}
