import 'package:flutter/material.dart';

/// Catálogo curado de íconos const para categorías.
/// Se guarda solo la clave (String) en Firestore; así evitamos problemas de
/// tree-shaking de íconos y mantenemos el dominio libre de Flutter.
class CategoryCatalog {
  CategoryCatalog._();

  static const Map<String, IconData> icons = {
    'receipt': Icons.receipt_long_rounded,
    'food': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'flight': Icons.flight_rounded,
    'hotel': Icons.hotel_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'supplies': Icons.inventory_2_rounded,
    'tools': Icons.build_rounded,
    'tech': Icons.devices_rounded,
    'phone': Icons.phone_iphone_rounded,
    'internet': Icons.wifi_rounded,
    'training': Icons.school_rounded,
    'marketing': Icons.campaign_rounded,
    'health': Icons.local_hospital_rounded,
    'gift': Icons.card_giftcard_rounded,
    'coffee': Icons.local_cafe_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'utilities': Icons.bolt_rounded,
    'rent': Icons.home_work_rounded,
    'other': Icons.category_rounded,
  };

  /// Paleta de colores disponibles para categorías (valores ARGB).
  static const List<int> colors = [
    0xFF6C63FF, // accent
    0xFF4CAF50, // verde
    0xFF2196F3, // azul
    0xFFFF9800, // naranja
    0xFFE91E63, // rosa
    0xFF9C27B0, // morado
    0xFF00BCD4, // cian
    0xFFFFC107, // ámbar
    0xFFF44336, // rojo
    0xFF795548, // café
    0xFF607D8B, // gris azulado
    0xFF8BC34A, // lima
  ];

  static const String defaultIconKey = 'receipt';
  static const int defaultColor = 0xFF6C63FF;

  static IconData iconFor(String key) =>
      icons[key] ?? icons[defaultIconKey]!;
}
