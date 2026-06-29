import '../../../../core/result/result.dart';
import '../entities/department_entity.dart';
import '../repositories/i_department_repository.dart';

/// Crea un departamento (id vacío) o actualiza uno existente.
class SaveDepartmentUseCase {
  final IDepartmentRepository _repository;
  const SaveDepartmentUseCase(this._repository);

  Future<Result<void>> call(DepartmentEntity department) {
    return department.id.isEmpty
        ? _repository.createDepartment(department)
        : _repository.updateDepartment(department);
  }
}
