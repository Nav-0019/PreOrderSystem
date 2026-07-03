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

  /// Create a new outlet
  static Future<String?> createOutlet(String name, String tagline) async {
    try {
      final docRef = await _db.collection('outlets').add({
        'name': name,
        'tagline': tagline,
        'isOpen': true,
        'queueCount': 0,
        'waitTime': 'No wait',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating outlet: $e');
      return null;
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
    required String outletName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('placeOrder: user not logged in');
        return null;
      }

      final orderRef = _db.collection('orders').doc();
      final outletRef = _db.collection('outlets').doc(outletId);

      await _db.runTransaction((transaction) async {
        // 1. Read outlet current queue
        final outletSnap = await transaction.get(outletRef);
        final currentQueue = outletSnap.data()?['queueCount'] as int? ?? 0;
        final newQueue = currentQueue + 1;
        final newWaitTime = '${newQueue * 2}-${newQueue * 2 + 3} mins';

        // 2. Write order document
        transaction.set(orderRef, {
          'userId': user.uid,
          'outletId': outletId,
          'outletName': outletName,
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

        // 3. Increment outlet queue
        transaction.update(outletRef, {
          'queueCount': newQueue,
          'waitTime': newWaitTime,
        });
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
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // Client-side sort: newest first
          docs.sort((a, b) {
            final at = (a['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            final bt = (b['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at);
          });
          return docs;
        });
  }

  /// Stream a single order by ID
  static Stream<List<Map<String, dynamic>>> streamSingleOrder(String orderId) {
    return _db
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((snap) {
          if (snap.exists && snap.data() != null) {
            return [{'id': snap.id, ...snap.data()!}];
          }
          return [];
        });
  }

  /// Stream ALL orders for a given outlet (for staff/admin).
  static Stream<List<Map<String, dynamic>>> streamOutletOrders(String outletId) {
    if (outletId.trim().isEmpty) return const Stream.empty();
    return _db
        .collection('orders')
        .where('outletId', isEqualTo: outletId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          // Client-side filter for active statuses + sort oldest first
          final active = docs.where((d) {
            final status = d['status'] as String? ?? '';
            return ['pending', 'prep', 'ready'].contains(status);
          }).toList();
          active.sort((a, b) {
            final at = (a['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            final bt = (b['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            return at.compareTo(bt);
          });
          return active;
        });
  }

  /// Update order status (staff/admin).
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);

      await _db.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) return;

        final data = orderSnap.data()!;
        final currentStatus = data['status'] as String?;
        final outletId = data['outletId'] as String?;

        if (outletId == null || currentStatus == null) return;

        transaction.update(orderRef, {'status': status});

        // If transitioning from active ('pending', 'prep', 'ready') to inactive
        final wasActive = ['pending', 'prep', 'ready'].contains(currentStatus);
        final isNowActive = ['pending', 'prep', 'ready'].contains(status);

        if (wasActive && !isNowActive) {
          final outletRef = _db.collection('outlets').doc(outletId);
          final outletSnap = await transaction.get(outletRef);
          final currentQueue = outletSnap.data()?['queueCount'] as int? ?? 0;
          final newQueue = (currentQueue > 0) ? currentQueue - 1 : 0;
          final newWaitTime = newQueue == 0 ? 'No wait' : '${newQueue * 2}-${newQueue * 2 + 3} mins';

          transaction.update(outletRef, {
            'queueCount': newQueue,
            'waitTime': newWaitTime,
          });
        }
      });
    } catch (e) {
      debugPrint('Error updating order status: $e');
    }
  }

  // ── Menu Management (admin) ───────────────────────────────

  /// Real-time stream of menu items for a given outlet.
  static Stream<List<Map<String, dynamic>>> streamMenuItems(String outletId) {
    if (outletId.trim().isEmpty) return const Stream.empty();
    return _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  static Future<void> addMenuItem(
      String outletId, Map<String, dynamic> item) async {
    if (outletId.trim().isEmpty) return;
    await _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .add({
          ...item,
          'outletId': outletId,
          'isAvailable': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static Future<void> updateMenuItemAvailability(
      String outletId, String itemId, bool isAvailable) async {
    if (outletId.trim().isEmpty || itemId.trim().isEmpty) return;
    await _db
        .collection('outlets')
        .doc(outletId)
        .collection('menu_items')
        .doc(itemId)
        .update({'isAvailable': isAvailable});
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

  /// Update manager's outlet info (isOpen, waitTime, etc)
  static Future<void> updateOutlet(String outletId, Map<String, dynamic> data) async {
    if (outletId.trim().isEmpty) return;
    await _db.collection('outlets').doc(outletId).update(data);
  }

  /// Update a user's profile (e.g. photoBase64)
  static Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update(data);
  }
}
