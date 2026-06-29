import '../../../../core/result/result.dart';
import '../entities/budget_entity.dart';
import '../entities/payment_entity.dart';

abstract interface class IBudgetRepository {
  Stream<List<BudgetEntity>> watchBudgets(String companyId);

  Future<Result<void>> createBudget(BudgetEntity budget);

  Future<Result<void>> updateBudget(BudgetEntity budget);

  Future<Result<void>> deleteBudget(String budgetId);

  // ── Pagos (presupuestos de adquisición a plazos) ──────────

  Stream<List<PaymentEntity>> watchPayments(String budgetId);

  Future<Result<void>> addPayment(PaymentEntity payment);

  Future<Result<void>> deletePayment(String budgetId, String paymentId);
}
