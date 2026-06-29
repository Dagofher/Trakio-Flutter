import '../../../../core/result/result.dart';
import '../entities/app_notification.dart';

abstract interface class INotificationRepository {
  Stream<List<AppNotification>> watchMyNotifications(String userId);

  Future<Result<void>> create(AppNotification notification);

  Future<Result<void>> markAsRead(String notificationId);

  Future<Result<void>> markAllAsRead(String userId);
}
