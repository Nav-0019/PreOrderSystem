import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  CartItem({required this.id, required this.name, required this.price, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? currentOutletId;
  String? currentOutletName;

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  void addItem(String id, String name, double price, {String? outletId, String? outletName}) {
    if (outletId != null && currentOutletId != outletId) {
      _items.clear();
      currentOutletId = outletId;
      currentOutletName = outletName;
    }
    if (_items.containsKey(id)) {
      _items[id]!.quantity += 1;
    } else {
      _items[id] = CartItem(id: id, name: name, price: price);
    }
    notifyListeners();
  }

  void removeItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      _items[id]!.quantity -= 1;
    } else {
      _items.remove(id);
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
