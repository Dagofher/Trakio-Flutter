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
import '../../../notifications/domain/entities/app_notification.dart';
import '../../../notifications/domain/repositories/i_notification_repository.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/i_expense_repository.dart';
import '../../domain/usecases/create_expense_usecase.dart';
import '../../domain/usecases/delete_expense_usecase.dart';
import '../../domain/usecases/review_expense_usecase.dart';
import '../../domain/usecases/watch_company_expenses_usecase.dart';
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

/// Todos los gastos de la empresa (para la bandeja de aprobaciones).
final companyExpensesStreamProvider =
    StreamProvider<List<ExpenseEntity>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return WatchCompanyExpensesUseCase(ref.read(_expenseRepositoryProvider))
      .call(companyId);
});

/// Gastos pendientes de revisión de la empresa.
final pendingExpensesProvider = Provider<List<ExpenseEntity>>((ref) {
  final expenses = ref.watch(companyExpensesStreamProvider).valueOrNull;
  if (expenses == null) return const [];
  return expenses.where((e) => e.status == ExpenseStatus.pending).toList();
});

// ── Revisión (aprobar / rechazar) ─────────────────────────

final expenseReviewProvider =
    StateNotifierProvider<ExpenseReviewNotifier, CrudActionState>(
  (ref) => ExpenseReviewNotifier(
    review: ReviewExpenseUseCase(ref.read(_expenseRepositoryProvider)),
    notifications: ref.read(notificationRepositoryProvider),
  ),
);

class ExpenseReviewNotifier extends StateNotifier<CrudActionState> {
  final ReviewExpenseUseCase _review;
  final INotificationRepository _notifications;

  ExpenseReviewNotifier({
    required ReviewExpenseUseCase review,
    required INotificationRepository notifications,
  })  : _review = review,
        _notifications = notifications,
        super(const CrudIdle());

  /// Aprueba o rechaza un gasto y notifica al empleado dueño.
  Future<void> review({
    required ExpenseEntity expense,
    required bool approve,
    required String reviewerUid,
    String? comment,
  }) async {
    state = const CrudLoading();
    final status =
        approve ? ExpenseStatus.approved : ExpenseStatus.rejected;
    final result = await _review(
      expenseId: expense.id,
      status: status,
      reviewedBy: reviewerUid,
      comment: comment,
    );

    switch (result) {
      case Success():
        await _notifications.create(AppNotification(
          id: '',
          userId: expense.userId,
          title: approve ? 'Gasto aprobado' : 'Gasto rechazado',
          body: approve
              ? 'Tu gasto de \$${expense.amount.toStringAsFixed(2)} fue aprobado.'
              : 'Tu gasto de \$${expense.amount.toStringAsFixed(2)} fue rechazado.'
                  '${(comment != null && comment.isNotEmpty) ? ' Motivo: $comment' : ''}',
          type: approve
              ? NotificationType.expenseApproved
              : NotificationType.expenseRejected,
          createdAt: DateTime.now(),
          relatedExpenseId: expense.id,
        ));
        state = CrudSuccess(approve ? 'Gasto aprobado' : 'Gasto rechazado');
      case Failure(message: final msg):
        state = CrudError(msg);
    }
  }

  void reset() => state = const CrudIdle();
}

// ── Acciones (crear/eliminar) ─────────────────────────────

final expenseActionProvider =
    StateNotifierProvider<ExpenseActionNotifier, CrudActionState>(
  (ref) => ExpenseActionNotifier(
    create: CreateExpenseUseCase(ref.read(_expenseRepositoryProvider)),
    delete: DeleteExpenseUseCase(ref.read(_expenseRepositoryProvider)),
    notifications: ref.read(notificationRepositoryProvider),
  ),
);

class ExpenseActionNotifier extends StateNotifier<CrudActionState> {
  final CreateExpenseUseCase _create;
  final DeleteExpenseUseCase _delete;
  final INotificationRepository _notifications;

  ExpenseActionNotifier({
    required CreateExpenseUseCase create,
    required DeleteExpenseUseCase delete,
    required INotificationRepository notifications,
  })  : _create = create,
        _delete = delete,
        _notifications = notifications,
        super(const CrudIdle());

  Future<void> create(ExpenseEntity expense, {String? photoPath}) async {
    state = const CrudLoading();
    final result = await _create(expense, photoPath: photoPath);
    switch (result) {
      case Success():
        // Si una regla lo autoaprobó, notificar al empleado.
        if (expense.status == ExpenseStatus.approved) {
          await _notifications.create(AppNotification(
            id: '',
            userId: expense.userId,
            title: 'Gasto aprobado automáticamente',
            body:
                'Tu gasto de \$${expense.amount.toStringAsFixed(2)} fue aprobado por una regla.',
            type: NotificationType.expenseAutoApproved,
            createdAt: DateTime.now(),
          ));
        }
        state = CrudSuccess(switch (expense.status) {
          ExpenseStatus.draft => 'Gasto guardado como borrador',
          ExpenseStatus.approved => 'Gasto aprobado automáticamente',
          _ => 'Gasto enviado',
        });
      case Failure(message: final msg):
        state = CrudError(msg);
    }
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
