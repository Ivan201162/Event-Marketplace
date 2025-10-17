import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель календаря доступности специалиста
class AvailabilityCalendar {
  const AvailabilityCalendar({
    required this.id,
    required this.specialistId,
    required this.date,
    required this.timeSlots,
    this.isAvailable = true,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Создать из документа Firestore
  factory AvailabilityCalendar.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AvailabilityCalendar(
      id: doc.id,
      specialistId: data['specialistId'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      timeSlots:
          (data['timeSlots'] as List<dynamic>?)?.map((slot) => TimeSlot.fromMap(slot)).toList() ??
              [],
      isAvailable: data['isAvailable'] as bool? ?? true,
      note: data['note'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String specialistId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final bool isAvailable;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'date': Timestamp.fromDate(date),
        'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
        'isAvailable': isAvailable,
        'note': note,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  /// Создать копию с изменениями
  AvailabilityCalendar copyWith({
    String? id,
    String? specialistId,
    DateTime? date,
    List<TimeSlot>? timeSlots,
    bool? isAvailable,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      AvailabilityCalendar(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        date: date ?? this.date,
        timeSlots: timeSlots ?? this.timeSlots,
        isAvailable: isAvailable ?? this.isAvailable,
        note: note ?? this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Проверить, доступен ли специалист в указанное время
  bool isAvailableAt(DateTime dateTime) {
    if (!isAvailable) return false;

    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final calendarDate = DateTime(date.year, date.month, date.day);

    if (!targetDate.isAtSameMomentAs(calendarDate)) return false;

    return timeSlots.any((slot) => slot.isTimeInSlot(dateTime));
  }

  /// Получить доступные временные слоты на дату
  List<TimeSlot> getAvailableSlots(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final calendarDate = DateTime(this.date.year, this.date.month, this.date.day);

    if (!targetDate.isAtSameMomentAs(calendarDate) || !isAvailable) {
      return [];
    }

    return timeSlots.where((slot) => slot.isAvailable).toList();
  }
}

/// Временной слот в календаре
class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.bookingId,
    this.note,
  });

  /// Создать из Map
  factory TimeSlot.fromMap(Map<String, dynamic> map) => TimeSlot(
        id: map['id'] ?? '',
        startTime: (map['startTime'] as Timestamp).toDate(),
        endTime: (map['endTime'] as Timestamp).toDate(),
        isAvailable: map['isAvailable'] ?? true,
        bookingId: map['bookingId'],
        note: map['note'],
      );
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAvailable;
  final String? bookingId;
  final String? note;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'isAvailable': isAvailable,
        'bookingId': bookingId,
        'note': note,
      };

  /// Проверить, находится ли время в этом слоте
  bool isTimeInSlot(DateTime dateTime) => dateTime.isAfter(startTime) && dateTime.isBefore(endTime);

  /// Получить продолжительность слота в часах
  double get durationInHours => endTime.difference(startTime).inHours.toDouble();

  /// Создать копию с изменениями
  TimeSlot copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAvailable,
    String? bookingId,
    String? note,
  }) =>
      TimeSlot(
        id: id ?? this.id,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isAvailable: isAvailable ?? this.isAvailable,
        bookingId: bookingId ?? this.bookingId,
        note: note ?? this.note,
      );
}

/// Типы доступности
enum AvailabilityType {
  available, // Доступен
  busy, // Занят
  unavailable, // Недоступен
  breakTime, // Перерыв
}

/// Настройки рабочего времени
class WorkingHours {
  const WorkingHours({
    this.weeklySchedule = const {},
    this.holidays = const [],
    this.minBookingHours = 1,
    this.maxBookingHours = 8,
  });
  final Map<int, List<TimeSlot>> weeklySchedule; // 1-7 (понедельник-воскресенье)
  final List<DateTime> holidays; // Праздничные дни
  final int minBookingHours;
  final int maxBookingHours;

  /// Получить рабочие часы для дня недели
  List<TimeSlot> getWorkingHoursForDay(int dayOfWeek) => weeklySchedule[dayOfWeek] ?? [];

  /// Проверить, является ли день праздничным
  bool isHoliday(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return holidays.any(
      (holiday) => DateTime(holiday.year, holiday.month, holiday.day).isAtSameMomentAs(dateOnly),
    );
  }

  /// Проверить, рабочий ли день
  bool isWorkingDay(DateTime date) {
    if (isHoliday(date)) return false;
    final dayOfWeek = date.weekday;
    return weeklySchedule.containsKey(dayOfWeek) && weeklySchedule[dayOfWeek]!.isNotEmpty;
  }
}
