/// Qué ocurre con un gasto que cae dentro del rango de la regla.
enum ApprovalOutcome {
  autoApprove,
  requireSupervisor,
  requireAdmin;

  static ApprovalOutcome fromString(String? value) =>
      ApprovalOutcome.values.firstWhere(
        (o) => o.name == value,
        orElse: () => ApprovalOutcome.requireAdmin,
      );

  String get label => switch (this) {
        ApprovalOutcome.autoApprove => 'Aprobar automáticamente',
        ApprovalOutcome.requireSupervisor => 'Requiere supervisor',
        ApprovalOutcome.requireAdmin => 'Requiere admin',
      };

  bool get isAuto => this == ApprovalOutcome.autoApprove;
}

class ApprovalRule {
  final String id;
  final String companyId;
  final double minAmount;

  /// Tope máximo del rango. Null = sin límite superior.
  final double? maxAmount;

  /// Categoría a la que aplica. Null = cualquier categoría.
  final String? categoryId;

  final ApprovalOutcome outcome;

  const ApprovalRule({
    required this.id,
    required this.companyId,
    required this.minAmount,
    required this.outcome,
    this.maxAmount,
    this.categoryId,
  });

  /// ¿El gasto (monto + categoría) cae dentro de esta regla?
  bool matches(double amount, String categoryId) {
    if (amount < minAmount) return false;
    if (maxAmount != null && amount > maxAmount!) return false;
    if (this.categoryId != null && this.categoryId != categoryId) return false;
    return true;
  }

  ApprovalRule copyWith({
    String? id,
    String? companyId,
    double? minAmount,
    double? maxAmount,
    String? categoryId,
    ApprovalOutcome? outcome,
  }) {
    return ApprovalRule(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      categoryId: categoryId ?? this.categoryId,
      outcome: outcome ?? this.outcome,
    );
  }
}
