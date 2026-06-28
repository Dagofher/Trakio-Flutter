import '../../../../core/result/result.dart';
import '../entities/category_entity.dart';

abstract interface class ICategoryRepository {
  /// Lista en tiempo real las categorías de una empresa.
  Stream<List<CategoryEntity>> watchCategories(String companyId);

  Future<Result<void>> createCategory(CategoryEntity category);

  Future<Result<void>> updateCategory(CategoryEntity category);

  Future<Result<void>> deleteCategory(String categoryId);
}
