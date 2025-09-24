import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event_calendar.dart';
import '../services/event_calendar_service.dart';
import '../widgets/event_card.dart';
import '../widgets/add_event_dialog.dart';

/// Экран календаря событий
class EventCalendarScreen extends StatefulWidget {
  const EventCalendarScreen({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<EventCalendarScreen> createState() => _EventCalendarScreenState();
}

class _EventCalendarScreenState extends State<EventCalendarScreen>
    with TickerProviderStateMixin {
  final EventCalendarService _calendarService = EventCalendarService();
  
  late TabController _tabController;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  
  List<CalendarEvent> _events = [];
  List<CalendarEvent> _selectedEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month - 1, 1);
      final endOfMonth = DateTime(now.year, now.month + 2, 0);

      final events = await _calendarService.getEventsForPeriod(
        userId: widget.userId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      setState(() {
        _events = events;
        _isLoading = false;
        _updateSelectedEvents();
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки событий: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateSelectedEvents() {
    if (_selectedDay != null) {
      _selectedEvents = _events.where((event) {
        return event.date.year == _selectedDay!.year &&
               event.date.month == _selectedDay!.month &&
               event.date.day == _selectedDay!.day;
      }).toList();
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return event.date.year == day.year &&
             event.date.month == day.month &&
             event.date.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Календарь событий'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Календарь',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Список',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarTab(),
                _buildListTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(),
        child: const Icon(Icons.add),
      ),
    );

  Widget _buildCalendarTab() {
    return Column(
      children: [
        TableCalendar<CalendarEvent>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _updateSelectedEvents();
            });
          },
          onFormatChanged: (format) {
            setState(() {
              _calendarFormat = format;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() {
              _focusedDay = focusedDay;
            });
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
        ),
        const Divider(),
        Expanded(
          child: _buildSelectedDayEvents(),
        ),
      ],
    );
  }

  Widget _buildListTab() {
    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return EventCard(
            event: event,
            onTap: () => _showEventDetails(event),
            onEdit: () => _showEditEventDialog(event),
            onDelete: () => _deleteEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayEvents() {
    if (_selectedDay == null) {
      return const Center(
        child: Text('Выберите день для просмотра событий'),
      );
    }

    if (_selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'На ${_formatDate(_selectedDay!)} нет событий',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => _showAddEventDialog(),
              child: const Text('Добавить событие'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _selectedEvents.length,
      itemBuilder: (context, index) {
        final event = _selectedEvents[index];
        return EventCard(
          event: event,
          onTap: () => _showEventDetails(event),
          onEdit: () => _showEditEventDialog(event),
          onDelete: () => _deleteEvent(event),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        userId: widget.userId,
        initialDate: _selectedDay ?? DateTime.now(),
        onEventCreated: () {
          _loadEvents();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEditEventDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        userId: widget.userId,
        initialDate: event.date,
        existingEvent: event,
        onEventCreated: () {
          _loadEvents();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showEventDetails(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(event.type.icon),
            const SizedBox(width: 8),
            Expanded(child: Text(event.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null) ...[
              const Text(
                'Описание:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(event.description!),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(_formatDate(event.date)),
              ],
            ),
            if (event.location != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(event.location!)),
                ],
              ),
            ],
            if (event.reminderTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.alarm, size: 16),
                  const SizedBox(width: 8),
                  Text('Напоминание: ${_formatDate(event.reminderTime!)}'),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showEditEventDialog(event);
            },
            child: const Text('Редактировать'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие'),
        content: Text('Вы уверены, что хотите удалить событие "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarService.deleteEvent(event.id);
        _loadEvents();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Событие удалено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления события: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
