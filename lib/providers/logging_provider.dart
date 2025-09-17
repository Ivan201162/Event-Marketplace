import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logging_service.dart';

/// Провайдер для сервиса логирования
final loggingServiceProvider = Provider<LoggingService>((ref) {
  return LoggingService();
});

/// Провайдер для уровня логирования
final logLevelProvider =
    StateNotifierProvider<LogLevelNotifier, LogLevel>((ref) {
  return LogLevelNotifier();
});

/// Провайдер для настроек логирования
final loggingSettingsProvider =
    StateNotifierProvider<LoggingSettingsNotifier, LoggingSettings>((ref) {
  return LoggingSettingsNotifier();
});

/// Нотификатор для уровня логирования
class LogLevelNotifier extends StateNotifier<LogLevel> {
  LogLevelNotifier() : super(LogLevel.info) {
    _loadLogLevel();
  }

  Future<void> _loadLogLevel() async {
    state = LoggingService.getLogLevel();
  }

  Future<void> setLogLevel(LogLevel level) async {
    await LoggingService.setLogLevel(level);
    state = level;
  }
}

/// Настройки логирования
class LoggingSettings {
  final bool enableCrashlytics;
  final bool enablePerformance;
  final bool enableConsoleLogging;
  final bool enableFileLogging;
  final int maxLogFileSize;
  final int maxLogFiles;

  const LoggingSettings({
    this.enableCrashlytics = true,
    this.enablePerformance = true,
    this.enableConsoleLogging = true,
    this.enableFileLogging = false,
    this.maxLogFileSize = 10 * 1024 * 1024, // 10MB
    this.maxLogFiles = 5,
  });

  LoggingSettings copyWith({
    bool? enableCrashlytics,
    bool? enablePerformance,
    bool? enableConsoleLogging,
    bool? enableFileLogging,
    int? maxLogFileSize,
    int? maxLogFiles,
  }) {
    return LoggingSettings(
      enableCrashlytics: enableCrashlytics ?? this.enableCrashlytics,
      enablePerformance: enablePerformance ?? this.enablePerformance,
      enableConsoleLogging: enableConsoleLogging ?? this.enableConsoleLogging,
      enableFileLogging: enableFileLogging ?? this.enableFileLogging,
      maxLogFileSize: maxLogFileSize ?? this.maxLogFileSize,
      maxLogFiles: maxLogFiles ?? this.maxLogFiles,
    );
  }
}

/// Нотификатор для настроек логирования
class LoggingSettingsNotifier extends StateNotifier<LoggingSettings> {
  LoggingSettingsNotifier() : super(const LoggingSettings());

  Future<void> setCrashlyticsEnabled(bool enabled) async {
    await LoggingService.setCrashlyticsEnabled(enabled);
    state = state.copyWith(enableCrashlytics: enabled);
  }

  Future<void> setPerformanceEnabled(bool enabled) async {
    await LoggingService.setPerformanceEnabled(enabled);
    state = state.copyWith(enablePerformance: enabled);
  }

  void setConsoleLoggingEnabled(bool enabled) {
    state = state.copyWith(enableConsoleLogging: enabled);
  }

  void setFileLoggingEnabled(bool enabled) {
    state = state.copyWith(enableFileLogging: enabled);
  }

  void setMaxLogFileSize(int size) {
    state = state.copyWith(maxLogFileSize: size);
  }

  void setMaxLogFiles(int count) {
    state = state.copyWith(maxLogFiles: count);
  }
}

/// Провайдер для получения описания уровня логирования
final logLevelDescriptionProvider = Provider<String>((ref) {
  final level = ref.watch(logLevelProvider);

  switch (level) {
    case LogLevel.debug:
      return 'Отладка - все сообщения';
    case LogLevel.info:
      return 'Информация - важные события';
    case LogLevel.warning:
      return 'Предупреждения - потенциальные проблемы';
    case LogLevel.error:
      return 'Ошибки - критические проблемы';
    case LogLevel.fatal:
      return 'Критические ошибки - только фатальные';
  }
});

/// Провайдер для получения цвета уровня логирования
final logLevelColorProvider = Provider<int>((ref) {
  final level = ref.watch(logLevelProvider);

  switch (level) {
    case LogLevel.debug:
      return 0xFF9E9E9E; // Серый
    case LogLevel.info:
      return 0xFF2196F3; // Синий
    case LogLevel.warning:
      return 0xFFFF9800; // Оранжевый
    case LogLevel.error:
      return 0xFFF44336; // Красный
    case LogLevel.fatal:
      return 0xFFE91E63; // Розовый
  }
});

/// Провайдер для проверки, включено ли логирование
final isLoggingEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(loggingSettingsProvider);
  return settings.enableConsoleLogging ||
      settings.enableFileLogging ||
      settings.enableCrashlytics;
});

/// Провайдер для получения статистики логирования
final loggingStatsProvider = FutureProvider<LoggingStats>((ref) async {
  // В реальном приложении здесь можно получить статистику из файлов или базы данных
  return const LoggingStats(
    totalLogs: 0,
    errorLogs: 0,
    warningLogs: 0,
    infoLogs: 0,
    debugLogs: 0,
    lastLogTime: null,
  );
});

/// Статистика логирования
class LoggingStats {
  final int totalLogs;
  final int errorLogs;
  final int warningLogs;
  final int infoLogs;
  final int debugLogs;
  final DateTime? lastLogTime;

  const LoggingStats({
    required this.totalLogs,
    required this.errorLogs,
    required this.warningLogs,
    required this.infoLogs,
    required this.debugLogs,
    this.lastLogTime,
  });

  /// Получить процент ошибок
  double get errorPercentage {
    if (totalLogs == 0) return 0.0;
    return (errorLogs / totalLogs) * 100;
  }

  /// Получить процент предупреждений
  double get warningPercentage {
    if (totalLogs == 0) return 0.0;
    return (warningLogs / totalLogs) * 100;
  }

  /// Получить процент информационных сообщений
  double get infoPercentage {
    if (totalLogs == 0) return 0.0;
    return (infoLogs / totalLogs) * 100;
  }

  /// Получить процент отладочных сообщений
  double get debugPercentage {
    if (totalLogs == 0) return 0.0;
    return (debugLogs / totalLogs) * 100;
  }
}
