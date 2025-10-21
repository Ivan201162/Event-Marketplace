import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../models/user.dart' show AppUser, UserRole;
import '../providers/auth_providers.dart';
import '../providers/event_providers.dart';
import '../providers/user_role_provider.dart';
import 'create_event_screen.dart';
import 'event_detail_screen.dart';

class MyEventsScreen extends ConsumerWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(userRoleProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(userRole == UserRole.customer ? 'Мои мероприятия' : 'Мои проекты'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => const CreateEventScreen()),
              );
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Пользователь не найден'));
          }

          return userRole == UserRole.customer
              ? _buildCustomerEvents(context, ref, user)
              : _buildSpecialistProjects(context, ref, user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ошибка загрузки: $error')),
      ),
    );
  }

  Widget _buildCustomerEvents(BuildContext context, WidgetRef ref, AppUser user) {
    final userEvents = ref.watch(userEventsProvider(user.id));
    final userStats = ref.watch(userEventStatsProvider(user.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Статистика
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: userStats.when(
                data: (stats) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, 'Всего', "${stats['total'] ?? 0}", Icons.event),
                    _buildStatItem(
                      context,
                      'Активных',
                      "${stats['active'] ?? 0}",
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      context,
                      'Завершено',
                      "${stats['completed'] ?? 0}",
                      Icons.history,
                    ),
                    _buildStatItem(context, 'Отменено', "${stats['cancelled'] ?? 0}", Icons.cancel),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Ошибка загрузки статистики: $error'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Список мероприятий
          Expanded(
            child: userEvents.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'У вас пока нет мероприятий',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text('Создайте первое мероприятие', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(event.categoryIcon, color: Colors.white),
                        ),
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${event.formattedDate} • ${event.formattedTime}'),
                            const SizedBox(height: 4),
                            Text('${event.categoryName} • ${event.location}'),
                            const SizedBox(height: 4),
                            Text(event.formattedPrice),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: event.statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event.statusText,
                                    style: TextStyle(color: event.statusColor, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${event.currentParticipants}/${event.maxParticipants} участников',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showEventMenu(context, ref, event);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка загрузки мероприятий: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistProjects(BuildContext context, WidgetRef ref, AppUser user) {
    final userEvents = ref.watch(userEventsProvider(user.id));
    final userStats = ref.watch(userEventStatsProvider(user.id));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Статистика
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: userStats.when(
                data: (stats) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(context, 'Активных', "${stats['active'] ?? 0}", Icons.work),
                    _buildStatItem(
                      context,
                      'Завершено',
                      "${stats['completed'] ?? 0}",
                      Icons.check_circle,
                    ),
                    _buildStatItem(context, 'Всего', "${stats['total'] ?? 0}", Icons.event),
                    _buildStatItem(context, 'Отменено', "${stats['cancelled'] ?? 0}", Icons.cancel),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Text('Ошибка загрузки статистики: $error'),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Список проектов
          Expanded(
            child: userEvents.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'У вас пока нет проектов',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text('Создайте первый проект', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Icon(event.categoryIcon, color: Colors.white),
                        ),
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${event.formattedDate} • ${event.formattedTime}'),
                            const SizedBox(height: 4),
                            Text('${event.categoryName} • ${event.location}'),
                            const SizedBox(height: 4),
                            Text(event.formattedPrice),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: event.statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    event.statusText,
                                    style: TextStyle(color: event.statusColor, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${event.currentParticipants}/${event.maxParticipants} участников',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            _showEventMenu(context, ref, event);
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Ошибка загрузки проектов: $error')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) => Column(
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ],
  );

  void _showEventMenu(BuildContext context, WidgetRef ref, Event event) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('Просмотреть'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => EventDetailScreen(event: event)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Редактировать'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => CreateEventScreen(event: event)),
              );
            },
          ),
          if (event.status == EventStatus.active)
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Завершить', style: TextStyle(color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                _completeEvent(context, ref, event);
              },
            ),
          if (event.status == EventStatus.active)
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Отменить', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _cancelEvent(context, ref, event);
              },
            ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Удалить', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _deleteEvent(context, ref, event);
            },
          ),
        ],
      ),
    );
  }

  /// Завершить событие
  void _completeEvent(BuildContext context, WidgetRef ref, Event event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить мероприятие'),
        content: const Text('Вы уверены, что хотите завершить это мероприятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.updateEventStatus(event.id, EventStatus.completed);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Мероприятие завершено')));
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  /// Отменить событие
  void _cancelEvent(BuildContext context, WidgetRef ref, Event event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить мероприятие'),
        content: const Text('Вы уверены, что хотите отменить это мероприятие?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.updateEventStatus(event.id, EventStatus.cancelled);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Мероприятие отменено')));
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Отменить'),
          ),
        ],
      ),
    );
  }

  /// Удалить событие
  void _deleteEvent(BuildContext context, WidgetRef ref, Event event) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мероприятие'),
        content: const Text(
          'Вы уверены, что хотите удалить это мероприятие? Это действие нельзя будет отменить.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.deleteEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Мероприятие удалено')));
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
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
}
