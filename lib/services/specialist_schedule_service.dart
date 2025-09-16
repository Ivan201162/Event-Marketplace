import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/specialist_schedule.dart';

class SpecialistScheduleService {
  static const String _schedulesKey = 'specialist_schedules';

  // Получить расписание специалиста
  Future<SpecialistSchedule?> getSpecialistSchedule(String specialistId) async {
    final schedules = await getAllSchedules();
    try {
      return schedules
          .firstWhere((schedule) => schedule.specialistId == specialistId);
    } catch (e) {
      return null;
    }
  }

  // Получить все расписания
  Future<List<SpecialistSchedule>> getAllSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson = prefs.getStringList(_schedulesKey) ?? [];

    if (schedulesJson.isEmpty) {
      // Добавляем тестовые данные при первом запуске
      await _addTestData();
      return await getAllSchedules();
    }

    return schedulesJson
        .map((json) => SpecialistSchedule.fromMap(jsonDecode(json)))
        .toList();
  }

  // Сохранить расписание специалиста
  Future<void> saveSpecialistSchedule(SpecialistSchedule schedule) async {
    final schedules = await getAllSchedules();

    // Удаляем старое расписание если существует
    schedules.removeWhere((s) => s.specialistId == schedule.specialistId);

    // Добавляем новое
    schedules.add(schedule);

    await _saveSchedules(schedules);
  }

  // Добавить занятую дату
  Future<void> addBusyDate(String specialistId, DateTime date) async {
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
  }

  // Удалить занятую дату
  Future<void> removeBusyDate(String specialistId, DateTime date) async {
    final schedule = await getSpecialistSchedule(specialistId);
    if (schedule != null) {
      final updatedSchedule = schedule.removeBusyDate(date);
      await saveSpecialistSchedule(updatedSchedule);
    }
  }

  // Проверить, доступна ли дата
  Future<bool> isDateAvailable(String specialistId, DateTime date) async {
    final schedule = await getSpecialistSchedule(specialistId);
    if (schedule == null) return true; // Если расписания нет, дата доступна
    return !schedule.isDateBusy(date);
  }

  // Получить доступные даты в диапазоне
  Future<List<DateTime>> getAvailableDates(
      String specialistId, DateTime startDate, DateTime endDate) async {
    final schedule = await getSpecialistSchedule(specialistId);
    if (schedule == null) {
      // Если расписания нет, все даты доступны
      final availableDates = <DateTime>[];
      var currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      while (currentDate.isBefore(end) || currentDate.isAtSameMomentAs(end)) {
        availableDates.add(
            DateTime(currentDate.year, currentDate.month, currentDate.day));
        currentDate = currentDate.add(const Duration(days: 1));
      }
      return availableDates;
    }

    return schedule.getAvailableDates(startDate, endDate);
  }

  // Очистить все расписания (для тестирования)
  Future<void> clearAllSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_schedulesKey);
  }

  // Сохранить список расписаний
  Future<void> _saveSchedules(List<SpecialistSchedule> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final schedulesJson =
        schedules.map((schedule) => jsonEncode(schedule.toMap())).toList();
    await prefs.setStringList(_schedulesKey, schedulesJson);
  }

  // Добавить тестовые данные
  Future<void> _addTestData() async {
    final testSchedules = [
      SpecialistSchedule(
        specialistId: 'specialist1',
        busyDates: [
          DateTime(2025, 9, 15),
          DateTime(2025, 9, 16),
          DateTime(2025, 9, 22),
          DateTime(2025, 9, 23),
        ],
      ),
      SpecialistSchedule(
        specialistId: 'specialist2',
        busyDates: [
          DateTime(2025, 9, 18),
          DateTime(2025, 9, 19),
          DateTime(2025, 9, 25),
        ],
      ),
    ];

    for (final schedule in testSchedules) {
      await saveSpecialistSchedule(schedule);
    }
  }
}
