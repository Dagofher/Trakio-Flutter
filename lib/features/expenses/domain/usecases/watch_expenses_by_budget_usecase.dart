import '../entities/expense_entity.dart';
import '../repositories/i_expense_repository.dart';

class WatchExpensesByBudgetUseCase {
  final IExpenseRepository _repository;
  const WatchExpensesByBudgetUseCase(this._repository);

  Stream<List<ExpenseEntity>> call(String budgetId) =>
      _repository.watchExpensesByBudget(budgetId);
}
