import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_notification.dart' as app_notification;
import '../services/notification_service.dart';

/// Провайдер для получения текущего пользователя
final currentUserProvider =
    StreamProvider<User?>((ref) => FirebaseAuth.instance.authStateChanges());

/// Провайдер для управления уведомлениями пользователя
final userNotificationsProvider = StreamProvider<List<app_notification.AppNotification>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(app_notification.AppNotification.fromFirestore).toList(),
          );
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Провайдер для подсчёта непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.when(
    data: (user) {
      if (user == null) return Stream.value(0);
      return FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});

/// Провайдер для управления уведомлениями
class NotificationNotifier
    extends StateNotifier<AsyncValue<List<app_notification.AppNotification>>> {
  NotificationNotifier() : super(const AsyncValue.loading()) {
    _loadNotifications();
  }

  void _loadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(app_notification.AppNotification.fromFirestore).toList(),
        )
        .listen((notifications) {
      state = AsyncValue.data(notifications);
    });
  }

  /// Отметить уведомление как прочитанное
  Future<void> markAsRead(String notificationId) async {
    try {
      await NotificationService.markNotificationAsRead(notificationId);
    } on Exception catch (e) {
      debugPrint('Ошибка при отметке уведомления как прочитанного: $e');
    }
  }

  /// Отметить все уведомления как прочитанные
  Future<void> markAllAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService.markAllAsRead(user.uid);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка при отметке всех уведомлений как прочитанных: $e');
    }
  }

  /// Закрепить уведомление
  Future<void> pinNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService.pinNotification(user.uid, notificationId);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка при закреплении уведомления: $e');
    }
  }

  /// Открепить уведомление
  Future<void> unpinNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService.unpinNotification(user.uid, notificationId);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка при откреплении уведомления: $e');
    }
  }

  /// Удалить уведомление
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await NotificationService.deleteNotification(user.uid, notificationId);
      }
    } on Exception catch (e) {
      debugPrint('Ошибка при удалении уведомления: $e');
    }
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<app_notification.AppNotification>>>(
  (ref) => NotificationNotifier(),
);

/// Временный класс для совместимости с DocumentSnapshot
class MockDocumentSnapshot implements DocumentSnapshot {
  MockDocumentSnapshot(this._data, this._id);

  final Map<String, dynamic> _data;
  final String _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  String get id => _id;

  @override
  bool get exists => true;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  dynamic get(Object field) => _data[field];
}
