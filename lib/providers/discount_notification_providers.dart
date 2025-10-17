import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/discount_notification.dart';
import '../services/discount_notification_service.dart';

/// Сервис уведомлений о скидках
final discountNotificationServiceProvider = Provider<DiscountNotificationService>(
  (ref) => DiscountNotificationService(),
);

/// Провайдер для создания уведомления о скидке
final createDiscountNotificationProvider =
    FutureProvider.family<DiscountNotification, CreateDiscountNotification>((ref, params) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.createDiscountNotification(params);
});

/// Провайдер для получения уведомлений клиента
final customerNotificationsProvider =
    StreamProvider.family<List<DiscountNotification>, String>((ref, customerId) {
  final service = ref.read(discountNotificationServiceProvider);
  return service.watchCustomerNotifications(customerId);
});

/// Провайдер для получения непрочитанных уведомлений клиента
final unreadCustomerNotificationsProvider =
    StreamProvider.family<List<DiscountNotification>, String>((ref, customerId) {
  final service = ref.read(discountNotificationServiceProvider);
  return service.watchUnreadCustomerNotifications(customerId);
});

/// Провайдер для получения количества непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider.family<int, String>((ref, customerId) {
  final service = ref.read(discountNotificationServiceProvider);
  return service.watchUnreadCount(customerId);
});

/// Провайдер для получения уведомления по ID
final notificationProvider =
    FutureProvider.family<DiscountNotification?, String>((ref, notificationId) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.getNotification(notificationId);
});

/// Провайдер для отметки уведомления как прочитанного
final markNotificationAsReadProvider =
    FutureProvider.family<void, String>((ref, notificationId) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.markAsRead(notificationId);
});

/// Провайдер для отметки всех уведомлений как прочитанных
final markAllNotificationsAsReadProvider =
    FutureProvider.family<void, String>((ref, customerId) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.markAllAsRead(customerId);
});

/// Провайдер для удаления уведомления
final deleteNotificationProvider = FutureProvider.family<void, String>((ref, notificationId) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.deleteNotification(notificationId);
});

/// Провайдер для получения статистики уведомлений клиента
final customerNotificationStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, customerId) async {
  final service = ref.read(discountNotificationServiceProvider);
  return service.getCustomerStats(customerId);
});
