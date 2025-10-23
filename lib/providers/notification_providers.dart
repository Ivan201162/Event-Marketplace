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
      StreamProvider.family<List<AppNotification>, String>((ref, userId) {
    final service = ref.watch(notificationServiceProvider);
    return service.getNotificationsForUser(userId);
  });

  /// Количество непрочитанных уведомлений
  static final unreadCountProvider =
      StreamProvider.family<int, String>((ref, userId) {
    final service = ref.watch(notificationServiceProvider);
    return service.getUnreadCount(userId);
  });

  /// Последние уведомления (для бейджа)
  static final recentNotificationsProvider =
      StreamProvider.family<List<AppNotification>, String>((ref, userId) {
    final service = ref.watch(notificationServiceProvider);
    return service.getNotificationsForUser(userId);
  });
}
