import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/event_providers.dart';
import '../models/user.dart';
import '../models/event.dart';
import '../services/event_service.dart';
import '../services/auth_service.dart';

/// Экран админ-панели
class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null || !user.isAdmin) {
            return const Center(
              child: Text('Доступ запрещен'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Статистика
                _buildStatsSection(context, ref),

                const SizedBox(height: 24),

                // Управление событиями
                _buildEventsManagementSection(context, ref),

                const SizedBox(height: 24),

                // Управление пользователями
                _buildUsersManagementSection(context, ref),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Статистика',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Всего событий',
                    '0', // TODO: Получить реальную статистику
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Активных событий',
                    '0', // TODO: Получить реальную статистику
                    Icons.event_available,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Всего пользователей',
                    '0', // TODO: Получить реальную статистику
                    Icons.people,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Заблокированных',
                    '0', // TODO: Получить реальную статистику
                    Icons.block,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsManagementSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление событиями',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Все события'),
              subtitle: const Text('Просмотр и управление всеми событиями'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _showAllEventsDialog(context, ref);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('События на модерации'),
              subtitle: const Text('События, требующие проверки'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Реализовать модерацию событий
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersManagementSection(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Управление пользователями',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Все пользователи'),
              subtitle: const Text('Просмотр и управление пользователями'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Реализовать управление пользователями
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Заблокированные пользователи'),
              subtitle: const Text('Управление заблокированными аккаунтами'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // TODO: Реализовать управление заблокированными пользователями
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Функция в разработке')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAllEventsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Все события',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Event>>(
                  stream: ref.read(eventServiceProvider).getAllEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Ошибка: ${snapshot.error}'),
                      );
                    }

                    final events = snapshot.data ?? [];

                    if (events.isEmpty) {
                      return const Center(
                        child: Text('События не найдены'),
                      );
                    }

                    return ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(event.categoryIcon),
                            title: Text(event.title),
                            subtitle: Text(
                                '${event.organizerName} • ${event.formattedDate}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'delete':
                                    _showDeleteEventDialog(context, ref, event);
                                    break;
                                  case 'block_organizer':
                                    _showBlockUserDialog(
                                        context, ref, event.organizerId);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Удалить событие'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'block_organizer',
                                  child: Row(
                                    children: [
                                      Icon(Icons.block, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Заблокировать организатора'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteEventDialog(
      BuildContext context, WidgetRef ref, Event event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие'),
        content:
            Text('Вы уверены, что хотите удалить событие "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(eventServiceProvider).deleteEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Событие удалено'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showBlockUserDialog(
      BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать пользователя'),
        content: const Text(
            'Вы уверены, что хотите заблокировать этого пользователя?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                // TODO: Реализовать блокировку пользователя
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Пользователь заблокирован'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }
}
