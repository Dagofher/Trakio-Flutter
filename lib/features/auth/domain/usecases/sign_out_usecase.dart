import '../../../../core/result/result.dart';
import '../repositories/i_auth_repository.dart';

class SignOutUseCase {
  final IAuthRepository _repository;
  const SignOutUseCase(this._repository);

  Future<Result<void>> call() => _repository.signOut();
}
