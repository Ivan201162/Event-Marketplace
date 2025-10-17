import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../core/feature_flags.dart';
import '../models/booking.dart';
import '../models/specialist_schedule.dart';
import '../models/user.dart';

/// Модель фильтра доступности
class AvailabilityFilter {
  const AvailabilityFilter({
    this.startDate,
    this.endDate,
    this.preferredHours,
    this.preferredDays,
    this.minDuration,
    this.maxDuration,
    this.onlyAvailable = true,
  });

  /// Создать из Map
  factory AvailabilityFilter.fromMap(Map<String, dynamic> data) => AvailabilityFilter(
        startDate: data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null,
        endDate: data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null,
        preferredHours:
            data['preferredHours'] != null ? List<int>.from(data['preferredHours']) : null,
        preferredDays:
            data['preferredDays'] != null ? List<String>.from(data['preferredDays']) : null,
        minDuration: data['minDuration'] != null ? Duration(minutes: data['minDuration']) : null,
        maxDuration: data['maxDuration'] != null ? Duration(minutes: data['maxDuration']) : null,
        onlyAvailable: data['onlyAvailable'] ?? true,
      );
  final DateTime? startDate;
  final DateTime? endDate;
  final List<int>? preferredHours; // Часы дня (0-23)
  final List<String>? preferredDays; // Дни недели (monday, tuesday, etc.)
  final Duration? minDuration;
  final Duration? maxDuration;
  final bool onlyAvailable;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'preferredHours': preferredHours,
        'preferredDays': preferredDays,
        'minDuration': minDuration?.inMinutes,
        'maxDuration': maxDuration?.inMinutes,
        'onlyAvailable': onlyAvailable,
      };

  /// Копировать с изменениями
  AvailabilityFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<int>? preferredHours,
    List<String>? preferredDays,
    Duration? minDuration,
    Duration? maxDuration,
    bool? onlyAvailable,
  }) =>
      AvailabilityFilter(
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        preferredHours: preferredHours ?? this.preferredHours,
        preferredDays: preferredDays ?? this.preferredDays,
        minDuration: minDuration ?? this.minDuration,
        maxDuration: maxDuration ?? this.maxDuration,
        onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      );
}

/// Модель доступности специалиста
class SpecialistAvailability {
  const SpecialistAvailability({
    required this.specialistId,
    required this.specialistName,
    this.specialistPhoto,
    required this.availableSlots,
    required this.busySlots,
    required this.weeklyAvailability,
    required this.availabilityScore,
    required this.availableDays,
    required this.availableHours,
  });

  /// Создать из Map
  factory SpecialistAvailability.fromMap(Map<String, dynamic> data) => SpecialistAvailability(
        specialistId: data['specialistId'] ?? '',
        specialistName: data['specialistName'] ?? '',
        specialistPhoto: data['specialistPhoto'],
        availableSlots: (data['availableSlots'] as List?)
                ?.map((slot) => (slot as Timestamp).toDate())
                .toList() ??
            [],
        busySlots:
            (data['busySlots'] as List?)?.map((slot) => (slot as Timestamp).toDate()).toList() ??
                [],
        weeklyAvailability: Map<String, List<DateTime>>.from(
          (data['weeklyAvailability'] as Map?)?.map(
                (key, value) => MapEntry(
                  key.toString(),
                  (value as List).map((slot) => (slot as Timestamp).toDate()).toList(),
                ),
              ) ??
              {},
        ),
        availabilityScore: (data['availabilityScore'] ?? 0.0).toDouble(),
        availableDays: List<String>.from(data['availableDays'] ?? []),
        availableHours: List<int>.from(data['availableHours'] ?? []),
      );
  final String specialistId;
  final String specialistName;
  final String? specialistPhoto;
  final List<DateTime> availableSlots;
  final List<DateTime> busySlots;
  final Map<String, List<DateTime>> weeklyAvailability;
  final double availabilityScore; // 0.0 - 1.0
  final List<String> availableDays;
  final List<int> availableHours;

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
        'specialistId': specialistId,
        'specialistName': specialistName,
        'specialistPhoto': specialistPhoto,
        'availableSlots': availableSlots.map(Timestamp.fromDate).toList(),
        'busySlots': busySlots.map(Timestamp.fromDate).toList(),
        'weeklyAvailability': weeklyAvailability.map(
          (key, value) => MapEntry(
            key,
            value.map(Timestamp.fromDate).toList(),
          ),
        ),
        'availabilityScore': availabilityScore,
        'availableDays': availableDays,
        'availableHours': availableHours,
      };
}

