import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Провайдер для получения уведомлений
final notificationsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList(),
      );
});

/// Провайдер для подсчета непрочитанных уведомлений
final unreadNotificationsCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('notifications')
      .where('userId', isEqualTo: user.uid)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

/// Экран уведомлений
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notificationsAsync = ref.watch(notificationsProvider);
              return notificationsAsync.when(
                data: (notifications) {
                  final hasUnread = notifications.any((n) => !n['isRead']);
                  if (!hasUnread) return const SizedBox.shrink();

                  return TextButton(
                    onPressed: () => _markAllAsRead(ref),
                    child: const Text('Отметить все как прочитанные'),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Уведомлений пока нет',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItem(
                notification: notification,
                onTap: () => _handleNotificationTap(context, notification),
                onMarkAsRead: () => _markAsRead(ref, notification['id']),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки уведомлений',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Обработка нажатия на уведомление
  void _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    final type = notification['type'] as String?;
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    switch (type) {
      case 'chat':
        final chatId = data['chatId'] as String?;
        if (chatId != null) {
          context.push('/chat/$chatId');
        }
        break;
      case 'booking':
        context.push('/my-bookings');
        break;
      case 'review':
        context.push('/profile');
        break;
      default:
        // Остаемся на экране уведомлений
        break;
    }
  }

  /// Отметить уведомление как прочитанное
  void _markAsRead(WidgetRef ref, String notificationId) {
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  /// Отметить все уведомления как прочитанные
  void _markAllAsRead(WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get()
        .then((snapshot) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      batch.commit();
    });
  }
}

/// Виджет элемента уведомления
class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });
  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  @override
  Widget build(BuildContext context) {
    final isRead = notification['isRead'] as bool? ?? false;
    final title = notification['title'] as String? ?? '';
    final message = notification['message'] as String? ?? '';
    final timestamp = notification['timestamp'] as Timestamp?;
    final type = notification['type'] as String? ?? 'system';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isRead
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.1),
      child: ListTile(
        leading: _getNotificationIcon(type),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (timestamp != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
        trailing: isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.mark_email_read),
                onPressed: onMarkAsRead,
                tooltip: 'Отметить как прочитанное',
              ),
        onTap: onTap,
      ),
    );
  }

  /// Получение иконки для типа уведомления
  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'chat':
        iconData = Icons.chat;
        iconColor = Colors.blue;
        break;
      case 'booking':
        iconData = Icons.event;
        iconColor = Colors.green;
        break;
      case 'review':
        iconData = Icons.star;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  /// Форматирование времени
  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return DateFormat('dd.MM.yyyy HH:mm').format(date);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м назад';
    } else {
      return 'Только что';
    }
  }
}
