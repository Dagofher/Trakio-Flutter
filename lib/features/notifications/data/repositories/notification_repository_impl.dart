import '../../../../core/result/result.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements INotificationRepository {
  final NotificationRemoteDatasource _datasource;
  const NotificationRepositoryImpl(this._datasource);

  @override
  Stream<List<AppNotification>> watchMyNotifications(String userId) =>
      _datasource.watchMyNotifications(userId);

  @override
  Future<Result<void>> create(AppNotification notification) async {
    try {
      await _datasource.create(notification);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo crear la notificación.');
    }
  }

  @override
  Future<Result<void>> markAsRead(String notificationId) async {
    try {
      await _datasource.markAsRead(notificationId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudo marcar como leída.');
    }
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    try {
      await _datasource.markAllAsRead(userId);
      return const Success(null);
    } catch (_) {
      return const Failure('No se pudieron marcar como leídas.');
    }
  }
}
