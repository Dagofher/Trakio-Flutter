import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/domain/entities/user_entity.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../pages/admin_panel_page.dart';
import '../pages/approval_rules_page.dart';
import '../pages/approvals_page.dart';
import '../pages/budgets_page.dart';
import '../pages/categories_page.dart';
import '../pages/departments_page.dart';
import '../pages/expense_form_page.dart';
import '../pages/expenses_page.dart';
import '../pages/quick_expense_page.dart';
import '../pages/forgot_password_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/notifications_page.dart';
import '../pages/onboarding_page.dart';
import '../pages/profile_page.dart';
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
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/departments',
        builder: (context, state) => const DepartmentsPage(),
      ),
      GoRoute(
        path: '/budgets',
        builder: (context, state) => const BudgetsPage(),
      ),
      GoRoute(
        path: '/expenses',
        builder: (context, state) => const ExpensesPage(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const ExpenseFormPage(),
          ),
          GoRoute(
            path: 'quick',
            builder: (context, state) => const QuickExpensePage(),
          ),
        ],
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/approvals',
        builder: (context, state) => const ApprovalsPage(),
      ),
      GoRoute(
        path: '/approval-rules',
        builder: (context, state) => const ApprovalRulesPage(),
      ),
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

      // Login social sin empresa: forzar el onboarding.
      if (auth is AuthNeedsOnboarding) {
        return loc == '/onboarding' ? null : '/onboarding';
      }

      final isAuthed = auth is AuthAuthenticated;

      // Sesión ya resuelta: salir del splash.
      if (isSplash) return isAuthed ? '/home' : '/login';

      // Nadie más debe quedarse en onboarding.
      if (loc == '/onboarding') return isAuthed ? '/home' : '/login';

      if (!isAuthed) {
        // No autenticado: solo se permiten las rutas de auth.
        return _authRoutes.contains(loc) ? null : '/login';
      }

      // Autenticado: no debe quedarse en pantallas de auth.
      if (_authRoutes.contains(loc)) return '/home';

      // Guard por rol: /admin y /approval-rules solo para administradores.
      const adminOnly = {'/admin', '/approval-rules'};
      if (adminOnly.contains(loc) && auth.user.role != UserRole.admin) {
        return '/home';
      }

      // /approvals: admin o supervisor.
      if (loc == '/approvals' &&
          !(auth.user.isAdmin || auth.user.isSupervisor)) {
        return '/home';
      }

      return null;
    },
  );
});
