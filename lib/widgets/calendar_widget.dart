import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/calendar_providers.dart';
import '../models/specialist_schedule.dart';
import '../services/firestore_service.dart';
import '../providers/firestore_providers.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final String specialistId;
  final DateTime? initialDate;
  final Function(DateTime)? onDateSelected;
  final bool showEvents;
  final bool showTimeSlots;

  const CalendarWidget({
    super.key,
    required this.specialistId,
    this.initialDate,
    this.onDateSelected,
    this.showEvents = true,
    this.showTimeSlots = false,
  });

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    final scheduleAsync = ref.watch(specialistScheduleProvider(widget.specialistId));
    final busyDatesAsync = ref.watch(busyDatesProvider(widget.specialistId));
    final busyDateRangesAsync = ref.watch(busyDateRangesProvider(widget.specialistId));
    final calendarState = ref.watch(calendarStateProvider);

    return Column(
      children: [
        // Календарь
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TableCalendar<ScheduleEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              eventLoader: (day) => _getEventsForDay(day, scheduleAsync),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                holidayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                canMarkersOverflow: true,
                // Стили для занятых дат
                disabledDecoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                disabledTextStyle: TextStyle(
                  color: Colors.grey.withOpacity(0.6),
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                // Проверяем, не занята ли дата
                if (_isDateBusy(selectedDay, busyDatesAsync)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Эта дата уже занята'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (!isSameDay(_selectedDay, selectedDay)) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  
                  // Обновляем состояние календаря
                  ref.read(calendarStateProvider.notifier).selectDate(selectedDay);
                  
                  // Вызываем callback
                  widget.onDateSelected?.call(selectedDay);
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
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  
                  return Positioned(
                    right: 1,
                    bottom: 1,
                    child: _buildEventMarker(events),
                  );
                },
                dowBuilder: (context, day) {
                  final text = _getDayName(day.weekday);
                  return Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  );
                },
                // Кастомный билдер для дней
                defaultBuilder: (context, day, focusedDay) {
                  final isBusy = _isDateBusy(day, busyDatesAsync);
                  final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
                  
                  return Container(
                    margin: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: isBusy 
                          ? Colors.red.withOpacity(0.3)
                          : isPast 
                              ? Colors.grey.withOpacity(0.2)
                              : null,
                      shape: BoxShape.circle,
                      border: isBusy 
                          ? Border.all(color: Colors.red, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isBusy 
                              ? Colors.red
                              : isPast 
                                  ? Colors.grey
                                  : null,
                          fontWeight: isBusy ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // События на выбранную дату
        if (widget.showEvents && _selectedDay != null) ...[
          _buildEventsForSelectedDay(scheduleAsync),
          const SizedBox(height: 16),
        ],
        
        // Временные слоты
        if (widget.showTimeSlots && _selectedDay != null) ...[
          _buildTimeSlotsForSelectedDay(),
        ],
      ],
    );
  }

  /// Получить события для дня
  List<ScheduleEvent> _getEventsForDay(DateTime day, AsyncValue<SpecialistSchedule?> scheduleAsync) {
    return scheduleAsync.when(
      data: (schedule) {
        if (schedule == null) return [];
        return schedule.getEventsForDate(day);
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Построить маркер события
  Widget _buildEventMarker(List<ScheduleEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: _getEventColor(events.first.type),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          events.length.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// Получить цвет события
  Color _getEventColor(ScheduleEventType type) {
    switch (type) {
      case ScheduleEventType.booking:
        return Colors.blue;
      case ScheduleEventType.unavailable:
        return Colors.red;
      case ScheduleEventType.vacation:
        return Colors.green;
      case ScheduleEventType.maintenance:
        return Colors.orange;
    }
  }

  /// Получить название дня недели
  String _getDayName(int weekday) {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[weekday - 1];
  }

  /// Построить события на выбранную дату
  Widget _buildEventsForSelectedDay(AsyncValue<SpecialistSchedule?> scheduleAsync) {
    return scheduleAsync.when(
      data: (schedule) {
        if (schedule == null || _selectedDay == null) {
          return const SizedBox.shrink();
        }
        
        final events = schedule.getEventsForDate(_selectedDay!);
        
        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.event_available,
                    color: Colors.green,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'На эту дату нет событий',
                    style: Theme.of(context).textTheme.bodyLarge,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...events.map((event) => _buildEventItem(event)),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ошибка загрузки событий: $error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить элемент события
  Widget _buildEventItem(ScheduleEvent event) {
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
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getEventColor(event.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (event.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_formatTime(event.startTime)} - ${_formatTime(event.endTime)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Построить временные слоты на выбранную дату
  Widget _buildTimeSlotsForSelectedDay() {
    final timeSlotsAsync = ref.watch(availableTimeSlotsProvider(
      AvailableTimeSlotsParams(
        specialistId: widget.specialistId,
        date: _selectedDay!,
      ),
    ));

    return timeSlotsAsync.when(
      data: (timeSlots) {
        if (timeSlots.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange),
                  const SizedBox(width: 12),
                  Text('Нет доступных временных слотов'),
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
                  'Доступные временные слоты',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: timeSlots.map((slot) => _buildTimeSlotChip(slot)).toList(),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ошибка загрузки временных слотов: $error',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Построить чип временного слота
  Widget _buildTimeSlotChip(DateTime timeSlot) {
    return ActionChip(
      label: Text(_formatTime(timeSlot)),
      onPressed: () {
        // TODO: Обработка выбора временного слота
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Выбран слот: ${_formatTime(timeSlot)}')),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Форматировать время
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Проверить, занята ли дата
  bool _isDateBusy(DateTime date, AsyncValue<List<DateTime>> busyDatesAsync) {
    return busyDatesAsync.when(
      data: (busyDates) {
        return busyDates.any((busyDate) => 
          busyDate.year == date.year &&
          busyDate.month == date.month &&
          busyDate.day == date.day
        );
      },
      loading: () => false,
      error: (_, __) => false,
    );
  }
}
