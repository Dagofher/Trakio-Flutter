import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/crud_action_state.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/datasources/budget_remote_datasource.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../../domain/usecases/add_payment_usecase.dart';
import '../../domain/usecases/delete_budget_usecase.dart';
import '../../domain/usecases/delete_payment_usecase.dart';
import '../../domain/usecases/save_budget_usecase.dart';
import '../../domain/usecases/watch_budgets_usecase.dart';
import '../../domain/usecases/watch_payments_usecase.dart';

// ── Infraestructura ───────────────────────────────────────

final _budgetDatasourceProvider = Provider<BudgetRemoteDatasource>(
  (ref) => BudgetRemoteDatasource(FirebaseFirestore.instance),
);

final _budgetRepositoryProvider = Provider<IBudgetRepository>(
  (ref) => BudgetRepositoryImpl(ref.read(_budgetDatasourceProvider)),
);

// ── Lista en tiempo real ──────────────────────────────────

final budgetsStreamProvider = StreamProvider<List<BudgetEntity>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return WatchBudgetsUseCase(ref.read(_budgetRepositoryProvider))
      .call(companyId);
});

/// Pagos de un presupuesto de adquisición (en tiempo real, recientes primero).
final budgetPaymentsStreamProvider =
    StreamProvider.family<List<PaymentEntity>, String>((ref, budgetId) {
  return WatchPaymentsUseCase(ref.read(_budgetRepositoryProvider))
      .call(budgetId);
});

/// Total pagado de un presupuesto de adquisición (suma del historial).
final budgetPaidProvider =
    Provider.family<double, String>((ref, budgetId) {
  final payments = ref.watch(budgetPaymentsStreamProvider(budgetId)).valueOrNull;
  if (payments == null) return 0;
  return payments.fold<double>(0, (acc, p) => acc + p.amount);
});

/// Monto consumido de un presupuesto operativo.
///
/// Por ahora devuelve 0: el cálculo real se conectará en la Fase 5 (Gastos),
/// sumando los gastos aprobados que apunten a este presupuesto. Aislarlo aquí
/// permite cambiar solo esta línea sin tocar la UI.
final budgetConsumedProvider =
    Provider.family<double, BudgetEntity>((ref, budget) {
  // TODO(fase5): sumar gastos aprobados del presupuesto `budget.id`.
  return 0;
});

// ── Acciones ──────────────────────────────────────────────

final budgetActionProvider =
    StateNotifierProvider<BudgetActionNotifier, CrudActionState>(
  (ref) => BudgetActionNotifier(
    save: SaveBudgetUseCase(ref.read(_budgetRepositoryProvider)),
    delete: DeleteBudgetUseCase(ref.read(_budgetRepositoryProvider)),
  ),
);

class BudgetActionNotifier extends StateNotifier<CrudActionState> {
  final SaveBudgetUseCase _save;
  final DeleteBudgetUseCase _delete;

  BudgetActionNotifier({
    required SaveBudgetUseCase save,
    required DeleteBudgetUseCase delete,
  })  : _save = save,
        _delete = delete,
        super(const CrudIdle());

  Future<void> save(BudgetEntity budget) async {
    state = const CrudLoading();
    final result = await _save(budget);
    state = switch (result) {
      Success() => CrudSuccess(
          budget.id.isEmpty ? 'Presupuesto creado' : 'Presupuesto actualizado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> delete(String budgetId) async {
    state = const CrudLoading();
    final result = await _delete(budgetId);
    state = switch (result) {
      Success() => const CrudSuccess('Presupuesto eliminado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  void reset() => state = const CrudIdle();
}

// ── Acciones de pagos ─────────────────────────────────────

final paymentActionProvider =
    StateNotifierProvider<PaymentActionNotifier, CrudActionState>(
  (ref) => PaymentActionNotifier(
    add: AddPaymentUseCase(ref.read(_budgetRepositoryProvider)),
    delete: DeletePaymentUseCase(ref.read(_budgetRepositoryProvider)),
  ),
);

class PaymentActionNotifier extends StateNotifier<CrudActionState> {
  final AddPaymentUseCase _add;
  final DeletePaymentUseCase _delete;

  PaymentActionNotifier({
    required AddPaymentUseCase add,
    required DeletePaymentUseCase delete,
  })  : _add = add,
        _delete = delete,
        super(const CrudIdle());

  Future<void> add(PaymentEntity payment) async {
    state = const CrudLoading();
    final result = await _add(payment);
    state = switch (result) {
      Success() => const CrudSuccess('Pago registrado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> delete(String budgetId, String paymentId) async {
    state = const CrudLoading();
    final result = await _delete(budgetId, paymentId);
    state = switch (result) {
      Success() => const CrudSuccess('Pago eliminado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  void reset() => state = const CrudIdle();
}
