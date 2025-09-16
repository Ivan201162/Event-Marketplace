import 'package:cloud_firestore/cloud_firestore.dart';

/// Типы событий в расписании
enum ScheduleEventType {
  booking, // Бронирование
  unavailable, // Недоступность
  vacation, // Отпуск
  maintenance, // Техническое обслуживание
}

/// Событие в расписании специалиста
class ScheduleEvent {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleEventType type;
  final String? description;
  final String? bookingId; // Ссылка на бронирование, если это booking

  const ScheduleEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.description,
    this.bookingId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'type': type.name,
      'description': description,
      'bookingId': bookingId,
    };
  }

  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    return ScheduleEvent(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      type: ScheduleEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ScheduleEventType.booking,
      ),
      description: map['description'],
      bookingId: map['bookingId'],
    );
  }

  ScheduleEvent copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    ScheduleEventType? type,
    String? description,
    String? bookingId,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      description: description ?? this.description,
      bookingId: bookingId ?? this.bookingId,
    );
  }
}

class SpecialistSchedule {
  final String specialistId;
  final List<DateTime> busyDates;
  final List<ScheduleEvent> events;
  final DateTime createdAt;
  final DateTime updatedAt;

  SpecialistSchedule({
    required this.specialistId,
    required this.busyDates,
    this.events = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'specialistId': specialistId,
      'busyDates': busyDates.map((d) => Timestamp.fromDate(d)).toList(),
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory SpecialistSchedule.fromMap(Map<String, dynamic> map) {
    return SpecialistSchedule(
      specialistId: map['specialistId'] ?? '',
      busyDates: (map['busyDates'] as List<dynamic>?)
              ?.map((d) => (d as Timestamp).toDate())
              .toList() ??
          [],
      events: (map['events'] as List<dynamic>?)
              ?.map((e) => ScheduleEvent.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Создать из документа Firestore
  factory SpecialistSchedule.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SpecialistSchedule.fromMap(data);
  }

  /// Проверяет, занята ли дата
  bool isDateBusy(DateTime date) {
    // Проверяем в busyDates
    final isInBusyDates = busyDates.any((busyDate) =>
        busyDate.year == date.year &&
        busyDate.month == date.month &&
        busyDate.day == date.day);

    // Проверяем в событиях
    final isInEvents = events.any((event) =>
        event.startTime.year == date.year &&
        event.startTime.month == date.month &&
        event.startTime.day == date.day);

    return isInBusyDates || isInEvents;
  }

  /// Проверяет, доступна ли дата и время
  bool isDateTimeAvailable(DateTime dateTime) {
    return events.every((event) =>
        !(dateTime.isAfter(event.startTime) &&
            dateTime.isBefore(event.endTime)) &&
        !dateTime.isAtSameMomentAs(event.startTime));
  }

  /// Добавляет занятую дату
  SpecialistSchedule addBusyDate(DateTime date) {
    final newBusyDates = List<DateTime>.from(busyDates);
    if (!isDateBusy(date)) {
      newBusyDates.add(date);
    }
    return copyWith(
      busyDates: newBusyDates,
      updatedAt: DateTime.now(),
    );
  }

  /// Удаляет занятую дату
  SpecialistSchedule removeBusyDate(DateTime date) {
    final newBusyDates = busyDates
        .where((busyDate) => !(busyDate.year == date.year &&
            busyDate.month == date.month &&
            busyDate.day == date.day))
        .toList();
    return copyWith(
      busyDates: newBusyDates,
      updatedAt: DateTime.now(),
    );
  }

  /// Добавляет событие в расписание
  SpecialistSchedule addEvent(ScheduleEvent event) {
    final newEvents = List<ScheduleEvent>.from(events);
    newEvents.add(event);
    return copyWith(
      events: newEvents,
      updatedAt: DateTime.now(),
    );
  }

  /// Удаляет событие из расписания
  SpecialistSchedule removeEvent(String eventId) {
    final newEvents = events.where((event) => event.id != eventId).toList();
    return copyWith(
      events: newEvents,
      updatedAt: DateTime.now(),
    );
  }

  /// Получает события на определенную дату
  List<ScheduleEvent> getEventsForDate(DateTime date) {
    return events
        .where((event) =>
            event.startTime.year == date.year &&
            event.startTime.month == date.month &&
            event.startTime.day == date.day)
        .toList();
  }

  /// Получает доступные даты в диапазоне
  List<DateTime> getAvailableDates(DateTime startDate, DateTime endDate) {
    final availableDates = <DateTime>[];
    var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
      if (!isDateBusy(currentDate)) {
        availableDates.add(
            DateTime(currentDate.year, currentDate.month, currentDate.day));
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return availableDates;
  }

  /// Получает доступные временные слоты на дату
  List<DateTime> getAvailableTimeSlots(DateTime date,
      {Duration slotDuration = const Duration(hours: 1)}) {
    final availableSlots = <DateTime>[];
    final startOfDay = DateTime(date.year, date.month, date.day, 9); // 9:00
    final endOfDay = DateTime(date.year, date.month, date.day, 18); // 18:00

    var currentTime = startOfDay;
    while (currentTime.isBefore(endOfDay)) {
      if (isDateTimeAvailable(currentTime)) {
        availableSlots.add(currentTime);
      }
      currentTime = currentTime.add(slotDuration);
    }

    return availableSlots;
  }

  /// Копирует объект с новыми данными
  SpecialistSchedule copyWith({
    String? specialistId,
    List<DateTime>? busyDates,
    List<ScheduleEvent>? events,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpecialistSchedule(
      specialistId: specialistId ?? this.specialistId,
      busyDates: busyDates ?? this.busyDates,
      events: events ?? this.events,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SpecialistSchedule(specialistId: $specialistId, busyDates: ${busyDates.length}, events: ${events.length})';
  }
}
