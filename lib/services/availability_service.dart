import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/availability_calendar.dart';

/// Сервис для управления календарем доступности специалистов
class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'availability_calendar';

  /// Получить календарь доступности специалиста
  Future<List<AvailabilityCalendar>> getSpecialistAvailability(
    String specialistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection(_collectionName)
          .where('specialistId', isEqualTo: specialistId);

      if (startDate != null) {
        query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.orderBy('date').get();
      return querySnapshot.docs.map(AvailabilityCalendar.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения календаря доступности: $e');
      return [];
    }
  }

  /// Поток календаря доступности специалиста
  Stream<List<AvailabilityCalendar>> getSpecialistAvailabilityStream(
    String specialistId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var query = _firestore
        .collection(_collectionName)
        .where('specialistId', isEqualTo: specialistId);

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }

    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    return query
        .orderBy('date')
        .snapshots()
        .map((querySnapshot) => querySnapshot.docs.map(AvailabilityCalendar.fromDocument).toList());
  }

  /// Добавить занятую дату
  Future<bool> addBusyDate(String specialistId, DateTime date, {String? note}) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';

      await _firestore.collection(_collectionName).doc(calendarId).set({
        'specialistId': specialistId,
        'date': Timestamp.fromDate(date),
        'timeSlots': [],
        'isAvailable': false,
        'note': note,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка добавления занятой даты: $e');
      return false;
    }
  }

  /// Добавить временной слот
  Future<bool> addTimeSlot(String specialistId, DateTime date, TimeSlot timeSlot) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';

      // Получить существующий календарь или создать новый
      final docRef = _firestore.collection(_collectionName).doc(calendarId);
      final doc = await docRef.get();

      if (doc.exists) {
        // Обновить существующий календарь
        final existingCalendar = AvailabilityCalendar.fromDocument(doc);
        final updatedTimeSlots = [...existingCalendar.timeSlots, timeSlot];

        await docRef.update({
          'timeSlots': updatedTimeSlots.map((slot) => slot.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });
      } else {
        // Создать новый календарь
        await docRef.set({
          'specialistId': specialistId,
          'date': Timestamp.fromDate(date),
          'timeSlots': [timeSlot.toMap()],
          'isAvailable': true,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка добавления временного слота: $e');
      return false;
    }
  }

  /// Заблокировать временной слот (для бронирования)
  Future<bool> blockTimeSlot(
    String specialistId,
    DateTime date,
    String timeSlotId,
    String bookingId,
  ) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
      final docRef = _firestore.collection(_collectionName).doc(calendarId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final calendar = AvailabilityCalendar.fromDocument(doc);
      final updatedTimeSlots = calendar.timeSlots.map((slot) {
        if (slot.id == timeSlotId) {
          return slot.copyWith(isAvailable: false, bookingId: bookingId);
        }
        return slot;
      }).toList();

      await docRef.update({
        'timeSlots': updatedTimeSlots.map((slot) => slot.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка блокировки временного слота: $e');
      return false;
    }
  }

  /// Разблокировать временной слот (отмена бронирования)
  Future<bool> unblockTimeSlot(String specialistId, DateTime date, String timeSlotId) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
      final docRef = _firestore.collection(_collectionName).doc(calendarId);
      final doc = await docRef.get();

      if (!doc.exists) return false;

      final calendar = AvailabilityCalendar.fromDocument(doc);
      final updatedTimeSlots = calendar.timeSlots.map((slot) {
        if (slot.id == timeSlotId) {
          return slot.copyWith(isAvailable: true);
        }
        return slot;
      }).toList();

      await docRef.update({
        'timeSlots': updatedTimeSlots.map((slot) => slot.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });

      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка разблокировки временного слота: $e');
      return false;
    }
  }

  /// Удалить занятую дату
  Future<bool> removeBusyDate(String specialistId, DateTime date) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
      await _firestore.collection(_collectionName).doc(calendarId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка удаления занятой даты: $e');
      return false;
    }
  }

  /// Проверить доступность специалиста в указанное время
  Future<bool> isSpecialistAvailable(String specialistId, DateTime dateTime) async {
    try {
      final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
      final doc = await _firestore.collection(_collectionName).doc(calendarId).get();

      if (!doc.exists) return true; // Если записи нет, специалист доступен

      final calendar = AvailabilityCalendar.fromDocument(doc);
      return calendar.isAvailableAt(dateTime);
    } on Exception catch (e) {
      debugPrint('Ошибка проверки доступности: $e');
      return false;
    }
  }

  /// Получить доступные временные слоты на дату
  Future<List<TimeSlot>> getAvailableTimeSlots(String specialistId, DateTime date) async {
    try {
      final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
      final doc = await _firestore.collection(_collectionName).doc(calendarId).get();

      if (!doc.exists) {
        // Если записи нет, возвращаем стандартные рабочие часы
        return _getDefaultWorkingHours(date);
      }

      final calendar = AvailabilityCalendar.fromDocument(doc);
      return calendar.getAvailableSlots(date);
    } on Exception catch (e) {
      debugPrint('Ошибка получения доступных слотов: $e');
      return [];
    }
  }

  /// Получить стандартные рабочие часы
  List<TimeSlot> _getDefaultWorkingHours(DateTime date) {
    final dayOfWeek = date.weekday;

    // Стандартные рабочие часы: 9:00-18:00 в будни
    if (dayOfWeek >= 1 && dayOfWeek <= 5) {
      final startTime = DateTime(date.year, date.month, date.day, 9);
      final endTime = DateTime(date.year, date.month, date.day, 18);

      return [
        TimeSlot(
          id: 'default_${startTime.millisecondsSinceEpoch}',
          startTime: startTime,
          endTime: endTime,
        ),
      ];
    }

    return [];
  }

  /// Массовое добавление занятых дат
  Future<bool> addMultipleBusyDates(
    String specialistId,
    List<DateTime> dates, {
    String? note,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final date in dates) {
        final calendarId = '${specialistId}_${date.toIso8601String().split('T')[0]}';
        final docRef = _firestore.collection(_collectionName).doc(calendarId);

        batch.set(docRef, {
          'specialistId': specialistId,
          'date': Timestamp.fromDate(date),
          'timeSlots': [],
          'isAvailable': false,
          'note': note,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return true;
    } on Exception catch (e) {
      debugPrint('Ошибка массового добавления занятых дат: $e');
      return false;
    }
  }
}
