import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/budget_entity.dart';
import '../../domain/entities/payment_entity.dart';

class BudgetRemoteDatasource {
  final FirebaseFirestore _db;
  const BudgetRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _db.collection('budgets');

  CollectionReference<Map<String, dynamic>> _payments(String budgetId) =>
      _budgets.doc(budgetId).collection('payments');

  // ── Presupuestos ──────────────────────────────────────────

  Stream<List<BudgetEntity>> watchBudgets(String companyId) {
    return _budgets
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
      list.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> createBudget(BudgetEntity budget) =>
      _budgets.add(_toMap(budget));

  Future<void> updateBudget(BudgetEntity budget) =>
      _budgets.doc(budget.id).update(_toMap(budget));

  Future<void> deleteBudget(String budgetId) =>
      _budgets.doc(budgetId).delete();

  // ── Pagos ─────────────────────────────────────────────────

  Stream<List<PaymentEntity>> watchPayments(String budgetId) {
    return _payments(budgetId).snapshots().map((snap) {
      final list =
          snap.docs.map((d) => _paymentFromDoc(budgetId, d.id, d.data())).toList();
      list.sort((a, b) => b.date.compareTo(a.date)); // más reciente primero
      return list;
    });
  }

  Future<void> addPayment(PaymentEntity payment) {
    return _payments(payment.budgetId).add({
      'amount': payment.amount,
      'date': Timestamp.fromDate(payment.date),
      'note': payment.note,
      'createdBy': payment.createdBy,
    });
  }

  Future<void> deletePayment(String budgetId, String paymentId) =>
      _payments(budgetId).doc(paymentId).delete();

  // ── Mapeo ─────────────────────────────────────────────────

  Map<String, dynamic> _toMap(BudgetEntity b) => {
        'companyId': b.companyId,
        'name': b.name,
        'type': b.type.name,
        'scope': b.scope.name,
        'scopeName': b.scopeName,
        'departmentId': b.departmentId,
        'amount': b.amount,
        'period': b.period?.name,
        'allowedCategoryIds': b.allowedCategoryIds,
        'alertThresholds': b.alertThresholds,
        'dueDate': b.dueDate != null ? Timestamp.fromDate(b.dueDate!) : null,
        'installments': b.installments,
        'nextChargeDate':
            b.nextChargeDate != null ? Timestamp.fromDate(b.nextChargeDate!) : null,
      };

  BudgetEntity _fromDoc(String id, Map<String, dynamic> data) {
    return BudgetEntity(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: BudgetType.fromString(data['type'] as String?),
      scope: BudgetScope.fromString(data['scope'] as String?),
      scopeName: data['scopeName'] as String? ?? '',
      departmentId: data['departmentId'] as String?,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      period: data['period'] != null
          ? BudgetPeriod.fromString(data['period'] as String?)
          : null,
      allowedCategoryIds:
          (data['allowedCategoryIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      alertThresholds:
          (data['alertThresholds'] as List<dynamic>? ?? const [50, 75, 90])
              .map((e) => (e as num).toInt())
              .toList(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      installments: (data['installments'] as num?)?.toInt(),
      nextChargeDate: (data['nextChargeDate'] as Timestamp?)?.toDate(),
    );
  }

  PaymentEntity _paymentFromDoc(
    String budgetId,
    String id,
    Map<String, dynamic> data,
  ) {
    return PaymentEntity(
      id: id,
      budgetId: budgetId,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
    );
  }
}
