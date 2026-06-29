import '../entities/department_entity.dart';
import '../repositories/i_department_repository.dart';

class WatchDepartmentsUseCase {
  final IDepartmentRepository _repository;
  const WatchDepartmentsUseCase(this._repository);

  Stream<List<DepartmentEntity>> call(String companyId) =>
      _repository.watchDepartments(companyId);
}
