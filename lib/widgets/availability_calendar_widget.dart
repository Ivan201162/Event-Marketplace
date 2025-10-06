import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Виджет календаря занятости специалиста
class AvailabilityCalendarWidget extends StatefulWidget {
  const AvailabilityCalendarWidget({
    super.key,
    required this.busyDates,
    this.availableDates = const [],
    this.onDateSelected,
    this.isReadOnly = true,
  });
  final List<DateTime> busyDates;
  final List<DateTime> availableDates;
  final Function(DateTime)? onDateSelected;
  final bool isReadOnly;

  @override
  State<AvailabilityCalendarWidget> createState() =>
      _AvailabilityCalendarWidgetState();
}

class _AvailabilityCalendarWidgetState
    extends State<AvailabilityCalendarWidget> {
  late final ValueNotifier<List<DateTime>> _selectedDates;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDates = ValueNotifier([]);
  }

  @override
  void dispose() {
    _selectedDates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Легенда
          _buildLegend(),

          const SizedBox(height: 16),

          // Календарь
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TableCalendar<DateTime>(
              firstDay: DateTime.utc(2020),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedDay != null && isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (!widget.isReadOnly) {
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
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                weekendTextStyle: const TextStyle(color: Colors.red),
                holidayTextStyle: const TextStyle(color: Colors.red),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Colors.blue.shade200,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day),
                todayBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, isToday: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _buildDayCell(day, isSelected: true),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Статистика
          _buildStatistics(),
        ],
      );

  Widget _buildLegend() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(
              color: Colors.green,
              label: 'Свободен',
            ),
            _buildLegendItem(
              color: Colors.red,
              label: 'Занят',
            ),
            _buildLegendItem(
              color: Colors.blue,
              label: 'Выбран',
            ),
          ],
        ),
      );

  Widget _buildLegendItem({
    required Color color,
    required String label,
  }) =>
      Row(
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

  Widget _buildDayCell(
    DateTime day, {
    bool isToday = false,
    bool isSelected = false,
  }) {
    final isBusy = _isDateBusy(day);
    final isAvailable = _isDateAvailable(day);

    var backgroundColor = Colors.transparent;
    var textColor = Colors.black;

    if (isSelected) {
      backgroundColor = Colors.blue;
      textColor = Colors.white;
    } else if (isToday) {
      backgroundColor = Colors.blue.shade200;
      textColor = Colors.blue.shade800;
    } else if (isBusy) {
      backgroundColor = Colors.red.shade100;
      textColor = Colors.red.shade700;
    } else if (isAvailable) {
      backgroundColor = Colors.green.shade100;
      textColor = Colors.green.shade700;
    }

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
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

  Widget _buildStatistics() {
    final totalDays = DateTime.now()
        .difference(DateTime.now().subtract(const Duration(days: 30)))
        .inDays;
    final busyDays = widget.busyDates.length;
    final availableDays = widget.availableDates.length;
    final freeDays = totalDays - busyDays;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Статистика за последние 30 дней',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Занятых дней',
                  busyDays,
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Свободных дней',
                  freeDays,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) => Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  bool _isDateBusy(DateTime date) => widget.busyDates.any(
        (busyDate) =>
            busyDate.year == date.year &&
            busyDate.month == date.month &&
            busyDate.day == date.day,
      );

  bool _isDateAvailable(DateTime date) => widget.availableDates.any(
        (availableDate) =>
            availableDate.year == date.year &&
            availableDate.month == date.month &&
            availableDate.day == date.day,
      );
}
