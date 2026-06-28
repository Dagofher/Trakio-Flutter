import '../../../../core/result/result.dart';
import '../repositories/i_auth_repository.dart';

class SendPasswordResetUseCase {
  final IAuthRepository _repository;
  const SendPasswordResetUseCase(this._repository);

  Future<Result<void>> call({required String email}) =>
      _repository.sendPasswordReset(email: email);
}
