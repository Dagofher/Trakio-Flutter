enum ExpenseStatus {
  draft,
  pending,
  approved,
  rejected,
  reimbursed;

  static ExpenseStatus fromString(String? value) =>
      ExpenseStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ExpenseStatus.pending,
      );

  String get label => switch (this) {
        ExpenseStatus.draft => 'Borrador',
        ExpenseStatus.pending => 'Pendiente',
        ExpenseStatus.approved => 'Aprobado',
        ExpenseStatus.rejected => 'Rechazado',
        ExpenseStatus.reimbursed => 'Reembolsado',
      };

  /// Estados que comprometen presupuesto (cuentan como consumido).
  bool get countsAgainstBudget =>
      this == ExpenseStatus.pending ||
      this == ExpenseStatus.approved ||
      this == ExpenseStatus.reimbursed;
}

class ExpenseEntity {
  final String id;
  final String companyId;
  final String userId;
  final String budgetId;
  final String categoryId;
  final double amount;
  final String description;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final ExpenseStatus status;
  final DateTime createdAt;

  // Revisión (se usa en Fase 6)
  final String? reviewedBy;
  final String? reviewComment;

  const ExpenseEntity({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.budgetId,
    required this.categoryId,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.status = ExpenseStatus.pending,
    this.reviewedBy,
    this.reviewComment,
  });

  bool get hasLocation => latitude != null && longitude != null;

  ExpenseEntity copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? budgetId,
    String? categoryId,
    double? amount,
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    ExpenseStatus? status,
    DateTime? createdAt,
    String? reviewedBy,
    String? reviewComment,
  }) {
    return ExpenseEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      budgetId: budgetId ?? this.budgetId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewComment: reviewComment ?? this.reviewComment,
    );
  }
}
