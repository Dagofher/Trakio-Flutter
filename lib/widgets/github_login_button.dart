import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import 'social_login_button.dart';

/// Botón "Continuar con GitHub" conectado al flujo real de autenticación.
class GithubLoginButton extends ConsumerWidget {
  const GithubLoginButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authProvider) is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.message),
          backgroundColor: AppColors.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
        ref.read(authProvider.notifier).clearError();
      }
    });

    if (isLoading) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
      );
    }

    return SocialLoginButton(
      label: 'Continuar con GitHub',
      icon: Icons.code_rounded,
      onPressed: () => ref.read(authProvider.notifier).signInWithGithub(),
    );
  }
}
