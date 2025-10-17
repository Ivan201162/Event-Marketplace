import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Система логирования ошибок в файл
class ErrorLogger {
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();
  static final ErrorLogger _instance = ErrorLogger._internal();

  static const String _logFileName = 'error_logs.json';
  static const String _maxLogsKey = 'max_error_logs';
  static const int _defaultMaxLogs = 1000;

  /// Логирование ошибки
  static Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? context,
    String? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final errorLog = {
        'timestamp': DateTime.now().toIso8601String(),
        'errorType': errorType,
        'errorMessage': errorMessage,
        'context': context ?? 'Unknown',
        'stackTrace': stackTrace,
        'additionalData': additionalData ?? {},
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
        'appVersion': '1.0.0', // Можно получить из pubspec.yaml
      };

      await _writeToFile(errorLog);
      await _cleanupOldLogs();
    } catch (e) {
      // Если не удалось записать в файл, логируем в консоль
      if (kDebugMode) {
        debugPrint('Failed to log error to file: $e');
      }
    }
  }

  /// Запись ошибки в файл
  static Future<void> _writeToFile(Map<String, dynamic> errorLog) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');

      var logs = <Map<String, dynamic>>[];

      // Читаем существующие логи
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          try {
            final dynamic decoded = json.decode(content);
            if (decoded is List) {
              final jsonList = decoded;
              logs = jsonList.cast<Map<String, dynamic>>();
            } else {
              logs = [];
            }
          } catch (e) {
            // Если файл поврежден, создаем новый
            logs = [];
          }
        }
      }

      // Добавляем новый лог
      logs.add(errorLog);

      // Записываем обратно в файл
      await file.writeAsString(json.encode(logs));

      if (kDebugMode) {
        debugPrint('Error logged to file: ${errorLog['errorType']}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error writing to log file: $e');
      }
    }
  }

  /// Очистка старых логов
  static Future<void> _cleanupOldLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maxLogs = prefs.getInt(_maxLogsKey) ?? _defaultMaxLogs;

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final dynamic decoded = json.decode(content);
          if (decoded is List) {
            final jsonList = decoded;
            final logs = jsonList.cast<Map<String, dynamic>>();

            // Если логов больше максимального количества, удаляем старые
            if (logs.length > maxLogs) {
              final recentLogs = logs.skip(logs.length - maxLogs).toList();
              await file.writeAsString(json.encode(recentLogs));
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error cleaning up old logs: $e');
      }
    }
  }

  /// Получение всех логов ошибок
  static Future<List<Map<String, dynamic>>> getAllLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');

      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final jsonList = json.decode(content) as List<dynamic>;
          return jsonList.cast<Map<String, dynamic>>();
        }
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error reading logs: $e');
      }
      return [];
    }
  }

  /// Получение логов за определенный период
  static Future<List<Map<String, dynamic>>> getLogsSince(DateTime since) async {
    try {
      final allLogs = await getAllLogs();
      return allLogs.where((log) {
        final timestamp = DateTime.tryParse(log['timestamp'] as String? ?? '');
        return timestamp != null && timestamp.isAfter(since);
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error filtering logs: $e');
      }
      return [];
    }
  }

  /// Получение логов по типу ошибки
  static Future<List<Map<String, dynamic>>> getLogsByType(
    String errorType,
  ) async {
    try {
      final allLogs = await getAllLogs();
      return allLogs.where((log) => log['errorType'] == errorType).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error filtering logs by type: $e');
      }
      return [];
    }
  }

  /// Очистка всех логов
  static Future<void> clearAllLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');

      if (await file.exists()) {
        await file.delete();
      }

      if (kDebugMode) {
        debugPrint('All error logs cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing logs: $e');
      }
    }
  }

  /// Экспорт логов в JSON
  static Future<String> exportLogsAsJson() async {
    try {
      final logs = await getAllLogs();
      return json.encode(logs);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting logs: $e');
      }
      return '[]';
    }
  }

  /// Экспорт логов в текстовый формат
  static Future<String> exportLogsAsText() async {
    try {
      final logs = await getAllLogs();
      final buffer = StringBuffer();

      buffer.writeln('=== ERROR LOGS EXPORT ===');
      buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total logs: ${logs.length}');
      buffer.writeln('========================\n');

      for (final log in logs) {
        buffer.writeln('Timestamp: ${log['timestamp']}');
        buffer.writeln('Type: ${log['errorType']}');
        buffer.writeln('Message: ${log['errorMessage']}');
        buffer.writeln('Context: ${log['context']}');
        buffer.writeln('Platform: ${log['platform']}');

        if (log['stackTrace'] != null) {
          buffer.writeln('Stack Trace:');
          buffer.writeln(log['stackTrace']);
        }

        if (log['additionalData'] != null && (log['additionalData'] as Map).isNotEmpty) {
          buffer.writeln('Additional Data:');
          buffer.writeln(json.encode(log['additionalData']));
        }

        buffer.writeln('---');
      }

      return buffer.toString();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error exporting logs as text: $e');
      }
      return 'Error exporting logs';
    }
  }

  /// Установка максимального количества логов
  static Future<void> setMaxLogs(int maxLogs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_maxLogsKey, maxLogs);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting max logs: $e');
      }
    }
  }

  /// Получение максимального количества логов
  static Future<int> getMaxLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_maxLogsKey) ?? _defaultMaxLogs;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting max logs: $e');
      }
      return _defaultMaxLogs;
    }
  }

  /// Получение статистики логов
  static Future<Map<String, dynamic>> getLogStatistics() async {
    try {
      final logs = await getAllLogs();

      if (logs.isEmpty) {
        return {
          'totalLogs': 0,
          'errorTypes': <String, int>{},
          'contexts': <String, int>{},
          'dateRange': null,
        };
      }

      final errorTypes = <String, int>{};
      final contexts = <String, int>{};
      DateTime? earliestDate;
      DateTime? latestDate;

      for (final log in logs) {
        // Подсчет типов ошибок
        final errorType = log['errorType'] ?? 'Unknown';
        errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;

        // Подсчет контекстов
        final context = log['context'] ?? 'Unknown';
        contexts[context] = (contexts[context] ?? 0) + 1;

        // Определение диапазона дат
        final timestamp = DateTime.tryParse(log['timestamp'] as String? ?? '');
        if (timestamp != null) {
          if (earliestDate == null || timestamp.isBefore(earliestDate)) {
            earliestDate = timestamp;
          }
          if (latestDate == null || timestamp.isAfter(latestDate)) {
            latestDate = timestamp;
          }
        }
      }

      return {
        'totalLogs': logs.length,
        'errorTypes': errorTypes,
        'contexts': contexts,
        'dateRange': earliestDate != null && latestDate != null
            ? {
                'earliest': earliestDate.toIso8601String(),
                'latest': latestDate.toIso8601String(),
              }
            : null,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting log statistics: $e');
      }
      return {
        'totalLogs': 0,
        'errorTypes': <String, int>{},
        'contexts': <String, int>{},
        'dateRange': null,
      };
    }
  }

  /// Проверка размера файла логов
  static Future<int> getLogFileSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_logFileName');

      if (await file.exists()) {
        return await file.length();
      }

      return 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting log file size: $e');
      }
      return 0;
    }
  }

  /// Получение пути к файлу логов
  static Future<String> getLogFilePath() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return '${directory.path}/$_logFileName';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting log file path: $e');
      }
      return '';
    }
  }
}
