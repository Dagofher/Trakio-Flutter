import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/approval_rule.dart';

class ApprovalRuleRemoteDatasource {
  final FirebaseFirestore _db;
  const ApprovalRuleRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _rules =>
      _db.collection('approvalRules');

  Stream<List<ApprovalRule>> watchRules(String companyId) {
    return _rules
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
      list.sort((a, b) => a.minAmount.compareTo(b.minAmount));
      return list;
    });
  }

  Future<void> saveRule(ApprovalRule rule) {
    if (rule.id.isEmpty) return _rules.add(_toMap(rule));
    return _rules.doc(rule.id).update(_toMap(rule));
  }

  Future<void> deleteRule(String ruleId) => _rules.doc(ruleId).delete();

  Map<String, dynamic> _toMap(ApprovalRule r) => {
        'companyId': r.companyId,
        'minAmount': r.minAmount,
        'maxAmount': r.maxAmount,
        'categoryId': r.categoryId,
        'outcome': r.outcome.name,
      };

  ApprovalRule _fromDoc(String id, Map<String, dynamic> data) {
    return ApprovalRule(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      minAmount: (data['minAmount'] as num?)?.toDouble() ?? 0,
      maxAmount: (data['maxAmount'] as num?)?.toDouble(),
      categoryId: data['categoryId'] as String?,
      outcome: ApprovalOutcome.fromString(data['outcome'] as String?),
    );
  }
}
