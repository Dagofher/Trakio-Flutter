import '../entities/category_entity.dart';
import '../repositories/i_category_repository.dart';

class WatchCategoriesUseCase {
  final ICategoryRepository _repository;
  const WatchCategoriesUseCase(this._repository);

  Stream<List<CategoryEntity>> call(String companyId) =>
      _repository.watchCategories(companyId);
}
