import '../../../../core/result/result.dart';
import '../entities/budget_entity.dart';
import '../repositories/i_budget_repository.dart';

/// Crea un presupuesto (id vacío) o actualiza uno existente.
class SaveBudgetUseCase {
  final IBudgetRepository _repository;
  const SaveBudgetUseCase(this._repository);

  Future<Result<void>> call(BudgetEntity budget) {
    return budget.id.isEmpty
        ? _repository.createBudget(budget)
        : _repository.updateBudget(budget);
  }
}
