import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/push_notification.dart';
import '../../providers/auth_providers.dart';
import '../../providers/push_notification_providers.dart';
import '../../widgets/notification_card.dart';

/// Screen for managing notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Все', icon: Icon(Icons.notifications)),
            Tab(text: 'Непрочитанные', icon: Icon(Icons.mark_email_unread)),
            Tab(text: 'Важные', icon: Icon(Icons.priority_high)),
            Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(userNotificationsProvider);
            },
          ),
          IconButton(icon: const Icon(Icons.mark_email_read), onPressed: () => _markAllAsRead()),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAllNotificationsTab(user.id),
              _buildUnreadNotificationsTab(user.id),
              _buildHighPriorityNotificationsTab(user.id),
              _buildStatisticsTab(user.id),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(currentUserProvider);
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllNotificationsTab(String userId) {
    final notificationsAsync = ref.watch(userNotificationsStreamProvider(userId));

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.notifications_none,
            title: 'Нет уведомлений',
            subtitle: 'Здесь будут отображаться ваши уведомления',
          );
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
              return NotificationCard(
                notification: notification,
                onTap: () => _showNotificationDetails(notification),
                onMarkAsRead: () => _markAsRead(notification.id),
                onDelete: () => _deleteNotification(notification.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildUnreadNotificationsTab(String userId) {
    final unreadNotificationsAsync = ref.watch(unreadNotificationsProvider(userId));

    return unreadNotificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.mark_email_read,
            title: 'Все уведомления прочитаны',
            subtitle: 'У вас нет непрочитанных уведомлений',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(unreadNotificationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _showNotificationDetails(notification),
                onMarkAsRead: () => _markAsRead(notification.id),
                onDelete: () => _deleteNotification(notification.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildHighPriorityNotificationsTab(String userId) {
    final highPriorityNotificationsAsync = ref.watch(highPriorityNotificationsProvider(userId));

    return highPriorityNotificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return _buildEmptyState(
            icon: Icons.priority_high,
            title: 'Нет важных уведомлений',
            subtitle: 'Здесь будут отображаться важные уведомления',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(highPriorityNotificationsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                notification: notification,
                onTap: () => _showNotificationDetails(notification),
                onMarkAsRead: () => _markAsRead(notification.id),
                onDelete: () => _deleteNotification(notification.id),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildStatisticsTab(String userId) {
    final statsAsync = ref.watch(notificationStatsProvider(userId));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(notificationStatsProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: statsAsync.when(
          data: (stats) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Всего',
                      stats['totalNotifications'] ?? 0,
                      Colors.blue,
                      Icons.notifications,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Непрочитанных',
                      stats['unreadNotifications'] ?? 0,
                      Colors.orange,
                      Icons.mark_email_unread,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Прочитанных',
                      stats['readNotifications'] ?? 0,
                      Colors.green,
                      Icons.mark_email_read,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Сегодня',
                      stats['todaysNotifications'] ?? 0,
                      Colors.purple,
                      Icons.today,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // By Type
              Text(
                'По типам',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._buildTypeStats(stats['notificationsByType'] ?? {}),
              const SizedBox(height: 24),
              // By Priority
              Text(
                'По приоритету',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ..._buildPriorityStats(stats['notificationsByPriority'] ?? {}),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTypeStats(Map<PushNotificationType, int> typeStats) {
    return PushNotificationType.values.map((type) {
      final count = typeStats[type] ?? 0;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Text(_getTypeIcon(type), style: const TextStyle(fontSize: 24)),
          title: Text(type.displayName),
          trailing: Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPriorityStats(Map<PushNotificationPriority, int> priorityStats) {
    return PushNotificationPriority.values.map((priority) {
      final count = priorityStats[priority] ?? 0;
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(_getPriorityIcon(priority), color: _getPriorityColor(priority)),
          title: Text(priority.displayName),
          trailing: Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ошибка загрузки уведомлений'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userNotificationsProvider);
            },
            child: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(PushNotification notification) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => NotificationDetailsSheet(notification: notification),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    final service = ref.read(pushNotificationServiceProvider);
    final success = await service.markAsRead(notificationId);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Уведомление отмечено как прочитанное')));
    }
  }

  Future<void> _markAllAsRead() async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final service = ref.read(pushNotificationServiceProvider);
    final success = await service.markAllAsRead(currentUser.id);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Все уведомления отмечены как прочитанные')));
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    final service = ref.read(pushNotificationServiceProvider);
    final success = await service.deleteNotification(notificationId);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Уведомление удалено')));
    }
  }

  String _getTypeIcon(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.booking:
        return '📅';
      case PushNotificationType.payment:
        return '💳';
      case PushNotificationType.message:
        return '💬';
      case PushNotificationType.review:
        return '⭐';
      case PushNotificationType.request:
        return '📋';
      case PushNotificationType.system:
        return '⚙️';
      case PushNotificationType.promotion:
        return '🎉';
      case PushNotificationType.reminder:
        return '⏰';
    }
  }

  IconData _getPriorityIcon(PushNotificationPriority priority) {
    switch (priority) {
      case PushNotificationPriority.low:
        return Icons.keyboard_arrow_down;
      case PushNotificationPriority.normal:
        return Icons.remove;
      case PushNotificationPriority.high:
        return Icons.keyboard_arrow_up;
      case PushNotificationPriority.urgent:
        return Icons.priority_high;
    }
  }

  Color _getPriorityColor(PushNotificationPriority priority) {
    switch (priority) {
      case PushNotificationPriority.low:
        return Colors.grey;
      case PushNotificationPriority.normal:
        return Colors.blue;
      case PushNotificationPriority.high:
        return Colors.orange;
      case PushNotificationPriority.urgent:
        return Colors.red;
    }
  }
}

/// Bottom sheet for displaying notification details
class NotificationDetailsSheet extends StatelessWidget {
  final PushNotification notification;

  const NotificationDetailsSheet({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(notification.typeIcon, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title, style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            notification.type.displayName,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(notification.priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.priority.displayName,
                        style: TextStyle(
                          color: _getPriorityColor(notification.priority),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text(notification.body, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    _buildDetailRow('ID уведомления', notification.id),
                    _buildDetailRow('Тип', notification.type.displayName),
                    _buildDetailRow('Приоритет', notification.priority.displayName),
                    _buildDetailRow('Статус', notification.read ? 'Прочитано' : 'Непрочитано'),
                    _buildDetailRow('Доставлено', notification.delivered ? 'Да' : 'Нет'),
                    _buildDetailRow('Создано', notification.formattedDateTime),
                    if (notification.readAt != null)
                      _buildDetailRow('Прочитано', _formatDateTime(notification.readAt!)),
                    if (notification.deliveredAt != null)
                      _buildDetailRow('Доставлено', _formatDateTime(notification.deliveredAt!)),
                    if (notification.senderName != null)
                      _buildDetailRow('Отправитель', notification.senderName!),
                    if (notification.actionUrl != null)
                      _buildDetailRow('Действие', notification.actionUrl!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(PushNotificationType type) {
    switch (type) {
      case PushNotificationType.booking:
        return Colors.blue;
      case PushNotificationType.payment:
        return Colors.green;
      case PushNotificationType.message:
        return Colors.purple;
      case PushNotificationType.review:
        return Colors.orange;
      case PushNotificationType.request:
        return Colors.teal;
      case PushNotificationType.system:
        return Colors.grey;
      case PushNotificationType.promotion:
        return Colors.pink;
      case PushNotificationType.reminder:
        return Colors.amber;
    }
  }

  Color _getPriorityColor(PushNotificationPriority priority) {
    switch (priority) {
      case PushNotificationPriority.low:
        return Colors.grey;
      case PushNotificationPriority.normal:
        return Colors.blue;
      case PushNotificationPriority.high:
        return Colors.orange;
      case PushNotificationPriority.urgent:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} в ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
