import '../../../../core/result/result.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../datasources/expense_remote_datasource.dart';

class ExpenseRepositoryImpl implements IExpenseRepository {
  final ExpenseRemoteDatasource _datasource;
  const ExpenseRepositoryImpl(this._datasource);

  @override
  Stream<List<ExpenseEntity>> watchMyExpenses(String userId) =>
      _datasource.watchMyExpenses(userId);

  @override
  Stream<List<ExpenseEntity>> watchExpensesByBudget(String budgetId) =>
      _datasource.watchExpensesByBudget(budgetId);

  @override
  Future<Result<void>> createExpense(
    ExpenseEntity expense, {
    String? photoPath,
  }) async {
    try {
      await _datasource.createExpense(expense, photoPath: photoPath);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo registrar el gasto. Intenta de nuevo.');
    }
  }

  @override
  Future<Result<void>> deleteExpense(String expenseId) async {
    try {
      await _datasource.deleteExpense(expenseId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar el gasto.');
    }
  }
}
