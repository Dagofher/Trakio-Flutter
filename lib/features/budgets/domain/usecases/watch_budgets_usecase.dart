import '../entities/budget_entity.dart';
import '../repositories/i_budget_repository.dart';

class WatchBudgetsUseCase {
  final IBudgetRepository _repository;
  const WatchBudgetsUseCase(this._repository);

  Stream<List<BudgetEntity>> call(String companyId) =>
      _repository.watchBudgets(companyId);
}
