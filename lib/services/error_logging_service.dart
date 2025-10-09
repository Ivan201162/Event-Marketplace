import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для логирования ошибок
class ErrorLoggingService {
  static final ErrorLoggingService _instance = ErrorLoggingService._internal();
  factory ErrorLoggingService() => _instance;
  ErrorLoggingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

      // Логирование в Firestore для продакшена
      await _firestore.collection('error_logs').add({
        'error': error,
        'stackTrace': stackTrace,
        'userId': userId,
        'screen': screen,
        'action': action,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });
    } catch (e) {
      // Если не удалось записать в Firestore, хотя бы выводим в консоль
      developer.log('Failed to log error to Firestore: $e');
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

      await _firestore.collection('warning_logs').add({
        'warning': warning,
        'userId': userId,
        'screen': screen,
        'action': action,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });
    } catch (e) {
      developer.log('Failed to log warning to Firestore: $e');
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

      await _firestore.collection('performance_logs').add({
        'operation': operation,
        'duration': duration.inMilliseconds,
        'userId': userId,
        'screen': screen,
        'additionalData': additionalData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.name,
        'isDebug': kDebugMode,
      });
    } catch (e) {
      developer.log('Failed to log performance to Firestore: $e');
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

      final QuerySnapshot snapshot = await query.get();
      
      int totalErrors = 0;
      Map<String, int> errorsByScreen = {};
      Map<String, int> errorsByAction = {};
      Map<String, int> errorsByType = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
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

  /// Очистить старые логи
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      
      final collections = ['error_logs', 'warning_logs', 'info_logs', 'performance_logs'];
      
      for (final collection in collections) {
        final QuerySnapshot snapshot = await _firestore
            .collection(collection)
            .where('timestamp', isLessThan: cutoffDate)
            .get();

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        
        if (snapshot.docs.isNotEmpty) {
          await batch.commit();
        }
      }
    } catch (e) {
      developer.log('Failed to cleanup old logs: $e');
    }
  }
}
