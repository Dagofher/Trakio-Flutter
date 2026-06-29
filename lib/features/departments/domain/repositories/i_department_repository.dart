import '../../../../core/result/result.dart';
import '../entities/department_entity.dart';

abstract interface class IDepartmentRepository {
  Stream<List<DepartmentEntity>> watchDepartments(String companyId);

  Future<Result<void>> createDepartment(DepartmentEntity department);

  Future<Result<void>> updateDepartment(DepartmentEntity department);

  Future<Result<void>> deleteDepartment(String departmentId);
}
