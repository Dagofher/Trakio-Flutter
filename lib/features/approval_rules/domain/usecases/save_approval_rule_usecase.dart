import '../../../../core/result/result.dart';
import '../entities/approval_rule.dart';
import '../repositories/i_approval_rule_repository.dart';

class SaveApprovalRuleUseCase {
  final IApprovalRuleRepository _repository;
  const SaveApprovalRuleUseCase(this._repository);

  Future<Result<void>> call(ApprovalRule rule) => _repository.saveRule(rule);
}
