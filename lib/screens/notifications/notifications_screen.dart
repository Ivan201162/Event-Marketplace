import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification.dart';
import '../../providers/auth_providers.dart';
import '../../services/notification_service.dart';
import '../../widgets/loading/loading_state_widget.dart';

/// Экран уведомлений
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Отметить все как прочитанные',
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('Войдите в аккаунт для просмотра уведомлений'),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _buildNotificationsList(user.uid),
            ),
          );
        },
        loading: () => const LoadingStateWidget(
          message: 'Загрузка уведомлений...',
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки уведомлений'),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationsList(String userId) {
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService.getUserNotificationsStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget(
            message: 'Загрузка уведомлений...',
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Ошибка загрузки уведомлений'),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final notifications = snapshot.data ?? [];

        if (notifications.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Нет уведомлений',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут появляться уведомления о новых заявках, сообщениях и обновлениях',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final theme = Theme.of(context);
    final isUnread = !notification.read;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 2 : 1,
      color: isUnread ? theme.primaryColor.withValues(alpha: 0.05) : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: isUnread
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'new_application':
        return Colors.blue;
      case 'new_message':
        return Colors.green;
      case 'new_idea':
        return Colors.orange;
      case 'booking_update':
        return Colors.purple;
      case 'system':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_application':
        return Icons.assignment;
      case 'new_message':
        return Icons.message;
      case 'new_idea':
        return Icons.lightbulb;
      case 'booking_update':
        return Icons.event;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
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

  void _handleNotificationTap(AppNotification notification) {
    // Отмечаем как прочитанное
    _markAsRead(notification.id);

    // Навигация на основе типа уведомления
    switch (notification.type) {
      case 'new_application':
        if (notification.targetId != null) {
          context.push('/applications/${notification.targetId}');
        }
        break;
      case 'new_message':
        if (notification.targetId != null) {
          context.push('/chat/${notification.targetId}');
        }
        break;
      case 'new_idea':
        if (notification.targetId != null) {
          context.push('/ideas/${notification.targetId}');
        }
        break;
      case 'booking_update':
        if (notification.targetId != null) {
          context.push('/bookings/${notification.targetId}');
        }
        break;
    }
  }

  void _markAsRead(String notificationId) {
    // TODO: Реализовать отметку уведомления как прочитанного
    debugPrint('Marking notification as read: $notificationId');
  }

  void _markAllAsRead() {
    // TODO: Реализовать отметку всех уведомлений как прочитанных
    debugPrint('Marking all notifications as read');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Все уведомления отмечены как прочитанные'),
        backgroundColor: Colors.green,
      ),
    );
  }
}