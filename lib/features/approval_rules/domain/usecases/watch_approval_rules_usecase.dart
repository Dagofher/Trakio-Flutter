import '../entities/approval_rule.dart';
import '../repositories/i_approval_rule_repository.dart';

class WatchApprovalRulesUseCase {
  final IApprovalRuleRepository _repository;
  const WatchApprovalRulesUseCase(this._repository);

  Stream<List<ApprovalRule>> call(String companyId) =>
      _repository.watchRules(companyId);
}
