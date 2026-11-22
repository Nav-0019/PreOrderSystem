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

  /// Fetch menu items safely from both subcollection and root /menu_items
  static Future<List<MenuItem>> _fetchMenuItemsForOutlet(DocumentSnapshot doc) async {
    final Map<String, MenuItem> itemsMap = {};

    // 1. Try reading subcollection
    try {
      final menuSnapshot = await doc.reference.collection('menu_items').get();
      for (final m in menuSnapshot.docs) {
        final md = m.data();
        if (md['isAvailable'] == false || md['isApproved'] == false || md['approvalStatus'] == 'pending') continue;
        itemsMap[m.id] = MenuItem(
          id: m.id,
          name: md['name'] ?? '',
          description: md['description'] ?? '',
          price: (md['price'] as num?)?.toDouble() ?? 0.0,
          category: md['category'] ?? 'General',
          icon: Icons.fastfood,
          isAvailable: md['isAvailable'] ?? true,
        );
      }
    } catch (_) {}

    // 2. Fetch from root collection /menu_items (which has read permissions in live rules)
    try {
      final rootSnap = await _db.collection('menu_items').get();
      for (final m in rootSnap.docs) {
        final md = m.data();
        final outletId = md['outletId'] as String?;
        // Match outletId or default if not set
        if (outletId != null && outletId.isNotEmpty && outletId != doc.id) continue;
        if (md['isAvailable'] == false || md['isApproved'] == false || md['approvalStatus'] == 'pending' || md['approvalStatus'] == 'rejected') continue;
        itemsMap[m.id] = MenuItem(
          id: m.id,
          name: md['name'] ?? '',
          description: md['description'] ?? '',
          price: (md['price'] as num?)?.toDouble() ?? 0.0,
          category: md['category'] ?? 'General',
          icon: Icons.fastfood,
          isAvailable: md['isAvailable'] ?? true,
        );
      }
    } catch (_) {}

    return itemsMap.values.toList();
  }

  /// One-time fetch: get all outlets with their menu items.
  static Future<List<Outlet>> getOutlets() async {
    try {
      final snapshot = await _db.collection('outlets').get();
      final List<Outlet> outlets = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final menuItems = await _fetchMenuItemsForOutlet(doc);

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
        final menuItems = await _fetchMenuItemsForOutlet(doc);

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
    String paymentMethod = 'UPI_QR',
    String paymentStatus = 'PAID',
    String? transactionId,
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
        final pickupToken = orderRef.id.length >= 4
            ? orderRef.id.substring(orderRef.id.length - 4).toUpperCase()
            : '1001';

        transaction.set(orderRef, {
          'userId': user.uid,
          'userName': user.displayName ?? 'Customer',
          'outletId': outletId,
          'outletName': outletName,
          'totalAmount': totalAmount,
          'status': 'pending',
          'paymentMethod': paymentMethod,
          'paymentStatus': paymentStatus,
          'transactionId': transactionId ?? '',
          'pickupToken': pickupToken,
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

  /// Cancel an order (customer can cancel if still pending)
  static Future<bool> cancelOrder(String orderId) async {
    try {
      final orderRef = _db.collection('orders').doc(orderId);
      await _db.runTransaction((transaction) async {
        final orderSnap = await transaction.get(orderRef);
        if (!orderSnap.exists) return;
        final data = orderSnap.data()!;
        final status = data['status'] as String?;
        final outletId = data['outletId'] as String?;
        if (status != 'pending') return;

        transaction.update(orderRef, {'status': 'cancelled'});

        if (outletId != null) {
          final outletRef = _db.collection('outlets').doc(outletId);
          final outletSnap = await transaction.get(outletRef);
          if (outletSnap.exists) {
            final currentQueue = outletSnap.data()?['queueCount'] as int? ?? 0;
            final newQueue = currentQueue > 0 ? currentQueue - 1 : 0;
            final newWaitTime = newQueue == 0 ? 'No wait' : '${newQueue * 2}-${newQueue * 2 + 3} mins';
            transaction.update(outletRef, {
              'queueCount': newQueue,
              'waitTime': newWaitTime,
            });
          }
        }
      });
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      return false;
    }
  }

  /// Stream completed & cancelled past orders for an outlet (for manager history)
  static Stream<List<Map<String, dynamic>>> streamOutletPastOrders(String outletId) {
    if (outletId.trim().isEmpty) return const Stream.empty();
    return _db
        .collection('orders')
        .where('outletId', isEqualTo: outletId)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
          final past = docs.where((d) {
            final status = d['status'] as String? ?? '';
            return ['completed', 'cancelled'].contains(status);
          }).toList();
          past.sort((a, b) {
            final at = (a['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            final bt = (b['createdAt'] as dynamic)?.millisecondsSinceEpoch ?? 0;
            return bt.compareTo(at); // Newest first
          });
          return past;
        });
  }

  /// Real-time stream of a single outlet's details (e.g. upiId, isOpen, waitTime)
  static Stream<Map<String, dynamic>?> streamOutlet(String outletId) {
    if (outletId.trim().isEmpty) return Stream.value(null);
    return _db.collection('outlets').doc(outletId).snapshots().map((snap) {
      if (snap.exists && snap.data() != null) {
        return {'id': snap.id, ...snap.data()!};
      }
      return null;
    });
  }

  // ── Menu Management (staff/admin) ─────────────────────────

  /// Real-time stream of menu items for a given outlet.
  static Stream<List<Map<String, dynamic>>> streamMenuItems(String outletId) {
    if (outletId.trim().isEmpty) return const Stream.empty();
    return _db.collection('menu_items').snapshots().map((snap) {
      final items = snap.docs
          .map((d) => {'id': d.id, ...d.data()})
          .where((d) =>
              (d['outletId'] == outletId || d['outletId'] == null || (d['outletId'] as String).isEmpty) &&
              d['approvalStatus'] != 'pending' &&
              d['approvalStatus'] != 'rejected')
          .toList();
      return items;
    });
  }

  /// Submit a menu item approval ticket for Administrator to confirm or reject.
  static Future<String> submitMenuItemApprovalTicket({
    required String outletId,
    required String outletName,
    required Map<String, dynamic> itemData,
  }) async {
    final user = _auth.currentUser;
    String ticketId = '';

    // 1. Write pending item directly to /menu_items (which has write permission in live rules)
    try {
      final docRef = await _db.collection('menu_items').add({
        'name': itemData['name'],
        'description': itemData['description'] ?? '',
        'price': itemData['price'],
        'category': itemData['category'] ?? 'Snacks',
        'prepTime': itemData['prepTime'] ?? 5,
        if (itemData['photoBase64'] != null) 'photoBase64': itemData['photoBase64'],
        'outletId': outletId,
        'outletName': outletName,
        'approvalStatus': 'pending',
        'isApproved': false,
        'isAvailable': false,
        'submittedByUid': user?.uid ?? '',
        'submittedByName': user?.displayName ?? 'Outlet Manager',
        'createdAt': FieldValue.serverTimestamp(),
      });
      ticketId = docRef.id;
      debugPrint('Item created in /menu_items with pending status, ID: $ticketId');
    } catch (e) {
      debugPrint('Error writing pending item to menu_items: $e');
    }

    // 2. Also try writing to approval_tickets (if collection is whitelisted)
    try {
      final ticketRef = await _db.collection('approval_tickets').add({
        'type': 'MENU_ITEM_ADD',
        'status': 'pending',
        'outletId': outletId,
        'outletName': outletName,
        'submittedByUid': user?.uid ?? '',
        'submittedByName': user?.displayName ?? 'Outlet Manager',
        'itemData': itemData,
        'menuItemId': ticketId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (ticketId.isEmpty) ticketId = ticketRef.id;
    } catch (e) {
      debugPrint('approval_tickets notice: $e (using /menu_items fallback)');
    }

    return ticketId;
  }

  /// Real-time stream of approval tickets for an outlet (to track pending, approved, rejected status)
  static Stream<List<Map<String, dynamic>>> streamOutletApprovalTickets(String outletId) {
    if (outletId.trim().isEmpty) return const Stream.empty();
    return _db.collection('menu_items').snapshots().map((snap) {
      return snap.docs
          .map((d) {
            final data = d.data();
            return {
              'id': d.id,
              'status': data['approvalStatus'] ?? (data['isApproved'] == true ? 'approved' : 'pending'),
              'itemData': {
                'name': data['name'],
                'price': data['price'],
                'category': data['category'],
              },
              ...data,
            };
          })
          .where((d) =>
              (d['outletId'] == outletId || d['outletId'] == null) &&
              (d['approvalStatus'] != null || d['isApproved'] == false))
          .toList();
    });
  }

  static Future<void> addMenuItem(
      String outletId, Map<String, dynamic> item) async {
    if (outletId.trim().isEmpty) return;
    try {
      await _db.collection('menu_items').add({
        ...item,
        'outletId': outletId,
        'isAvailable': true,
        'isApproved': true,
        'approvalStatus': 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    try {
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
    } catch (_) {}
  }

  static Future<void> updateMenuItemAvailability(
      String outletId, String itemId, bool isAvailable) async {
    if (itemId.trim().isEmpty) return;
    try {
      await _db.collection('menu_items').doc(itemId).update({'isAvailable': isAvailable});
    } catch (_) {}

    if (outletId.isNotEmpty) {
      try {
        await _db
            .collection('outlets')
            .doc(outletId)
            .collection('menu_items')
            .doc(itemId)
            .update({'isAvailable': isAvailable});
      } catch (_) {}
    }
  }

  static Future<void> updateMenuItem(
      String outletId, String itemId, Map<String, dynamic> data) async {
    try {
      await _db.collection('menu_items').doc(itemId).update(data);
    } catch (_) {}

    if (outletId.isNotEmpty) {
      try {
        await _db
            .collection('outlets')
            .doc(outletId)
            .collection('menu_items')
            .doc(itemId)
            .update(data);
      } catch (_) {}
    }
  }

  static Future<void> deleteMenuItem(String outletId, String itemId) async {
    try {
      await _db.collection('menu_items').doc(itemId).delete();
    } catch (_) {}

    if (outletId.isNotEmpty) {
      try {
        await _db
            .collection('outlets')
            .doc(outletId)
            .collection('menu_items')
            .doc(itemId)
            .delete();
      } catch (_) {}
    }
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
