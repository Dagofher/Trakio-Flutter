import '../../../../core/result/result.dart';
import '../entities/company_entity.dart';
import '../entities/company_registration.dart';
import '../entities/user_entity.dart';

abstract interface class IAuthRepository {
  Future<Result<UserEntity>> signIn({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> signUp({
    required String email,
    required String password,
    required String displayName,
    required CompanyRegistration company,
  });

  Future<Result<void>> signOut();

  Future<Result<void>> sendPasswordReset({required String email});

  Future<Result<UserEntity?>> getCurrentUser();

  Future<Result<CompanyEntity?>> getCompany(String companyId);

  /// Inicia sesión con GitHub. Devuelve el perfil si ya existe en Firestore,
  /// o un UserEntity SIN companyId (necesita onboarding) si es la primera vez.
  Future<Result<UserEntity>> signInWithGithub();

  /// Completa el onboarding de un usuario social: lo asocia a una empresa.
  Future<Result<UserEntity>> completeOnboarding({
    required UserEntity baseUser,
    required CompanyRegistration company,
  });

  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Actualiza el nombre visible (Auth + perfil Firestore).
  Future<Result<UserEntity>> updateDisplayName({
    required UserEntity current,
    required String displayName,
  });
}
