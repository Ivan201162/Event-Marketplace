import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/specialist_schedule.dart';

class SpecialistCalendarScreen extends StatefulWidget {
  final SpecialistSchedule schedule;

  const SpecialistCalendarScreen({super.key, required this.schedule});

  @override
  State<SpecialistCalendarScreen> createState() =>
      _SpecialistCalendarScreenState();
}

class _SpecialistCalendarScreenState extends State<SpecialistCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Календарь занятости")),
      body: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            final isBusy = widget.schedule.busyDates.any(
              (d) => isSameDay(d, day),
            );
            if (isBusy) {
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "${day.day}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
            return null;
          },
        ),
      ),
    );
  }
}