class CompanyEntity {
  final String id;
  final String name;
  final String ownerId;
  final String inviteCode;

  const CompanyEntity({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.inviteCode,
  });
}
