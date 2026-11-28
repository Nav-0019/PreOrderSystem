import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_app/models/menu_item.dart';

void main() {
  group('Model Tests', () {
    test('MenuItem instantiates with correct values and defaults', () {
      final item = MenuItem(
        id: 'item_101',
        name: 'Paneer Puff',
        description: 'Freshly baked spicy puff',
        price: 35.0,
        category: 'Snacks',
        icon: Icons.bakery_dining,
      );

      expect(item.id, 'item_101');
      expect(item.name, 'Paneer Puff');
      expect(item.price, 35.0);
      expect(item.prepTime, 5); // default
      expect(item.isAvailable, isTrue); // default
      expect(item.photoBase64, isNull);
    });

    test('Outlet model instantiates with menu items', () {
      final item = MenuItem(
        id: 'item_101',
        name: 'Samosa',
        description: 'Crispy potato samosa',
        price: 25.0,
        category: 'Snacks',
        icon: Icons.fastfood,
      );

      final outlet = Outlet(
        id: 'outlet_2000',
        name: 'Campus Canteen 2000',
        tagline: 'Best snacks on campus',
        icon: Icons.store,
        isOpen: true,
        queueCount: 3,
        waitTime: '6-9 mins',
        menu: [item],
      );

      expect(outlet.id, 'outlet_2000');
      expect(outlet.isOpen, isTrue);
      expect(outlet.queueCount, 3);
      expect(outlet.menu.length, 1);
      expect(outlet.menu.first.name, 'Samosa');
    });
  });
}
