import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../auth/presentation/providers/auth_state.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/repositories/i_notification_repository.dart';

final _notificationDatasourceProvider =
    Provider<NotificationRemoteDatasource>(
  (ref) => NotificationRemoteDatasource(FirebaseFirestore.instance),
);

/// Repositorio de notificaciones (público: otras features lo usan para crear).
final notificationRepositoryProvider = Provider<INotificationRepository>(
  (ref) => NotificationRepositoryImpl(ref.read(_notificationDatasourceProvider)),
);

/// Notificaciones del usuario autenticado (tiempo real).
final myNotificationsStreamProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final auth = ref.watch(authProvider);
  if (auth is! AuthAuthenticated) return Stream.value(const []);
  return ref
      .read(notificationRepositoryProvider)
      .watchMyNotifications(auth.user.uid);
});

/// Conteo de notificaciones sin leer (para el badge).
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(myNotificationsStreamProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.read).length;
});
