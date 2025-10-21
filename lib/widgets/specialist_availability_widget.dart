import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/availability_calendar.dart';
import '../services/availability_service.dart';

class SpecialistAvailabilityWidget extends ConsumerStatefulWidget {
  // Является ли текущий пользователь владельцем профиля

  const SpecialistAvailabilityWidget({super.key, required this.specialistId, this.isOwner = false});
  final String specialistId;
  final bool isOwner;

  @override
  ConsumerState<SpecialistAvailabilityWidget> createState() => _SpecialistAvailabilityWidgetState();
}

class _SpecialistAvailabilityWidgetState extends ConsumerState<SpecialistAvailabilityWidget> {
  final AvailabilityService _availabilityService = AvailabilityService();

  DateTime _focusedDay = DateTime.now();
  List<AvailabilityCalendar> _availabilityData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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
    }
  }

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
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  const Text(
                    'Календарь доступности',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (widget.isOwner)
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _openCalendarSettings,
                      tooltip: 'Настройки календаря',
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Календарь
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildCompactCalendar(),
            ],
          ),
        ),
      );

  Widget _buildCompactCalendar() => TableCalendar<AvailabilityCalendar>(
        firstDay: DateTime.utc(2020),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          markersMaxCount: 1,
          markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          cellMargin: EdgeInsets.all(2),
          cellPadding: EdgeInsets.all(4),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(Icons.chevron_left, size: 20),
          rightChevronIcon: Icon(Icons.chevron_right, size: 20),
          titleTextStyle: TextStyle(fontSize: 16),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _showDayDetails(selectedDay);
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
          _loadAvailabilityData();
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) {
              return null;
            }

            final availability = events.first;
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: availability.isAvailable ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              width: 6,
              height: 6,
            );
          },
          todayBuilder: (context, day, focusedDay) {
            final isToday = isSameDay(day, DateTime.now());
            if (!isToday) {
              return null;
            }

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            );
          },
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

  void _showDayDetails(DateTime day) {
    final events = _getEventsForDay(day);
    final availability = events.isNotEmpty ? events.first : null;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${day.day} ${_getMonthName(day.month)} ${day.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (availability == null) ...[
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Доступен'),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Стандартные рабочие часы: 9:00 - 18:00',
                style: TextStyle(color: Colors.grey),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(
                    availability.isAvailable ? Icons.check_circle : Icons.block,
                    color: availability.isAvailable ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(availability.isAvailable ? 'Доступен' : 'Занят'),
                ],
              ),
              if (availability.note != null) ...[
                const SizedBox(height: 8),
                Text('Примечание: ${availability.note}'),
              ],
              if (availability.timeSlots.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Временные слоты:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...availability.timeSlots.map(_buildTimeSlotInfo),
              ],
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Закрыть')),
          if (widget.isOwner) ...[
            if (availability == null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _markDayAsBusy(day);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Заблокировать'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _unmarkDayAsBusy(day);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Освободить'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSlotInfo(TimeSlot slot) => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: slot.isAvailable ? Colors.green.shade50 : Colors.red.shade50,
          border: Border.all(color: slot.isAvailable ? Colors.green : Colors.red),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              slot.isAvailable ? Icons.check_circle : Icons.block,
              color: slot.isAvailable ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '${_formatTime(slot.startTime)} - ${_formatTime(slot.endTime)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (slot.note != null) ...[
              const Spacer(),
              Text(slot.note!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ],
        ),
      );

  void _openCalendarSettings() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Календарь доступности')),
          body: const Center(child: Text('Календарь доступности в разработке')),
        ),
      ),
    );
  }

  Future<void> _markDayAsBusy(DateTime date) async {
    final note = await _showNoteDialog('Добавить примечание (необязательно)');

    final success = await _availabilityService.addBusyDate(widget.specialistId, date, note: note);

    if (success) {
      await _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Дата заблокирована')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка блокировки даты')));
      }
    }
  }

  Future<void> _unmarkDayAsBusy(DateTime date) async {
    final success = await _availabilityService.removeBusyDate(widget.specialistId, date);

    if (success) {
      await _loadAvailabilityData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Дата освобождена')));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ошибка освобождения даты')));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
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
}
