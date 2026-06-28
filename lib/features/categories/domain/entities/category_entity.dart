class CategoryEntity {
  final String id;
  final String companyId;
  final String name;

  /// Clave del ícono dentro del catálogo (ver category_catalog.dart).
  final String iconKey;

  /// Color como valor entero ARGB (Color.value).
  final int colorValue;

  /// Límite de gasto por defecto para la categoría. Null = sin límite.
  final double? defaultLimit;

  const CategoryEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.defaultLimit,
  });

  CategoryEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    String? iconKey,
    int? colorValue,
    double? defaultLimit,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      defaultLimit: defaultLimit ?? this.defaultLimit,
    );
  }
}
