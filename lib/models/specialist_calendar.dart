import 'package:cloud_firestore/cloud_firestore.dart';

/// Статус временного слота
enum TimeSlotStatus {
  available, // Доступен
  booked, // Забронирован
  blocked, // Заблокирован
  unavailable, // Недоступен
}

/// Тип блокировки
enum BlockType {
  personal, // Личные дела
  vacation, // Отпуск
  maintenance, // Техническое обслуживание
  emergency, // Экстренная ситуация
  other, // Другое
}

/// Модель временного слота
class TimeSlot {
  const TimeSlot({
    required this.id,
    required this.specialistId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.bookingId,
    this.blockType,
    this.blockReason,
    this.notes,
    this.isRecurring = false,
    this.recurringPattern,
    this.createdAt,
    this.updatedAt,
  });

  factory TimeSlot.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TimeSlot(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: TimeSlotStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TimeSlotStatus.available,
      ),
      bookingId: data['bookingId'] as String?,
      blockType: data['blockType'] != null
          ? BlockType.values.firstWhere(
              (e) => e.name == data['blockType'],
              orElse: () => BlockType.other,
            )
          : null,
      blockReason: data['blockReason'] as String?,
      notes: data['notes'] as String?,
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurringPattern: data['recurringPattern'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String specialistId;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final TimeSlotStatus status;
  final String? bookingId;
  final BlockType? blockType;
  final String? blockReason;
  final String? notes;
  final bool isRecurring;
  final String? recurringPattern;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'date': Timestamp.fromDate(date),
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': status.name,
        'bookingId': bookingId,
        'blockType': blockType?.name,
        'blockReason': blockReason,
        'notes': notes,
        'isRecurring': isRecurring,
        'recurringPattern': recurringPattern,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  TimeSlot copyWith({
    String? id,
    String? specialistId,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    TimeSlotStatus? status,
    String? bookingId,
    BlockType? blockType,
    String? blockReason,
    String? notes,
    bool? isRecurring,
    String? recurringPattern,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      TimeSlot(
        id: id ?? this.id,
        specialistId: specialistId ?? this.specialistId,
        date: date ?? this.date,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        bookingId: bookingId ?? this.bookingId,
        blockType: blockType ?? this.blockType,
        blockReason: blockReason ?? this.blockReason,
        notes: notes ?? this.notes,
        isRecurring: isRecurring ?? this.isRecurring,
        recurringPattern: recurringPattern ?? this.recurringPattern,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  /// Получить продолжительность слота в часах
  double get durationInHours {
    return endTime.difference(startTime).inHours.toDouble();
  }

  /// Получить продолжительность слота в минутах
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Получить отформатированное время начала
  String get formattedStartTime {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Получить отформатированное время окончания
  String get formattedEndTime {
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  /// Получить отформатированный временной диапазон
  String get formattedTimeRange {
    return '$formattedStartTime - $formattedEndTime';
  }

  /// Получить отформатированную дату
  String get formattedDate {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Проверить, доступен ли слот
  bool get isAvailable => status == TimeSlotStatus.available;

  /// Проверить, забронирован ли слот
  bool get isBooked => status == TimeSlotStatus.booked;

  /// Проверить, заблокирован ли слот
  bool get isBlocked => status == TimeSlotStatus.blocked;

  /// Проверить, недоступен ли слот
  bool get isUnavailable => status == TimeSlotStatus.unavailable;

  /// Получить цвет статуса
  String get statusColor {
    switch (status) {
      case TimeSlotStatus.available:
        return 'green';
      case TimeSlotStatus.booked:
        return 'blue';
      case TimeSlotStatus.blocked:
        return 'red';
      case TimeSlotStatus.unavailable:
        return 'grey';
    }
  }

  /// Получить текст статуса
  String get statusText {
    switch (status) {
      case TimeSlotStatus.available:
        return 'Доступен';
      case TimeSlotStatus.booked:
        return 'Забронирован';
      case TimeSlotStatus.blocked:
        return 'Заблокирован';
      case TimeSlotStatus.unavailable:
        return 'Недоступен';
    }
  }

  /// Получить отображаемое название типа блокировки
  String? get blockTypeDisplayName {
    if (blockType == null) return null;
    
    switch (blockType!) {
      case BlockType.personal:
        return 'Личные дела';
      case BlockType.vacation:
        return 'Отпуск';
      case BlockType.maintenance:
        return 'Техническое обслуживание';
      case BlockType.emergency:
        return 'Экстренная ситуация';
      case BlockType.other:
        return 'Другое';
    }
  }
}

/// Модель рабочего расписания специалиста
class SpecialistSchedule {
  const SpecialistSchedule({
    required this.id,
    required this.specialistId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
    this.breakStartTime,
    this.breakEndTime,
    this.maxBookingsPerDay,
    this.advanceBookingDays,
    this.createdAt,
    this.updatedAt,
  });

  factory SpecialistSchedule.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistSchedule(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      dayOfWeek: data['dayOfWeek'] as int,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      isActive: data['isActive'] as bool? ?? true,
      breakStartTime: data['breakStartTime'] != null
          ? (data['breakStartTime'] as Timestamp).toDate()
          : null,
      breakEndTime: data['breakEndTime'] != null
          ? (data['breakEndTime'] as Timestamp).toDate()
          : null,
      maxBookingsPerDay: data['maxBookingsPerDay'] as int?,
      advanceBookingDays: data['advanceBookingDays'] as int?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String specialistId;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;
  final DateTime? breakStartTime;
  final DateTime? breakEndTime;
  final int? maxBookingsPerDay;
  final int? advanceBookingDays;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'dayOfWeek': dayOfWeek,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'isActive': isActive,
        'breakStartTime': breakStartTime != null ? Timestamp.fromDate(breakStartTime!) : null,
        'breakEndTime': breakEndTime != null ? Timestamp.fromDate(breakEndTime!) : null,
        'maxBookingsPerDay': maxBookingsPerDay,
        'advanceBookingDays': advanceBookingDays,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Получить название дня недели
  String get dayName {
    switch (dayOfWeek) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return 'Неизвестно';
    }
  }

  /// Получить отформатированное рабочее время
  String get formattedWorkingHours {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  /// Получить отформатированное время перерыва
  String? get formattedBreakTime {
    if (breakStartTime == null || breakEndTime == null) return null;
    
    final start = '${breakStartTime!.hour.toString().padLeft(2, '0')}:${breakStartTime!.minute.toString().padLeft(2, '0')}';
    final end = '${breakEndTime!.hour.toString().padLeft(2, '0')}:${breakEndTime!.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  /// Получить продолжительность рабочего дня в часах
  double get workingHours {
    return endTime.difference(startTime).inHours.toDouble();
  }

  /// Получить продолжительность перерыва в часах
  double? get breakHours {
    if (breakStartTime == null || breakEndTime == null) return null;
    return breakEndTime!.difference(breakStartTime!).inHours.toDouble();
  }

  /// Получить эффективное рабочее время (без перерыва)
  double get effectiveWorkingHours {
    final total = workingHours;
    final breakTime = breakHours ?? 0;
    return total - breakTime;
  }
}

/// Модель календаря специалиста
class SpecialistCalendar {
  const SpecialistCalendar({
    required this.id,
    required this.specialistId,
    required this.date,
    required this.timeSlots,
    this.isWorkingDay = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory SpecialistCalendar.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SpecialistCalendar(
      id: doc.id,
      specialistId: data['specialistId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      timeSlots: (data['timeSlots'] as List<dynamic>?)
              ?.map((slot) => TimeSlot.fromDocument(slot as DocumentSnapshot))
              .toList() ??
          [],
      isWorkingDay: data['isWorkingDay'] as bool? ?? true,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  final String id;
  final String specialistId;
  final DateTime date;
  final List<TimeSlot> timeSlots;
  final bool isWorkingDay;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'date': Timestamp.fromDate(date),
        'timeSlots': timeSlots.map((slot) => slot.toMap()).toList(),
        'isWorkingDay': isWorkingDay,
        'notes': notes,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  /// Получить доступные слоты
  List<TimeSlot> get availableSlots {
    return timeSlots.where((slot) => slot.isAvailable).toList();
  }

  /// Получить забронированные слоты
  List<TimeSlot> get bookedSlots {
    return timeSlots.where((slot) => slot.isBooked).toList();
  }

  /// Получить заблокированные слоты
  List<TimeSlot> get blockedSlots {
    return timeSlots.where((slot) => slot.isBlocked).toList();
  }

  /// Получить недоступные слоты
  List<TimeSlot> get unavailableSlots {
    return timeSlots.where((slot) => slot.isUnavailable).toList();
  }

  /// Получить количество доступных слотов
  int get availableSlotsCount {
    return availableSlots.length;
  }

  /// Получить количество забронированных слотов
  int get bookedSlotsCount {
    return bookedSlots.length;
  }

  /// Получить общее количество слотов
  int get totalSlotsCount {
    return timeSlots.length;
  }

  /// Получить процент занятости
  double get occupancyPercentage {
    if (totalSlotsCount == 0) return 0.0;
    return (bookedSlotsCount / totalSlotsCount) * 100;
  }

  /// Получить отформатированную дату
  String get formattedDate {
    return '${date.day}.${date.month}.${date.year}';
  }

  /// Получить отформатированный день недели
  String get formattedDayOfWeek {
    switch (date.weekday) {
      case 1:
        return 'Понедельник';
      case 2:
        return 'Вторник';
      case 3:
        return 'Среда';
      case 4:
        return 'Четверг';
      case 5:
        return 'Пятница';
      case 6:
        return 'Суббота';
      case 7:
        return 'Воскресенье';
      default:
        return 'Неизвестно';
    }
  }

  /// Проверить, есть ли доступные слоты
  bool get hasAvailableSlots {
    return availableSlots.isNotEmpty;
  }

  /// Проверить, полностью ли занят день
  bool get isFullyBooked {
    return availableSlots.isEmpty && totalSlotsCount > 0;
  }

  /// Проверить, является ли день выходным
  bool get isWeekend {
    return date.weekday == 6 || date.weekday == 7;
  }

  /// Получить цвет статуса дня
  String get dayStatusColor {
    if (!isWorkingDay) return 'grey';
    if (isFullyBooked) return 'red';
    if (occupancyPercentage > 80) return 'orange';
    if (occupancyPercentage > 50) return 'yellow';
    return 'green';
  }

  /// Получить текст статуса дня
  String get dayStatusText {
    if (!isWorkingDay) return 'Выходной';
    if (isFullyBooked) return 'Полностью занят';
    if (occupancyPercentage > 80) return 'Почти занят';
    if (occupancyPercentage > 50) return 'Частично занят';
    return 'Свободен';
  }
}
