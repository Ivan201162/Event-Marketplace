import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../widgets/available_time_slots_widget.dart';

/// Экран календаря для заказчиков
class CustomerCalendarScreen extends ConsumerStatefulWidget {
  const CustomerCalendarScreen({
    super.key,
    required this.specialistId,
    this.specialistName,
  });

  final String specialistId;
  final String? specialistName;

  @override
  ConsumerState<CustomerCalendarScreen> createState() => _CustomerCalendarScreenState();
}

class _CustomerCalendarScreenState extends ConsumerState<CustomerCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  
  final CalendarService _calendarService = CalendarService();
  List<CalendarEvent> _events = [];
  List<TimeSlot> _availableSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadSpecialistAvailability();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.specialistName ?? 'Календарь специалиста'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showSpecialistInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Календарь
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
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
              // Цветовая кодировка для заказчика
              defaultTextStyle: const TextStyle(color: Colors.black),
              weekendTextStyle: const TextStyle(color: Colors.red),
              holidayTextStyle: const TextStyle(color: Colors.red),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
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
              _loadSpecialistAvailability();
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            // Кастомизация отображения дней
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                final events = _getEventsForDay(day);
                final isAvailable = _isDayAvailable(day);
                
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isAvailable 
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isAvailable ? Colors.green : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: isAvailable ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                final isAvailable = _isDayAvailable(day);
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Легенда
          _buildLegend(),
          
          const SizedBox(height: 16),
          
          // Доступные слоты времени
          Expanded(
            child: _buildAvailableTimeSlots(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.green, 'Доступен'),
          _buildLegendItem(Colors.red, 'Занят'),
          _buildLegendItem(Colors.orange, 'Ограниченно'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
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

  Widget _buildAvailableTimeSlots() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableSlots.isEmpty) {
      return _buildNoAvailableSlots();
    }

    return AvailableTimeSlotsWidget(
      slots: _availableSlots,
      onSlotSelected: _onTimeSlotSelected,
    );
  }

  Widget _buildNoAvailableSlots() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Нет доступных слотов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'На ${_formatDate(_selectedDay)} нет свободного времени',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Выбрать другую дату
              _selectNextAvailableDate();
            },
            child: const Text('Выбрать другую дату'),
          ),
        ],
      ),
    );
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) => event.occursOnDate(day)).toList();
  }

  bool _isDayAvailable(DateTime day) {
    final events = _getEventsForDay(day);
    
    // Если нет событий, день доступен
    if (events.isEmpty) return true;
    
    // Проверяем, есть ли свободные слоты
    final busyEvents = events.where((event) => 
        event.status == CalendarEventStatus.busy || 
        event.status == CalendarEventStatus.blocked).toList();
    
    // Если все события заняты, день недоступен
    if (busyEvents.length == events.length) return false;
    
    // Если есть смешанные события, день ограниченно доступен
    return true;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _loadAvailableTimeSlots();
  }

  void _onTimeSlotSelected(TimeSlot slot) {
    _showBookingDialog(slot);
  }

  Future<void> _loadSpecialistAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final events = await _calendarService.getEventsForPeriod(
        userId: widget.specialistId,
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      setState(() {
        _events = events;
        _isLoading = false;
      });

      // Загружаем доступные слоты для выбранного дня
      _loadAvailableTimeSlots();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка загрузки календаря: $e');
    }
  }

  Future<void> _loadAvailableTimeSlots() async {
    try {
      final slots = await _calendarService.getAvailableTimeSlots(
        userId: widget.specialistId,
        date: _selectedDay,
        slotDuration: const Duration(hours: 1),
        workingHoursStart: const Duration(hours: 9),
        workingHoursEnd: const Duration(hours: 18),
      );

      setState(() {
        _availableSlots = slots;
      });
    } catch (e) {
      _showErrorSnackBar('Ошибка загрузки доступных слотов: $e');
    }
  }

  void _selectNextAvailableDate() {
    // Ищем следующую доступную дату
    var nextDate = _selectedDay.add(const Duration(days: 1));
    var attempts = 0;
    
    while (attempts < 30) { // Ищем в течение месяца
      if (_isDayAvailable(nextDate)) {
        setState(() {
          _selectedDay = nextDate;
          _focusedDay = nextDate;
        });
        _loadAvailableTimeSlots();
        return;
      }
      nextDate = nextDate.add(const Duration(days: 1));
      attempts++;
    }
    
    _showErrorSnackBar('Не найдено доступных дат в ближайший месяц');
  }

  void _showBookingDialog(TimeSlot slot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Забронировать время'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Специалист: ${widget.specialistName ?? 'Неизвестно'}'),
            const SizedBox(height: 8),
            Text('Дата: ${_formatDate(_selectedDay)}'),
            const SizedBox(height: 8),
            Text('Время: ${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}'),
            const SizedBox(height: 8),
            Text('Длительность: ${slot.duration.inHours} ч'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _proceedToBooking(slot);
            },
            child: const Text('Забронировать'),
          ),
        ],
      ),
    );
  }

  void _proceedToBooking(TimeSlot slot) {
    // Переход к экрану бронирования
    Navigator.pushNamed(
      context,
      '/booking',
      arguments: {
        'specialistId': widget.specialistId,
        'specialistName': widget.specialistName,
        'selectedDate': _selectedDay,
        'selectedSlot': slot,
      },
    );
  }

  void _showSpecialistInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Информация о специалисте'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Имя: ${widget.specialistName ?? 'Неизвестно'}'),
            const SizedBox(height: 8),
            Text('ID: ${widget.specialistId}'),
            const SizedBox(height: 8),
            const Text('Рабочие часы: 9:00 - 18:00'),
            const SizedBox(height: 8),
            const Text('Длительность слота: 1 час'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
