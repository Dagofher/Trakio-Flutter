import '../../../../core/result/result.dart';
import '../repositories/i_category_repository.dart';

class DeleteCategoryUseCase {
  final ICategoryRepository _repository;
  const DeleteCategoryUseCase(this._repository);

  Future<Result<void>> call(String categoryId) =>
      _repository.deleteCategory(categoryId);
}
