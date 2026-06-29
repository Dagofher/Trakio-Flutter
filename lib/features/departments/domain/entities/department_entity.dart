class DepartmentEntity {
  final String id;
  final String companyId;
  final String name;

  /// uid del supervisor a cargo. Null mientras no haya gestión de usuarios.
  final String? supervisorId;

  const DepartmentEntity({
    required this.id,
    required this.companyId,
    required this.name,
    this.supervisorId,
  });

  DepartmentEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    String? supervisorId,
  }) {
    return DepartmentEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      supervisorId: supervisorId ?? this.supervisorId,
    );
  }
}
