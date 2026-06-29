import '../../../../core/result/result.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';

class BudgetRepositoryImpl implements IBudgetRepository {
  final BudgetRemoteDatasource _datasource;
  const BudgetRepositoryImpl(this._datasource);

  @override
  Stream<List<BudgetEntity>> watchBudgets(String companyId) =>
      _datasource.watchBudgets(companyId);

  @override
  Future<Result<void>> createBudget(BudgetEntity budget) async {
    try {
      await _datasource.createBudget(budget);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo crear el presupuesto.');
    }
  }

  @override
  Future<Result<void>> updateBudget(BudgetEntity budget) async {
    try {
      await _datasource.updateBudget(budget);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo actualizar el presupuesto.');
    }
  }

  @override
  Future<Result<void>> deleteBudget(String budgetId) async {
    try {
      await _datasource.deleteBudget(budgetId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar el presupuesto.');
    }
  }

  @override
  Stream<List<PaymentEntity>> watchPayments(String budgetId) =>
      _datasource.watchPayments(budgetId);

  @override
  Future<Result<void>> addPayment(PaymentEntity payment) async {
    try {
      await _datasource.addPayment(payment);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo registrar el pago.');
    }
  }

  @override
  Future<Result<void>> deletePayment(String budgetId, String paymentId) async {
    try {
      await _datasource.deletePayment(budgetId, paymentId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar el pago.');
    }
  }
}
