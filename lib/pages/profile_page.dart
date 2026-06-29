import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/crud_action_state.dart';
import '../desings/colors.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../widgets/change_password_sheet.dart';
import '../widgets/edit_name_dialog.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth is AuthAuthenticated ? auth.user : null;

    ref.listen<CrudActionState>(accountActionProvider, (_, next) {
      final messenger = ScaffoldMessenger.of(context);
      if (next is CrudSuccess) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.accentColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(accountActionProvider.notifier).reset();
      } else if (next is CrudError) {
        messenger.showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(accountActionProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 8),
                _Avatar(name: user.displayName),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user.displayName.isEmpty ? 'Sin nombre' : user.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    user.email,
                    style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: _RoleChip(role: user.role)),
                const SizedBox(height: 28),
                _SectionLabel('Cuenta'),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.person_outline_rounded,
                  title: 'Editar nombre',
                  onTap: () => showEditNameDialog(context, ref,
                      currentName: user.displayName),
                ),
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Cambiar contraseña',
                  onTap: () => showChangePasswordSheet(context),
                ),
                const SizedBox(height: 24),
                _SectionLabel('Apariencia'),
                const SizedBox(height: 10),
                _ActionTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema (claro/oscuro)',
                  trailing: Text(
                    'Próximamente',
                    style: TextStyle(
                        color: AppColors.textColor.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                  onTap: null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(authProvider.notifier).signOut(),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Cerrar sesión'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                      side: BorderSide(
                          color: AppColors.errorColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Center(
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: AppColors.accentColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.accentColor.withValues(alpha: 0.4), width: 2),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.accentColor,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
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
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.textColor.withValues(alpha: 0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.accentColor, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                trailing ??
                    Icon(Icons.chevron_right_rounded,
                        color: AppColors.textColor.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
