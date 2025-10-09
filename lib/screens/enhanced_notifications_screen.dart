import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_notification.dart';
import '../providers/auth_providers.dart';
import '../providers/enhanced_notifications_providers.dart';
import '../widgets/notification_card_widget.dart';

/// Расширенный экран уведомлений
class EnhancedNotificationsScreen extends ConsumerStatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  ConsumerState<EnhancedNotificationsScreen> createState() =>
      _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState
    extends ConsumerState<EnhancedNotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final String _selectedFilter = 'all';
  NotificationType? _selectedType;
  NotificationPriority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Уведомления'),
          actions: [
            IconButton(
              onPressed: _showFiltersDialog,
              icon: const Icon(Icons.filter_list),
            ),
            IconButton(
              onPressed: _showMarkAllReadDialog,
              icon: const Icon(Icons.mark_email_read),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все', icon: Icon(Icons.notifications)),
              Tab(text: 'Непрочитанные', icon: Icon(Icons.mark_email_unread)),
              Tab(text: 'Архив', icon: Icon(Icons.archive)),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAllNotificationsTab(),
            _buildUnreadNotificationsTab(),
            _buildArchivedNotificationsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _clearAllNotifications,
          tooltip: 'Очистить все',
          child: const Icon(Icons.clear_all),
        ),
      );

  Widget _buildAllNotificationsTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final notificationsAsync =
                  ref.watch(notificationsProvider(user.uid));

              return notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(notificationsProvider(user.uid));
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationCardWidget(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                          onMarkAsRead: () => _markAsRead(notification.id),
                          onArchive: () =>
                              _archiveNotification(notification.id),
                          onDelete: () => _deleteNotification(notification.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      );

  Widget _buildUnreadNotificationsTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final unreadNotificationsAsync =
                  ref.watch(unreadNotificationsProvider(user.uid));

              return unreadNotificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyUnreadState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(unreadNotificationsProvider(user.uid));
                    },
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationCardWidget(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                          onMarkAsRead: () => _markAsRead(notification.id),
                          onArchive: () =>
                              _archiveNotification(notification.id),
                          onDelete: () => _deleteNotification(notification.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      );

  Widget _buildArchivedNotificationsTab() => Consumer(
        builder: (context, ref, child) {
          final currentUser = ref.watch(currentUserProvider);

          return currentUser.when(
            data: (user) {
              if (user == null) {
                return _buildLoginPrompt();
              }

              final archivedNotificationsAsync =
                  ref.watch(archivedNotificationsProvider(user.uid));

              return archivedNotificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyArchivedState();
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(archivedNotificationsProvider(user.uid));
                    },
                    child: ListView.builder(
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return NotificationCardWidget(
                          notification: notification,
                          onTap: () => _handleNotificationTap(notification),
                          onMarkAsRead: () => _markAsRead(notification.id),
                          onArchive: () =>
                              _archiveNotification(notification.id),
                          onDelete: () => _deleteNotification(notification.id),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
          );
        },
      );

  Widget _buildEmptyState() => Center(
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
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Здесь будут отображаться ваши уведомления',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyUnreadState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Все уведомления прочитаны',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'У вас нет непрочитанных уведомлений',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildEmptyArchivedState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.archive,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Архив пуст',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Здесь будут отображаться архивированные уведомления',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildLoginPrompt() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Войдите в аккаунт',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Чтобы получать уведомления, необходимо войти в аккаунт',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
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
              'Ошибка загрузки',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final currentUser = ref.read(currentUserProvider).value;
                if (currentUser != null) {
                  ref.invalidate(notificationsProvider(currentUser.uid));
                }
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Фильтры'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<NotificationType?>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип уведомления',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все типы'),
                  ),
                  ...NotificationType.values.map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text('${type.icon} ${type.displayName}'),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<NotificationPriority?>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все приоритеты'),
                  ),
                  ...NotificationPriority.values.map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.displayName),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedType = null;
                  _selectedPriority = null;
                });
              },
              child: const Text('Сбросить'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyFilters();
              },
              child: const Text('Применить'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkAllReadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отметить все как прочитанные'),
        content: const Text(
            'Вы уверены, что хотите отметить все уведомления как прочитанные?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markAllAsRead();
            },
            child: const Text('Отметить все'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(EnhancedNotification notification) {
    // Отметить как прочитанное
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }

    // Навигация к соответствующему экрану
    if (notification.actionUrl != null) {
      // TODO: Навигация по actionUrl
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Переход к: ${notification.actionUrl}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _markAsRead(String notificationId) {
    final notificationsService = ref.read(enhancedNotificationsServiceProvider);
    notificationsService.markAsRead(notificationId).then((_) {
      // Обновить провайдеры
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.invalidate(notificationsProvider(currentUser.uid));
        ref.invalidate(unreadNotificationsProvider(currentUser.uid));
        ref.invalidate(notificationStatsProvider(currentUser.uid));
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _markAllAsRead() {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    final notificationsService = ref.read(enhancedNotificationsServiceProvider);
    notificationsService.markAllAsRead(currentUser.uid).then((_) {
      // Обновить провайдеры
      ref.invalidate(notificationsProvider(currentUser.uid));
      ref.invalidate(unreadNotificationsProvider(currentUser.uid));
      ref.invalidate(notificationStatsProvider(currentUser.uid));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Все уведомления отмечены как прочитанные'),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _archiveNotification(String notificationId) {
    final notificationsService = ref.read(enhancedNotificationsServiceProvider);
    notificationsService.archiveNotification(notificationId).then((_) {
      // Обновить провайдеры
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        ref.invalidate(notificationsProvider(currentUser.uid));
        ref.invalidate(archivedNotificationsProvider(currentUser.uid));
        ref.invalidate(notificationStatsProvider(currentUser.uid));
      }
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _deleteNotification(String notificationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить уведомление'),
        content: const Text('Вы уверены, что хотите удалить это уведомление?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final notificationsService =
                  ref.read(enhancedNotificationsServiceProvider);
              notificationsService.deleteNotification(notificationId).then((_) {
                // Обновить провайдеры
                final currentUser = ref.read(currentUserProvider).value;
                if (currentUser != null) {
                  ref.invalidate(notificationsProvider(currentUser.uid));
                  ref.invalidate(
                      archivedNotificationsProvider(currentUser.uid));
                  ref.invalidate(notificationStatsProvider(currentUser.uid));
                }
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все уведомления'),
        content: const Text(
            'Вы уверены, что хотите удалить все уведомления? Это действие необратимо.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final currentUser = ref.read(currentUserProvider).value;
              if (currentUser == null) return;

              final notificationsService =
                  ref.read(enhancedNotificationsServiceProvider);
              notificationsService
                  .clearAllNotifications(currentUser.uid)
                  .then((_) {
                // Обновить провайдеры
                ref.invalidate(notificationsProvider(currentUser.uid));
                ref.invalidate(unreadNotificationsProvider(currentUser.uid));
                ref.invalidate(archivedNotificationsProvider(currentUser.uid));
                ref.invalidate(notificationStatsProvider(currentUser.uid));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Все уведомления удалены'),
                  ),
                );
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: $error'),
                    backgroundColor: Colors.red,
                  ),
                );
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Очистить все'),
          ),
        ],
      ),
    );
  }

  void _applyFilters() {
    // TODO: Реализовать применение фильтров
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Фильтры применены'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
