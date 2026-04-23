import 'package:flutter/material.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final IconData icon; // Upgraded from emoji to IconData
  bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    this.isAvailable = true,
  });
}

class Outlet {
  final String id;
  final String name;
  final String tagline;
  final IconData icon; // Upgraded from emoji
  final bool isOpen;
  final int queueCount;
  final String waitTime;
  final List<MenuItem> menu;

  Outlet({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.isOpen,
    required this.queueCount,
    required this.waitTime,
    required this.menu,
  });
}
