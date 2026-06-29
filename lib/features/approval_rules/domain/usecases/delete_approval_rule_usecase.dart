import '../../../../core/result/result.dart';
import '../repositories/i_approval_rule_repository.dart';

class DeleteApprovalRuleUseCase {
  final IApprovalRuleRepository _repository;
  const DeleteApprovalRuleUseCase(this._repository);

  Future<Result<void>> call(String ruleId) => _repository.deleteRule(ruleId);
}
