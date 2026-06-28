import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';

class AdminPanelPage extends ConsumerWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    final name = state is AuthAuthenticated ? state.user.displayName : '';
    final companyAsync = ref.watch(companyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.admin_panel_settings_rounded,
                size: 64, color: AppColors.accentColor),
            const SizedBox(height: 16),
            Text(
              'Bienvenido, $name',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            companyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.accentColor),
              ),
              error: (err, stack) => const Text(
                'No se pudo cargar la empresa.',
                style: TextStyle(color: AppColors.errorColor),
              ),
              data: (company) {
                if (company == null) return const SizedBox.shrink();
                return _InviteCodeCard(
                  companyName: company.name,
                  inviteCode: company.inviteCode,
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Comparte este código con tu equipo para que se una a la empresa.\n'
              'Aquí gestionarás usuarios, presupuestos y reglas (próximas fases).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String companyName;
  final String inviteCode;

  const _InviteCodeCard({required this.companyName, required this.inviteCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            companyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Código de invitación',
            style: TextStyle(
              color: AppColors.textColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SelectableText(
                inviteCode,
                style: const TextStyle(
                  color: AppColors.accentColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 20, color: AppColors.accentColor),
                tooltip: 'Copiar código',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteCode));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado'),
                      backgroundColor: AppColors.accentColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
