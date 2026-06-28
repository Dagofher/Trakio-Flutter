import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDatasource _datasource;
  const AuthRepositoryImpl(this._datasource);

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _datasource.signIn(email: email, password: password);
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (_) {
      return const Failure('Error inesperado. Intenta de nuevo.');
    }
  }

  @override
  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final user = await _datasource.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      return Success(user);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (_) {
      return const Failure('Error inesperado. Intenta de nuevo.');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo cerrar la sesión.');
    }
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    try {
      await _datasource.sendPasswordReset(email: email);
      return const Success(null);
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (_) {
      return const Failure('Error inesperado. Intenta de nuevo.');
    }
  }

  @override
  Future<Result<UserEntity?>> getCurrentUser() async {
    try {
      return Success(_datasource.getCurrentUser());
    } catch (_) {
      return const Failure('No se pudo obtener el usuario actual.');
    }
  }

  String _mapFirebaseError(String code) => switch (code) {
        'user-not-found' => 'No existe una cuenta con ese correo.',
        'wrong-password' => 'Contraseña incorrecta.',
        'invalid-credential' => 'Credenciales incorrectas.',
        'email-already-in-use' => 'Este correo ya está registrado.',
        'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
        'invalid-email' => 'El correo ingresado no es válido.',
        'too-many-requests' => 'Demasiados intentos. Intenta más tarde.',
        'network-request-failed' => 'Sin conexión. Verifica tu internet.',
        _ => 'Error de autenticación. Intenta de nuevo.',
      };
}
