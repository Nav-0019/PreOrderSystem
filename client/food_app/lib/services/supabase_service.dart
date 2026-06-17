import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';
import 'package:flutter/material.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<List<Outlet>> getOutlets() async {
    try {
      final data = await _client.from('outlets').select('*, menu_items(*)');
      List<Outlet> outlets = [];
      for (var item in data) {
        List<MenuItem> menuItems = [];
        if (item['menu_items'] != null) {
          for (var menuItem in item['menu_items']) {
            menuItems.add(MenuItem(
              id: menuItem['id'],
              name: menuItem['name'],
              description: menuItem['description'] ?? '',
              price: (menuItem['price'] as num).toDouble(),
              category: menuItem['category'] ?? 'General',
              icon: Icons.fastfood, // simplify icon mapping for now
              isAvailable: menuItem['is_available'] ?? true,
            ));
          }
        }
        outlets.add(Outlet(
          id: item['id'],
          name: item['name'],
          tagline: item['tagline'] ?? '',
          icon: Icons.store, // simplify icon mapping
          isOpen: item['is_open'] ?? true,
          queueCount: item['queue_count'] ?? 0,
          waitTime: item['wait_time'] ?? '10m',
          menu: menuItems,
        ));
      }
      return outlets;
    } catch (e) {
      debugPrint('Error fetching outlets: $e');
      return [];
    }
  }

  static Future<String?> placeOrder({
    required double totalAmount,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // In a real app we'd group items by outlet, but for now we'll assume they're all from the same outlet or just assign to 'o1'.
      // Hardcode outlet_id to 'o1' for this MVP unless passed in.
      
      final orderRes = await _client.from('orders').insert({
        'user_id': user.id,
        'outlet_id': 'o1', 
        'total_amount': totalAmount,
        'status': 'pending',
      }).select().single();

      final orderId = orderRes['id'];

      List<Map<String, dynamic>> orderItems = [];
      for (var item in items) {
        orderItems.add({
          'order_id': orderId,
          'menu_item_id': item['id'],
          'quantity': item['quantity'],
          'unit_price': item['price'],
        });
      }

      await _client.from('order_items').insert(orderItems);
      return orderId;
    } catch (e) {
      debugPrint('Error placing order: $e');
      return null;
    }
  }
}
