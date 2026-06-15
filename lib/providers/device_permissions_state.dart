import '../desings/device_feature.dart';

class DevicePermissionsState {
  final List<DeviceFeature> features;
  final bool isInitializing;

  const DevicePermissionsState({
    required this.features,
    this.isInitializing = true,
  });

  // Acceso rápido por tipo
  DeviceFeature featureOf(DeviceFeatureType type) {
    return features.firstWhere((f) => f.type == type);
  }

  DevicePermissionsState copyWithFeature(DeviceFeature updated) {
    return DevicePermissionsState(
      isInitializing: false,
      features: features.map((f) {
        return f.type == updated.type ? updated : f;
      }).toList(),
    );
  }

  DevicePermissionsState withInitializing(bool value) {
    return DevicePermissionsState(
      features: features,
      isInitializing: value,
    );
  }
}