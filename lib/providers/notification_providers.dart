import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Провайдеры для уведомлений
class NotificationProviders {
  /// Сервис уведомлений
  static final notificationServiceProvider =
      Provider<NotificationService>((ref) {
    return NotificationService();
  });

  /// Уведомления пользователя
  static final userNotificationsProvider =
      FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
    final service = ref.watch(notificationServiceProvider);
    final notifications = await service.getNotificationsForUser(userId);
    return notifications.map((data) => AppNotification.fromMap(data)).toList();
  });

  /// Количество непрочитанных уведомлений
  static final unreadCountProvider =
      FutureProvider.family<int, String>((ref, userId) async {
    final service = ref.watch(notificationServiceProvider);
    return await service.getUnreadCount(userId);
  });

  /// Последние уведомления (для бейджа)
  static final recentNotificationsProvider =
      FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
    final service = ref.watch(notificationServiceProvider);
    final notifications = await service.getNotificationsForUser(userId);
    return notifications.map((data) => AppNotification.fromMap(data)).toList();
  });
}
