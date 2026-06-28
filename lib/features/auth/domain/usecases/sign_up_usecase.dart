import '../../../../core/result/result.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class SignUpUseCase {
  final IAuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _repository.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
}
