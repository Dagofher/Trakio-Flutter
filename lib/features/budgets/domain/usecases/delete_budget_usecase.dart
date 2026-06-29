import '../../../../core/result/result.dart';
import '../repositories/i_budget_repository.dart';

class DeleteBudgetUseCase {
  final IBudgetRepository _repository;
  const DeleteBudgetUseCase(this._repository);

  Future<Result<void>> call(String budgetId) =>
      _repository.deleteBudget(budgetId);
}
