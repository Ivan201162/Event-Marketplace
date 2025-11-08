import 'package:cloud_firestore/cloud_firestore.dart';

/// Агрегат дня календаря
class CalendarDayAggregate {
  CalendarDayAggregate({
    required this.date,
    required this.status,
    this.pendingCount = 0,
    this.acceptedBookingId,
  });

  final String date; // YYYY-MM-DD
  CalendarDayStatus status;
  int pendingCount;
  String? acceptedBookingId; // Используем acceptedBookingId как в Firestore

  factory CalendarDayAggregate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final dateStr = data['date'] as String? ?? doc.id;
    final acceptedBookingId = data['acceptedBookingId'] as String?;
    final pendingCount = (data['pendingCount'] as num?)?.toInt() ?? 0;
    
    // Определяем статус автоматически
    final status = acceptedBookingId != null 
        ? CalendarDayStatus.confirmed 
        : (pendingCount > 0 ? CalendarDayStatus.pending : CalendarDayStatus.free);
    
    return CalendarDayAggregate(
      date: dateStr,
      status: status,
      pendingCount: pendingCount,
      acceptedBookingId: acceptedBookingId,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'status': status.value,
      'pendingCount': pendingCount,
      'acceptedBookingId': acceptedBookingId,
    };
  }
}

/// Статус дня календаря (агрегат)
enum CalendarDayStatus {
  free('free'),
  pending('pending'),
  confirmed('confirmed');

  const CalendarDayStatus(this.value);
  final String value;

  static CalendarDayStatus fromString(String value) {
    return CalendarDayStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarDayStatus.free,
    );
  }
}

