import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_event_widget.dart';
import 'create_event_screen.dart';

/// Экран календаря
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({
    super.key,
    required this.userId,
    this.specialistId,
  });
  final String userId;
  final String? specialistId;

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final CalendarService _calendarService = CalendarService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _selectedEvents = [];

  CalendarFilter _filter = const CalendarFilter();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Календарь'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareEvents,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Экспорт'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'sync',
                  child: Row(
                    children: [
                      Icon(Icons.sync),
                      SizedBox(width: 8),
                      Text('Синхронизация'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Настройки'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Календарь
            _buildCalendar(),

            // Список событий
            Expanded(
              child: _buildEventsList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _createEvent,
          child: const Icon(Icons.add),
        ),
      );

  Widget _buildCalendar() => StreamBuilder<List<CalendarEvent>>(
        stream: _getEventsStream(),
        builder: (context, snapshot) {
          final events = snapshot.data ?? [];
          final eventSource = _getEventSource(events);

          return Card(
            margin: const EdgeInsets.all(8),
            child: TableCalendar<CalendarEvent>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: (day) => eventSource[day] ?? [],
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                markersMaxCount: 3,
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
              ),
              onDaySelected: (selectedDay, focusedDay) {
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvents = eventSource[selectedDay] ?? [];
                  });
                }
              },
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            ),
          );
        },
      );

  Widget _buildEventsList() => Column(
        children: [
          // Заголовок с количеством событий
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'События на ${_formatDate(_selectedDay!)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedEvents.length}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Список событий
          Expanded(
            child: _selectedEvents.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      return CalendarEventWidget(
                        event: event,
                        onTap: () => _showEventDetails(event),
                        onEdit: () => _editEvent(event),
                        onDelete: () => _deleteEvent(event),
                      );
                    },
                  ),
          ),
        ],
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Нет событий',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Нажмите + чтобы добавить событие',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createEvent,
              icon: const Icon(Icons.add),
              label: const Text('Добавить событие'),
            ),
          ],
        ),
      );

  Stream<List<CalendarEvent>> _getEventsStream() {
    if (widget.specialistId != null) {
      return _calendarService.getSpecialistEvents(
        widget.specialistId!,
        _filter,
      );
    } else {
      return _calendarService.getUserEvents(widget.userId, _filter);
    }
  }

  Map<DateTime, List<CalendarEvent>> _getEventSource(
    List<CalendarEvent> events,
  ) {
    final eventSource = <DateTime, List<CalendarEvent>>{};

    for (final event in events) {
      final day = DateTime(
        event.startTime.year,
        event.startTime.month,
        event.startTime.day,
      );
      if (eventSource[day] == null) {
        eventSource[day] = [];
      }
      eventSource[day]!.add(event);
    }

    return eventSource;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) {
      return 'Сегодня';
    } else if (date == yesterday) {
      return 'Вчера';
    } else if (date == tomorrow) {
      return 'Завтра';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  void _createEvent() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          userId: widget.userId,
          specialistId: widget.specialistId,
          selectedDate: _selectedDay,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _editEvent(CalendarEvent event) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateEventScreen(
          userId: widget.userId,
          specialistId: widget.specialistId,
          event: event,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _deleteEvent(CalendarEvent event) {
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
              final success = await _calendarService.deleteEvent(event.id);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Событие удалено')),
                );
                setState(() {});
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description.isNotEmpty) ...[
              const Text(
                'Описание:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(event.description),
              const SizedBox(height: 8),
            ],
            const Text('Время:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '${_formatDateTime(event.startTime)} - ${_formatDateTime(event.endTime)}',
            ),
            const SizedBox(height: 8),
            if (event.location.isNotEmpty) ...[
              const Text(
                'Место:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(event.location),
              const SizedBox(height: 8),
            ],
            const Text(
              'Статус:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_getStatusText(event.status)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editEvent(event);
            },
            child: const Text('Редактировать'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск событий'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите поисковый запрос...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _filter = _filter.copyWith(searchQuery: value);
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        filter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
        },
      ),
    );
  }

  Future<void> _shareEvents() async {
    final events = _selectedEvents;
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет событий для экспорта')),
      );
      return;
    }

    await _calendarService.shareEvents(events);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportEvents();
        break;
      case 'sync':
        _syncCalendar();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  Future<void> _exportEvents() async {
    final events = _selectedEvents;
    if (events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет событий для экспорта')),
      );
      return;
    }

    final icsContent = await _calendarService.exportToICS(events);
    if (icsContent != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('События экспортированы')),
      );
    }
  }

  void _syncCalendar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Синхронизация календаря'),
        content: const Text('Выберите календарь для синхронизации:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать синхронизацию с Google Calendar
            },
            child: const Text('Google Calendar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать синхронизацию с Outlook Calendar
            },
            child: const Text('Outlook Calendar'),
          ),
        ],
      ),
    );
  }

  void _showSettings() {
    // TODO: Реализовать настройки календаря
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Настройки календаря')),
    );
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

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

/// Диалог фильтра событий
class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.filter,
    required this.onFilterChanged,
  });
  final CalendarFilter filter;
  final Function(CalendarFilter) onFilterChanged;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late CalendarFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Фильтр событий'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Статусы
            const Text('Статус:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...EventStatus.values.map(
              (status) => CheckboxListTile(
                title: Text(_getStatusText(status)),
                value: _filter.statuses?.contains(status) ?? false,
                onChanged: (value) {
                  setState(() {
                    final statuses = _filter.statuses ?? [];
                    if (value ?? false) {
                      _filter =
                          _filter.copyWith(statuses: [...statuses, status]);
                    } else {
                      _filter = _filter.copyWith(
                        statuses: statuses.where((s) => s != status).toList(),
                      );
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 16),

            // Типы
            const Text('Тип:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...EventType.values.map(
              (type) => CheckboxListTile(
                title: Text(_getTypeText(type)),
                value: _filter.types?.contains(type) ?? false,
                onChanged: (value) {
                  setState(() {
                    final types = _filter.types ?? [];
                    if (value ?? false) {
                      _filter = _filter.copyWith(types: [...types, type]);
                    } else {
                      _filter = _filter.copyWith(
                        types: types.where((t) => t != type).toList(),
                      );
                    }
                  });
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onFilterChanged(_filter);
              Navigator.pop(context);
            },
            child: const Text('Применить'),
          ),
        ],
      );

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

  String _getTypeText(EventType type) {
    switch (type) {
      case EventType.booking:
        return 'Бронирование';
      case EventType.consultation:
        return 'Консультация';
      case EventType.meeting:
        return 'Встреча';
      case EventType.reminder:
        return 'Напоминание';
      case EventType.deadline:
        return 'Дедлайн';
    }
  }
}
