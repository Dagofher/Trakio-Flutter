enum NotificationType {
  expenseApproved,
  expenseRejected,
  expenseAutoApproved,
  general;

  static NotificationType fromString(String? value) =>
      NotificationType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => NotificationType.general,
      );
}

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final bool read;
  final DateTime createdAt;
  final String? relatedExpenseId;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.type = NotificationType.general,
    this.read = false,
    this.relatedExpenseId,
  });
}
