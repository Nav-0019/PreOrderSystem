import 'package:flutter/material.dart';
import 'menu_item.dart';

// Mock Data
final List<Outlet> kOutlets = [
  Outlet(
    id: 'o_main',
    name: 'Main Canteen',
    tagline: 'Hot meals & daily specials',
    icon: Icons.restaurant,
    isOpen: true,
    queueCount: 23,
    waitTime: '8–12m',
    menu: [
      MenuItem(id: 'm1', name: 'Masala Maggi', description: 'Classic 2-min noodles with veggies', price: 45, category: 'Snacks', icon: Icons.ramen_dining),
      MenuItem(id: 'm2', name: 'Veg Thali', description: 'Roti, Dal, Sabzi & Rice', price: 80, category: 'Meals', icon: Icons.dinner_dining),
      MenuItem(id: 'm3', name: 'Cold Coffee', description: 'Classic iced frappe', price: 60, category: 'Beverages', icon: Icons.local_cafe),
    ],
  ),
  Outlet(
    id: 'o_snack',
    name: 'Snack Corner',
    tagline: 'Quick bites on the go',
    icon: Icons.fastfood,
    isOpen: true,
    queueCount: 7,
    waitTime: '3–5m',
    menu: [
      MenuItem(id: 's1', name: 'Samosa (2pc)', description: 'Crispy potato pastry', price: 20, category: 'Snacks', icon: Icons.bakery_dining),
      MenuItem(id: 's2', name: 'Cheese Burst Sandwich', description: 'Grilled triple layered', price: 65, category: 'Snacks', icon: Icons.breakfast_dining),
    ],
  ),
  Outlet(
    id: 'o_juice',
    name: 'Juice Bar',
    tagline: 'Fresh juices & shakes',
    icon: Icons.local_drink,
    isOpen: false,
    queueCount: 0,
    waitTime: 'Closed',
    menu: [
      MenuItem(id: 'j1', name: 'Fresh Orange', description: 'No sugar added', price: 50, category: 'Juices', icon: Icons.local_drink),
    ],
  ),
];
