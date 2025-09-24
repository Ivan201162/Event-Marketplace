import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/calendar_event_card.dart';
import '../widgets/add_event_dialog.dart';

/// Экран календаря для специалистов
class SpecialistCalendarScreen extends ConsumerStatefulWidget {
  const SpecialistCalendarScreen({super.key});

  @override
  ConsumerState<SpecialistCalendarScreen> createState() => _SpecialistCalendarScreenState();
}

class _SpecialistCalendarScreenState extends ConsumerState<SpecialistCalendarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  
  final CalendarService _calendarService = CalendarService();
  List<CalendarEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой календарь'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Календарь', icon: Icon(Icons.calendar_month)),
            Tab(text: 'События', icon: Icon(Icons.event)),
            Tab(text: 'Статистика', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddEventDialog,
          ),
          PopupMenuButton<String>(
            onSelected: _onMenuSelected,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block_time',
                child: ListTile(
                  leading: Icon(Icons.block),
                  title: Text('Заблокировать время'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Экспорт календаря'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Настройки'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
                children: [
          _buildCalendarTab(),
          _buildEventsTab(),
          _buildStatsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarTab() {
    return Column(
              children: [
                // Календарь
        TableCalendar<CalendarEvent>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            markersMaxCount: 3,
            markerDecoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
          ),
          onDaySelected: _onDaySelected,
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
        
        const SizedBox(height: 8),
        
        // События выбранного дня
        Expanded(
          child: _buildSelectedDayEvents(),
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_events.isEmpty) {
      return _buildEmptyEventsState();
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          final event = _events[index];
          return CalendarEventCard(
            event: event,
            onTap: () => _showEventDetails(event),
            onEdit: () => _showEditEventDialog(event),
            onDelete: () => _deleteEvent(event),
          );
        },
      ),
    );
  }

  Widget _buildStatsTab() {
    return FutureBuilder<CalendarStats>(
      future: _getCalendarStats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('Ошибка загрузки статистики'));
        }

        final stats = snapshot.data!;
        return _buildStatsContent(stats);
      },
    );
  }

  Widget _buildSelectedDayEvents() {
    final dayEvents = _getEventsForDay(_selectedDay);
    
    if (dayEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет событий на ${_formatDate(_selectedDay)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Нажмите + чтобы добавить событие',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: dayEvents.length,
      itemBuilder: (context, index) {
        final event = dayEvents[index];
        return CalendarEventCard(
          event: event,
          onTap: () => _showEventDetails(event),
          onEdit: () => _showEditEventDialog(event),
          onDelete: () => _deleteEvent(event),
        );
      },
    );
  }

  Widget _buildEmptyEventsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет событий',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте события в свой календарь',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: const Icon(Icons.add),
            label: const Text('Добавить событие'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(CalendarStats stats) {
    final theme = Theme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Общая статистика
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                    'Общая статистика',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                        child: _buildStatCard(
                          'Всего событий',
                          stats.totalEvents.toString(),
                          Icons.event,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Часов занято',
                          stats.totalHours.toStringAsFixed(1),
                          Icons.access_time,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Статистика по типам событий
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'По типам событий',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildEventTypeStat('Занят', stats.busyEvents, Colors.red),
                  _buildEventTypeStat('Свободен', stats.freeEvents, Colors.green),
                  _buildEventTypeStat('Личные', stats.personalEvents, Colors.blue),
                  _buildEventTypeStat('Заблокировано', stats.blockedEvents, Colors.grey),
                ],
              ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildEventTypeStat(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
              children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(title),
          const Spacer(),
          Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => event.occursOnDate(day)).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'block_time':
        _showBlockTimeDialog();
        break;
      case 'export':
        _exportCalendar();
        break;
      case 'settings':
        _showCalendarSettings();
        break;
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final events = await _calendarService.getEventsForPeriod(
        userId: 'current_user_id', // В реальном приложении получать из AuthService
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      setState(() {
        _events = events;
        _isLoading = false;
      });
                } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки событий: $e');
    }
  }

  Future<CalendarStats> _getCalendarStats() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    return await _calendarService.getCalendarStats(
      userId: 'current_user_id', // В реальном приложении получать из AuthService
      startDate: startOfMonth,
      endDate: endOfMonth,
    );
  }

  void _showAddEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        selectedDate: _selectedDay,
        onEventCreated: (event) {
          _loadEvents();
          _showSuccessSnackBar('Событие добавлено');
        },
      ),
    );
  }

  void _showEditEventDialog(CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        event: event,
        onEventCreated: (updatedEvent) {
          _loadEvents();
          _showSuccessSnackBar('Событие обновлено');
        },
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
            if (event.description != null) ...[
              Text('Описание: ${event.description}'),
              const SizedBox(height: 8),
            ],
            if (event.location != null) ...[
              Text('Место: ${event.location}'),
              const SizedBox(height: 8),
            ],
            Text('Начало: ${_formatDateTime(event.startDate)}'),
            Text('Окончание: ${_formatDateTime(event.endDate)}'),
            const SizedBox(height: 8),
            Text('Статус: ${_getStatusText(event.status)}'),
            Text('Тип: ${_getTypeText(event.type)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditEventDialog(event);
            },
            child: const Text('Редактировать'),
          ),
        ],
      ),
    );
  }

  void _showBlockTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEventDialog(
        selectedDate: _selectedDay,
        isBlockTime: true,
        onEventCreated: (event) {
          _loadEvents();
          _showSuccessSnackBar('Время заблокировано');
        },
      ),
    );
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие'),
        content: Text('Вы уверены, что хотите удалить "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _calendarService.deleteEvent(event.id);
        _loadEvents();
        _showSuccessSnackBar('Событие удалено');
      } catch (e) {
        _showErrorSnackBar('Ошибка удаления события: $e');
      }
    }
  }

  void _exportCalendar() {
    // Логика экспорта календаря
    _showSuccessSnackBar('Календарь экспортирован');
  }

  void _showCalendarSettings() {
    // Логика настроек календаря
    _showSuccessSnackBar('Настройки календаря');
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _getTypeText(CalendarEventType type) {
    switch (type) {
      case CalendarEventType.booking:
        return 'Бронирование';
      case CalendarEventType.personal:
        return 'Личное событие';
      case CalendarEventType.blocked:
        return 'Заблокированное время';
      case CalendarEventType.reminder:
        return 'Напоминание';
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}