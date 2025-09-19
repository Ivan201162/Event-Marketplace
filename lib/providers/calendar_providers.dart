import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/calendar_event.dart';
import '../models/specialist_schedule.dart';
import '../services/calendar_service.dart';

/// Провайдер сервиса календаря
final calendarServiceProvider =
    Provider<CalendarService>((ref) => CalendarService());

/// Провайдер расписания специалиста
final specialistScheduleProvider =
    StreamProvider.family<SpecialistSchedule?, String>((ref, specialistId) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getSpecialistSchedule(specialistId);
});

/// Провайдер доступности даты
final dateAvailabilityProvider =
    FutureProvider.family<bool, DateAvailabilityParams>((ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.isDateAvailable(params.specialistId, params.date);
});

/// Провайдер доступности времени
final dateTimeAvailabilityProvider =
    FutureProvider.family<bool, DateTimeAvailabilityParams>((ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.isDateTimeAvailable(
    params.specialistId,
    params.dateTime,
  );
});

/// Провайдер доступных дат в диапазоне
final availableDatesProvider =
    FutureProvider.family<List<DateTime>, AvailableDatesParams>((ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getAvailableDates(
    params.specialistId,
    30, // days ahead
  );
});

/// Провайдер доступных временных слотов
final availableTimeSlotsProvider =
    FutureProvider.family<List<DateTime>, AvailableTimeSlotsParams>(
        (ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getAvailableTimeSlots(
    params.specialistId,
    params.date,
    params.slotDuration,
  );
});

/// Провайдер событий на дату
final eventsForDateProvider =
    FutureProvider.family<List<CalendarEvent>, EventsForDateParams>(
        (ref, params) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getEventsForDate(params.specialistId, params.date);
});

/// Провайдер всех расписаний (для админов)
final allSchedulesProvider = StreamProvider<List<SpecialistSchedule>>((ref) {
  final calendarService = ref.watch(calendarServiceProvider);
  return calendarService.getAllSchedules();
});

/// Провайдер для управления состоянием календаря
final calendarStateProvider =
    NotifierProvider<CalendarStateNotifier, CalendarState>(
  CalendarStateNotifier.new,
);

