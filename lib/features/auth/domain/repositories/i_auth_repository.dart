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
}
