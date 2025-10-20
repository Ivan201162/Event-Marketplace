import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/push_notification.dart';
import '../services/push_notification_service.dart';

/// Push notification service provider
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

/// User notifications provider
final userNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  return service.getUserNotifications(userId);
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  return service.getUnreadCount(userId);
});

/// User notifications stream provider
final userNotificationsStreamProvider =
    StreamProvider.family<List<PushNotification>, String>((ref, userId) {
  final service = ref.read(pushNotificationServiceProvider);
  return service.getUserNotificationsStream(userId);
});

/// Unread count stream provider
final unreadCountStreamProvider = StreamProvider.family<int, String>((ref, userId) {
  final service = ref.read(pushNotificationServiceProvider);
  return service.getUnreadCountStream(userId);
});

/// Recent notifications provider
final recentNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications.take(10).toList();
});

/// Unread notifications provider
final unreadNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications.where((notification) => !notification.read).toList();
});

/// Notifications by type provider
final notificationsByTypeProvider =
    FutureProvider.family<List<PushNotification>, ({String userId, PushNotificationType type})>(
        (ref, params) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(params.userId);
  return notifications.where((notification) => notification.type == params.type).toList();
});

/// High priority notifications provider
final highPriorityNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) =>
          notification.priority == PushNotificationPriority.high ||
          notification.priority == PushNotificationPriority.urgent)
      .toList();
});

/// Today's notifications provider
final todaysNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return notifications.where((notification) {
    return notification.createdAt.isAfter(startOfDay) && notification.createdAt.isBefore(endOfDay);
  }).toList();
});

/// This week's notifications provider
final thisWeekNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);

  final now = DateTime.now();
  final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

  return notifications.where((notification) {
    return notification.createdAt.isAfter(startOfWeekDay);
  }).toList();
});

/// This month's notifications provider
final thisMonthNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month);

  return notifications.where((notification) {
    return notification.createdAt.isAfter(startOfMonth);
  }).toList();
});

/// Notification types provider
final notificationTypesProvider = Provider<List<PushNotificationType>>((ref) {
  return PushNotificationType.values;
});

/// Notification priorities provider
final notificationPrioritiesProvider = Provider<List<PushNotificationPriority>>((ref) {
  return PushNotificationPriority.values;
});

/// Booking notifications provider
final bookingNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.booking)
      .toList();
});

/// Payment notifications provider
final paymentNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.payment)
      .toList();
});

/// Message notifications provider
final messageNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.message)
      .toList();
});

/// Review notifications provider
final reviewNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.review)
      .toList();
});

/// System notifications provider
final systemNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.system)
      .toList();
});

/// Promotion notifications provider
final promotionNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.promotion)
      .toList();
});

/// Reminder notifications provider
final reminderNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.reminder)
      .toList();
});

/// Request notifications provider
final requestNotificationsProvider =
    FutureProvider.family<List<PushNotification>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);
  return notifications
      .where((notification) => notification.type == PushNotificationType.request)
      .toList();
});

/// Notification statistics provider
final notificationStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.read(pushNotificationServiceProvider);
  final notifications = await service.getUserNotifications(userId);

  final totalNotifications = notifications.length;
  final unreadNotifications = notifications.where((n) => !n.read).length;
  final readNotifications = notifications.where((n) => n.read).length;

  final notificationsByType = <PushNotificationType, int>{};
  for (final type in PushNotificationType.values) {
    notificationsByType[type] = notifications.where((n) => n.type == type).length;
  }

  final notificationsByPriority = <PushNotificationPriority, int>{};
  for (final priority in PushNotificationPriority.values) {
    notificationsByPriority[priority] = notifications.where((n) => n.priority == priority).length;
  }

  final today = DateTime.now();
  final startOfDay = DateTime(today.year, today.month, today.day);
  final todaysNotifications = notifications.where((n) => n.createdAt.isAfter(startOfDay)).length;

  return {
    'totalNotifications': totalNotifications,
    'unreadNotifications': unreadNotifications,
    'readNotifications': readNotifications,
    'notificationsByType': notificationsByType,
    'notificationsByPriority': notificationsByPriority,
    'todaysNotifications': todaysNotifications,
  };
});
