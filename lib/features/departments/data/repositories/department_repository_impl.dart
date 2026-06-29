import '../../../../core/result/result.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/repositories/i_department_repository.dart';
import '../datasources/department_remote_datasource.dart';

class DepartmentRepositoryImpl implements IDepartmentRepository {
  final DepartmentRemoteDatasource _datasource;
  const DepartmentRepositoryImpl(this._datasource);

  @override
  Stream<List<DepartmentEntity>> watchDepartments(String companyId) =>
      _datasource.watchDepartments(companyId);

  @override
  Future<Result<void>> createDepartment(DepartmentEntity department) async {
    try {
      await _datasource.createDepartment(department);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo crear el departamento.');
    }
  }

  @override
  Future<Result<void>> updateDepartment(DepartmentEntity department) async {
    try {
      await _datasource.updateDepartment(department);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo actualizar el departamento.');
    }
  }

  @override
  Future<Result<void>> deleteDepartment(String departmentId) async {
    try {
      await _datasource.deleteDepartment(departmentId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar el departamento.');
    }
  }
}
