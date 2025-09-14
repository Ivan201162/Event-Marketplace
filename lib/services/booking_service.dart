import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';
import 'specialist_schedule_service.dart';
import 'notification_service.dart';
import 'badge_service.dart';

class BookingService {
  static const String _bookingsKey = 'bookings';
  final SpecialistScheduleService _scheduleService = SpecialistScheduleService();
  final NotificationService _notificationService = NotificationService();
  final BadgeService _badgeService = BadgeService();

  Future<void> addBooking(Booking booking) async {
    final bookings = await getBookings();
    bookings.add(booking);
    await _saveBookings(bookings);
    
    // Добавляем дату в расписание специалиста как занятую
    await _scheduleService.addBusyDate(booking.specialistId, booking.eventDate);
    
    // Планируем напоминание об оплате
    try {
      await _notificationService.sendPaymentReminder(
        customerId: booking.customerId,
        bookingId: booking.id,
        eventName: booking.eventName,
        amount: booking.totalAmount,
        dueDate: booking.paymentDueDate ?? booking.eventDate,
      );
    } catch (e) {
      // Логируем ошибку, но не прерываем создание бронирования
      print('Error scheduling payment reminder: $e');
    }
    
    // Проверяем бейджи
    try {
      await _badgeService.checkBookingBadges(booking.customerId, booking.specialistId);
    } catch (e) {
      // Логируем ошибку, но не прерываем создание бронирования
      print('Error checking booking badges: $e');
    }
  }

  Future<List<Booking>> getBookingsForSpecialist(String specialistId) async {
    final bookings = await getBookings();
    return bookings.where((booking) => booking.specialistId == specialistId).toList();
  }

  Future<List<Booking>> getBookingsForCustomer(String customerId) async {
    final bookings = await getBookings();
    return bookings.where((booking) => booking.customerId == customerId).toList();
  }

  // Проверить доступность даты для специалиста
  Future<bool> isDateAvailable(String specialistId, DateTime date) async {
    return await _scheduleService.isDateAvailable(specialistId, date);
  }

  // Получить доступные даты для специалиста в диапазоне
  Future<List<DateTime>> getAvailableDates(
    String specialistId, 
    DateTime startDate, 
    DateTime endDate
  ) async {
    return await _scheduleService.getAvailableDates(specialistId, startDate, endDate);
  }

  // Отменить бронирование и освободить дату
  Future<void> cancelBooking(String bookingId) async {
    final bookings = await getBookings();
    final bookingIndex = bookings.indexWhere((booking) => booking.id == bookingId);
    
    if (bookingIndex != -1) {
      final booking = bookings[bookingIndex];
      
      // Удаляем бронирование
      bookings.removeAt(bookingIndex);
      await _saveBookings(bookings);
      
      // Освобождаем дату в расписании
      await _scheduleService.removeBusyDate(booking.specialistId, booking.eventDate);
    }
  }

  Future<List<Booking>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = prefs.getStringList(_bookingsKey) ?? [];
    
    if (bookingsJson.isEmpty) {
      // Добавляем тестовые данные при первом запуске
      await _addTestData();
      return await getBookings();
    }

    return bookingsJson
        .map((json) {
          final data = jsonDecode(json);
          return Booking(
            id: data['id'],
            customerId: data['customerId'],
            specialistId: data['specialistId'],
            eventDate: DateTime.parse(data['eventDate']),
            status: data['status'],
            prepayment: data['prepayment'],
            totalPrice: data['totalPrice'],
            prepaymentPaid: data['prepaymentPaid'] ?? false,
            paymentStatus: data['paymentStatus'] ?? "pending",
            createdAt: DateTime.parse(data['createdAt']),
          );
        })
        .toList();
  }

  Future<void> _saveBookings(List<Booking> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    final bookingsJson = bookings
        .map((booking) => jsonEncode(booking.toMap()))
        .toList();
    await prefs.setStringList(_bookingsKey, bookingsJson);
  }

  Future<void> _addTestData() async {
    final testBookings = [
      Booking(
        id: '1',
        customerId: 'customer1',
        specialistId: 'specialist1',
        eventDate: DateTime(2025, 9, 20),
        status: 'pending',
        prepayment: 4500.0,
        totalPrice: 15000.0,
      ),
      Booking(
        id: '2',
        customerId: 'customer2',
        specialistId: 'specialist1',
        eventDate: DateTime(2025, 9, 25),
        status: 'confirmed',
        prepayment: 7500.0,
        totalPrice: 25000.0,
      ),
    ];

    for (final booking in testBookings) {
      await addBooking(booking);
    }
  }
}
