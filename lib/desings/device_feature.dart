import 'package:flutter/material.dart';

enum DeviceFeatureType { camera, location, storage, wifi }

class DeviceFeature {
  final DeviceFeatureType type;
  final String title;
  final String description;
  final IconData icon;
  final bool isActive;
  final bool isPermanentlyDenied;
  final bool isLoading;

  const DeviceFeature({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.isActive = false,
    this.isPermanentlyDenied = false,
    this.isLoading = false,
  });

  DeviceFeature copyWith({
    bool? isActive,
    bool? isPermanentlyDenied,
    bool? isLoading,
  }) {
    return DeviceFeature(
      type: type,
      title: title,
      description: description,
      icon: icon,
      isActive: isActive ?? this.isActive,
      isPermanentlyDenied: isPermanentlyDenied ?? this.isPermanentlyDenied,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Definición base de cada feature
  static List<DeviceFeature> defaults() => const [
        DeviceFeature(
          type: DeviceFeatureType.camera,
          title: 'Cámara',
          description: 'Para fotografiar recibos y comprobantes',
          icon: Icons.camera_alt_rounded,
        ),
        DeviceFeature(
          type: DeviceFeatureType.wifi,
          title: 'Wi-Fi',
          description: 'Sincronización de gastos en tiempo real',
          icon: Icons.wifi_rounded,
        ),
        DeviceFeature(
          type: DeviceFeatureType.storage,
          title: 'Memoria interna',
          description: 'Guardar recibos y reportes localmente',
          icon: Icons.storage_rounded,
        ),
        DeviceFeature(
          type: DeviceFeatureType.location,
          title: 'Ubicación',
          description: 'Etiquetar dónde ocurrió el gasto con GPS',
          icon: Icons.location_on_rounded,
        ),
      ];
}