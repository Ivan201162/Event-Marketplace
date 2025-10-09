import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/specialist.dart';
import '../services/calendar_service.dart';

/// Виджет календаря для отображения занятых и свободных дат специалиста
class SpecialistCalendarWidget extends StatefulWidget {
  const SpecialistCalendarWidget({
    super.key,
    required this.specialist,
    this.onDateSelected,
    this.onDateTapped,
  });

  final Specialist specialist;
  final void Function(DateTime)? onDateSelected;
  final void Function(DateTime)? onDateTapped;

  @override
  State<SpecialistCalendarWidget> createState() =>
      _SpecialistCalendarWidgetState();
}

class _SpecialistCalendarWidgetState extends State<SpecialistCalendarWidget> {
  late final ValueNotifier<List<DateTime>> _selectedDates;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final CalendarService _calendarService = CalendarService();

  @override
  void initState() {
    super.initState();
    _selectedDates = ValueNotifier(_getSelectedDates());
  }

  @override
  void dispose() {
    _selectedDates.dispose();
    super.dispose();
  }

  List<DateTime> _getSelectedDates() => widget.specialist.busyDates;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Доступность специалиста',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Легенда
              _buildLegend(),
              const SizedBox(height: 16),

              // Календарь
              TableCalendar<DateTime>(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: const TextStyle(color: Colors.red),
                  holidayTextStyle: const TextStyle(color: Colors.red),
                  defaultTextStyle: const TextStyle(color: Colors.black),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 1,
                  markerSize: 6,
                  markerMargin: const EdgeInsets.symmetric(horizontal: 1),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  if (!isSameDay(_selectedDay, selectedDay)) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });

                    widget.onDateSelected?.call(selectedDay);
                  }
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) =>
                      _buildDayCell(day, focusedDay),
                  todayBuilder: (context, day, focusedDay) =>
                      _buildDayCell(day, focusedDay, isToday: true),
                  selectedBuilder: (context, day, focusedDay) =>
                      _buildDayCell(day, focusedDay, isSelected: true),
                  markerBuilder: (context, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 1,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Информация о выбранной дате
              if (_selectedDay != null) _buildSelectedDateInfo(),
            ],
          ),
        ),
      );

  Widget _buildLegend() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            color: Colors.green,
            label: 'Свободно',
            icon: Icons.check_circle,
          ),
          _buildLegendItem(
            color: Colors.red,
            label: 'Занято',
            icon: Icons.cancel,
          ),
          _buildLegendItem(
            color: Colors.orange,
            label: 'Сегодня',
            icon: Icons.today,
          ),
        ],
      );

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );

  Widget _buildDayCell(
    DateTime day,
    DateTime focusedDay, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final isBusy = widget.specialist.isDateBusy(day);
    final isPast =
        day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    var backgroundColor = Colors.transparent;
    var textColor = Colors.black;

    if (isSelected) {
      backgroundColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.orange;
      textColor = Colors.white;
    } else if (isBusy) {
      backgroundColor = Colors.red.withValues(alpha: 0.2);
      textColor = Colors.red;
    } else if (!isBusy && !isPast) {
      backgroundColor = Colors.green.withValues(alpha: 0.2);
      textColor = Colors.green;
    } else if (isPast) {
      textColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: isBusy ? Border.all(color: Colors.red, width: 2) : null,
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

  List<DateTime> _getEventsForDay(DateTime day) {
    if (widget.specialist.isDateBusy(day)) {
      return [day];
    }
    return [];
  }

  Widget _buildSelectedDateInfo() {
    final isBusy = widget.specialist.isDateBusy(_selectedDay!);
    final isPast = _selectedDay!
        .isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isBusy
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isBusy ? Colors.red : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isBusy ? Icons.cancel : Icons.check_circle,
            color: isBusy ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(_selectedDay!),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPast
                      ? 'Прошедшая дата'
                      : isBusy
                          ? 'Специалист занят в этот день'
                          : 'Специалист доступен для бронирования',
                  style: TextStyle(
                    color: isBusy ? Colors.red : Colors.green,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (!isBusy && !isPast)
            ElevatedButton(
              onPressed: () => widget.onDateTapped?.call(_selectedDay!),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Забронировать'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

/// Упрощенный виджет календаря для быстрого просмотра
class CompactSpecialistCalendarWidget extends StatelessWidget {
  const CompactSpecialistCalendarWidget({
    super.key,
    required this.specialist,
    this.onDateSelected,
  });

  final Specialist specialist;
  final void Function(DateTime)? onDateSelected;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 20,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Доступность',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Мини-календарь на текущий месяц
              _buildMiniCalendar(context),

              const SizedBox(height: 12),

              // Статистика
              _buildAvailabilityStats(),
            ],
          ),
        ),
      );

  Widget _buildMiniCalendar(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Заголовок месяца
        Text(
          _getMonthName(now.month),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),

        // Дни недели
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['П', 'В', 'С', 'Ч', 'П', 'С', 'В']
              .map(
                (day) => SizedBox(
                  width: 24,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),

        // Календарная сетка
        ...List.generate(
          6,
          (weekIndex) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 2;
              if (dayNumber < 1 || dayNumber > lastDayOfMonth.day) {
                return const SizedBox(width: 24, height: 24);
              }

              final day = DateTime(now.year, now.month, dayNumber);
              final isBusy = specialist.isDateBusy(day);
              final isToday = isSameDay(day, now);

              return GestureDetector(
                onTap: () => onDateSelected?.call(day),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isToday
                        ? Colors.orange
                        : isBusy
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.green.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: isBusy ? Border.all(color: Colors.red) : null,
                  ),
                  child: Center(
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 10,
                        color: isToday
                            ? Colors.white
                            : isBusy
                                ? Colors.red
                                : Colors.green,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityStats() {
    final now = DateTime.now();
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final totalDays = endOfMonth.day;
    final busyDays = specialist.busyDates
        .where((date) => date.year == now.year && date.month == now.month)
        .length;
    final availableDays = totalDays - busyDays;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('Свободно', availableDays, Colors.green),
        _buildStatItem('Занято', busyDays, Colors.red),
      ],
    );
  }

  Widget _buildStatItem(String label, int count, Color color) => Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      );

  String _getMonthName(int month) {
    const months = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    return months[month - 1];
  }
}

bool isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return false;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
