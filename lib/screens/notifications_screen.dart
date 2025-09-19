import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../providers/notification_providers.dart';

/// Экран уведомлений
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Отметить все как прочитанные',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAllNotifications,
            tooltip: 'Очистить все уведомления',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userNotificationsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _buildNotificationCard(notification);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(userNotificationsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет уведомлений',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут появляться важные уведомления',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );

  Widget _buildNotificationCard(AppNotification notification) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: notification.isRead ? 1 : 3,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Colors.grey[300]
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              _getNotificationIcon(notification.type),
              color: notification.isRead ? Colors.grey[600] : Colors.white,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.body),
              const SizedBox(height: 4),
              Text(
                _formatDateTime(notification.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
          onTap: () => _handleNotificationTap(notification),
        ),
      );

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.event;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.promotion:
        return Icons.local_offer;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    // Отмечаем как прочитанное
    if (!notification.isRead) {
      ref.read(notificationStateProvider.notifier).markAsRead(notification.id);
    }

    // Навигация в зависимости от типа уведомления
    switch (notification.type) {
      case NotificationType.booking:
        // Навигация к деталям бронирования
        break;
      case NotificationType.message:
        // Навигация к чату
        break;
      case NotificationType.payment:
        // Навигация к платежам
        break;
      case NotificationType.review:
        // Навигация к отзывам
        break;
      default:
        break;
    }
  }

  void _markAllAsRead() {
    ref.read(notificationStateProvider.notifier).markAllAsRead();
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все уведомления'),
        content: const Text('Вы уверены, что хотите удалить все уведомления?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(notificationStateProvider.notifier).clearAll();
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }
}
