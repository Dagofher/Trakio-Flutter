import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../desings/device_feature.dart';
import 'device_permissions_state.dart';

// ── Provider ─────────────────────────────────────────────

final devicePermissionsProvider =
    StateNotifierProvider<DevicePermissionsNotifier, DevicePermissionsState>(
  (ref) => DevicePermissionsNotifier(),
);

// ── Notifier ─────────────────────────────────────────────

class DevicePermissionsNotifier
    extends StateNotifier<DevicePermissionsState> {
  DevicePermissionsNotifier()
      : super(DevicePermissionsState(features: DeviceFeature.defaults())) {
    _loadAllStatuses();
  }

  // ── Carga inicial ─────────────────────────────────────

  Future<void> _loadAllStatuses() async {
    state = state.withInitializing(true);

    await Future.wait([
      _syncPermission(DeviceFeatureType.camera, Permission.camera),
      _syncPermission(DeviceFeatureType.location, Permission.locationWhenInUse),
      _syncPermission(DeviceFeatureType.storage, Permission.storage),
      _syncWifi(),
    ]);

    state = state.withInitializing(false);
  }

  // ── Toggle público ────────────────────────────────────

  Future<void> toggle(DeviceFeatureType type) async {
    final feature = state.featureOf(type);

    // Evitar doble tap
    if (feature.isLoading) return;

    // Marcar como cargando
    state = state.copyWithFeature(feature.copyWith(isLoading: true));

    switch (type) {
      case DeviceFeatureType.camera:
        await _togglePermission(type, Permission.camera);
      case DeviceFeatureType.location:
        await _togglePermission(type, Permission.locationWhenInUse);
      case DeviceFeatureType.storage:
        await _togglePermission(type, Permission.storage);
      case DeviceFeatureType.wifi:
        await _toggleWifi();
    }
  }

  // ── Lógica de permisos ────────────────────────────────

  Future<void> _togglePermission(
    DeviceFeatureType type,
    Permission permission,
  ) async {
    final feature = state.featureOf(type);

    if (feature.isActive) {
      // No se puede revocar programáticamente → abrir configuración del sistema
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      await _syncPermission(type, permission);
      return;
    }

    if (feature.isPermanentlyDenied) {
      // Usuario negó permanentemente → solo se puede ir a configuración
      await AppSettings.openAppSettings(type: AppSettingsType.settings);
      await _syncPermission(type, permission);
      return;
    }

    // Solicitar permiso
    final status = await permission.request();
    _applyPermissionStatus(type, status);
  }

  Future<void> _syncPermission(
    DeviceFeatureType type,
    Permission permission,
  ) async {
    final status = await permission.status;
    _applyPermissionStatus(type, status);
  }

  void _applyPermissionStatus(DeviceFeatureType type, PermissionStatus status) {
    final feature = state.featureOf(type);
    state = state.copyWithFeature(
      feature.copyWith(
        isActive: status.isGranted || status.isLimited,
        isPermanentlyDenied: status.isPermanentlyDenied,
        isLoading: false,
      ),
    );
  }

  // ── Lógica WiFi ───────────────────────────────────────

  Future<void> _toggleWifi() async {
    // Android 10+ no permite toggle programático → abrir panel de WiFi
    await AppSettings.openAppSettings(type: AppSettingsType.wifi);
    await Future.delayed(const Duration(milliseconds: 500));
    await _syncWifi();
  }

  Future<void> _syncWifi() async {
    final result = await Connectivity().checkConnectivity();
    final isConnected = result.contains(ConnectivityResult.wifi);

    final feature = state.featureOf(DeviceFeatureType.wifi);
    state = state.copyWithFeature(
      feature.copyWith(isActive: isConnected, isLoading: false),
    );
  }

  // ── Refresh manual ────────────────────────────────────

  Future<void> refresh() => _loadAllStatuses();
}