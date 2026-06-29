import '../../../../core/result/result.dart';
import '../../domain/entities/approval_rule.dart';
import '../../domain/repositories/i_approval_rule_repository.dart';
import '../datasources/approval_rule_remote_datasource.dart';

class ApprovalRuleRepositoryImpl implements IApprovalRuleRepository {
  final ApprovalRuleRemoteDatasource _datasource;
  const ApprovalRuleRepositoryImpl(this._datasource);

  @override
  Stream<List<ApprovalRule>> watchRules(String companyId) =>
      _datasource.watchRules(companyId);

  @override
  Future<Result<void>> saveRule(ApprovalRule rule) async {
    try {
      await _datasource.saveRule(rule);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo guardar la regla.');
    }
  }

  @override
  Future<Result<void>> deleteRule(String ruleId) async {
    try {
      await _datasource.deleteRule(ruleId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar la regla.');
    }
  }
}
