import 'package:flutter/material.dart';
import '../desings/colors.dart';
import '../desings/device_feature.dart';

class DeviceToggleTile extends StatelessWidget {
  final DeviceFeature feature;
  final ValueChanged<bool> onToggle;

  const DeviceToggleTile({
    super.key,
    required this.feature,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: feature.isActive
              ? AppColors.accentColor.withOpacity(0.5)
              : AppColors.borderColor,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _FeatureIcon(feature: feature),
          const SizedBox(width: 14),
          Expanded(child: _FeatureInfo(feature: feature)),
          const SizedBox(width: 12),
          _FeatureToggle(feature: feature, onToggle: onToggle),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────

class _FeatureIcon extends StatelessWidget {
  final DeviceFeature feature;
  const _FeatureIcon({required this.feature});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: feature.isActive
            ? AppColors.accentColor.withOpacity(0.15)
            : AppColors.borderColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        feature.icon,
        size: 22,
        color: feature.isActive
            ? AppColors.accentColor
            : AppColors.textColor.withOpacity(0.4),
      ),
    );
  }
}

class _FeatureInfo extends StatelessWidget {
  final DeviceFeature feature;
  const _FeatureInfo({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          feature.isPermanentlyDenied
              ? 'Acceso denegado — ir a Configuración'
              : feature.description,
          style: TextStyle(
            color: feature.isPermanentlyDenied
                ? AppColors.errorColor
                : AppColors.textColor.withOpacity(0.6),
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final DeviceFeature feature;
  final ValueChanged<bool> onToggle;
  const _FeatureToggle({required this.feature, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (feature.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.accentColor,
        ),
      );
    }

    return Switch(
      value: feature.isActive,
      onChanged: onToggle,
      activeColor: AppColors.accentColor,
      activeTrackColor: AppColors.accentColor.withOpacity(0.25),
      inactiveThumbColor: AppColors.textColor.withOpacity(0.4),
      inactiveTrackColor: AppColors.borderColor,
    );
  }
}