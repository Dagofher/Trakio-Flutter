import '../../../../core/result/result.dart';
import '../entities/expense_entity.dart';
import '../repositories/i_expense_repository.dart';

class CreateExpenseUseCase {
  final IExpenseRepository _repository;
  const CreateExpenseUseCase(this._repository);

  Future<Result<void>> call(ExpenseEntity expense, {String? photoPath}) =>
      _repository.createExpense(expense, photoPath: photoPath);
}
