import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/booking.dart';
import 'package:event_marketplace_app/models/calendar_day_aggregate.dart';
import 'package:event_marketplace_app/services/booking_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Провайдер для агрегата дня календаря
final dayAggregateProvider = StreamProvider.family<CalendarDayAggregate?, DayAggregateParams>(
  (ref, params) async* {
    final service = BookingService();
    final dateStr = DateFormat('yyyy-MM-dd').format(params.date);
    
    yield* FirebaseFirestore.instance
        .collection('calendars')
        .doc(params.specialistId)
        .collection('days')
        .doc(dateStr)
        .snapshots()
        .asyncMap((doc) async {
          if (doc.exists) {
            return CalendarDayAggregate.fromFirestore(doc);
          }
          return CalendarDayAggregate(
            date: dateStr,
            status: CalendarDayStatus.free,
            pendingCount: 0,
          );
        });
  },
);

class DayAggregateParams {
  DayAggregateParams({
    required this.specialistId,
    required this.date,
  });

  final String specialistId;
  final DateTime date;
}

/// Провайдер для заявок на день
final bookingsByDayProvider = StreamProvider.family<List<Booking>, BookingsByDayParams>(
  (ref, params) {
    final service = BookingService();
    return service.bookingsForDay(params.specialistId, params.date);
  },
);

class BookingsByDayParams {
  BookingsByDayParams({
    required this.specialistId,
    required this.date,
  });

  final String specialistId;
  final DateTime date;
}

/// Провайдер для политики календаря
final calendarPolicyProvider = FutureProvider.family<String, String>(
  (ref, specialistId) async {
    final service = BookingService();
    return await service.getCalendarPolicy(specialistId);
  },
);
