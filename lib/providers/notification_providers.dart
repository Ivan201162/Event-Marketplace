import 'package:event_marketplace_app/models/app_notification.dart';
import 'package:event_marketplace_app/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return notifications.map(AppNotification.fromMap).toList();
  });

  /// Количество непрочитанных уведомлений
  static final unreadCountProvider =
      FutureProvider.family<int, String>((ref, userId) async {
    final service = ref.watch(notificationServiceProvider);
    return service.getUnreadCount(userId);
  });

  /// Последние уведомления (для бейджа)
  static final recentNotificationsProvider =
      FutureProvider.family<List<AppNotification>, String>((ref, userId) async {
    final service = ref.watch(notificationServiceProvider);
    final notifications = await service.getNotificationsForUser(userId);
    return notifications.map(AppNotification.fromMap).toList();
  });
}
