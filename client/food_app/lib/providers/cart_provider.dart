import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String outletId;
  final String outletName;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.category = 'General',
    this.outletId = '',
    this.outletName = '',
    this.quantity = 1,
  });
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? currentOutletId;
  String? currentOutletName;

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addItem(
    String id,
    String name,
    double price, {
    String? category,
    String? outletId,
    String? outletName,
  }) {
    if (outletId != null && outletId.isNotEmpty) {
      // If switching to another vendor, clear items from the previous vendor so orders are never mixed
      if (currentOutletId != null && currentOutletId != outletId && _items.isNotEmpty) {
        _items.clear();
      }
      currentOutletId = outletId;
      if (outletName != null && outletName.isNotEmpty) {
        currentOutletName = outletName;
      }
    }

    if (_items.containsKey(id)) {
      _items[id]!.quantity += 1;
    } else {
      _items[id] = CartItem(
        id: id,
        name: name,
        price: price,
        category: category ?? 'General',
        outletId: outletId ?? currentOutletId ?? '',
        outletName: outletName ?? currentOutletName ?? '',
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      _items[id]!.quantity -= 1;
    } else {
      _items.remove(id);
      if (_items.isEmpty) {
        currentOutletId = null;
        currentOutletName = null;
      }
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    currentOutletId = null;
    currentOutletName = null;
    notifyListeners();
  }
}
