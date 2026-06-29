import '../../domain/entities/user_entity.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

class AuthPasswordResetSent extends AuthState {
  const AuthPasswordResetSent();
}

class AuthRegistrationSuccess extends AuthState {
  const AuthRegistrationSuccess();
}

/// Usuario autenticado vía proveedor social pero sin empresa: requiere onboarding.
class AuthNeedsOnboarding extends AuthState {
  final UserEntity user;
  const AuthNeedsOnboarding(this.user);
}