/// Сервис для фильтрации специалистов по занятости
class AvailabilityFilterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить доступность специалиста
  Future<SpecialistAvailability> getSpecialistAvailability(
    String specialistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!FeatureFlags.availabilityFilterEnabled) {
      return _createMockAvailability(specialistId);
    }

    try {
      final now = DateTime.now();
      final start = startDate ?? now;
      final end = endDate ?? now.add(const Duration(days: 30));

      // Получаем расписание специалиста
      final scheduleQuery = await _firestore
          .collection('specialist_schedules')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .get();

      // Получаем бронирования специалиста
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'status',
            whereIn: [
              BookingStatus.pending.name,
              BookingStatus.confirmed.name,
            ],
          )
          .where('eventDate', isGreaterThanOrEqualTo: start)
          .where('eventDate', isLessThanOrEqualTo: end)
          .get();

      // Получаем информацию о специалисте
      final specialistDoc = await _firestore.collection('users').doc(specialistId).get();

      final specialistName = specialistDoc.data()?['displayName'] ?? 'Специалист';
      final specialistPhoto = specialistDoc.data()?['photoURL'];

      // Обрабатываем расписание
      final scheduleEvents = scheduleQuery.docs
          .map(
            (doc) => ScheduleEvent.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      // Обрабатываем бронирования
      final bookings = bookingsQuery.docs
          .map(
            (doc) => Booking.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      return _calculateAvailability(
        specialistId,
        specialistName,
        specialistPhoto,
        scheduleEvents,
        bookings,
        start,
        end,
      );
    } catch (e) {
      debugPrint('Error getting specialist availability: $e');
      return _createMockAvailability(specialistId);
    }
  }

  /// Получить список специалистов с фильтрацией по доступности
  Future<List<SpecialistAvailability>> getAvailableSpecialists(
    AvailabilityFilter filter,
  ) async {
    if (!FeatureFlags.availabilityFilterEnabled) {
      return _createMockSpecialistsList();
    }

    try {
      // Получаем всех специалистов
      final specialistsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.specialist.name)
          .get();

      final specialists = specialistsQuery.docs
          .map(
            AppUser.fromDocument,
          )
          .toList();

      final availabilityList = <SpecialistAvailability>[];

      // Для каждого специалиста проверяем доступность
      for (final specialist in specialists) {
        final availability = await getSpecialistAvailability(
          specialist.id,
          startDate: filter.startDate,
          endDate: filter.endDate,
        );

        // Применяем фильтры
        if (_matchesFilter(availability, filter)) {
          availabilityList.add(availability);
        }
      }

      // Сортируем по score доступности
      availabilityList.sort((a, b) => b.availabilityScore.compareTo(a.availabilityScore));

      return availabilityList;
    } catch (e) {
      debugPrint('Error getting available specialists: $e');
      return _createMockSpecialistsList();
    }
  }

  /// Получить занятые даты специалиста
  Future<List<DateTime>> getBusyDates(String specialistId) async {
    if (!FeatureFlags.availabilityFilterEnabled) {
      return _createMockBusyDates();
    }

    try {
      final now = DateTime.now();
      final endDate = now.add(const Duration(days: 90));

      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where(
            'status',
            whereIn: [
              BookingStatus.pending.name,
              BookingStatus.confirmed.name,
            ],
          )
          .where('eventDate', isGreaterThanOrEqualTo: now)
          .where('eventDate', isLessThanOrEqualTo: endDate)
          .get();

      final busyDates = <DateTime>[];

      for (final doc in bookingsQuery.docs) {
        final booking = Booking.fromMap({
          'id': doc.id,
          ...doc.data(),
        });

        // Добавляем дату события как занятую
        busyDates.add(
          DateTime(
            booking.eventDate.year,
            booking.eventDate.month,
            booking.eventDate.day,
          ),
        );
      }

      return busyDates;
    } catch (e) {
      debugPrint('Error getting busy dates: $e');
      return _createMockBusyDates();
    }
  }

  /// Получить доступные временные слоты для специалиста
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date, {
    Duration? duration,
  }) async {
    if (!FeatureFlags.availabilityFilterEnabled) {
      return _createMockTimeSlots(date);
    }

    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Получаем расписание на день
      final scheduleQuery = await _firestore
          .collection('specialist_schedules')
          .where('specialistId', isEqualTo: specialistId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      // Получаем бронирования на день
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('specialistId', isEqualTo: specialistId)
          .where('eventDate', isGreaterThanOrEqualTo: startOfDay)
          .where('eventDate', isLessThan: endOfDay)
          .where(
        'status',
        whereIn: [
          BookingStatus.pending.name,
          BookingStatus.confirmed.name,
        ],
      ).get();

      final scheduleEvents = scheduleQuery.docs
          .map(
            (doc) => ScheduleEvent.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      final bookings = bookingsQuery.docs
          .map(
            (doc) => Booking.fromMap({
              'id': doc.id,
              ...doc.data(),
            }),
          )
          .toList();

      return _calculateAvailableSlots(
        scheduleEvents,
        bookings,
        date,
        duration ?? const Duration(hours: 1),
      );
    } catch (e) {
      debugPrint('Error getting available time slots: $e');
      return _createMockTimeSlots(date);
    }
  }

  /// Проверить, соответствует ли специалист фильтру
  bool _matchesFilter(
    SpecialistAvailability availability,
    AvailabilityFilter filter,
  ) {
    if (!filter.onlyAvailable) return true;

    // Проверяем предпочитаемые дни
    if (filter.preferredDays != null) {
      final hasPreferredDays = filter.preferredDays!.any(
        (day) => availability.availableDays.contains(day),
      );
      if (!hasPreferredDays) return false;
    }

    // Проверяем предпочитаемые часы
    if (filter.preferredHours != null) {
      final hasPreferredHours = filter.preferredHours!.any(
        (hour) => availability.availableHours.contains(hour),
      );
      if (!hasPreferredHours) return false;
    }

    // Проверяем минимальный score доступности
    if (availability.availabilityScore < 0.3) return false;

    return true;
  }

  /// Вычислить доступность специалиста
  SpecialistAvailability _calculateAvailability(
    String specialistId,
    String specialistName,
    String? specialistPhoto,
    List<ScheduleEvent> scheduleEvents,
    List<Booking> bookings,
    DateTime startDate,
    DateTime endDate,
  ) {
    final availableSlots = <DateTime>[];
    final busySlots = <DateTime>[];
    final weeklyAvailability = <String, List<DateTime>>{};
    final availableDays = <String>[];
    final availableHours = <int>[];

    // Инициализируем дни недели
    for (var i = 0; i < 7; i++) {
      final dayName = _getDayName(i);
      weeklyAvailability[dayName] = [];
    }

    // Обрабатываем расписание
    for (final event in scheduleEvents) {
      if (event.isAvailable) {
        availableSlots.add(event.startTime);
        final dayName = _getDayName(event.startTime.weekday - 1);
        weeklyAvailability[dayName]!.add(event.startTime);

        if (!availableDays.contains(dayName)) {
          availableDays.add(dayName);
        }

        if (!availableHours.contains(event.startTime.hour)) {
          availableHours.add(event.startTime.hour);
        }
      } else {
        busySlots.add(event.startTime);
      }
    }

    // Обрабатываем бронирования
    for (final booking in bookings) {
      busySlots.add(booking.eventDate);
    }

    // Вычисляем score доступности
    final totalSlots = availableSlots.length + busySlots.length;
    final availabilityScore = totalSlots > 0 ? availableSlots.length / totalSlots : 0.0;

    return SpecialistAvailability(
      specialistId: specialistId,
      specialistName: specialistName,
      specialistPhoto: specialistPhoto,
      availableSlots: availableSlots,
      busySlots: busySlots,
      weeklyAvailability: weeklyAvailability,
      availabilityScore: availabilityScore,
      availableDays: availableDays,
      availableHours: availableHours,
    );
  }

  /// Вычислить доступные временные слоты
  List<DateTime> _calculateAvailableSlots(
    List<ScheduleEvent> scheduleEvents,
    List<Booking> bookings,
    DateTime date,
    Duration duration,
  ) {
    final availableSlots = <DateTime>[];

    // Рабочие часы (9:00 - 18:00)
    const startHour = 9;
    const endHour = 18;

    for (var hour = startHour; hour < endHour; hour++) {
      final slotTime = DateTime(date.year, date.month, date.day, hour);

      // Проверяем, не занят ли слот
      var isBusy = false;

      // Проверяем в расписании
      for (final event in scheduleEvents) {
        if (!event.isAvailable && event.startTime.hour == hour) {
          isBusy = true;
          break;
        }
      }

      // Проверяем в бронированиях
      if (!isBusy) {
        for (final booking in bookings) {
          if (booking.eventDate.hour == hour) {
            isBusy = true;
            break;
          }
        }
      }

      if (!isBusy) {
        availableSlots.add(slotTime);
      }
    }

    return availableSlots;
  }

  /// Получить название дня недели
  String _getDayName(int dayIndex) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    return days[dayIndex];
  }

  /// Создать mock доступность для демонстрации
  SpecialistAvailability _createMockAvailability(String specialistId) {
    final now = DateTime.now();
    final availableSlots = <DateTime>[];
    final busySlots = <DateTime>[];
    final weeklyAvailability = <String, List<DateTime>>{};

    // Инициализируем дни недели
    for (var i = 0; i < 7; i++) {
      final dayName = _getDayName(i);
      weeklyAvailability[dayName] = [];
    }

    // Создаем mock слоты на следующие 7 дней
    for (var day = 0; day < 7; day++) {
      final date = now.add(Duration(days: day));
      final dayName = _getDayName(date.weekday - 1);

      for (var hour = 9; hour < 18; hour++) {
        final slot = DateTime(date.year, date.month, date.day, hour);

        // 70% слотов доступны
        if (hour % 3 != 0) {
          availableSlots.add(slot);
          weeklyAvailability[dayName]!.add(slot);
        } else {
          busySlots.add(slot);
        }
      }
    }

    final availableDays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
    ];
    final availableHours = [9, 10, 11, 12, 13, 14, 15, 16, 17];

    return SpecialistAvailability(
      specialistId: specialistId,
      specialistName: 'Mock Специалист',
      specialistPhoto: 'https://via.placeholder.com/100x100/4CAF50/FFFFFF?text=MS',
      availableSlots: availableSlots,
      busySlots: busySlots,
      weeklyAvailability: weeklyAvailability,
      availabilityScore: 0.7,
      availableDays: availableDays,
      availableHours: availableHours,
    );
  }

  /// Создать mock список специалистов
  List<SpecialistAvailability> _createMockSpecialistsList() => [
        _createMockAvailability('specialist_1'),
        _createMockAvailability('specialist_2'),
        _createMockAvailability('specialist_3'),
      ];

  /// Создать mock занятые даты
  List<DateTime> _createMockBusyDates() {
    final now = DateTime.now();
    return [
      now.add(const Duration(days: 1)),
      now.add(const Duration(days: 3)),
      now.add(const Duration(days: 5)),
      now.add(const Duration(days: 7)),
    ];
  }

  /// Создать mock временные слоты
  List<DateTime> _createMockTimeSlots(DateTime date) {
    final slots = <DateTime>[];
    for (var hour = 9; hour < 18; hour++) {
      if (hour % 2 == 0) {
        // Каждый второй час доступен
        slots.add(DateTime(date.year, date.month, date.day, hour));
      }
    }
    return slots;
  }
}
