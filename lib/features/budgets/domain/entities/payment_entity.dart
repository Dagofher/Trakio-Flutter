/// Un pago registrado contra un presupuesto de tipo adquisición a plazos.
class PaymentEntity {
  final String id;
  final String budgetId;
  final double amount;
  final DateTime date;
  final String note;
  final String createdBy;

  const PaymentEntity({
    required this.id,
    required this.budgetId,
    required this.amount,
    required this.date,
    this.note = '',
    this.createdBy = '',
  });
}
