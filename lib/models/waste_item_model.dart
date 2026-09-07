import 'package:flutter/material.dart';

class WasteItemModel {
  final int? id;
  final String name;
  final String type; // 'Organik' or 'Non-Organik'
  final String sampleItem;
  final double ratePerKg;
  final int ecoPoints;
  final String iconName;
  final String imageUrl;
  final String description;
  final String handlingTip;

  const WasteItemModel({
    this.id,
    required this.name,
    required this.type,
    required this.sampleItem,
    required this.ratePerKg,
    this.ecoPoints = 10,
    required this.iconName,
    required this.imageUrl,
    this.description = '',
    this.handlingTip = '',
  });

  bool get isOrganic => type.toLowerCase() == 'organik';

  // Convert iconName to Material IconData
  IconData get icon {
    switch (iconName) {
      case 'eco':
      case 'leaf':
        return Icons.energy_savings_leaf;
      case 'local_drink':
      case 'bottle':
        return Icons.local_drink_outlined;
      case 'menu_book':
      case 'book':
        return Icons.inventory_outlined;
      case 'paper':
        return Icons.menu_book_outlined;
      case 'inventory_2':
      case 'metal':
        return Icons.inventory_2_outlined;
      case 'wine_bar':
      case 'glass':
        return Icons.wine_bar_outlined;
      case 'devices':
      case 'electronic':
        return Icons.devices_other_outlined;
      case 'compost':
      case 'food':
        return Icons.compost;
      case 'oil':
      case 'water_drop':
        return Icons.water_drop_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      default:
        return isOrganic ? Icons.eco : Icons.recycling;
    }
  }

  // Convert model to Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'sample_item': sampleItem,
      'rate_per_kg': ratePerKg,
      'eco_points': ecoPoints,
      'icon_name': iconName,
      'image_url': imageUrl,
      'description': description,
      'handling_tip': handlingTip,
    };
  }

  // Create model from SQLite Map
  factory WasteItemModel.fromMap(Map<String, dynamic> map) {
    return WasteItemModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      type: map['type'] as String,
      sampleItem: (map['sample_item'] ?? '') as String,
      ratePerKg: (map['rate_per_kg'] as num).toDouble(),
      ecoPoints: (map['eco_points'] as int?) ?? 10,
      iconName: (map['icon_name'] ?? '') as String,
      imageUrl: (map['image_url'] ?? '') as String,
      description: (map['description'] ?? '') as String,
      handlingTip: (map['handling_tip'] ?? '') as String,
    );
  }
}
