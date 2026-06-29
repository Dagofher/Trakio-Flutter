import '../entities/payment_entity.dart';
import '../repositories/i_budget_repository.dart';

class WatchPaymentsUseCase {
  final IBudgetRepository _repository;
  const WatchPaymentsUseCase(this._repository);

  Stream<List<PaymentEntity>> call(String budgetId) =>
      _repository.watchPayments(budgetId);
}
