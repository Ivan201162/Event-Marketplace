import 'package:event_marketplace_app/calendar/ics_export.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для проверки доступности экспорта календаря
final calendarExportAvailableProvider =
    Provider<bool>((ref) => FeatureFlags.calendarExportEnabled);

/// Провайдер для получения информации о поддерживаемых форматах
final supportedCalendarFormatsProvider = Provider<List<String>>(
  (ref) => IcsExportService.supportedFormats,
);

/// Провайдер для получения максимального количества событий для экспорта
final maxEventsPerExportProvider =
    Provider<int>((ref) => IcsExportService.maxEventsPerExport);

/// Провайдер для проверки возможности экспорта
final canExportEventsProvider = Provider.family<bool, int>(
  (ref, count) => IcsExportService.canExportEvents(count),
);

/// Провайдер для экспорта одного события
final exportEventProvider =
    FutureProvider.family<String?, String>((ref, eventId) async {
  // Здесь можно добавить логику получения события по ID
  // Пока возвращаем null, так как нужен объект Event
  return null;
});

/// Провайдер для экспорта одного бронирования
final exportBookingProvider =
    FutureProvider.family<String?, String>((ref, bookingId) async {
  // Здесь можно добавить логику получения бронирования по ID
  // Пока возвращаем null, так как нужен объект Booking
  return null;
});

/// Провайдер для экспорта нескольких событий
final exportEventsProvider =
    FutureProvider.family<String?, List<String>>((ref, eventIds) async {
  // Здесь можно добавить логику получения событий по ID
  // Пока возвращаем null, так как нужны объекты Event
  return null;
});

/// Провайдер для экспорта нескольких бронирований
final exportBookingsProvider = FutureProvider.family<String?, List<String>>((
  ref,
  bookingIds,
) async {
  // Здесь можно добавить логику получения бронирований по ID
  // Пока возвращаем null, так как нужны объекты Booking
  return null;
});

/// Нотификатор для проверки статуса экспорта
class ExportStatusNotifier extends Notifier<String> {
  @override
  String build() => 'ready';

  void setStatus(String status) {
    state = status;
  }
}

/// Провайдер для проверки статуса экспорта
final exportStatusProvider = NotifierProvider<ExportStatusNotifier, String>(
  ExportStatusNotifier.new,
);

/// Нотификатор для отслеживания прогресса экспорта
class ExportProgressNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void setProgress(double progress) {
    state = progress;
  }
}

/// Провайдер для отслеживания прогресса экспорта
final exportProgressProvider = NotifierProvider<ExportProgressNotifier, double>(
  ExportProgressNotifier.new,
);

/// Нотификатор для последней ошибки экспорта
class ExportErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }
}

/// Провайдер для последней ошибки экспорта
final exportErrorProvider =
    NotifierProvider<ExportErrorNotifier, String?>(ExportErrorNotifier.new);

/// Нотификатор для истории экспорта
class ExportHistoryNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addExport(Map<String, dynamic> export) {
    state = [...state, export];
  }

  void clearHistory() {
    state = [];
  }
}

/// Провайдер для истории экспорта
final exportHistoryProvider =
    NotifierProvider<ExportHistoryNotifier, List<Map<String, dynamic>>>(
  ExportHistoryNotifier.new,
);

/// Провайдер для настроек экспорта
final exportSettingsProvider =
    NotifierProvider<ExportSettingsNotifier, ExportSettings>(
  ExportSettingsNotifier.new,
);

/// Настройки экспорта
class ExportSettings {
  const ExportSettings({
    this.includeDescription = true,
    this.includeLocation = true,
    this.includeAttendees = false,
    this.includeReminders = true,
    this.reminderMinutes = 15,
    this.defaultDuration = '2 hours',
    this.autoShare = false,
  });
  final bool includeDescription;
  final bool includeLocation;
  final bool includeAttendees;
  final bool includeReminders;
  final int reminderMinutes;
  final String defaultDuration;
  final bool autoShare;

  ExportSettings copyWith({
    bool? includeDescription,
    bool? includeLocation,
    bool? includeAttendees,
    bool? includeReminders,
    int? reminderMinutes,
    String? defaultDuration,
    bool? autoShare,
  }) =>
      ExportSettings(
        includeDescription: includeDescription ?? this.includeDescription,
        includeLocation: includeLocation ?? this.includeLocation,
        includeAttendees: includeAttendees ?? this.includeAttendees,
        includeReminders: includeReminders ?? this.includeReminders,
        reminderMinutes: reminderMinutes ?? this.reminderMinutes,
        defaultDuration: defaultDuration ?? this.defaultDuration,
        autoShare: autoShare ?? this.autoShare,
      );
}

/// Нотификатор для настроек экспорта
class ExportSettingsNotifier extends Notifier<ExportSettings> {
  @override
  ExportSettings build() => const ExportSettings();

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

/// Нотификатор для статистики экспорта
class ExportStatsNotifier extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => {
        'totalExports': 0,
        'successfulExports': 0,
        'failedExports': 0,
        'eventsExported': 0,
        'bookingsExported': 0,
      };

  void incrementStat(String key) {
    state = {...state, key: (state[key] ?? 0) + 1};
  }

  void resetStats() {
    state = {
      'totalExports': 0,
      'successfulExports': 0,
      'failedExports': 0,
      'eventsExported': 0,
      'bookingsExported': 0,
    };
  }
}

/// Провайдер для статистики экспорта
final exportStatsProvider =
    NotifierProvider<ExportStatsNotifier, Map<String, int>>(
  ExportStatsNotifier.new,
);

/// Нотификатор для последнего экспорта
class LastExportNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void setLastExport(Map<String, dynamic>? export) {
    state = export;
  }
}

/// Провайдер для последнего экспорта
final lastExportProvider =
    NotifierProvider<LastExportNotifier, Map<String, dynamic>?>(
  LastExportNotifier.new,
);

/// Нотификатор для активных экспортов
class ActiveExportsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void addExport(String exportId) {
    state = {...state, exportId};
  }

  void removeExport(String exportId) {
    state = state.where((id) => id != exportId).toSet();
  }

  void clearExports() {
    state = {};
  }
}

/// Провайдер для активных экспортов
final activeExportsProvider =
    NotifierProvider<ActiveExportsNotifier, Set<String>>(
  ActiveExportsNotifier.new,
);

/// Нотификатор для очереди экспорта
class ExportQueueNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() => [];

  void addToQueue(Map<String, dynamic> export) {
    state = [...state, export];
  }

  void removeFromQueue(String exportId) {
    state = state.where((export) => export['id'] != exportId).toList();
  }

  void clearQueue() {
    state = [];
  }
}

/// Провайдер для очереди экспорта
final exportQueueProvider =
    NotifierProvider<ExportQueueNotifier, List<Map<String, dynamic>>>(
  ExportQueueNotifier.new,
);

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
