import '../../../../core/result/result.dart';
import '../repositories/i_department_repository.dart';

class DeleteDepartmentUseCase {
  final IDepartmentRepository _repository;
  const DeleteDepartmentUseCase(this._repository);

  Future<Result<void>> call(String departmentId) =>
      _repository.deleteDepartment(departmentId);
}
