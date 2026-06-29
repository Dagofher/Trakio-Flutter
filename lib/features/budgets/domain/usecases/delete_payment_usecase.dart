import '../../../../core/result/result.dart';
import '../repositories/i_budget_repository.dart';

class DeletePaymentUseCase {
  final IBudgetRepository _repository;
  const DeletePaymentUseCase(this._repository);

  Future<Result<void>> call(String budgetId, String paymentId) =>
      _repository.deletePayment(budgetId, paymentId);
}
