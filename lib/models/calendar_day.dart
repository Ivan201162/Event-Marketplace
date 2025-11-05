import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель дня календаря специалиста
class CalendarDay {
  CalendarDay({
    required this.specialistId,
    required this.year,
    required this.month,
    required this.day,
    this.status = CalendarStatus.free,
    this.requestId,
    this.clientId,
    this.createdAt,
    this.updatedAt,
  });

  final String specialistId;
  final int year;
  final int month; // 1-12
  final int day; // 1-31
  final CalendarStatus status;
  final String? requestId;
  final String? clientId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Создать из Firestore
  factory CalendarDay.fromFirestore(Map<String, dynamic> data, String specialistId, String monthId, String dayId) {
    final parts = monthId.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(dayId);

    return CalendarDay(
      specialistId: specialistId,
      year: year,
      month: month,
      day: day,
      status: CalendarStatus.fromString(data['status'] ?? 'free'),
      requestId: data['requestId'] as String?,
      clientId: data['clientId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Преобразовать в Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'status': status.value,
      'requestId': requestId,
      'clientId': clientId,
      'updatedAt': FieldValue.serverTimestamp(),
      if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Получить ID месяца для Firestore
  String get monthId => '$year-$month';

  /// Получить дату
  DateTime get date => DateTime(year, month, day);

  /// Проверить, можно ли выбрать эту дату
  bool get isSelectable => status == CalendarStatus.free || status == CalendarStatus.pending;

  /// Проверить, свободна ли дата
  bool get isFree => status == CalendarStatus.free;
}

/// Статус дня в календаре
enum CalendarStatus {
  free('free'),
  pending('pending'),
  booked('booked');

  const CalendarStatus(this.value);
  final String value;

  static CalendarStatus fromString(String value) {
    return CalendarStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => CalendarStatus.free,
    );
  }
}

