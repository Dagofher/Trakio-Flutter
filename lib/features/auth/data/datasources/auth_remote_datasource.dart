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

extension _UserEntityCopyWith on UserEntity {
  UserEntity copyWith({String? displayName}) => UserEntity(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role,
        companyId: companyId,
        departmentId: departmentId,
      );
}
