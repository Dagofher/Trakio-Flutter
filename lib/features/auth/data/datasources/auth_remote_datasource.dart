import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';

class AuthRemoteDatasource {
  final FirebaseAuth _auth;
  const AuthRemoteDatasource(this._auth);

  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _toEntity(credential.user!);
  }

  /// Crea la cuenta en Firebase Auth y devuelve la entidad base (sin rol aún).
  Future<UserEntity> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user!.updateDisplayName(displayName);
    return _toEntity(credential.user!).copyWith(displayName: displayName);
  }

  Future<void> signOut() => _auth.signOut();

  /// Inicia sesión con GitHub (flujo web vía Custom Tab / popup).
  Future<UserEntity> signInWithGithub() async {
    final provider = GithubAuthProvider()..addScope('read:user');
    final credential = await _auth.signInWithProvider(provider);
    return _toEntity(credential.user!);
  }

  /// Cambia la contraseña reautenticando primero con la actual.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  /// Actualiza el nombre visible en Firebase Auth.
  Future<void> updateDisplayName(String displayName) =>
      _auth.currentUser!.updateDisplayName(displayName);

  /// Borra la cuenta recién creada (rollback si el registro no se completa).
  Future<void> deleteCurrentUser() => _auth.currentUser?.delete() ?? Future.value();

  Future<void> sendPasswordReset({required String email}) =>
      _auth.sendPasswordResetEmail(email: email);

  UserEntity? getCurrentUser() {
    final user = _auth.currentUser;
    return user != null ? _toEntity(user) : null;
  }

  UserEntity _toEntity(User user) => UserEntity(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
}
