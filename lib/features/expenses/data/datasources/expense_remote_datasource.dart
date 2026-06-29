import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../domain/entities/expense_entity.dart';

class ExpenseRemoteDatasource {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  const ExpenseRemoteDatasource(this._db, this._storage);

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _db.collection('expenses');

  Stream<List<ExpenseEntity>> watchMyExpenses(String userId) {
    return _expenses
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapAndSort);
  }

  Stream<List<ExpenseEntity>> watchExpensesByBudget(String budgetId) {
    return _expenses
        .where('budgetId', isEqualTo: budgetId)
        .snapshots()
        .map(_mapAndSort);
  }

  Future<void> createExpense(ExpenseEntity expense, {String? photoPath}) async {
    final ref = _expenses.doc();

    String? photoUrl;
    if (photoPath != null) {
      photoUrl = await _uploadReceipt(
        companyId: expense.companyId,
        expenseId: ref.id,
        photoPath: photoPath,
      );
    }

    await ref.set(_toMap(expense.copyWith(photoUrl: photoUrl)));
  }

  Future<void> deleteExpense(String expenseId) =>
      _expenses.doc(expenseId).delete();

  // ── Storage ───────────────────────────────────────────────

  Future<String> _uploadReceipt({
    required String companyId,
    required String expenseId,
    required String photoPath,
  }) async {
    final ref = _storage.ref('receipts/$companyId/$expenseId.jpg');
    final task = await ref.putFile(
      File(photoPath),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return task.ref.getDownloadURL();
  }

  // ── Mapeo ─────────────────────────────────────────────────

  List<ExpenseEntity> _mapAndSort(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Map<String, dynamic> _toMap(ExpenseEntity e) => {
        'companyId': e.companyId,
        'userId': e.userId,
        'budgetId': e.budgetId,
        'categoryId': e.categoryId,
        'amount': e.amount,
        'description': e.description,
        'photoUrl': e.photoUrl,
        'latitude': e.latitude,
        'longitude': e.longitude,
        'status': e.status.name,
        'createdAt': Timestamp.fromDate(e.createdAt),
        'reviewedBy': e.reviewedBy,
        'reviewComment': e.reviewComment,
      };

  ExpenseEntity _fromDoc(String id, Map<String, dynamic> data) {
    return ExpenseEntity(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      budgetId: data['budgetId'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      status: ExpenseStatus.fromString(data['status'] as String?),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewComment: data['reviewComment'] as String?,
    );
  }
}
