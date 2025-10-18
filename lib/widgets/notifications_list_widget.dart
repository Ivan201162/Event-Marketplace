import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';

/// Виджет для отображения списка уведомлений
class NotificationsListWidget extends StatefulWidget {
  const NotificationsListWidget({
    super.key,
    required this.userId,
    this.onNotificationTap,
  });

  final String userId;
  final void Function(Map<String, dynamic>)? onNotificationTap;

  @override
  State<NotificationsListWidget> createState() => _NotificationsListWidgetState();
}

class _NotificationsListWidgetState extends State<NotificationsListWidget> {
  @override
  Widget build(BuildContext context) => StreamBuilder<List<AppNotification>>(
        stream: NotificationService.getUserNotifications(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingWidget();
          }

          if (snapshot.hasError) {
            return _ErrorWidget(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const _EmptyWidget();
          }

          return _NotificationsList(
            notifications: notifications,
            onNotificationTap: widget.onNotificationTap,
            onMarkAsRead: _markAsRead,
            onMarkAllAsRead: _markAllAsRead,
          );
        },
      );

  Future<void> _markAsRead(String notificationId) async {
    try {
      await NotificationService.markAsRead(notificationId);
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка отметки уведомления: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead(widget.userId);
      _showSuccessSnackBar('Все уведомления отмечены как прочитанные');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка отметки всех уведомлений: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Виджет загрузки
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
}

/// Виджет ошибки
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки уведомлений',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
}

/// Виджет пустого состояния
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Нет уведомлений',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Здесь будут отображаться ваши уведомления',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

/// Список уведомлений
class _NotificationsList extends StatelessWidget {
  const _NotificationsList({
    required this.notifications,
    this.onNotificationTap,
    required this.onMarkAsRead,
    required this.onMarkAllAsRead,
  });

  final List<AppNotification> notifications;
  final void Function(AppNotification)? onNotificationTap;
  final void Function(String) onMarkAsRead;
  final VoidCallback onMarkAllAsRead;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () {
                    if (!notification.isRead) {
                      onMarkAsRead(notification.id);
                    }
                    onNotificationTap?.call(notification);
                  },
                );
              },
            ),
          ),
        ],
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Text(
              'Уведомления',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onMarkAllAsRead,
              child: const Text('Отметить все как прочитанные'),
            ),
          ],
        ),
      );
}

/// Карточка уведомления
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: notification.isRead ? 1 : 2,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatDate(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case 'new_booking':
        iconData = Icons.event;
        iconColor = Colors.green;
        break;
      case 'discount_offer':
        iconData = Icons.local_offer;
        iconColor = Colors.orange;
        break;
      case 'booking_confirmed':
        iconData = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
}

/// Форматирование даты
String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

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
