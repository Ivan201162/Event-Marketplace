import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Сервис для логирования ошибок с батчевыми операциями и кэшированием
class ErrorLoggingService {
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Кэш для батчевых операций
  final List<Map<String, dynamic>> _errorLogCache = [];
  final List<Map<String, dynamic>> _warningLogCache = [];
  final List<Map<String, dynamic>> _performanceLogCache = [];
  
  // Таймеры для периодической отправки
  Timer? _errorLogTimer;
  Timer? _warningLogTimer;
  Timer? _performanceLogTimer;
  
  // Константы
  static const int _batchSize = 50;
  static const Duration _flushInterval = Duration(seconds: 30);

  /// Логировать ошибку
  Future<void> logError({
    required String error,
    required String stackTrace,
    String? userId,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Логирование в консоль для разработки
      if (kDebugMode) {
        developer.log(
          'ERROR: $error',
          name: 'ErrorLogging',
          error: error,
          stackTrace: StackTrace.current,
        );
      }

      // Добавляем в кэш для батчевой отправки
      _errorLogCache.add({
        'error': error,
        'stackTrace': stackTrace,
        'userId': userId,
        'screen': screen,
        'action': action,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
        'errorType': _getErrorType(error),
      });

      // Если кэш заполнен, отправляем немедленно
      if (_errorLogCache.length >= _batchSize) {
        await _flushErrorLogs();
      } else {
        // Запускаем таймер для периодической отправки
        _errorLogTimer?.cancel();
        _errorLogTimer = Timer(_flushInterval, () => _flushErrorLogs());
      }
    } catch (e) {
      // Если не удалось записать в Firestore, хотя бы выводим в консоль
      developer.log('Failed to log error to Firestore: $e');
    }
  }

  /// Отправить накопленные логи ошибок
  Future<void> _flushErrorLogs() async {
    if (_errorLogCache.isEmpty) return;

    final logsToSend = List<Map<String, dynamic>>.from(_errorLogCache);
    _errorLogCache.clear();

    try {
      final batch = _firestore.batch();

      for (final logData in logsToSend) {
        final docRef = _firestore.collection('error_logs').doc();
        batch.set(docRef, logData);
      }

      await batch.commit();
      developer.log('Flushed ${logsToSend.length} error logs to Firestore');
    } catch (e) {
      // Возвращаем логи в кэш при ошибке
      _errorLogCache.insertAll(0, logsToSend);
      developer.log('Failed to flush error logs: $e');
    }
  }

  /// Логировать предупреждение
  Future<void> logWarning({
    required String warning,
    String? userId,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (kDebugMode) {
        developer.log(
          'WARNING: $warning',
          name: 'ErrorLogging',
        );
      }

      // Добавляем в кэш для батчевой отправки
      _warningLogCache.add({
        'warning': warning,
        'userId': userId,
        'screen': screen,
        'action': action,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });

      // Если кэш заполнен, отправляем немедленно
      if (_warningLogCache.length >= _batchSize) {
        await _flushWarningLogs();
      } else {
        // Запускаем таймер для периодической отправки
        _warningLogTimer?.cancel();
        _warningLogTimer = Timer(_flushInterval, () => _flushWarningLogs());
      }
    } catch (e) {
      developer.log('Failed to log warning to Firestore: $e');
    }
  }

  /// Отправить накопленные логи предупреждений
  Future<void> _flushWarningLogs() async {
    if (_warningLogCache.isEmpty) return;

    final logsToSend = List<Map<String, dynamic>>.from(_warningLogCache);
    _warningLogCache.clear();

    try {
      final batch = _firestore.batch();

      for (final logData in logsToSend) {
        final docRef = _firestore.collection('warning_logs').doc();
        batch.set(docRef, logData);
      }

      await batch.commit();
      developer.log('Flushed ${logsToSend.length} warning logs to Firestore');
    } catch (e) {
      // Возвращаем логи в кэш при ошибке
      _warningLogCache.insertAll(0, logsToSend);
      developer.log('Failed to flush warning logs: $e');
    }
  }

  /// Логировать информацию
  Future<void> logInfo({
    required String message,
    String? userId,
    String? screen,
    String? action,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (kDebugMode) {
        developer.log(
          'INFO: $message',
          name: 'ErrorLogging',
        );
      }

      await _firestore.collection('info_logs').add({
        'message': message,
        'userId': userId,
        'screen': screen,
        'action': action,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });
    } catch (e) {
      developer.log('Failed to log info to Firestore: $e');
    }
  }

  /// Логировать производительность
  Future<void> logPerformance({
    required String operation,
    required Duration duration,
    String? userId,
    String? screen,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (kDebugMode) {
        developer.log(
          'PERFORMANCE: $operation took ${duration.inMilliseconds}ms',
          name: 'ErrorLogging',
        );
      }

      // Добавляем в кэш для батчевой отправки
      _performanceLogCache.add({
        'operation': operation,
        'duration': duration.inMilliseconds,
        'userId': userId,
        'screen': screen,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });

      // Если кэш заполнен, отправляем немедленно
      if (_performanceLogCache.length >= _batchSize) {
        await _flushPerformanceLogs();
      } else {
        // Запускаем таймер для периодической отправки
        _performanceLogTimer?.cancel();
        _performanceLogTimer = Timer(_flushInterval, () => _flushPerformanceLogs());
      }
    } catch (e) {
      developer.log('Failed to log performance to Firestore: $e');
    }
  }

