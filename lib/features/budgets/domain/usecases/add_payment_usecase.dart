import '../../../../core/result/result.dart';
import '../entities/payment_entity.dart';
import '../repositories/i_budget_repository.dart';

class AddPaymentUseCase {
  final IBudgetRepository _repository;
  const AddPaymentUseCase(this._repository);

  Future<Result<void>> call(PaymentEntity payment) =>
      _repository.addPayment(payment);
}
