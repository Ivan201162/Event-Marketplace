import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/availability_calendar.dart';
import '../services/availability_service.dart';

class AvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const AvailabilityCalendarScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends ConsumerState<AvailabilityCalendarScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final DateTime _rangeStart = DateTime.now();
  DateTime? _rangeEnd;

  List<AvailabilityCalendar> _availabilityData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadAvailabilityData();
  }

  Future<void> _loadAvailabilityData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      final data = await _availabilityService.getSpecialistAvailability(
        widget.specialistId,
        startDate: startDate,
        endDate: endDate,
      );

      setState(() {
        _availabilityData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Календарь доступности'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddBusyDateDialog,
              tooltip: 'Добавить занятую дату',
            ),
          ],
        ),
        body: Column(
          children: [
            // Календарь
            _buildCalendar(),

            // Детали выбранного дня
            if (_selectedDay != null) _buildSelectedDayDetails(),
          ],
        ),
      );

  Widget _buildCalendar() => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Заголовок календаря
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_getMonthName(_focusedDay.month)} ${_focusedDay.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                            );
                          });
                          _loadAvailabilityData();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                            );
                          });
                          _loadAvailabilityData();
                        },
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Календарь
              TableCalendar<AvailabilityCalendar>(
                firstDay: DateTime.utc(2020),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markersMaxCount: 1,
                  markerDecoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
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
                  _loadAvailabilityData();
                },
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    if (events.isEmpty) return null;

                    final availability = events.first;
                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: availability.isAvailable
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                      width: 8,
                      height: 8,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildSelectedDayDetails() {
    final selectedDate = _selectedDay!;
    final availability = _getAvailabilityForDay(selectedDate);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (availability == null)
              _buildAvailableDay()
            else
              _buildBusyDay(availability),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDay() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Text('Доступен'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _markDayAsBusy(_selectedDay!),
                icon: const Icon(Icons.block),
                label: const Text('Заблокировать'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Стандартные рабочие часы: 9:00 - 18:00',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );

  Widget _buildBusyDay(AvailabilityCalendar availability) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Занят'),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _unmarkDayAsBusy(_selectedDay!),
                icon: const Icon(Icons.check),
                label: const Text('Освободить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (availability.note != null) ...[
            const SizedBox(height: 8),
            Text('Примечание: ${availability.note}'),
          ],
          if (availability.timeSlots.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Временные слоты:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...availability.timeSlots.map(_buildTimeSlot),
          ],
        ],
      );

  Widget _buildTimeSlot(TimeSlot slot) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: slot.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
          border: Border.all(
            color: slot.isAvailable ? Colors.green : Colors.red,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              slot.isAvailable ? Icons.check_circle : Icons.block,
              color: slot.isAvailable ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            if (slot.note != null)
              Text(
                slot.note!,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
          ],
        ),
      );

  List<AvailabilityCalendar> _getEventsForDay(DateTime day) =>
      _availabilityData.where((availability) {
        final availabilityDate = DateTime(
          availability.date.year,
          availability.date.month,
          availability.date.day,
        );
        final targetDate = DateTime(day.year, day.month, day.day);
        return availabilityDate.isAtSameMomentAs(targetDate);
      }).toList();

  AvailabilityCalendar? _getAvailabilityForDay(DateTime day) {
    final events = _getEventsForDay(day);
    return events.isNotEmpty ? events.first : null;
  }

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

  String _formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  void _showAddBusyDateDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddBusyDateDialog(
        specialistId: widget.specialistId,
        onDateAdded: _loadAvailabilityData,
      ),
    );
  }

  Future<void> _markDayAsBusy(DateTime date) async {
    final note = await _showNoteDialog('Добавить примечание (необязательно)');

    final success = await _availabilityService.addBusyDate(
      widget.specialistId,
      date,
      note: note,
    );

    if (success) {
      _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата заблокирована')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка блокировки даты')),
        );
      }
    }
  }

  Future<void> _unmarkDayAsBusy(DateTime date) async {
    final success = await _availabilityService.removeBusyDate(
      widget.specialistId,
      date,
    );

    if (success) {
      _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дата освобождена')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка освобождения даты')),
        );
      }
    }
  }

  Future<String?> _showNoteDialog(String title) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Введите примечание',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }
}

class _AddBusyDateDialog extends StatefulWidget {
  const _AddBusyDateDialog({
    required this.specialistId,
    required this.onDateAdded,
  });
  final String specialistId;
  final VoidCallback onDateAdded;

  @override
  State<_AddBusyDateDialog> createState() => _AddBusyDateDialogState();
}

class _AddBusyDateDialogState extends State<_AddBusyDateDialog> {
  final AvailabilityService _availabilityService = AvailabilityService();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Добавить занятую дату'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Выбор даты
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Дата'),
              subtitle: Text(
                '${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
              ),
              onTap: _selectDate,
            ),

            const SizedBox(height: 16),

            // Примечание
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Примечание (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _addBusyDate,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Добавить'),
          ),
        ],
      );

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _addBusyDate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _availabilityService.addBusyDate(
        widget.specialistId,
        _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (success) {
        widget.onDateAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Дата добавлена')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка добавления даты')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
