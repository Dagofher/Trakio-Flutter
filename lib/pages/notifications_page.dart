import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../desings/colors.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/providers/auth_state.dart';
import '../features/notifications/domain/entities/app_notification.dart';
import '../features/notifications/presentation/providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsStreamProvider);
    final hasUnread = ref.watch(unreadNotificationsCountProvider) > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: () {
                final auth = ref.read(authProvider);
                if (auth is AuthAuthenticated) {
                  ref
                      .read(notificationRepositoryProvider)
                      .markAllAsRead(auth.user.uid);
                }
              },
              child: const Text('Marcar leídas',
                  style: TextStyle(color: AppColors.accentColor)),
            ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentColor),
        ),
        error: (err, stack) => Center(
          child: Text('No se pudieron cargar las notificaciones.',
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.7))),
        ),
        data: (notifications) {
          if (notifications.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, i) => _NotificationTile(
              notification: notifications[i],
              onTap: () => ref
                  .read(notificationRepositoryProvider)
                  .markAsRead(notifications[i].id),
            ),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationTile({required this.notification, required this.onTap});

  ({IconData icon, Color color}) get _visual => switch (notification.type) {
        NotificationType.expenseApproved => (
            icon: Icons.check_circle_rounded,
            color: const Color(0xFF4CAF50)
          ),
        NotificationType.expenseAutoApproved => (
            icon: Icons.bolt_rounded,
            color: const Color(0xFF4CAF50)
          ),
        NotificationType.expenseRejected => (
            icon: Icons.cancel_rounded,
            color: AppColors.errorColor
          ),
        NotificationType.general => (
            icon: Icons.notifications_rounded,
            color: AppColors.accentColor
          ),
      };

  @override
  Widget build(BuildContext context) {
    final v = _visual;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: notification.read
              ? AppColors.surfaceColor
              : AppColors.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.read
                ? AppColors.borderColor
                : AppColors.accentColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: v.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(v.icon, color: v.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!notification.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _fmtDate(notification.createdAt),
                    style: TextStyle(
                      color: AppColors.textColor.withValues(alpha: 0.55),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: AppColors.textColor.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            const Text('Sin notificaciones',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Aquí verás avisos cuando aprueben o rechacen tus gastos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final date =
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  final time =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '$date · $time';
}
