import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/category_entity.dart';

class CategoryRemoteDatasource {
  final FirebaseFirestore _db;
  const CategoryRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _categories =>
      _db.collection('categories');

  Stream<List<CategoryEntity>> watchCategories(String companyId) {
    return _categories
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
      // Orden alfabético en cliente para no requerir índice compuesto.
      list.sort((a, b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> createCategory(CategoryEntity category) {
    return _categories.add(_toMap(category));
  }

  Future<void> updateCategory(CategoryEntity category) {
    return _categories.doc(category.id).update(_toMap(category));
  }

  Future<void> deleteCategory(String categoryId) {
    return _categories.doc(categoryId).delete();
  }

  // ── Mapeo ─────────────────────────────────────────────────

  Map<String, dynamic> _toMap(CategoryEntity c) => {
        'companyId': c.companyId,
        'name': c.name,
        'iconKey': c.iconKey,
        'colorValue': c.colorValue,
        'defaultLimit': c.defaultLimit,
      };

  CategoryEntity _fromDoc(String id, Map<String, dynamic> data) {
    return CategoryEntity(
      id: id,
      companyId: data['companyId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      iconKey: data['iconKey'] as String? ?? 'receipt',
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF6C63FF,
      defaultLimit: (data['defaultLimit'] as num?)?.toDouble(),
    );
  }
}
