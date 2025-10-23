import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../services/notification_service.dart';

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// User's notifications provider
final userNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((
  ref,
  userId,
) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUserNotifications(userId);
});

/// Unread notifications provider
final unreadNotificationsProvider =
    FutureProvider.family<List<AppNotification>, String>((
  ref,
  userId,
) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadNotifications(userId);
});

/// Notifications by type provider
final notificationsByTypeProvider = FutureProvider.family<List<AppNotification>,
    ({String userId, NotificationType type})>((
  ref,
  params,
) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotificationsByType(params.userId, params.type);
});

/// Notification by ID provider
final notificationByIdProvider =
    FutureProvider.family<AppNotification?, String>((
  ref,
  notificationId,
) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getNotificationById(notificationId);
});

/// Stream of user's notifications provider
final userNotificationsStreamProvider =
    StreamProvider.family<List<AppNotification>, String>((
  ref,
  userId,
) {
  final service = ref.read(notificationServiceProvider);
  return service.getUserNotificationsStream(userId);
});

/// Stream of unread notifications provider
final unreadNotificationsStreamProvider =
    StreamProvider.family<List<AppNotification>, String>((
  ref,
  userId,
) {
  final service = ref.read(notificationServiceProvider);
  return service.getUnreadNotificationsStream(userId);
});

/// Unread count provider
final unreadCountProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.read(notificationServiceProvider);
  return await service.getUnreadCount(userId);
});

/// Stream of unread count provider
final unreadCountStreamProvider =
    StreamProvider.family<int, String>((ref, userId) {
  final service = ref.read(notificationServiceProvider);
  return service.getUnreadCountStream(userId);
});
