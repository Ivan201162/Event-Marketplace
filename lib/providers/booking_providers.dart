import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';

/// Booking service provider
final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService();
});

/// Specialist bookings provider
final specialistBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, specialistId) async {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getSpecialistBookings(specialistId);
});

/// Client bookings provider
final clientBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, clientId) async {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getClientBookings(clientId);
});

/// Bookings by status provider
final bookingsByStatusProvider = FutureProvider.family<List<Booking>, BookingStatus>((ref, status) async {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getBookingsByStatus(status);
});

/// Booking by ID provider
final bookingByIdProvider = FutureProvider.family<Booking?, String>((ref, bookingId) async {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getBookingById(bookingId);
});

/// Specialist bookings stream provider
final specialistBookingsStreamProvider = StreamProvider.family<List<Booking>, String>((ref, specialistId) {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getSpecialistBookingsStream(specialistId);
});

/// Client bookings stream provider
final clientBookingsStreamProvider = StreamProvider.family<List<Booking>, String>((ref, clientId) {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getClientBookingsStream(clientId);
});

/// Bookings by status stream provider
final bookingsByStatusStreamProvider = StreamProvider.family<List<Booking>, BookingStatus>((ref, status) {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getBookingsByStatusStream(status);
});

/// Booking statistics provider
final bookingStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, specialistId) async {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getBookingStats(specialistId);
});

/// Available time slots provider
final availableTimeSlotsProvider = FutureProvider.family<List<String>, Map<String, dynamic>>((ref, params) async {
  final bookingService = ref.read(bookingServiceProvider);
  final specialistId = params['specialistId'] as String;
  final date = params['date'] as DateTime;
  return bookingService.getAvailableTimeSlots(specialistId, date);
});

/// Time slot availability provider
final timeSlotAvailabilityProvider = FutureProvider.family<bool, Map<String, dynamic>>((ref, params) async {
  final bookingService = ref.read(bookingServiceProvider);
  final specialistId = params['specialistId'] as String;
  final date = params['date'] as DateTime;
  final time = params['time'] as String;
  final duration = params['duration'] as int;
  return bookingService.isTimeSlotAvailable(specialistId, date, time, duration);
});

/// Pending bookings count provider
final pendingBookingsCountProvider = FutureProvider.family<int, String>((ref, specialistId) async {
  final bookingService = ref.read(bookingServiceProvider);
  final bookings = await bookingService.getBookingsByStatus(BookingStatus.pending);
  return bookings.length;
});

/// Pending bookings count stream provider
final pendingBookingsCountStreamProvider = StreamProvider.family<int, String>((ref, specialistId) {
  final bookingService = ref.read(bookingServiceProvider);
  return bookingService.getBookingsByStatusStream(BookingStatus.pending)
      .map((bookings) => bookings.where((b) => b.specialistId == specialistId).length);
});

/// Today's bookings provider
final todaysBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, specialistId) async {
  final bookingService = ref.read(bookingServiceProvider);
  final today = DateTime.now();
  final bookings = await bookingService.getSpecialistBookings(specialistId);
  return bookings.where((booking) {
    final bookingDate = booking.date;
    return bookingDate.year == today.year &&
           bookingDate.month == today.month &&
           bookingDate.day == today.day;
  }).toList();
});

/// Today's bookings stream provider
final todaysBookingsStreamProvider = StreamProvider.family<List<Booking>, String>((ref, specialistId) {
  final bookingService = ref.read(bookingServiceProvider);
  final today = DateTime.now();
  return bookingService.getSpecialistBookingsStream(specialistId)
      .map((bookings) => bookings.where((booking) {
        final bookingDate = booking.date;
        return bookingDate.year == today.year &&
               bookingDate.month == today.month &&
               bookingDate.day == today.day;
      }).toList());
});

/// Upcoming bookings provider
final upcomingBookingsProvider = FutureProvider.family<List<Booking>, String>((ref, specialistId) async {
  final bookingService = ref.read(bookingServiceProvider);
  final now = DateTime.now();
  final bookings = await bookingService.getSpecialistBookings(specialistId);
  return bookings.where((booking) {
    return booking.date.isAfter(now) && 
           (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending);
  }).toList();
});

/// Upcoming bookings stream provider
final upcomingBookingsStreamProvider = StreamProvider.family<List<Booking>, String>((ref, specialistId) {
  final bookingService = ref.read(bookingServiceProvider);
  final now = DateTime.now();
  return bookingService.getSpecialistBookingsStream(specialistId)
      .map((bookings) => bookings.where((booking) {
        return booking.date.isAfter(now) && 
               (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending);
      }).toList());
});