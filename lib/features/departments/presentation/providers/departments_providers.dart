import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/presentation/crud_action_state.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/datasources/department_remote_datasource.dart';
import '../../data/repositories/department_repository_impl.dart';
import '../../domain/entities/department_entity.dart';
import '../../domain/repositories/i_department_repository.dart';
import '../../domain/usecases/delete_department_usecase.dart';
import '../../domain/usecases/save_department_usecase.dart';
import '../../domain/usecases/watch_departments_usecase.dart';

// ── Infraestructura ───────────────────────────────────────

final _departmentDatasourceProvider = Provider<DepartmentRemoteDatasource>(
  (ref) => DepartmentRemoteDatasource(FirebaseFirestore.instance),
);

final _departmentRepositoryProvider = Provider<IDepartmentRepository>(
  (ref) => DepartmentRepositoryImpl(ref.read(_departmentDatasourceProvider)),
);

// ── Lista en tiempo real ──────────────────────────────────

final departmentsStreamProvider =
    StreamProvider<List<DepartmentEntity>>((ref) {
  final companyId = ref.watch(companyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return WatchDepartmentsUseCase(ref.read(_departmentRepositoryProvider))
      .call(companyId);
});

// ── Acciones ──────────────────────────────────────────────

final departmentActionProvider =
    StateNotifierProvider<DepartmentActionNotifier, CrudActionState>(
  (ref) => DepartmentActionNotifier(
    save: SaveDepartmentUseCase(ref.read(_departmentRepositoryProvider)),
    delete: DeleteDepartmentUseCase(ref.read(_departmentRepositoryProvider)),
  ),
);

class DepartmentActionNotifier extends StateNotifier<CrudActionState> {
  final SaveDepartmentUseCase _save;
  final DeleteDepartmentUseCase _delete;

  DepartmentActionNotifier({
    required SaveDepartmentUseCase save,
    required DeleteDepartmentUseCase delete,
  })  : _save = save,
        _delete = delete,
        super(const CrudIdle());

  Future<void> save(DepartmentEntity department) async {
    state = const CrudLoading();
    final result = await _save(department);
    state = switch (result) {
      Success() => CrudSuccess(
          department.id.isEmpty ? 'Departamento creado' : 'Departamento actualizado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  Future<void> delete(String departmentId) async {
    state = const CrudLoading();
    final result = await _delete(departmentId);
    state = switch (result) {
      Success() => const CrudSuccess('Departamento eliminado'),
      Failure(message: final msg) => CrudError(msg),
    };
  }

  void reset() => state = const CrudIdle();
}
