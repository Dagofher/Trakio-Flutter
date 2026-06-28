import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/company_entity.dart';
import '../../domain/entities/company_registration.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/user_profile_datasource.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDatasource _auth;
  final UserProfileDatasource _profiles;
  const AuthRepositoryImpl(this._auth, this._profiles);

  @override
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final base = await _auth.signIn(email: email, password: password);
      // Cargar el perfil con rol/empresa desde Firestore.
      final profile = await _profiles.getUserProfile(base.uid);
      return Success(profile ?? base);
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
    required CompanyRegistration company,
  }) async {
    try {
      final base = await _auth.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      // Resolver la empresa según el modo elegido. Si algo falla a partir de
      // aquí, borramos la cuenta de Auth recién creada para no dejar huérfanos.
      try {
        final UserEntity profile;
        switch (company) {
          case CreateCompany(:final name):
            final created = await _profiles.createCompany(
              name: name,
              ownerId: base.uid,
            );
            profile = base.copyWith(
              role: UserRole.admin,
              companyId: created.id,
            );
          case JoinByCode(:final inviteCode):
            final found = await _profiles.findCompanyByCode(inviteCode);
            if (found == null) {
              await _auth.deleteCurrentUser();
              return const Failure('Código de invitación inválido.');
            }
            profile = base.copyWith(
              role: UserRole.employee,
              companyId: found.id,
            );
        }

        await _profiles.createUserProfile(profile);
        return Success(profile);
      } catch (_) {
        await _auth.deleteCurrentUser();
        return const Failure('No se pudo completar el registro. Intenta de nuevo.');
      }
    } on FirebaseAuthException catch (e) {
      return Failure(_mapFirebaseError(e.code));
    } catch (_) {
      return const Failure('Error inesperado. Intenta de nuevo.');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo cerrar la sesión.');
    }
  }

  @override
  Future<Result<void>> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordReset(email: email);
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
      final base = _auth.getCurrentUser();
      if (base == null) return const Success(null);
      final profile = await _profiles.getUserProfile(base.uid);
      return Success(profile ?? base);
    } catch (_) {
      return const Failure('No se pudo obtener el usuario actual.');
    }
  }

  @override
  Future<Result<CompanyEntity?>> getCompany(String companyId) async {
    try {
      return Success(await _profiles.getCompany(companyId));
    } catch (_) {
      return const Failure('No se pudo obtener la empresa.');
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
