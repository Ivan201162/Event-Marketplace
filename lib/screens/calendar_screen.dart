import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/back_button_handler.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final BookingService _bookingService = BookingService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  List<Booking> _bookings = [];
  List<DateTime> _bookedDates = [];
  List<DateTime> _availableDates = [];
  bool _isLoading = true;
  bool _isSpecialist = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Проверяем, является ли пользователь специалистом
      final specialistDoc = await _firestore.collection('specialists').doc(user.uid).get();

      _isSpecialist = specialistDoc.exists;

      if (_isSpecialist) {
        await _loadSpecialistCalendar(user.uid);
      } else {
        await _loadCustomerBookings(user.uid);
      }

      setState(() {
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadSpecialistCalendar(String specialistId) async {
    // Загружаем забронированные даты
    final bookingsSnapshot = await _firestore
        .collection('bookings')
        .where('specialistId', isEqualTo: specialistId)
        .where('status', whereIn: ['confirmed', 'pending'])
        .get();

    _bookedDates = bookingsSnapshot.docs
        .map((doc) {
          final data = doc.data();
          final eventDate = data['eventDate'] as Timestamp?;
          return eventDate?.toDate();
        })
        .where((date) => date != null)
        .cast<DateTime>()
        .toList();

    // Загружаем доступные даты
    final availabilityDoc = await _firestore
        .collection('specialist_availability')
        .doc(specialistId)
        .get();

    if (availabilityDoc.exists) {
      final data = availabilityDoc.data()!;
      final availableDates = data['availableDates'] as List<dynamic>? ?? [];
      _availableDates = availableDates.map((date) => (date as Timestamp).toDate()).toList();
    }
  }

  Future<void> _loadCustomerBookings(String userId) async {
    final bookings = await _bookingService.getCustomerBookings(userId).first;
    setState(() {
      _bookings = bookings;
    });
  }

  List<Booking> _getBookingsForDate(DateTime date) => _bookings
      .where(
        (booking) =>
            booking.eventDate.year == date.year &&
            booking.eventDate.month == date.month &&
            booking.eventDate.day == date.day,
      )
      .toList();

  Color _getBookingColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.rejected:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Ожидает подтверждения';
      case BookingStatus.confirmed:
        return 'Подтверждена';
      case BookingStatus.completed:
        return 'Выполнена';
      case BookingStatus.cancelled:
        return 'Отменена';
      case BookingStatus.rejected:
        return 'Отклонена';
    }
  }

  @override
  Widget build(BuildContext context) => BackButtonHandler(
    child: Scaffold(
      appBar: AppBar(
        title: Text(_isSpecialist ? 'Календарь специалиста' : 'Мой календарь'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        actions: [
          if (_isSpecialist)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editAvailability,
              tooltip: 'Редактировать доступность',
            ),
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedDate = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Календарь
                _buildTableCalendar(),

                // Легенда
                _buildLegend(),

                // Список событий на выбранную дату
                _buildSelectedDateEvents(),
              ],
            ),
    ),
  );

  Widget _buildTableCalendar() => TableCalendar<Booking>(
    firstDay: DateTime.utc(2020),
    lastDay: DateTime.utc(2030, 12, 31),
    focusedDay: _focusedDate,
    calendarFormat: _calendarFormat,
    eventLoader: _getEventsForDay,
    startingDayOfWeek: StartingDayOfWeek.monday,
    calendarStyle: CalendarStyle(
      outsideDaysVisible: false,
      markersMaxCount: 3,
      markerDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      selectedDecoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
      todayDecoration: BoxDecoration(color: Colors.blue.shade100, shape: BoxShape.circle),
      weekendTextStyle: const TextStyle(color: Colors.red),
    ),
    headerStyle: const HeaderStyle(
      titleCentered: true,
      formatButtonShowsNext: false,
      formatButtonDecoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      formatButtonTextStyle: TextStyle(color: Colors.white),
    ),
    onDaySelected: (selectedDay, focusedDay) {
      if (!isSameDay(_selectedDate, selectedDay)) {
        setState(() {
          _selectedDate = selectedDay;
          _focusedDate = focusedDay;
        });
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
      _focusedDate = focusedDay;
    },
    selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
    calendarBuilders: CalendarBuilders(
      markerBuilder: (context, day, events) {
        if (_isSpecialist) {
          if (_bookedDates.any((date) => isSameDay(date, day))) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              child: const Icon(Icons.event, color: Colors.red, size: 16),
            );
          } else if (_availableDates.any((date) => isSameDay(date, day))) {
            return Container(
              margin: const EdgeInsets.only(top: 5),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
            );
          }
        }
        return null;
      },
    ),
  );

  List<Booking> _getEventsForDay(DateTime day) => _getBookingsForDate(day);

  Widget _buildLegend() {
    if (!_isSpecialist) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Icons.event, Colors.red, 'Занято'),
          _buildLegendItem(Icons.check_circle, Colors.green, 'Доступно'),
          _buildLegendItem(Icons.schedule, Colors.blue, 'Предстоящие'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12)),
    ],
  );

  void _editAvailability() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать доступность'),
        content: const Text(
          'Функция редактирования доступности будет добавлена в следующей версии.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildSelectedDateEvents() {
    final selectedBookings = _getBookingsForDate(_selectedDate);
    final isBooked = _bookedDates.any((date) => isSameDay(date, _selectedDate));
    final isAvailable = _availableDates.any((date) => isSameDay(date, _selectedDate));

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'События на ${_selectedDate.day}.${_selectedDate.month}.${_selectedDate.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isSpecialist) ...[
            if (isBooked)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.event, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text('Дата занята'),
                  ],
                ),
              )
            else if (isAvailable)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Дата доступна'),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
          if (selectedBookings.isEmpty)
            const Expanded(
              child: Center(
                child: Text('На эту дату событий нет', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: selectedBookings.length,
                itemBuilder: (context, index) {
                  final booking = selectedBookings[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getBookingColor(booking.status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        booking.eventTitle ?? 'Мероприятие',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(booking.specialistName ?? 'Специалист'),
                          Text(
                            '${booking.eventDate.hour.toString().padLeft(2, '0')}:${booking.eventDate.minute.toString().padLeft(2, '0')} - ${_getStatusText(booking.status)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '${booking.totalPrice.toInt() ?? 0}₽',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      onTap: () {
                        // TODO(developer): Показать детали заявки
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Детали заявки в разработке')));
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
