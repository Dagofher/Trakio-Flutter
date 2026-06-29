import '../entities/expense_entity.dart';
import '../repositories/i_expense_repository.dart';

class WatchCompanyExpensesUseCase {
  final IExpenseRepository _repository;
  const WatchCompanyExpensesUseCase(this._repository);

  Stream<List<ExpenseEntity>> call(String companyId) =>
      _repository.watchCompanyExpenses(companyId);
}