  /// Отправить накопленные логи производительности
  Future<void> _flushPerformanceLogs() async {
    if (_performanceLogCache.isEmpty) return;

    final logsToSend = List<Map<String, dynamic>>.from(_performanceLogCache);
    _performanceLogCache.clear();

    try {
      final batch = _firestore.batch();

      for (final logData in logsToSend) {
        final docRef = _firestore.collection('performance_logs').doc();
        batch.set(docRef, logData);
      }

      await batch.commit();
      developer.log('Flushed ${logsToSend.length} performance logs to Firestore');
    } catch (e) {
      // Возвращаем логи в кэш при ошибке
      _performanceLogCache.insertAll(0, logsToSend);
      developer.log('Failed to flush performance logs: $e');
    }
  }

  /// Получить статистику ошибок
  Future<Map<String, dynamic>> getErrorStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection('error_logs');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      final snapshot = await query.get();

      var totalErrors = 0;
      final errorsByScreen = <String, int>{};
      final errorsByAction = <String, int>{};
      final errorsByType = <String, int>{};

      for (final doc in snapshot.docs) {
        final data = doc.data()! as Map<String, dynamic>;
        totalErrors++;

        final screen = data['screen'] as String?;
        if (screen != null) {
          errorsByScreen[screen] = (errorsByScreen[screen] ?? 0) + 1;
        }

        final action = data['action'] as String?;
        if (action != null) {
          errorsByAction[action] = (errorsByAction[action] ?? 0) + 1;
        }

        final error = data['error'] as String?;
        if (error != null) {
          final errorType = _getErrorType(error);
          errorsByType[errorType] = (errorsByType[errorType] ?? 0) + 1;
        }
      }

      return {
        'totalErrors': totalErrors,
        'errorsByScreen': errorsByScreen,
        'errorsByAction': errorsByAction,
        'errorsByType': errorsByType,
      };
    } catch (e) {
      developer.log('Failed to get error stats: $e');
      return {};
    }
  }

  /// Определить тип ошибки
  String _getErrorType(String error) {
    if (error.contains('NoSuchMethodError')) return 'NoSuchMethodError';
    if (error.contains('Null check operator')) return 'NullCheckError';
    if (error.contains('RangeError')) return 'RangeError';
    if (error.contains('FormatException')) return 'FormatException';
    if (error.contains('TimeoutException')) return 'TimeoutException';
    if (error.contains('FirebaseException')) return 'FirebaseException';
    if (error.contains('NetworkException')) return 'NetworkException';
    return 'Unknown';
  }

  /// Принудительно отправить все накопленные логи
  Future<void> flushAllLogs() async {
    await Future.wait([
      _flushErrorLogs(),
      _flushWarningLogs(),
      _flushPerformanceLogs(),
    ]);
  }

  /// Очистить старые логи с батчевыми операциями
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final collections = [
        'error_logs',
        'warning_logs',
        'info_logs',
        'performance_logs'
      ];

      for (final collection in collections) {
        final QuerySnapshot snapshot = await _firestore
            .collection(collection)
            .where('timestamp', isLessThan: cutoffDate)
            .limit(500) // Ограничиваем количество для батчевых операций
            .get();

        if (snapshot.docs.isNotEmpty) {
          // Используем батчевые операции для удаления
          final batches = <WriteBatch>[];
          WriteBatch? currentBatch = _firestore.batch();
          int batchCount = 0;

          for (final doc in snapshot.docs) {
            currentBatch!.delete(doc.reference);
            batchCount++;

            if (batchCount >= _batchSize) {
              batches.add(currentBatch);
              currentBatch = _firestore.batch();
              batchCount = 0;
            }
          }

          if (batchCount > 0) {
            batches.add(currentBatch!);
          }

          for (final batch in batches) {
            await batch.commit();
          }

          developer.log('Cleaned up ${snapshot.docs.length} old logs from $collection');
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup old logs: $e');
    }
  }

  /// Получить статистику логов
  Future<Map<String, int>> getLogStats() async {
    try {
      final collections = [
        'error_logs',
        'warning_logs',
        'info_logs',
        'performance_logs'
      ];

      final stats = <String, int>{};
      
      for (final collection in collections) {
        final snapshot = await _firestore.collection(collection).get();
        stats[collection] = snapshot.docs.length;
      }

      // Добавляем статистику кэша
      stats['error_logs_cached'] = _errorLogCache.length;
      stats['warning_logs_cached'] = _warningLogCache.length;
      stats['performance_logs_cached'] = _performanceLogCache.length;

      return stats;
    } catch (e) {
      developer.log('Failed to get log stats: $e');
      return {};
    }
  }

  /// Освободить ресурсы
  void dispose() {
    _errorLogTimer?.cancel();
    _warningLogTimer?.cancel();
    _performanceLogTimer?.cancel();
  }
}
