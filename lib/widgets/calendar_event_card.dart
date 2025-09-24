import 'package:flutter/material.dart';

import '../models/calendar_event.dart';

/// Карточка события календаря
class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Цветовая полоска
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: event.eventColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Иконка события
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: event.eventColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  event.eventIcon,
                  color: event.eventColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Text(
                      event.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Время
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeRange(event.startDate, event.endDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    
                    // Описание (если есть)
                    if (event.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    // Местоположение (если есть)
                    if (event.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Статус и действия
              Column(
                children: [
                  // Статус
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(event.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getStatusColor(event.status),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Кнопки действий
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit, size: 16),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete, size: 16),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startTime = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endTime = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startTime - $endTime';
  }

  Color _getStatusColor(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.busy:
        return Colors.red;
      case CalendarEventStatus.free:
        return Colors.green;
      case CalendarEventStatus.tentative:
        return Colors.orange;
      case CalendarEventStatus.blocked:
        return Colors.grey;
      case CalendarEventStatus.personal:
        return Colors.blue;
    }
  }

  String _getStatusText(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.busy:
        return 'Занят';
      case CalendarEventStatus.free:
        return 'Свободен';
      case CalendarEventStatus.tentative:
        return 'Предварительно';
      case CalendarEventStatus.blocked:
        return 'Заблокирован';
      case CalendarEventStatus.personal:
        return 'Личное';
    }
  }
}

/// Компактная карточка события для списка
class CompactEventCard extends StatelessWidget {
  const CompactEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: event.eventColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: event.eventColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Цветовая точка
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: event.eventColor,
                shape: BoxShape.circle,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Время
            Text(
              _formatTime(event.startDate),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Заголовок
            Expanded(
              child: Text(
                event.title,
                style: theme.textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Виджет для отображения событий дня
class DayEventsWidget extends StatelessWidget {
  const DayEventsWidget({
    super.key,
    required this.events,
    this.onEventTap,
  });

  final List<CalendarEvent> events;
  final Function(CalendarEvent)? onEventTap;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'События (${events.length})',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...events.take(3).map((event) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: CompactEventCard(
            event: event,
            onTap: () => onEventTap?.call(event),
          ),
        )),
        if (events.length > 3)
          Text(
            'и еще ${events.length - 3} событий',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
      ],
    );
  }
}
