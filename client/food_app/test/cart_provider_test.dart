import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/providers/cart_provider.dart';

void main() {
  group('CartProvider Tests', () {
    late CartProvider cart;

    setUp(() {
      cart = CartProvider();
    });

    test('Initial cart is empty', () {
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.currentOutletId, isNull);
    });

    test('Adding single item updates item count and total amount', () {
      cart.addItem(
        'item_1',
        'Veg Burger',
        50.0,
        outletId: 'outlet_1',
        outletName: 'Campus Canteen',
        category: 'Snacks',
      );

      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 50.0);
      expect(cart.currentOutletId, 'outlet_1');
      expect(cart.currentOutletName, 'Campus Canteen');
    });

    test('Adding same item increments quantity', () {
      cart.addItem(
        'item_1',
        'Veg Burger',
        50.0,
        outletId: 'outlet_1',
        outletName: 'Campus Canteen',
      );
      cart.addItem(
        'item_1',
        'Veg Burger',
        50.0,
        outletId: 'outlet_1',
        outletName: 'Campus Canteen',
      );

      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 100.0);
    });

    test('Removing single quantity decrements count and resets when empty', () {
      cart.addItem(
        'item_1',
        'Veg Burger',
        50.0,
        outletId: 'outlet_1',
        outletName: 'Campus Canteen',
      );
      cart.addItem(
        'item_1',
        'Veg Burger',
        50.0,
        outletId: 'outlet_1',
        outletName: 'Campus Canteen',
      );

      cart.removeItem('item_1');
      expect(cart.itemCount, 1);
      expect(cart.totalAmount, 50.0);

      cart.removeItem('item_1');
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.currentOutletId, isNull);
    });

    test('Clear removes all items and resets outlet association', () {
      cart.addItem(
        'item_1',
        'Cold Coffee',
        40.0,
        outletId: 'outlet_1',
        outletName: 'Nescafe',
      );
      expect(cart.itemCount, 1);

      cart.clear();
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.currentOutletId, isNull);
    });

    test('Single outlet enforcement clears previous outlet items', () {
      cart.addItem(
        'item_1',
        'Cold Coffee',
        40.0,
        outletId: 'outlet_1',
        outletName: 'Nescafe',
      );
      expect(cart.currentOutletId, 'outlet_1');
      expect(cart.itemCount, 1);

      // Add item from another outlet
      cart.addItem(
        'item_2',
        'Thali',
        90.0,
        outletId: 'outlet_2',
        outletName: 'Campus Canteen',
      );
      expect(cart.currentOutletId, 'outlet_2');
      expect(cart.itemCount, 1);
      expect(cart.items.containsKey('item_1'), isFalse);
      expect(cart.items.containsKey('item_2'), isTrue);
    });
  });
}
