import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/specialist_schedule.dart';
import '../services/specialist_schedule_service.dart';

/// Улучшенный календарь занятости
class EnhancedAvailabilityCalendar extends ConsumerStatefulWidget {
  const EnhancedAvailabilityCalendar({
    super.key,
    required this.specialistId,
    this.isOwnProfile = false,
    this.onDateSelected,
    this.onAvailabilityChanged,
  });

  final String specialistId;
  final bool isOwnProfile;
  final Function(DateTime)? onDateSelected;
  final Function(DateTime, bool)? onAvailabilityChanged;

  @override
  ConsumerState<EnhancedAvailabilityCalendar> createState() => _EnhancedAvailabilityCalendarState();
}

class _EnhancedAvailabilityCalendarState extends ConsumerState<EnhancedAvailabilityCalendar> {
  late final ValueNotifier<List<ScheduleEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<ScheduleEvent> _getEventsForDay(DateTime day) {
    // В реальном приложении здесь была бы загрузка событий из сервиса
    return [];
  }

  List<ScheduleEvent> _getEventsForRange(DateTime start, DateTime end) {
    // В реальном приложении здесь была бы загрузка событий за период
    return [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
      widget.onDateSelected?.call(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else {
      _selectedEvents.value = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        // Календарь
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<ScheduleEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: theme.colorScheme.error,
                ),
                holidayTextStyle: TextStyle(
                  color: theme.colorScheme.error,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                defaultDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                weekendDecoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: Colors.white,
                ),
              ),
              onDaySelected: _onDaySelected,
              onRangeSelected: _onRangeSelected,
              rangeSelectionMode: _rangeSelectionMode,
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
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayBuilder(context, day, focusedDay, DayType.available);
                },
                weekendBuilder: (context, day, focusedDay) {
                  return _buildDayBuilder(context, day, focusedDay, DayType.weekend);
                },
                holidayBuilder: (context, day, focusedDay) {
                  return _buildDayBuilder(context, day, focusedDay, DayType.holiday);
                },
                outsideBuilder: (context, day, focusedDay) {
                  return _buildDayBuilder(context, day, focusedDay, DayType.outside);
                },
                markerBuilder: (context, day, events) {
                  if (events.isNotEmpty) {
                    return Positioned(
                      bottom: 1,
                      child: _buildEventsMarker(events),
                    );
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
        
        // Легенда
        _buildLegend(theme),
        
        // События выбранного дня
        if (_selectedDay != null) ...[
          const SizedBox(height: 16),
          _buildSelectedDayEvents(theme),
        ],
        
        // Кнопки управления
        if (widget.isOwnProfile) ...[
          const SizedBox(height: 16),
          _buildManagementButtons(theme),
        ],
      ],
    );
  }

  Widget _buildDayBuilder(
    BuildContext context,
    DateTime day,
    DateTime focusedDay,
    DayType dayType,
  ) {
    final theme = Theme.of(context);
    final isToday = isSameDay(day, DateTime.now());
    final isSelected = isSameDay(day, _selectedDay);
    final isInRange = _rangeStart != null && _rangeEnd != null &&
        day.isAfter(_rangeStart!.subtract(const Duration(days: 1))) &&
        day.isBefore(_rangeEnd!.add(const Duration(days: 1)));

    Color? backgroundColor;
    Color? textColor;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.5);
      textColor = theme.colorScheme.onPrimary;
    } else if (isInRange) {
      backgroundColor = theme.colorScheme.primary.withOpacity(0.3);
      textColor = theme.colorScheme.onPrimary;
    } else {
      switch (dayType) {
        case DayType.available:
          backgroundColor = Colors.green.withOpacity(0.1);
          textColor = Colors.green;
          break;
        case DayType.busy:
          backgroundColor = Colors.red.withOpacity(0.1);
          textColor = Colors.red;
          break;
        case DayType.weekend:
          backgroundColor = Colors.orange.withOpacity(0.1);
          textColor = Colors.orange;
          break;
        case DayType.holiday:
          backgroundColor = Colors.purple.withOpacity(0.1);
          textColor = Colors.purple;
          break;
        case DayType.outside:
          backgroundColor = Colors.grey.withOpacity(0.1);
          textColor = Colors.grey;
          break;
      }
    }

    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            color: textColor,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEventsMarker(List<ScheduleEvent> events) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildLegend(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem('Свободен', Colors.green),
          _buildLegendItem('Занят', Colors.red),
          _buildLegendItem('Выходной', Colors.orange),
          _buildLegendItem('Праздник', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSelectedDayEvents(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ValueListenableBuilder<List<ScheduleEvent>>(
        valueListenable: _selectedEvents,
        builder: (context, events, _) {
          if (events.isEmpty) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.event_available,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Свободный день',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'На ${_formatDate(_selectedDay!)} нет запланированных событий',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'События на ${_formatDate(_selectedDay!)}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...events.map((event) => _buildEventItem(event, theme)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventItem(ScheduleEvent event, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getEventColor(event.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getEventColor(event.type).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getEventColor(event.type),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.isOwnProfile)
            IconButton(
              onPressed: () => _editEvent(event),
              icon: const Icon(Icons.edit, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildManagementButtons(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _addEvent,
              icon: const Icon(Icons.add),
              label: const Text('Добавить событие'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleAvailability,
              icon: const Icon(Icons.block),
              label: const Text('Заблокировать'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.booking:
        return Colors.blue;
      case ScheduleEventType.break:
        return Colors.orange;
      case ScheduleEventType.unavailable:
        return Colors.red;
      case ScheduleEventType.vacation:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}';
  }

  void _addEvent() {
    if (_selectedDay != null) {
      // Логика добавления события
      showDialog(
        context: context,
        builder: (context) => _buildAddEventDialog(),
      );
    }
  }

  void _editEvent(ScheduleEvent event) {
    // Логика редактирования события
  }

  void _toggleAvailability() {
    if (_selectedDay != null) {
      // Логика переключения доступности
      widget.onAvailabilityChanged?.call(_selectedDay!, true);
    }
  }

  Widget _buildAddEventDialog() {
    return AlertDialog(
      title: const Text('Добавить событие'),
      content: const Text('Форма добавления события (заглушка)'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

/// Тип дня в календаре
enum DayType {
  available,   // Доступен
  busy,        // Занят
  weekend,     // Выходной
  holiday,     // Праздник
  outside,     // Вне диапазона
}

/// Провайдер сервиса расписания специалиста
final specialistScheduleServiceProvider = Provider<SpecialistScheduleService>((ref) {
  return SpecialistScheduleService();
});
