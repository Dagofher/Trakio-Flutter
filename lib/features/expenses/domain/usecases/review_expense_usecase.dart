import '../../../../core/result/result.dart';
import '../entities/expense_entity.dart';
import '../repositories/i_expense_repository.dart';

class ReviewExpenseUseCase {
  final IExpenseRepository _repository;
  const ReviewExpenseUseCase(this._repository);

  Future<Result<void>> call({
    required String expenseId,
    required ExpenseStatus status,
    required String reviewedBy,
    String? comment,
  }) =>
      _repository.reviewExpense(
        expenseId: expenseId,
        status: status,
        reviewedBy: reviewedBy,
        comment: comment,
      );
}
