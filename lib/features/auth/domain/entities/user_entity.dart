enum UserRole {
  employee,
  supervisor,
  admin;

  static UserRole fromString(String? value) => UserRole.values.firstWhere(
        (r) => r.name == value,
        orElse: () => UserRole.employee,
      );
}

class UserEntity {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? companyId;
  final String? departmentId;

  const UserEntity({
    required this.uid,
    required this.email,
    required this.displayName,
    this.role = UserRole.employee,
    this.companyId,
    this.departmentId,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSupervisor => role == UserRole.supervisor;

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? companyId,
    String? departmentId,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      departmentId: departmentId ?? this.departmentId,
    );
  }
}
