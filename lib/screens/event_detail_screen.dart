import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event.dart';
import '../providers/auth_providers.dart';
import '../providers/event_providers.dart';
import 'create_event_screen.dart';

/// Экран детального просмотра события
class EventDetailScreen extends ConsumerWidget {
  final Event event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser.whenOrNull(
      data: (user) => user?.id == event.organizerId,
    ) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали мероприятия'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isOwner)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateEventScreen(event: event),
                      ),
                    );
                    break;
                  case 'delete':
                    _showDeleteDialog(context, ref);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Редактировать'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            _buildHeaderSection(context),
            
            const SizedBox(height: 24),
            
            // Основная информация
            _buildBasicInfoSection(context),
            
            const SizedBox(height: 24),
            
            // Дата и время
            _buildDateTimeSection(context),
            
            const SizedBox(height: 24),
            
            // Место проведения
            _buildLocationSection(context),
            
            const SizedBox(height: 24),
            
            // Цена и участники
            _buildPriceAndParticipantsSection(context),
            
            const SizedBox(height: 24),
            
            // Дополнительная информация
            if (event.contactInfo != null || event.requirements != null)
              _buildAdditionalInfoSection(context),
            
            if (event.contactInfo != null || event.requirements != null)
              const SizedBox(height: 24),
            
            // Кнопки действий
            _buildActionButtons(context, ref, isOwner),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.categoryIcon,
                  size: 32,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.categoryName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: event.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: event.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    event.statusText,
                    style: TextStyle(
                      color: event.statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Описание',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              event.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дата и время',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Дата начала'),
                    Text(
                      event.formattedDate,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      event.formattedTime,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            if (event.endDate != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.event_available, color: Colors.green),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Дата окончания'),
                      Text(
                        '${event.endDate!.day}.${event.endDate!.month}.${event.endDate!.year}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${event.endDate!.hour.toString().padLeft(2, '0')}:${event.endDate!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Место проведения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceAndParticipantsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Цена и участники',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money, color: Colors.green),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Цена'),
                          Text(
                            event.formattedPrice,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Участники'),
                          Text(
                            '${event.currentParticipants}/${event.maxParticipants}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.hasAvailableSpots) ...[
              const SizedBox(height: 8),
              Text(
                'Свободных мест: ${event.availableSpots}',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Мест нет',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дополнительная информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (event.contactInfo != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.contact_phone, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Контактная информация'),
                        Text(
                          event.contactInfo!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (event.requirements != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Требования к участникам'),
                        Text(
                          event.requirements!,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isOwner) {
    return Column(
      children: [
        if (isOwner) ...[
          // Кнопки для организатора
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEventScreen(event: event),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Редактировать мероприятие'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (event.status == EventStatus.active) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _completeEvent(context, ref),
                icon: const Icon(Icons.check_circle),
                label: const Text('Завершить мероприятие'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _cancelEvent(context, ref),
                icon: const Icon(Icons.cancel),
                label: const Text('Отменить мероприятие'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showDeleteDialog(context, ref),
              icon: const Icon(Icons.delete),
              label: const Text('Удалить мероприятие'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ] else ...[
          // Кнопки для участника
          if (event.status == EventStatus.active && event.hasAvailableSpots) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Реализовать бронирование
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Функция бронирования будет реализована в следующих шагах')),
                  );
                },
                icon: const Icon(Icons.book_online),
                label: const Text('Забронировать участие'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ] else if (event.status == EventStatus.active && !event.hasAvailableSpots) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Мест нет',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  void _completeEvent(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Завершить мероприятие'),
        content: const Text('Вы уверены, что хотите завершить это мероприятие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.updateEventStatus(event.id, EventStatus.completed);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Мероприятие завершено')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  void _cancelEvent(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отменить мероприятие'),
        content: const Text('Вы уверены, что хотите отменить это мероприятие?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.updateEventStatus(event.id, EventStatus.cancelled);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Мероприятие отменено')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить мероприятие'),
        content: const Text('Вы уверены, что хотите удалить это мероприятие? Это действие нельзя будет отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final eventService = ref.read(eventServiceProvider);
                await eventService.deleteEvent(event.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Мероприятие удалено')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
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
}
