import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/user_profile_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/company_registration.dart';
import '../../domain/repositories/i_auth_repository.dart';
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
