import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/crud_action_state.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/datasources/approval_rule_remote_datasource.dart';
import '../../data/repositories/approval_rule_repository_impl.dart';
import '../../domain/entities/approval_rule.dart';
import '../../domain/repositories/i_approval_rule_repository.dart';
import '../../domain/services/approval_rule_engine.dart';
import '../../domain/usecases/delete_approval_rule_usecase.dart';
import '../../domain/usecases/save_approval_rule_usecase.dart';
import '../../domain/usecases/watch_approval_rules_usecase.dart';

// ── Infraestructura ───────────────────────────────────────

final _ruleDatasourceProvider = Provider<ApprovalRuleRemoteDatasource>(
  (ref) => ApprovalRuleRemoteDatasource(FirebaseFirestore.instance),
);

final _ruleRepositoryProvider = Provider<IApprovalRuleRepository>(
  (ref) => ApprovalRuleRepositoryImpl(ref.read(_ruleDatasourceProvider)),
);

final approvalRuleEngineProvider =
    Provider<ApprovalRuleEngine>((ref) => const ApprovalRuleEngine());

// ── Lista en tiempo real ──────────────────────────────────

final approvalRulesStreamProvider =
    StreamProvider<List<ApprovalRule>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return WatchApprovalRulesUseCase(ref.read(_ruleRepositoryProvider))
      .call(companyId);
});

// ── Acciones ──────────────────────────────────────────────

final approvalRuleActionProvider =
    StateNotifierProvider<ApprovalRuleActionNotifier, CrudActionState>(
  (ref) => ApprovalRuleActionNotifier(
    save: SaveApprovalRuleUseCase(ref.read(_ruleRepositoryProvider)),
    delete: DeleteApprovalRuleUseCase(ref.read(_ruleRepositoryProvider)),
  ),
);

class ApprovalRuleActionNotifier extends StateNotifier<CrudActionState> {
  final SaveApprovalRuleUseCase _save;
  final DeleteApprovalRuleUseCase _delete;

  ApprovalRuleActionNotifier({
    required SaveApprovalRuleUseCase save,
    required DeleteApprovalRuleUseCase delete,
  })  : _save = save,
        _delete = delete,
        super(const CrudIdle());

  Future<void> save(ApprovalRule rule) async {
    state = const CrudLoading();
    final result = await _save(rule);
    state = switch (result) {
      Success() =>
        CrudSuccess(rule.id.isEmpty ? 'Regla creada' : 'Regla actualizada'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> delete(String ruleId) async {
    state = const CrudLoading();
    final result = await _delete(ruleId);
    state = switch (result) {
      Success() => const CrudSuccess('Regla eliminada'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  void reset() => state = const CrudIdle();
}
