import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../pages/admin_panel_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';
import '../pages/splash_page.dart';

/// Rutas accesibles sin estar autenticado.
const _authRoutes = {'/login', '/register', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  // Puente entre Riverpod y go_router: notifica al router cuando cambia auth.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/admin', builder: (context, state) => const AdminPanelPage()),
    ],
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isSplash = loc == '/splash';

      // Mientras se restaura la sesión, quedarse en el splash.
      if (auth is AuthInitial) {
        return isSplash ? null : '/splash';
      }

      final isAuthed = auth is AuthAuthenticated;

      // Sesión ya resuelta: salir del splash.
      if (isSplash) return isAuthed ? '/home' : '/login';

      if (!isAuthed) {
        // No autenticado: solo se permiten las rutas de auth.
        return _authRoutes.contains(loc) ? null : '/login';
      }

      // Autenticado: no debe quedarse en pantallas de auth.
      if (_authRoutes.contains(loc)) return '/home';

      // Guard por rol: /admin es solo para administradores.
      if (loc == '/admin' && auth.user.role != UserRole.admin) {
        return '/home';
      }

      return null;
    },
  );
});
