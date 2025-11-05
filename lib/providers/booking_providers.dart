import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для BookingService
final bookingServiceProvider = Provider((ref) => BookingService());

/// Провайдер для документа дня календаря специалиста
final calendarDayDocProvider = StreamProvider.family<DocumentSnapshot?, CalendarDayParams>(
  (ref, params) {
    return FirebaseFirestore.instance
        .collection('specialist_calendar')
        .doc(params.specialistId)
        .collection('days')
        .doc(params.dayId)
        .snapshots();
  },
);

class CalendarDayParams {
  CalendarDayParams({
    required this.specialistId,
    required this.dayId,
  });

  final String specialistId;
  final String dayId; // YYYY-MM-DD
}

/// Провайдер для заявок на день специалиста
final bookingsForDayProvider = StreamProvider.family<List<Booking>, BookingsForDayParams>(
  (ref, params) {
    final service = ref.watch(bookingServiceProvider);
    return service.watchBookingsBySpecialistDay(params.specialistId, params.dayId);
  },
);

class BookingsForDayParams {
  BookingsForDayParams({
    required this.specialistId,
    required this.dayId,
  });

  final String specialistId;
  final String dayId; // YYYY-MM-DD
}

/// Провайдер для заявки по ID
final bookingByIdProvider = FutureProvider.family<Booking?, String>(
  (ref, bookingId) async {
    final service = ref.watch(bookingServiceProvider);
    return await service.getBookingById(bookingId);
  },
);

/// Провайдер для метаданных дня календаря
final calendarDayMetaProvider = FutureProvider.family<Map<String, dynamic>, CalendarDayMetaParams>(
  (ref, params) async {
    final service = ref.watch(bookingServiceProvider);
    return await service.getCalendarDayMeta(params.specialistId, params.dayId);
  },
);

class CalendarDayMetaParams {
  CalendarDayMetaParams({
    required this.specialistId,
    required this.dayId,
  });

  final String specialistId;
  final String dayId; // YYYY-MM-DD
}

/// Провайдер для autoAcceptBookings
final autoAcceptBookingsProvider = FutureProvider.family<bool, String>(
  (ref, specialistId) async {
    final service = ref.watch(bookingServiceProvider);
    return await service.getAutoAcceptBookings(specialistId);
  },
);
