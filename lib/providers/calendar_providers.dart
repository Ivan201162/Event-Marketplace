import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event.dart';
import '../services/calendar_service.dart';
import '../services/reminder_service.dart';
import '../services/booking_calendar_integration.dart';

/// Провайдер сервиса календаря
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

/// Провайдер сервиса напоминаний
final reminderServiceProvider = Provider<ReminderService>((ref) {
  return ReminderService();
});

/// Провайдер интеграции календаря с бронированиями
final bookingCalendarIntegrationProvider = Provider<BookingCalendarIntegration>((ref) {
  return BookingCalendarIntegration();
});

/// Провайдер событий календаря для периода
final calendarEventsProvider = StreamProvider.family<List<CalendarEvent>, CalendarEventsParams>((ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getEventsStream(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Провайдер событий на сегодня
final todayEventsProvider = FutureProvider.family<List<CalendarEvent>, String>((ref, userId) async {
  final calendarService = ref.watch(calendarServiceProvider);
  return await calendarService.getTodayEvents(userId);
});

/// Провайдер предстоящих событий
final upcomingEventsProvider = FutureProvider.family<List<CalendarEvent>, String>((ref, userId) async {
  final calendarService = ref.watch(calendarServiceProvider);
  return await calendarService.getUpcomingEvents(userId: userId, limit: 10);
});

/// Провайдер статистики календаря
final calendarStatsProvider = FutureProvider.family<CalendarStats, CalendarStatsParams>((ref, params) async {
  final calendarService = ref.watch(calendarServiceProvider);
  return await calendarService.getCalendarStats(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Провайдер доступных слотов времени
final availableTimeSlotsProvider = FutureProvider.family<List<TimeSlot>, AvailableSlotsParams>((ref, params) async {
  final calendarService = ref.watch(calendarServiceProvider);
  return await calendarService.getAvailableTimeSlots(
    userId: params.userId,
    date: params.date,
    slotDuration: params.slotDuration,
    workingHoursStart: params.workingHoursStart,
    workingHoursEnd: params.workingHoursEnd,
  );
});

/// Провайдер доступности специалиста
final specialistAvailabilityProvider = FutureProvider.family<bool, AvailabilityCheckParams>((ref, params) async {
  final integration = ref.watch(bookingCalendarIntegrationProvider);
  return await integration.isSpecialistAvailable(
    specialistId: params.specialistId,
    startDate: params.startDate,
    endDate: params.endDate,
    excludeBookingId: params.excludeBookingId,
  );
});

/// Провайдер статистики доступности специалиста
final specialistAvailabilityStatsProvider = FutureProvider.family<SpecialistAvailabilityStats, AvailabilityStatsParams>((ref, params) async {
  final integration = ref.watch(bookingCalendarIntegrationProvider);
  return await integration.getSpecialistAvailabilityStats(
    specialistId: params.specialistId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Провайдер конфликтов в расписании
final scheduleConflictsProvider = FutureProvider.family<List<ScheduleConflict>, ScheduleConflictsParams>((ref, params) async {
  final integration = ref.watch(bookingCalendarIntegrationProvider);
  return await integration.getScheduleConflicts(
    userId: params.userId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Провайдер предстоящих напоминаний
final upcomingRemindersProvider = FutureProvider.family<List<EventReminder>, String>((ref, userId) async {
  final reminderService = ref.watch(reminderServiceProvider);
  return await reminderService.getUpcomingReminders(userId);
});

/// Провайдер состояния календаря
final calendarStateProvider = StateNotifierProvider<CalendarStateNotifier, CalendarState>((ref) {
  return CalendarStateNotifier(ref);
});

/// Состояние календаря
class CalendarState {
  const CalendarState({
    this.selectedDate = const {},
    this.viewMode = CalendarViewMode.month,
    this.isLoading = false,
    this.error,
  });

  final Map<String, DateTime> selectedDate;
  final CalendarViewMode viewMode;
  final bool isLoading;
  final String? error;

  CalendarState copyWith({
    Map<String, DateTime>? selectedDate,
    CalendarViewMode? viewMode,
    bool? isLoading,
    String? error,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Нотификатор состояния календаря
class CalendarStateNotifier extends StateNotifier<CalendarState> {
  CalendarStateNotifier(this.ref) : super(const CalendarState());

  final Ref ref;

  /// Установить выбранную дату
  void setSelectedDate(String userId, DateTime date) {
    state = state.copyWith(
      selectedDate: {...state.selectedDate, userId: date},
    );
  }

  /// Установить режим просмотра
  void setViewMode(CalendarViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  /// Установить состояние загрузки
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Установить ошибку
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Режим просмотра календаря
enum CalendarViewMode {
  month,
  week,
  day,
}

/// Параметры для получения событий календаря
class CalendarEventsParams {
  const CalendarEventsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;
}

/// Параметры для получения статистики календаря
class CalendarStatsParams {
  const CalendarStatsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;
}

/// Параметры для получения доступных слотов
class AvailableSlotsParams {
  const AvailableSlotsParams({
    required this.userId,
    required this.date,
    this.slotDuration = const Duration(hours: 1),
    this.workingHoursStart = const Duration(hours: 9),
    this.workingHoursEnd = const Duration(hours: 18),
  });

  final String userId;
  final DateTime date;
  final Duration slotDuration;
  final Duration workingHoursStart;
  final Duration workingHoursEnd;
}

/// Параметры для проверки доступности
class AvailabilityCheckParams {
  const AvailabilityCheckParams({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
    this.excludeBookingId,
  });

  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;
  final String? excludeBookingId;
}

/// Параметры для статистики доступности
class AvailabilityStatsParams {
  const AvailabilityStatsParams({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
  });

  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;
}

/// Параметры для конфликтов расписания
class ScheduleConflictsParams {
  const ScheduleConflictsParams({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  final String userId;
  final DateTime startDate;
  final DateTime endDate;
}