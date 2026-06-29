import '../../../../core/result/result.dart';
import '../repositories/i_expense_repository.dart';

class DeleteExpenseUseCase {
  final IExpenseRepository _repository;
  const DeleteExpenseUseCase(this._repository);

  Future<Result<void>> call(String expenseId) =>
      _repository.deleteExpense(expenseId);
}
