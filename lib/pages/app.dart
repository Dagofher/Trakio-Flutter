import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../desings/themes.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import 'forgot_password_page.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'register_page.dart';

class TrakioApp extends ConsumerWidget {
  const TrakioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      theme: AppThemes.darkTheme,
      debugShowCheckedModeBanner: false,
      routes: {
        '/register': (_) => const RegisterPage(),
        '/forgot-password': (_) => const ForgotPasswordPage(),
      },
      home: switch (authState) {
        AuthAuthenticated() => const HomePage(),
        // Solo el arranque (restauración de sesión) muestra splash.
        // AuthLoading/AuthError mantienen LoginPage montada para no
        // desmontar las páginas que escuchan errores con ref.listen.
        AuthInitial() => const _SplashScreen(),
        _ => const LoginPage(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF030120),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
        ),
      ),
    );
  }
}
