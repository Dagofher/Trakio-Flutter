import '../../../../core/result/result.dart';
import '../entities/user_entity.dart';
import '../repositories/i_auth_repository.dart';

class SignInUseCase {
  final IAuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<Result<UserEntity>> call({
    required String email,
    required String password,
  }) =>
      _repository.signIn(email: email, password: password);
}
