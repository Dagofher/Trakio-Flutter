import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/result/result.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/datasources/category_remote_datasource.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/usecases/delete_category_usecase.dart';
import '../../domain/usecases/save_category_usecase.dart';
import '../../domain/usecases/watch_categories_usecase.dart';
import 'category_action_state.dart';

// ── Infraestructura ───────────────────────────────────────

final _categoryDatasourceProvider = Provider<CategoryRemoteDatasource>(
  (ref) => CategoryRemoteDatasource(FirebaseFirestore.instance),
);

final _categoryRepositoryProvider = Provider<ICategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.read(_categoryDatasourceProvider)),
);

/// companyId del usuario autenticado (o null).
final _companyIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is AuthAuthenticated ? auth.user.companyId : null;
});

// ── Lista en tiempo real ──────────────────────────────────

final categoriesStreamProvider =
    StreamProvider<List<CategoryEntity>>((ref) {
  final companyId = ref.watch(_companyIdProvider);
  if (companyId == null) return Stream.value(const []);
  return WatchCategoriesUseCase(ref.read(_categoryRepositoryProvider))
      .call(companyId);
});

// ── Acciones (crear/editar/eliminar) ──────────────────────

final categoryActionProvider =
    StateNotifierProvider<CategoryActionNotifier, CategoryActionState>(
  (ref) => CategoryActionNotifier(
    save: SaveCategoryUseCase(ref.read(_categoryRepositoryProvider)),
    delete: DeleteCategoryUseCase(ref.read(_categoryRepositoryProvider)),
  ),
);

class CategoryActionNotifier extends StateNotifier<CategoryActionState> {
  final SaveCategoryUseCase _save;
  final DeleteCategoryUseCase _delete;

  CategoryActionNotifier({
    required SaveCategoryUseCase save,
    required DeleteCategoryUseCase delete,
  })  : _save = save,
        _delete = delete,
        super(const CategoryActionIdle());

  Future<void> save(CategoryEntity category) async {
    state = const CategoryActionLoading();
    final result = await _save(category);
    state = switch (result) {
      Success() => CategoryActionSuccess(
          category.id.isEmpty ? 'Categoría creada' : 'Categoría actualizada'),
      Failure(message: final msg) => CategoryActionError(msg),
    };
  }

  Future<void> delete(String categoryId) async {
    state = const CategoryActionLoading();
    final result = await _delete(categoryId);
    state = switch (result) {
      Success() => const CategoryActionSuccess('Categoría eliminada'),
      Failure(message: final msg) => CategoryActionError(msg),
    };
  }

  void reset() => state = const CategoryActionIdle();
}
