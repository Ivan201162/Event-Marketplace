import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/calendar_service.dart';

/// Провайдер для сервиса календаря
final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());

/// Провайдер для получения занятых дат специалиста
final specialistBusyDatesProvider = FutureProvider.family<List<DateTime>, String>((
  ref,
  specialistId,
) async {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getBusyDates(specialistId);
});

/// Провайдер для получения свободных дат специалиста в диапазоне
final specialistAvailableDatesProvider =
    FutureProvider.family<List<DateTime>, Map<String, dynamic>>((ref, params) async {
      final calendarService = ref.watch(calendarServiceProvider);
      final specialistId = params['specialistId'] as String;
      final startDate = params['startDate'] as DateTime;
      final endDate = params['endDate'] as DateTime;

      return calendarService.getAvailableDates(specialistId, 30);
    });

/// Провайдер для проверки доступности даты
final dateAvailabilityProvider = FutureProvider.family<bool, Map<String, dynamic>>((
  ref,
  params,
) async {
  final calendarService = ref.watch(calendarServiceProvider);
  final specialistId = params['specialistId'] as String;
  final date = params['date'] as DateTime;

  return calendarService.isDateAvailable(specialistId, date);
});

/// Провайдер для проверки доступности даты и времени
final dateTimeAvailabilityProvider = FutureProvider.family<bool, Map<String, dynamic>>((
  ref,
  params,
) async {
  final calendarService = ref.watch(calendarServiceProvider);
  final specialistId = params['specialistId'] as String;
  final dateTime = params['dateTime'] as DateTime;

  return calendarService.isDateTimeAvailable(specialistId, dateTime);
});

/// Провайдер для получения доступных временных слотов
final availableTimeSlotsProvider = FutureProvider.family<List<DateTime>, Map<String, dynamic>>((
  ref,
  params,
) async {
  final calendarService = ref.watch(calendarServiceProvider);
  final specialistId = params['specialistId'] as String;
  final date = params['date'] as DateTime;
  final slotDuration = params['slotDuration'] as Duration;

  return calendarService.getAvailableTimeSlots(specialistId, date, slotDuration);
});

/// Провайдер для управления занятыми датами (мигрирован с StateNotifierProvider)
final busyDatesManagerProvider = NotifierProvider<BusyDatesManager, AsyncValue<void>>(() {
  return BusyDatesManager();
});

/// Менеджер для управления занятыми датами (мигрирован с StateNotifier)
class BusyDatesManager extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  CalendarService get _calendarService => ref.read(calendarServiceProvider);

  /// Пометить дату как занятую
  Future<void> markDateBusy(String specialistId, DateTime date) async {
    state = const AsyncValue.loading();

    try {
      final success = await _calendarService.markDateBusy(specialistId, date);
      if (success) {
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.error('Не удалось пометить дату как занятую', StackTrace.current);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Пометить дату как свободную
  Future<void> markDateFree(String specialistId, DateTime date) async {
    state = const AsyncValue.loading();

    try {
      final success = await _calendarService.markDateFree(specialistId, date);
      if (success) {
        state = const AsyncValue.data(null);
      } else {
        state = const AsyncValue.error(
          'Не удалось пометить дату как свободную',
          StackTrace.current,
        );
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Синхронизировать занятые даты с бронированиями
  Future<void> syncBusyDatesWithBookings(String specialistId) async {
    state = const AsyncValue.loading();

    try {
      await _calendarService.syncBusyDatesWithBookings(specialistId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

/// Провайдер для получения календарных данных специалиста
final specialistCalendarDataProvider = FutureProvider.family<SpecialistCalendarData, String>((
  ref,
  specialistId,
) async {
  final calendarService = ref.watch(calendarServiceProvider);

  // Получаем занятые даты
  final busyDates = await calendarService.getBusyDates(specialistId);

  // Получаем доступные даты на следующий месяц
  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1);
  final endOfNextMonth = DateTime(now.year, now.month + 2, 0);
  final availableDates = await calendarService.getAvailableDates(specialistId, 30);

  return SpecialistCalendarData(
    specialistId: specialistId,
    busyDates: busyDates,
    availableDates: availableDates,
    lastUpdated: DateTime.now(),
  );
});

/// Модель данных календаря специалиста
class SpecialistCalendarData {
  const SpecialistCalendarData({
    required this.specialistId,
    required this.busyDates,
    required this.availableDates,
    required this.lastUpdated,
  });

  final String specialistId;
  final List<DateTime> busyDates;
  final List<DateTime> availableDates;
  final DateTime lastUpdated;

  /// Проверить, занята ли дата
  bool isDateBusy(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return busyDates.any(
      (busyDate) =>
          busyDate.year == normalizedDate.year &&
          busyDate.month == normalizedDate.month &&
          busyDate.day == normalizedDate.day,
    );
  }

  /// Проверить, доступна ли дата
  bool isDateAvailable(DateTime date) => !isDateBusy(date);

  /// Получить статистику доступности
  AvailabilityStats get availabilityStats {
    final totalDays = availableDates.length + busyDates.length;
    final availableCount = availableDates.length;
    final busyCount = busyDates.length;

    return AvailabilityStats(
      totalDays: totalDays,
      availableDays: availableCount,
      busyDays: busyCount,
      availabilityPercentage: totalDays > 0 ? (availableCount / totalDays * 100) : 0.0,
    );
  }
}

/// Статистика доступности
class AvailabilityStats {
  const AvailabilityStats({
    required this.totalDays,
    required this.availableDays,
    required this.busyDays,
    required this.availabilityPercentage,
  });

  final int totalDays;
  final int availableDays;
  final int busyDays;
  final double availabilityPercentage;

  /// Получить цвет для отображения статистики
  String get availabilityColor {
    if (availabilityPercentage >= 80) return 'green';
    if (availabilityPercentage >= 60) return 'orange';
    return 'red';
  }

  /// Получить текст статуса доступности
  String get availabilityStatus {
    if (availabilityPercentage >= 80) return 'Высокая доступность';
    if (availabilityPercentage >= 60) return 'Средняя доступность';
    return 'Низкая доступность';
  }
}
