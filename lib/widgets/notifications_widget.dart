import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification.dart';
import '../providers/auth_providers.dart';
import '../providers/notification_providers.dart';

/// Виджет для отображения списка уведомлений
class NotificationsWidget extends ConsumerWidget {
  const NotificationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          // Кнопка "Отметить все как прочитанные"
          Consumer(
            builder: (context, ref, child) {
              final currentUser = ref.watch(currentUserProvider).value;
              if (currentUser == null) return const SizedBox.shrink();

              return unreadCount.when(
                data: (count) {
                  if (count == 0) return const SizedBox.shrink();

                  return TextButton(
                    onPressed: () async {
                      try {
                        await ref.read(
                          markAllNotificationsAsReadProvider(currentUser.id)
                              .future,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Все уведомления отмечены как прочитанные',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } on Exception catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Прочитать все'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: notifications.when(
        data: (notificationsList) {
          if (notificationsList.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            itemCount: notificationsList.length,
            itemBuilder: (context, index) {
              final notification = notificationsList[index];
              return NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, ref, notification),
                onDelete: () =>
                    _handleNotificationDelete(context, ref, notification),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Нет уведомлений',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Здесь будут появляться уведомления о новых заявках, отзывах и других событиях',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorState(BuildContext context, Object error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки уведомлений',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    // Отмечаем как прочитанное, если еще не прочитано
    if (!notification.isRead) {
      ref.read(markNotificationAsReadProvider(notification.id).future);
    }

    // Обрабатываем нажатие в зависимости от типа уведомления
    switch (notification.type) {
      case NotificationType.newBooking:
        // Переходим к заявке
        _navigateToBooking(context, notification.data['bookingId']);
        break;
      case NotificationType.bookingAccepted:
      case NotificationType.bookingRejected:
      case NotificationType.bookingCancelled:
        // Переходим к заявке
        _navigateToBooking(context, notification.data['bookingId']?.toString());
        break;
      case NotificationType.newReview:
        // Переходим к отзыву
        _navigateToReview(context, notification.data['reviewId']?.toString());
        break;
      case NotificationType.paymentReceived:
        // Переходим к платежу
        _navigateToPayment(context, notification.data['paymentId']?.toString());
        break;
      case NotificationType.reminder:
      case NotificationType.system:
        // Показываем детали уведомления
        _showNotificationDetails(context, notification);
        break;
    }
  }

  void _handleNotificationDelete(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить уведомление'),
        content: const Text('Вы уверены, что хотите удалить это уведомление?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(deleteNotificationProvider(notification.id).future);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Уведомление удалено'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ошибка удаления: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _navigateToBooking(BuildContext context, String? bookingId) {
    if (bookingId != null) {
      // TODO(developer): Реализовать навигацию к заявке
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Переход к заявке: $bookingId')),
      );
    }
  }

  void _navigateToReview(BuildContext context, String? reviewId) {
    if (reviewId != null) {
      // TODO(developer): Реализовать навигацию к отзыву
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Переход к отзыву: $reviewId')),
      );
    }
  }

  void _navigateToPayment(BuildContext context, String? paymentId) {
    if (paymentId != null) {
      // TODO(developer): Реализовать навигацию к платежу
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Переход к платежу: $paymentId')),
      );
    }
  }

  void _showNotificationDetails(
    BuildContext context,
    AppNotification notification,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            if (notification.createdAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Дата: ${_formatDate(notification.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

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
}

/// Виджет для отображения отдельного уведомления
class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: _buildNotificationIcon(context),
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
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatDate(notification.createdAt ?? DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                onDelete();
              }
            },
          ),
          onTap: onTap,
          tileColor:
              notification.isRead ? null : Colors.blue.withValues(alpha: 0.05),
        ),
      );

  Widget _buildNotificationIcon(BuildContext context) {
    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.newBooking:
        iconData = Icons.event;
        iconColor = Colors.blue;
        break;
      case NotificationType.bookingAccepted:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case NotificationType.bookingRejected:
        iconData = Icons.cancel;
        iconColor = Colors.red;
        break;
      case NotificationType.bookingCancelled:
        iconData = Icons.event_busy;
        iconColor = Colors.orange;
        break;
      case NotificationType.newReview:
        iconData = Icons.star;
        iconColor = Colors.amber;
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.payment;
        iconColor = Colors.green;
        break;
      case NotificationType.reminder:
        iconData = Icons.schedule;
        iconColor = Colors.purple;
        break;
      case NotificationType.system:
        iconData = Icons.info;
        iconColor = Colors.grey;
        break;
      case NotificationType.discount:
        iconData = Icons.local_offer;
        iconColor = Colors.green;
        break;
      case NotificationType.recommendation:
        iconData = Icons.lightbulb;
        iconColor = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

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
}
