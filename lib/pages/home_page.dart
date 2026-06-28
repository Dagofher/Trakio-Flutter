import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../desings/colors.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import 'device_settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trakio 🤖'),
        actions: [
          if (user != null && user.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_rounded, size: 24),
              tooltip: 'Panel de administración',
              onPressed: () => context.push('/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.settings, size: 24),
            tooltip: 'Permisos del dispositivo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeviceSettingsPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: 24),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              user == null ? '¡Hola, Trakio!' : '¡Hola, ${user.displayName}!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            if (user != null) ...[
              const SizedBox(height: 12),
              _RoleChip(role: user.role),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final UserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      UserRole.admin => 'Administrador',
      UserRole.supervisor => 'Supervisor',
      UserRole.employee => 'Empleado',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
