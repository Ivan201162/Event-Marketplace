import 'package:flutter/material.dart';
import '../models/calendar_event.dart';

/// Виджет календарного события
class CalendarEventWidget extends StatelessWidget {
  const CalendarEventWidget({
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
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Цветовая полоса
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: event.eventColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child:
                      Icon(event.eventIcon, color: event.eventColor, size: 20),
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
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // Время
                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(event.startTime, event.endTime),
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),

                      // Место
                      if (event.location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Статус
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(event.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _getStatusColor(event.status)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _getStatusText(event.status),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getStatusColor(event.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (event.isAllDay)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Весь день',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Действия
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit?.call();
                          break;
                        case 'delete':
                          onDelete?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Редактировать')
                            ],
                          ),
                        ),
                      if (onDelete != null)
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
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  String _formatTime(DateTime startTime, DateTime endTime) {
    if (startTime.day == endTime.day) {
      // Событие в один день
      return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Событие на несколько дней
      return '${startTime.day}.${startTime.month} - ${endTime.day}.${endTime.month}';
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return Colors.blue;
      case EventStatus.confirmed:
        return Colors.green;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.postponed:
        return Colors.orange;
    }
  }

  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return 'Запланировано';
      case EventStatus.confirmed:
        return 'Подтверждено';
      case EventStatus.cancelled:
        return 'Отменено';
      case EventStatus.completed:
        return 'Завершено';
      case EventStatus.postponed:
        return 'Перенесено';
    }
  }
}

/// Виджет для отображения события в списке
class CalendarEventListTile extends StatelessWidget {
  const CalendarEventListTile({
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
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: event.eventColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(event.eventIcon, color: event.eventColor, size: 20),
        ),
        title: Text(event.title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatTime(event.startTime, event.endTime)),
            if (event.location.isNotEmpty) Text(event.location),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(event.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color:
                        _getStatusColor(event.status).withValues(alpha: 0.3)),
              ),
              child: Text(
                _getStatusText(event.status),
                style: TextStyle(
                  fontSize: 12,
                  color: _getStatusColor(event.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Редактировать')
                        ],
                      ),
                    ),
                  if (onDelete != null)
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
              ),
            ],
          ],
        ),
        onTap: onTap,
      );

  String _formatTime(DateTime startTime, DateTime endTime) {
    if (startTime.day == endTime.day) {
      return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${startTime.day}.${startTime.month} - ${endTime.day}.${endTime.month}';
    }
  }

  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return Colors.blue;
      case EventStatus.confirmed:
        return Colors.green;
      case EventStatus.cancelled:
        return Colors.red;
      case EventStatus.completed:
        return Colors.grey;
      case EventStatus.postponed:
        return Colors.orange;
    }
  }

  String _getStatusText(EventStatus status) {
    switch (status) {
      case EventStatus.scheduled:
        return 'Запланировано';
      case EventStatus.confirmed:
        return 'Подтверждено';
      case EventStatus.cancelled:
        return 'Отменено';
      case EventStatus.completed:
        return 'Завершено';
      case EventStatus.postponed:
        return 'Перенесено';
    }
  }
}

/// Виджет для отображения события в календаре
class CalendarEventMarker extends StatelessWidget {
  const CalendarEventMarker({super.key, required this.event, this.onTap});
  final CalendarEvent event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
              color: event.eventColor, borderRadius: BorderRadius.circular(4)),
          child: Text(
            event.title,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
}
