import 'package:flutter/material.dart';

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final IconData icon; // Upgraded from emoji to IconData
  final int prepTime; // Average prep time in minutes
  final String? photoBase64; // Base64 compressed image
  bool isAvailable;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.icon,
    this.prepTime = 5,
    this.photoBase64,
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
