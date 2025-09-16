import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../calendar/ics_export.dart';
import '../core/feature_flags.dart';

/// Провайдер для проверки доступности экспорта календаря
final calendarExportAvailableProvider = Provider<bool>((ref) {
  return FeatureFlags.calendarExportEnabled;
});

/// Провайдер для получения информации о поддерживаемых форматах
final supportedCalendarFormatsProvider = Provider<List<String>>((ref) {
  return IcsExportService.supportedFormats;
});

/// Провайдер для получения максимального количества событий для экспорта
final maxEventsPerExportProvider = Provider<int>((ref) {
  return IcsExportService.maxEventsPerExport;
});

/// Провайдер для проверки возможности экспорта
final canExportEventsProvider = Provider.family<bool, int>((ref, count) {
  return IcsExportService.canExportEvents(count);
});

/// Провайдер для экспорта одного события
final exportEventProvider = FutureProvider.family<String?, String>((ref, eventId) async {
  // Здесь можно добавить логику получения события по ID
  // Пока возвращаем null, так как нужен объект Event
  return null;
});

/// Провайдер для экспорта одного бронирования
final exportBookingProvider = FutureProvider.family<String?, String>((ref, bookingId) async {
  // Здесь можно добавить логику получения бронирования по ID
  // Пока возвращаем null, так как нужен объект Booking
  return null;
});

/// Провайдер для экспорта нескольких событий
final exportEventsProvider = FutureProvider.family<String?, List<String>>((ref, eventIds) async {
  // Здесь можно добавить логику получения событий по ID
  // Пока возвращаем null, так как нужны объекты Event
  return null;
});

/// Провайдер для экспорта нескольких бронирований
final exportBookingsProvider = FutureProvider.family<String?, List<String>>((ref, bookingIds) async {
  // Здесь можно добавить логику получения бронирований по ID
  // Пока возвращаем null, так как нужны объекты Booking
  return null;
});

/// Провайдер для проверки статуса экспорта
final exportStatusProvider = StateProvider<String>((ref) {
  return 'ready';
});

/// Провайдер для отслеживания прогресса экспорта
final exportProgressProvider = StateProvider<double>((ref) {
  return 0.0;
});

/// Провайдер для последней ошибки экспорта
final exportErrorProvider = StateProvider<String?>((ref) {
  return null;
});

/// Провайдер для истории экспорта
final exportHistoryProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

/// Провайдер для настроек экспорта
final exportSettingsProvider = StateNotifierProvider<ExportSettingsNotifier, ExportSettings>((ref) {
  return ExportSettingsNotifier();
});

/// Настройки экспорта
class ExportSettings {
  final bool includeDescription;
  final bool includeLocation;
  final bool includeAttendees;
  final bool includeReminders;
  final int reminderMinutes;
  final String defaultDuration;
  final bool autoShare;

  const ExportSettings({
    this.includeDescription = true,
    this.includeLocation = true,
    this.includeAttendees = false,
    this.includeReminders = true,
    this.reminderMinutes = 15,
    this.defaultDuration = '2 hours',
    this.autoShare = false,
  });

  ExportSettings copyWith({
    bool? includeDescription,
    bool? includeLocation,
    bool? includeAttendees,
    bool? includeReminders,
    int? reminderMinutes,
    String? defaultDuration,
    bool? autoShare,
  }) {
    return ExportSettings(
      includeDescription: includeDescription ?? this.includeDescription,
      includeLocation: includeLocation ?? this.includeLocation,
      includeAttendees: includeAttendees ?? this.includeAttendees,
      includeReminders: includeReminders ?? this.includeReminders,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      defaultDuration: defaultDuration ?? this.defaultDuration,
      autoShare: autoShare ?? this.autoShare,
    );
  }
}

/// Нотификатор для настроек экспорта
class ExportSettingsNotifier extends StateNotifier<ExportSettings> {
  ExportSettingsNotifier() : super(const ExportSettings());

  void updateIncludeDescription(bool value) {
    state = state.copyWith(includeDescription: value);
  }

  void updateIncludeLocation(bool value) {
    state = state.copyWith(includeLocation: value);
  }

  void updateIncludeAttendees(bool value) {
    state = state.copyWith(includeAttendees: value);
  }

  void updateIncludeReminders(bool value) {
    state = state.copyWith(includeReminders: value);
  }

  void updateReminderMinutes(int minutes) {
    state = state.copyWith(reminderMinutes: minutes);
  }

  void updateDefaultDuration(String duration) {
    state = state.copyWith(defaultDuration: duration);
  }

  void updateAutoShare(bool value) {
    state = state.copyWith(autoShare: value);
  }

  void resetToDefaults() {
    state = const ExportSettings();
  }
}

/// Провайдер для статистики экспорта
final exportStatsProvider = StateProvider<Map<String, int>>((ref) {
  return {
    'totalExports': 0,
    'successfulExports': 0,
    'failedExports': 0,
    'eventsExported': 0,
    'bookingsExported': 0,
  };
});

/// Провайдер для последнего экспорта
final lastExportProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return null;
});

/// Провайдер для активных экспортов
final activeExportsProvider = StateProvider<Set<String>>((ref) {
  return {};
});

/// Провайдер для очереди экспорта
final exportQueueProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

/// Провайдер для проверки, идет ли экспорт
final isExportingProvider = Provider<bool>((ref) {
  final activeExports = ref.watch(activeExportsProvider);
  return activeExports.isNotEmpty;
});

/// Провайдер для получения количества элементов в очереди
final exportQueueLengthProvider = Provider<int>((ref) {
  final queue = ref.watch(exportQueueProvider);
  return queue.length;
});

/// Провайдер для получения следующего элемента в очереди
final nextExportItemProvider = Provider<Map<String, dynamic>?>((ref) {
  final queue = ref.watch(exportQueueProvider);
  return queue.isNotEmpty ? queue.first : null;
});

/// Провайдер для проверки, можно ли добавить в очередь
final canAddToQueueProvider = Provider.family<bool, int>((ref, count) {
  final queueLength = ref.watch(exportQueueLengthProvider);
  final maxEvents = ref.watch(maxEventsPerExportProvider);
  return queueLength < 10 && count <= maxEvents;
});

/// Провайдер для получения информации о экспорте
final exportInfoProvider = Provider<Map<String, dynamic>>((ref) {
  final isAvailable = ref.watch(calendarExportAvailableProvider);
  final supportedFormats = ref.watch(supportedCalendarFormatsProvider);
  final maxEvents = ref.watch(maxEventsPerExportProvider);
  final isExporting = ref.watch(isExportingProvider);
  final queueLength = ref.watch(exportQueueLengthProvider);

  return {
    'isAvailable': isAvailable,
    'supportedFormats': supportedFormats,
    'maxEventsPerExport': maxEvents,
    'isExporting': isExporting,
    'queueLength': queueLength,
  };
});
