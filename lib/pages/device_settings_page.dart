import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desings/colors.dart';
import '../desings/device_feature.dart';
import '../providers/device_permissions_notifier.dart';
import '../widgets/device_toggle_tile.dart';

class DeviceSettingsPage extends ConsumerWidget {
  const DeviceSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(devicePermissionsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.appBarColor,
        title: const Text(
          'Permisos del dispositivo',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: const BackButton(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textColor),
            onPressed: () =>
                ref.read(devicePermissionsProvider.notifier).refresh(),
            tooltip: 'Actualizar estados',
          ),
        ],
      ),
      body: state.isInitializing
          ? const _LoadingView()
          : _PermissionsBody(features: state.features),
    );
  }
}

// ── Body ──────────────────────────────────────────────────

class _PermissionsBody extends ConsumerWidget {
  final List<DeviceFeature> features;
  const _PermissionsBody({required this.features});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        const _SectionHeader(),
        const SizedBox(height: 20),
        ...features.map(
          (feature) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DeviceToggleTile(
              feature: feature,
              onToggle: (_) => ref
                  .read(devicePermissionsProvider.notifier)
                  .toggle(feature.type),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _InfoNote(),
      ],
    );
  }
}

// ── Componentes de apoyo ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accesos del sistema',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Activa los permisos necesarios para que Trakio '
          'funcione correctamente en campo.',
          style: TextStyle(
            color: AppColors.textColor.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.accentColor.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Para revocar un permiso ya concedido, '
              'Trakio abrirá la Configuración del sistema. '
              'Es un requisito de seguridad de Android e iOS.',
              style: TextStyle(
                color: AppColors.textColor.withValues(alpha: 0.6),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accentColor),
    );
  }
}