import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/user_profile_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/company_registration.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../../../core/presentation/crud_action_state.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../../../core/result/result.dart';
import 'auth_state.dart';

// ── Providers de infraestructura ──────────────────────────

final _authDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(FirebaseAuth.instance),
);

final _profileDatasourceProvider = Provider<UserProfileDatasource>(
  (ref) => UserProfileDatasource(FirebaseFirestore.instance),
);

final _authRepositoryProvider = Provider<IAuthRepository>(
  (ref) => AuthRepositoryImpl(
    ref.read(_authDatasourceProvider),
    ref.read(_profileDatasourceProvider),
  ),
);

// ── Provider público ──────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    signIn: SignInUseCase(ref.read(_authRepositoryProvider)),
    signUp: SignUpUseCase(ref.read(_authRepositoryProvider)),
    signOut: SignOutUseCase(ref.read(_authRepositoryProvider)),
    passwordReset: SendPasswordResetUseCase(ref.read(_authRepositoryProvider)),
    repository: ref.read(_authRepositoryProvider),
  ),
);

/// companyId del usuario autenticado (o null si no hay sesión).
final companyIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user.companyId : null;
});

/// Empresa del usuario autenticado (para mostrar el código de invitación, etc.).
final companyProvider = FutureProvider<CompanyEntity?>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated || auth.user.companyId == null) return null;
  final result =
      await ref.read(_authRepositoryProvider).getCompany(auth.user.companyId!);
  return switch (result) {
    Success(value: final company) => company,
    Failure() => null,
  };
});

// ── Notifier ──────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final SignInUseCase _signIn;
  final SignUpUseCase _signUp;
  final SignOutUseCase _signOut;
  final SendPasswordResetUseCase _passwordReset;
  final IAuthRepository _repository;

  AuthNotifier({
    required SignInUseCase signIn,
    required SignUpUseCase signUp,
    required SignOutUseCase signOut,
    required SendPasswordResetUseCase passwordReset,
    required IAuthRepository repository,
  })  : _signIn = signIn,
        _signUp = signUp,
        _signOut = signOut,
        _passwordReset = passwordReset,
        _repository = repository,
        super(const AuthInitial()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final result = await _repository.getCurrentUser();
    switch (result) {
      case Success(value: final user):
        state = user != null
            ? AuthAuthenticated(user)
            : const AuthUnauthenticated();
      case Failure():
        state = const AuthUnauthenticated();
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AuthLoading();
    final result = await _signIn(email: email, password: password);
    switch (result) {
      case Success(value: final user):
        state = AuthAuthenticated(user);
      case Failure(message: final msg):
        state = AuthError(msg);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required CompanyRegistration company,
  }) async {
    state = const AuthLoading();
    final result = await _signUp(
      email: email,
      password: password,
      displayName: displayName,
      company: company,
    );
    switch (result) {
      case Success():
        // Firebase deja la sesión iniciada al crear la cuenta; la cerramos
        // para que el usuario entre manualmente desde el login.
        await _signOut();
        state = const AuthRegistrationSuccess();
      case Failure(message: final msg):
        state = AuthError(msg);
    }
  }

  Future<void> signInWithGithub() async {
    state = const AuthLoading();
    final result = await _repository.signInWithGithub();
    switch (result) {
      case Success(value: final user):
        // Sin empresa → necesita onboarding; con empresa → autenticado.
        state = user.companyId == null
            ? AuthNeedsOnboarding(user)
            : AuthAuthenticated(user);
      case Failure(message: final msg):
        state = AuthError(msg);
    }
  }

  /// Marca al usuario como autenticado (usado tras onboarding o editar perfil).
  void markAuthenticated(UserEntity user) {
    state = AuthAuthenticated(user);
  }

  /// Usuario actualmente autenticado, si lo hay.
  UserEntity? get currentUser {
    final s = state;
    return s is AuthAuthenticated ? s.user : null;
  }

  Future<void> signOut() async {
    await _signOut();
    state = const AuthUnauthenticated();
  }

  Future<void> sendPasswordReset({required String email}) async {
    state = const AuthLoading();
    final result = await _passwordReset(email: email);
    switch (result) {
      case Success():
        state = const AuthPasswordResetSent();
      case Failure(message: final msg):
        state = AuthError(msg);
    }
  }

  void clearError() {
    if (state is AuthError) state = const AuthUnauthenticated();
  }
}

// ── Acciones de cuenta (onboarding, contraseña, nombre) ───

final accountActionProvider =
    StateNotifierProvider<AccountActionNotifier, CrudActionState>(
  (ref) => AccountActionNotifier(
    repository: ref.read(_authRepositoryProvider),
    auth: ref.read(authProvider.notifier),
  ),
);

class AccountActionNotifier extends StateNotifier<CrudActionState> {
  final IAuthRepository _repository;
  final AuthNotifier _auth;

  AccountActionNotifier({
    required IAuthRepository repository,
    required AuthNotifier auth,
  })  : _repository = repository,
        _auth = auth,
        super(const CrudIdle());

  Future<void> completeOnboarding({
    required UserEntity baseUser,
    required CompanyRegistration company,
  }) async {
    state = const CrudLoading();
    final result = await _repository.completeOnboarding(
      baseUser: baseUser,
      company: company,
    );
    switch (result) {
      case Success(value: final user):
        _auth.markAuthenticated(user);
        state = const CrudSuccess('Bienvenido a Trakio');
      case Failure(message: final msg):
        state = CrudError(msg);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const CrudLoading();
    final result = await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    state = switch (result) {
      Success() => const CrudSuccess('Contraseña actualizada'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> updateDisplayName(String displayName) async {
    final current = _auth.currentUser;
    if (current == null) return;
    state = const CrudLoading();
    final result = await _repository.updateDisplayName(
      current: current,
      displayName: displayName,
    );
    switch (result) {
      case Success(value: final user):
        _auth.markAuthenticated(user);
        state = const CrudSuccess('Nombre actualizado');
      case Failure(message: final msg):
        state = CrudError(msg);
    }
  }

  void reset() => state = const CrudIdle();
}
