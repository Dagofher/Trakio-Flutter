import '../../../../core/result/result.dart';
import '../entities/expense_entity.dart';

abstract interface class IExpenseRepository {
  /// Gastos creados por un usuario (en tiempo real).
  Stream<List<ExpenseEntity>> watchMyExpenses(String userId);

  /// Gastos asociados a un presupuesto (para cálculo de consumo / aprobaciones).
  Stream<List<ExpenseEntity>> watchExpensesByBudget(String budgetId);

  /// Crea un gasto. Si [photoPath] no es null, sube la foto a Storage primero.
  Future<Result<void>> createExpense(
    ExpenseEntity expense, {
    String? photoPath,
  });

  Future<Result<void>> deleteExpense(String expenseId);
}
