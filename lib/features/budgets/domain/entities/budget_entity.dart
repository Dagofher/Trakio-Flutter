enum BudgetPeriod {
  monthly,
  quarterly,
  annual;

  static BudgetPeriod fromString(String? value) =>
      BudgetPeriod.values.firstWhere(
        (p) => p.name == value,
        orElse: () => BudgetPeriod.monthly,
      );

  String get label => switch (this) {
        BudgetPeriod.monthly => 'Mensual',
        BudgetPeriod.quarterly => 'Trimestral',
        BudgetPeriod.annual => 'Anual',
      };
}

/// Naturaleza del presupuesto.
enum BudgetType {
  /// Pool de gasto que se consume con gastos (baja gastando).
  operational,

  /// Compra/adquisición que se salda registrando pagos (sube pagando).
  acquisition,

  /// Servicio o suscripción que se renueva cada periodo.
  recurring;

  static BudgetType fromString(String? value) =>
      BudgetType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => BudgetType.operational,
      );

  String get label => switch (this) {
        BudgetType.operational => 'Operativo',
        BudgetType.acquisition => 'Adquisición a plazos',
        BudgetType.recurring => 'Recurrente',
      };
}

/// A qué aplica el presupuesto.
enum BudgetScope {
  department,
  team,
  equipment,
  area,
  project,
  general;

  static BudgetScope fromString(String? value) =>
      BudgetScope.values.firstWhere(
        (s) => s.name == value,
        orElse: () => BudgetScope.department,
      );

  String get label => switch (this) {
        BudgetScope.department => 'Departamento',
        BudgetScope.team => 'Equipo',
        BudgetScope.equipment => 'Máquina/Equipo',
        BudgetScope.area => 'Área',
        BudgetScope.project => 'Proyecto',
        BudgetScope.general => 'General',
      };
}

class BudgetEntity {
  final String id;
  final String companyId;
  final String name;

  final BudgetType type;
  final BudgetScope scope;

  /// Nombre del objetivo del presupuesto (ej: "Máquina CNC-3", "Ventas").
  final String scopeName;

  /// Departamento asociado (cuando scope == department). Opcional en lo demás.
  final String? departmentId;

  /// Monto: operativo=pool total; adquisición=costo total; recurrente=monto/periodo.
  final double amount;

  /// Periodo (operativo y recurrente). Null para adquisición.
  final BudgetPeriod? period;

  // Operativo
  final List<String> allowedCategoryIds;
  final List<int> alertThresholds;

  // Adquisición a plazos
  final DateTime? dueDate;
  final int? installments;

  // Recurrente
  final DateTime? nextChargeDate;

  const BudgetEntity({
    required this.id,
    required this.companyId,
    required this.name,
    required this.amount,
    this.type = BudgetType.operational,
    this.scope = BudgetScope.department,
    this.scopeName = '',
    this.departmentId,
    this.period,
    this.allowedCategoryIds = const [],
    this.alertThresholds = const [50, 75, 90],
    this.dueDate,
    this.installments,
    this.nextChargeDate,
  });

  BudgetEntity copyWith({
    String? id,
    String? companyId,
    String? name,
    BudgetType? type,
    BudgetScope? scope,
    String? scopeName,
    String? departmentId,
    double? amount,
    BudgetPeriod? period,
    List<String>? allowedCategoryIds,
    List<int>? alertThresholds,
    DateTime? dueDate,
    int? installments,
    DateTime? nextChargeDate,
  }) {
    return BudgetEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      type: type ?? this.type,
      scope: scope ?? this.scope,
      scopeName: scopeName ?? this.scopeName,
      departmentId: departmentId ?? this.departmentId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      allowedCategoryIds: allowedCategoryIds ?? this.allowedCategoryIds,
      alertThresholds: alertThresholds ?? this.alertThresholds,
      dueDate: dueDate ?? this.dueDate,
      installments: installments ?? this.installments,
      nextChargeDate: nextChargeDate ?? this.nextChargeDate,
    );
  }
}
