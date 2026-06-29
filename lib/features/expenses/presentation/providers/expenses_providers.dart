import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/crud_action_state.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/datasources/expense_remote_datasource.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../data/services/receipt_image_service.dart';
import '../../data/services/receipt_ocr_service.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/watch_expenses_by_budget_usecase.dart';
import '../../domain/usecases/watch_my_expenses_usecase.dart';

// ── Infraestructura ───────────────────────────────────────

final _expenseDatasourceProvider = Provider<ExpenseRemoteDatasource>(
  (ref) => ExpenseRemoteDatasource(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  ),
);

final _expenseRepositoryProvider = Provider<IExpenseRepository>(
  (ref) => ExpenseRepositoryImpl(ref.read(_expenseDatasourceProvider)),
);

// Servicios nativos (reutilizables desde la UI).
final locationServiceProvider =
    Provider<LocationService>((ref) => const LocationService());
final receiptImageServiceProvider =
    Provider<ReceiptImageService>((ref) => ReceiptImageService());
final receiptOcrServiceProvider = Provider<ReceiptOcrService>((ref) {
  final service = ReceiptOcrService();
  ref.onDispose(service.dispose);
  return service;
});

// ── Listas en tiempo real ─────────────────────────────────

/// Gastos del usuario autenticado.
final myExpensesStreamProvider = StreamProvider<List<ExpenseEntity>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return Stream.value(const []);
  return WatchMyExpensesUseCase(ref.read(_expenseRepositoryProvider))
      .call(auth.user.uid);
});

/// Gastos asociados a un presupuesto.
final expensesByBudgetStreamProvider =
    StreamProvider.family<List<ExpenseEntity>, String>((ref, budgetId) {
  return WatchExpensesByBudgetUseCase(ref.read(_expenseRepositoryProvider))
      .call(budgetId);
});

/// Consumo de un presupuesto operativo: suma de gastos que comprometen
/// presupuesto (pendiente + aprobado + reembolsado). Reemplaza el placeholder
/// que antes devolvía 0.
final budgetConsumptionProvider =
    Provider.family<double, String>((ref, budgetId) {
  final expenses =
      ref.watch(expensesByBudgetStreamProvider(budgetId)).valueOrNull;
  if (expenses == null) return 0;
  return expenses
      .where((e) => e.status.countsAgainstBudget)
      .fold<double>(0, (acc, e) => acc + e.amount);
});

// ── Acciones (crear/eliminar) ─────────────────────────────

final expenseActionProvider =
    StateNotifierProvider<ExpenseActionNotifier, CrudActionState>(
  (ref) => ExpenseActionNotifier(
    create: CreateExpenseUseCase(ref.read(_expenseRepositoryProvider)),
    delete: DeleteExpenseUseCase(ref.read(_expenseRepositoryProvider)),
  ),
);

class ExpenseActionNotifier extends StateNotifier<CrudActionState> {
  final CreateExpenseUseCase _create;
  final DeleteExpenseUseCase _delete;

  ExpenseActionNotifier({
    required CreateExpenseUseCase create,
    required DeleteExpenseUseCase delete,
  })  : _create = create,
        _delete = delete,
        super(const CrudIdle());

  Future<void> create(ExpenseEntity expense, {String? photoPath}) async {
    state = const CrudLoading();
    final result = await _create(expense, photoPath: photoPath);
    state = switch (result) {
      Success() => CrudSuccess(
          expense.status == ExpenseStatus.draft
              ? 'Gasto guardado como borrador'
              : 'Gasto enviado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> delete(String expenseId) async {
    state = const CrudLoading();
    final result = await _delete(expenseId);
    state = switch (result) {
      Success() => const CrudSuccess('Gasto eliminado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  void reset() => state = const CrudIdle();
}
