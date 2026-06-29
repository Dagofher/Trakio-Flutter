import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/department_entity.dart';

class DepartmentRemoteDatasource {
  final FirebaseFirestore _db;
  const DepartmentRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _departments =>
      _db.collection('departments');

  Stream<List<DepartmentEntity>> watchDepartments(String companyId) {
    return _departments
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
      list.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> createDepartment(DepartmentEntity department) {
    return _departments.add(_toMap(department));
  }

  Future<void> updateDepartment(DepartmentEntity department) {
    return _departments.doc(department.id).update(_toMap(department));
  }

  Future<void> deleteDepartment(String departmentId) {
    return _departments.doc(departmentId).delete();
  }

  Map<String, dynamic> _toMap(DepartmentEntity d) => {
        'companyId': d.companyId,
        'name': d.name,
        'supervisorId': d.supervisorId,
      };

  DepartmentEntity _fromDoc(String id, Map<String, dynamic> data) {
    return DepartmentEntity(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      supervisorId: data['supervisorId'] as String?,
    );
  }
}
