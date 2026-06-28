import '../../../../core/result/result.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../datasources/category_remote_datasource.dart';

class CategoryRepositoryImpl implements ICategoryRepository {
  final CategoryRemoteDatasource _datasource;
  const CategoryRepositoryImpl(this._datasource);

  @override
  Stream<List<CategoryEntity>> watchCategories(String companyId) =>
      _datasource.watchCategories(companyId);

  @override
  Future<Result<void>> createCategory(CategoryEntity category) async {
    try {
      await _datasource.createCategory(category);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo crear la categoría.');
    }
  }

  @override
  Future<Result<void>> updateCategory(CategoryEntity category) async {
    try {
      await _datasource.updateCategory(category);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo actualizar la categoría.');
    }
  }

  @override
  Future<Result<void>> deleteCategory(String categoryId) async {
    try {
      await _datasource.deleteCategory(categoryId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo eliminar la categoría.');
    }
  }
}
