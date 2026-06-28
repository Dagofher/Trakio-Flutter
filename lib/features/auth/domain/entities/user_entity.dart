enum UserRole { employee, supervisor, admin }

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
}
