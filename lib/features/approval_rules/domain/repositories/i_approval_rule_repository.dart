import '../../../../core/result/result.dart';
import '../entities/approval_rule.dart';

abstract interface class IApprovalRuleRepository {
  Stream<List<ApprovalRule>> watchRules(String companyId);

  Future<Result<void>> saveRule(ApprovalRule rule);

  Future<Result<void>> deleteRule(String ruleId);
}
