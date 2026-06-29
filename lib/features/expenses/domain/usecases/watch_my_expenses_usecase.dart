import '../entities/expense_entity.dart';
import '../repositories/i_expense_repository.dart';

class WatchMyExpensesUseCase {
  final IExpenseRepository _repository;
  const WatchMyExpensesUseCase(this._repository);

  Stream<List<ExpenseEntity>> call(String userId) =>
      _repository.watchMyExpenses(userId);
}
