import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../services/fcm_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Провайдер FCM сервиса
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// Провайдер занятых дат специалиста
final busyDatesProvider = FutureProvider.family<List<DateTime>, String>((ref, specialistId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBusyDates(specialistId);
});

/// Провайдер занятых дат с временными интервалами
final busyDateRangesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, specialistId) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getBusyDateRanges(specialistId);
});

/// Провайдер проверки конфликтов бронирования
final bookingConflictProvider = FutureProvider.family<bool, BookingConflictParams>((ref, params) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.hasBookingConflict(
    params.specialistId,
    params.startTime,
    params.endTime,
    excludeBookingId: params.excludeBookingId,
  );
});

/// Параметры для проверки конфликтов бронирования
class BookingConflictParams {
  final String specialistId;
  final DateTime startTime;
  final DateTime endTime;
  final String? excludeBookingId;

  const BookingConflictParams({
    required this.specialistId,
    required this.startTime,
    required this.endTime,
    this.excludeBookingId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookingConflictParams &&
        other.specialistId == specialistId &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.excludeBookingId == excludeBookingId;
  }

  @override
  int get hashCode => specialistId.hashCode ^ startTime.hashCode ^ endTime.hashCode ^ excludeBookingId.hashCode;
}