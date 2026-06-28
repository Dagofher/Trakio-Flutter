import '../../../../core/result/result.dart';
import '../entities/category_entity.dart';
import '../repositories/i_category_repository.dart';

/// Crea una categoría (id vacío) o actualiza una existente.
class SaveCategoryUseCase {
  final ICategoryRepository _repository;
  const SaveCategoryUseCase(this._repository);

  Future<Result<void>> call(CategoryEntity category) {
    return category.id.isEmpty
        ? _repository.createCategory(category)
        : _repository.updateCategory(category);
  }
}
