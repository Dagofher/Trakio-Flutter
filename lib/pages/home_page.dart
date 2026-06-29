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
    final canManage = user?.isAdmin ?? false;

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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Column(
              children: [
                Text(
                  user == null
                      ? '¡Hola, Trakio!'
                      : '¡Hola, ${user.displayName}!',
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                if (user != null) ...[
                  const SizedBox(height: 12),
                  _RoleChip(role: user.role),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          _NavCard(
            icon: Icons.document_scanner_rounded,
            title: 'Gasto rápido',
            subtitle: 'Escanea una factura con la cámara',
            onTap: () => context.push('/expenses/quick'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.receipt_long_rounded,
            title: 'Mis gastos',
            subtitle: 'Registra y consulta tus gastos',
            onTap: () => context.push('/expenses'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.account_balance_wallet_rounded,
            title: canManage ? 'Presupuestos' : 'Mi presupuesto disponible',
            subtitle: 'Consulta y gestiona presupuestos',
            onTap: () => context.push('/budgets'),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.category_rounded,
            title: 'Categorías',
            subtitle: 'Gestiona las categorías de gasto',
            onTap: () => context.push('/categories'),
          ),
          if (canManage) ...[
            const SizedBox(height: 12),
            _NavCard(
              icon: Icons.apartment_rounded,
              title: 'Departamentos',
              subtitle: 'Organiza tu empresa por áreas',
              onTap: () => context.push('/departments'),
            ),
          ],
        ],
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

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
