import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/specialist_schedule.dart';

/// Сервис для управления календарем и расписанием специалистов
class CalendarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Получить расписание специалиста
  Future<SpecialistSchedule?> getSpecialistSchedule(String specialistId) async {
    try {
      final doc = await _db.collection('schedules').doc(specialistId).get();
      if (doc.exists) {
        return SpecialistSchedule.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения расписания: $e');
      return null;
    }
  }

  /// Поток расписания специалиста
  Stream<SpecialistSchedule?> getSpecialistScheduleStream(String specialistId) {
    return _db.collection('schedules').doc(specialistId).snapshots().map((doc) {
      if (doc.exists) {
        return SpecialistSchedule.fromDocument(doc);
      }
      return null;
    });
  }

  /// Сохранить расписание специалиста
  Future<void> saveSpecialistSchedule(SpecialistSchedule schedule) async {
    try {
      await _db.collection('schedules').doc(schedule.specialistId).set(schedule.toMap());
    } catch (e) {
      print('Ошибка сохранения расписания: $e');
      throw Exception('Не удалось сохранить расписание: $e');
    }
  }

  /// Добавить событие в расписание
  Future<void> addEvent(String specialistId, ScheduleEvent event) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule != null) {
        final updatedSchedule = schedule.addEvent(event);
        await saveSpecialistSchedule(updatedSchedule);
      } else {
        // Создаем новое расписание если его нет
        final newSchedule = SpecialistSchedule(
          specialistId: specialistId,
          busyDates: [],
          events: [event],
        );
        await saveSpecialistSchedule(newSchedule);
      }
    } catch (e) {
      print('Ошибка добавления события: $e');
      throw Exception('Не удалось добавить событие: $e');
    }
  }

  /// Удалить событие из расписания
  Future<void> removeEvent(String specialistId, String eventId) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule != null) {
        final updatedSchedule = schedule.removeEvent(eventId);
        await saveSpecialistSchedule(updatedSchedule);
      }
    } catch (e) {
      print('Ошибка удаления события: $e');
      throw Exception('Не удалось удалить событие: $e');
    }
  }

  /// Добавить занятую дату
  Future<void> addBusyDate(String specialistId, DateTime date) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule != null) {
        final updatedSchedule = schedule.addBusyDate(date);
        await saveSpecialistSchedule(updatedSchedule);
      } else {
        // Создаем новое расписание если его нет
        final newSchedule = SpecialistSchedule(
          specialistId: specialistId,
          busyDates: [date],
        );
        await saveSpecialistSchedule(newSchedule);
      }
    } catch (e) {
      print('Ошибка добавления занятой даты: $e');
      throw Exception('Не удалось добавить занятую дату: $e');
    }
  }

  /// Удалить занятую дату
  Future<void> removeBusyDate(String specialistId, DateTime date) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule != null) {
        final updatedSchedule = schedule.removeBusyDate(date);
        await saveSpecialistSchedule(updatedSchedule);
      }
    } catch (e) {
      print('Ошибка удаления занятой даты: $e');
      throw Exception('Не удалось удалить занятую дату: $e');
    }
  }

  /// Проверить, доступна ли дата
  Future<bool> isDateAvailable(String specialistId, DateTime date) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule == null) return true; // Если расписания нет, дата доступна
      return !schedule.isDateBusy(date);
    } catch (e) {
      print('Ошибка проверки доступности даты: $e');
      return false;
    }
  }

  /// Проверить, доступно ли время
  Future<bool> isDateTimeAvailable(String specialistId, DateTime dateTime) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule == null) return true; // Если расписания нет, время доступно
      return schedule.isDateTimeAvailable(dateTime);
    } catch (e) {
      print('Ошибка проверки доступности времени: $e');
      return false;
    }
  }

  /// Получить доступные даты в диапазоне
  Future<List<DateTime>> getAvailableDates(
    String specialistId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule == null) {
        // Если расписания нет, все даты доступны
        final availableDates = <DateTime>[];
        var currentDate = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day);

        while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
          availableDates.add(DateTime(currentDate.year, currentDate.month, currentDate.day));
          currentDate = currentDate.add(const Duration(days: 1));
        }
        return availableDates;
      }
      
      return schedule.getAvailableDates(startDate, endDate);
    } catch (e) {
      print('Ошибка получения доступных дат: $e');
      return [];
    }
  }

  /// Получить доступные временные слоты на дату
  Future<List<DateTime>> getAvailableTimeSlots(
    String specialistId,
    DateTime date, {
    Duration slotDuration = const Duration(hours: 1),
  }) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule == null) {
        // Если расписания нет, генерируем стандартные слоты
        final availableSlots = <DateTime>[];
        final startOfDay = DateTime(date.year, date.month, date.day, 9); // 9:00
        final endOfDay = DateTime(date.year, date.month, date.day, 18); // 18:00
        
        var currentTime = startOfDay;
        while (currentTime.isBefore(endOfDay)) {
          availableSlots.add(currentTime);
          currentTime = currentTime.add(slotDuration);
        }
        return availableSlots;
      }
      
      return schedule.getAvailableTimeSlots(date, slotDuration: slotDuration);
    } catch (e) {
      print('Ошибка получения доступных временных слотов: $e');
      return [];
    }
  }

  /// Получить события на дату
  Future<List<ScheduleEvent>> getEventsForDate(String specialistId, DateTime date) async {
    try {
      final schedule = await getSpecialistSchedule(specialistId);
      if (schedule == null) return [];
      return schedule.getEventsForDate(date);
    } catch (e) {
      print('Ошибка получения событий на дату: $e');
      return [];
    }
  }

  /// Создать событие бронирования
  Future<void> createBookingEvent({
    required String specialistId,
    required String bookingId,
    required String customerName,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) async {
    final event = ScheduleEvent(
      id: 'booking_$bookingId',
      title: 'Бронирование: $customerName',
      startTime: startTime,
      endTime: endTime,
      type: ScheduleEventType.booking,
      description: description,
      bookingId: bookingId,
    );

    await addEvent(specialistId, event);
  }

  /// Удалить событие бронирования
  Future<void> removeBookingEvent(String specialistId, String bookingId) async {
    await removeEvent(specialistId, 'booking_$bookingId');
  }

  /// Создать событие недоступности
  Future<void> createUnavailableEvent({
    required String specialistId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) async {
    final event = ScheduleEvent(
      id: 'unavailable_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: ScheduleEventType.unavailable,
      description: description,
    );

    await addEvent(specialistId, event);
  }

  /// Создать событие отпуска
  Future<void> createVacationEvent({
    required String specialistId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? description,
  }) async {
    final event = ScheduleEvent(
      id: 'vacation_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      startTime: startTime,
      endTime: endTime,
      type: ScheduleEventType.vacation,
      description: description,
    );

    await addEvent(specialistId, event);
  }

  /// Получить все расписания (для админов)
  Stream<List<SpecialistSchedule>> getAllSchedulesStream() {
    return _db.collection('schedules').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => SpecialistSchedule.fromDocument(doc)).toList();
    });
  }

  /// Добавить тестовые данные
  Future<void> addTestData() async {
    try {
      final now = DateTime.now();
      
      // Тестовое расписание для specialist1
      final schedule1 = SpecialistSchedule(
        specialistId: 'specialist1',
        busyDates: [
          now.add(const Duration(days: 1)),
          now.add(const Duration(days: 2)),
        ],
        events: [
          ScheduleEvent(
            id: 'test_event_1',
            title: 'Тестовое мероприятие',
            startTime: now.add(const Duration(days: 3, hours: 10)),
            endTime: now.add(const Duration(days: 3, hours: 12)),
            type: ScheduleEventType.booking,
            description: 'Тестовое бронирование',
          ),
        ],
      );

      // Тестовое расписание для specialist2
      final schedule2 = SpecialistSchedule(
        specialistId: 'specialist2',
        busyDates: [],
        events: [
          ScheduleEvent(
            id: 'test_event_2',
            title: 'Отпуск',
            startTime: now.add(const Duration(days: 5)),
            endTime: now.add(const Duration(days: 7)),
            type: ScheduleEventType.vacation,
            description: 'Ежегодный отпуск',
          ),
        ],
      );

      await saveSpecialistSchedule(schedule1);
      await saveSpecialistSchedule(schedule2);
    } catch (e) {
      print('Ошибка добавления тестовых данных: $e');
      throw Exception('Не удалось добавить тестовые данные: $e');
    }
  }
}
