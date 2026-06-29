import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_notification.dart';

class NotificationRemoteDatasource {
  final FirebaseFirestore _db;
  const NotificationRemoteDatasource(this._db);

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');

  Stream<List<AppNotification>> watchMyNotifications(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => _fromDoc(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> create(AppNotification n) {
    return _notifications.add({
      'userId': n.userId,
      'title': n.title,
      'body': n.body,
      'type': n.type.name,
      'read': n.read,
      'createdAt': Timestamp.fromDate(n.createdAt),
      'relatedExpenseId': n.relatedExpenseId,
    });
  }

  Future<void> markAsRead(String notificationId) =>
      _notifications.doc(notificationId).update({'read': true});

  Future<void> markAllAsRead(String userId) async {
    final query =
        await _notifications.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in query.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  AppNotification _fromDoc(String id, Map<String, dynamic> data) {
    return AppNotification(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: NotificationType.fromString(data['type'] as String?),
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      relatedExpenseId: data['relatedExpenseId'] as String?,
    );
  }
}