/// Состояние календаря
class CalendarState {
  const CalendarState({
    required this.selectedDate,
    required this.focusedDate,
    this.selectedSpecialistId,
    this.availableDates = const [],
    this.availableTimeSlots = const [],
    this.eventsForSelectedDate = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  final DateTime selectedDate;
  final DateTime focusedDate;
  final String? selectedSpecialistId;
  final List<DateTime> availableDates;
  final List<DateTime> availableTimeSlots;
  final List<CalendarEvent> eventsForSelectedDate;
  final bool isLoading;
  final String? errorMessage;

  CalendarState copyWith({
    DateTime? selectedDate,
    DateTime? focusedDate,
    String? selectedSpecialistId,
    List<DateTime>? availableDates,
    List<DateTime>? availableTimeSlots,
    List<CalendarEvent>? eventsForSelectedDate,
    bool? isLoading,
    String? errorMessage,
  }) =>
      CalendarState(
        selectedDate: selectedDate ?? this.selectedDate,
        focusedDate: focusedDate ?? this.focusedDate,
        selectedSpecialistId: selectedSpecialistId ?? this.selectedSpecialistId,
        availableDates: availableDates ?? this.availableDates,
        availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
        eventsForSelectedDate:
            eventsForSelectedDate ?? this.eventsForSelectedDate,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}

/// Нотификатор состояния календаря
class CalendarStateNotifier extends Notifier<CalendarState> {
  late final CalendarService _calendarService;

  @override
  CalendarState build() {
    _calendarService = ref.read(calendarServiceProvider);
    final now = DateTime.now();
    return CalendarState(
      selectedDate: now,
      focusedDate: now,
    );
  }

  /// Выбрать дату
  void selectDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
    _loadDataForSelectedDate();
  }

  /// Выбрать специалиста
  void selectSpecialist(String specialistId) {
    state = state.copyWith(selectedSpecialistId: specialistId);
    _loadDataForSelectedDate();
  }

  /// Загрузить данные для выбранной даты
  Future<void> _loadDataForSelectedDate() async {
    if (state.selectedSpecialistId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Загружаем доступные временные слоты
      final timeSlots = await _calendarService.getAvailableTimeSlots(
        state.selectedSpecialistId!,
        state.selectedDate,
        const Duration(hours: 1), // По умолчанию 1 час
      );

      // Загружаем события на дату
      final events = await _calendarService.getEventsForDate(
        state.selectedSpecialistId!,
        state.selectedDate,
      );

      state = state.copyWith(
        availableTimeSlots: timeSlots,
        eventsForSelectedDate: events,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Загрузить доступные даты в диапазоне
  Future<void> loadAvailableDates(DateTime startDate, DateTime endDate) async {
    if (state.selectedSpecialistId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final availableDates = await _calendarService.getAvailableDates(
        state.selectedSpecialistId!,
        30, // days ahead
      );

      state = state.copyWith(
        availableDates: availableDates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Добавить событие
  Future<void> addEvent(ScheduleEvent event) async {
    if (state.selectedSpecialistId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _calendarService.addEvent(
        state.selectedSpecialistId!,
        event as CalendarEvent,
      );
      await _loadDataForSelectedDate(); // Обновляем данные
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Удалить событие
  Future<void> removeEvent(String eventId) async {
    if (state.selectedSpecialistId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _calendarService.removeEvent(state.selectedSpecialistId!, eventId);
      await _loadDataForSelectedDate(); // Обновляем данные
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }
}

/// Параметры для проверки доступности даты
class DateAvailabilityParams {
  const DateAvailabilityParams({
    required this.specialistId,
    required this.date,
  });
  final String specialistId;
  final DateTime date;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateAvailabilityParams &&
        other.specialistId == specialistId &&
        other.date == date;
  }

  @override
  int get hashCode => specialistId.hashCode ^ date.hashCode;
}

/// Параметры для проверки доступности времени
class DateTimeAvailabilityParams {
  const DateTimeAvailabilityParams({
    required this.specialistId,
    required this.dateTime,
  });
  final String specialistId;
  final DateTime dateTime;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DateTimeAvailabilityParams &&
        other.specialistId == specialistId &&
        other.dateTime == dateTime;
  }

  @override
  int get hashCode => specialistId.hashCode ^ dateTime.hashCode;
}

/// Параметры для получения доступных дат
class AvailableDatesParams {
  const AvailableDatesParams({
    required this.specialistId,
    required this.startDate,
    required this.endDate,
  });
  final String specialistId;
  final DateTime startDate;
  final DateTime endDate;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailableDatesParams &&
        other.specialistId == specialistId &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode =>
      specialistId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

/// Параметры для получения доступных временных слотов
class AvailableTimeSlotsParams {
  const AvailableTimeSlotsParams({
    required this.specialistId,
    required this.date,
    this.slotDuration = const Duration(hours: 1),
  });
  final String specialistId;
  final DateTime date;
  final Duration slotDuration;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvailableTimeSlotsParams &&
        other.specialistId == specialistId &&
        other.date == date &&
        other.slotDuration == slotDuration;
  }

  @override
  int get hashCode =>
      specialistId.hashCode ^ date.hashCode ^ slotDuration.hashCode;
}

/// Параметры для получения событий на дату
class EventsForDateParams {
  const EventsForDateParams({
    required this.specialistId,
    required this.date,
  });
  final String specialistId;
  final DateTime date;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventsForDateParams &&
        other.specialistId == specialistId &&
        other.date == date;
  }

  @override
  int get hashCode => specialistId.hashCode ^ date.hashCode;
}
