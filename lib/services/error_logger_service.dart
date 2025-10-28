import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:event_marketplace_app/models/app_error.dart';
import 'package:flutter/foundation.dart';

/// Сервис для логирования ошибок приложения
class ErrorLoggerService {
  factory ErrorLoggerService() => _instance;
  ErrorLoggerService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final StreamController<AppError> _errorController =
      StreamController<AppError>.broadcast();

  static final ErrorLoggerService _instance = ErrorLoggerService._internal();

  /// Поток ошибок
  Stream<AppError> get errorStream => _errorController.stream;

  /// Инициализация сервиса логирования ошибок
  Future<void> initialize() async {
    // Перехватываем Flutter ошибки
    FlutterError.onError = _logFlutterError;

    // Перехватываем асинхронные ошибки
    PlatformDispatcher.instance.onError = (error, stack) {
      _logAsyncError(error, stack);
      return true;
    };

    // Перехватываем ошибки в зонах
    runZonedGuarded(() {
      // Основной код приложения
    }, _logZonedError,);
  }

  /// Логировать Flutter ошибку
  Future<void> _logFlutterError(FlutterErrorDetails details) async {
    try {
      final error = AppError(
        id: '', // Будет сгенерирован Firestore
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: details.exception.toString(),
        stackTrace: details.stack?.toString(),
        errorType: 'flutter_error',
        timestamp: DateTime.now(),
        metadata: {
          'library': details.library,
          'context': details.context?.toString(),
          'informationCollector': details.informationCollector?.toString(),
        },
      );

      await _saveError(error);
    } catch (e) {
      developer.log('Ошибка при логировании Flutter ошибки: $e');
    }
  }

  /// Логировать асинхронную ошибку
  Future<void> _logAsyncError(Object error, StackTrace stack) async {
    try {
      final appError = AppError(
        id: '', // Будет сгенерирован Firestore
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: error.toString(),
        stackTrace: stack.toString(),
        errorType: 'async_error',
        timestamp: DateTime.now(),
        metadata: {'errorType': error.runtimeType.toString()},
      );

      await _saveError(appError);
    } catch (e) {
      developer.log('Ошибка при логировании асинхронной ошибки: $e');
    }
  }

  /// Логировать ошибку в зоне
  Future<void> _logZonedError(Object error, StackTrace stack) async {
    try {
      final appError = AppError(
        id: '', // Будет сгенерирован Firestore
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: error.toString(),
        stackTrace: stack.toString(),
        errorType: 'zoned_error',
        timestamp: DateTime.now(),
        metadata: {'errorType': error.runtimeType.toString()},
      );

      await _saveError(appError);
    } catch (e) {
      developer.log('Ошибка при логировании ошибки в зоне: $e');
    }
  }

  /// Логировать пользовательскую ошибку
  Future<void> logUserError({
    required String message,
    String? stackTrace,
    String? screen,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final error = AppError(
        id: '', // Будет сгенерирован Firestore
        userId: userId,
        device: await _getDeviceInfo(),
        screen: screen ?? _getCurrentScreen(),
        errorMessage: message,
        stackTrace: stackTrace,
        errorType: 'user_error',
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _saveError(error);
    } catch (e) {
      developer.log('Ошибка при логировании пользовательской ошибки: $e');
    }
  }

  /// Логировать сетевую ошибку
  Future<void> logNetworkError({
    required String message,
    required String url,
    required int statusCode,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final error = AppError(
        id: '', // Будет сгенерирован Firestore
        userId: userId,
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: message,
        errorType: 'network_error',
        timestamp: DateTime.now(),
        metadata: {'url': url, 'statusCode': statusCode, ...?metadata},
      );

      await _saveError(error);
    } catch (e) {
      developer.log('Ошибка при логировании сетевой ошибки: $e');
    }
  }

  /// Логировать ошибку валидации
  Future<void> logValidationError({
    required String message,
    required String field,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final error = AppError(
        id: '', // Будет сгенерирован Firestore
        userId: userId,
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: message,
        errorType: 'validation_error',
        timestamp: DateTime.now(),
        metadata: {'field': field, ...?metadata},
      );

      await _saveError(error);
    } catch (e) {
      developer.log('Ошибка при логировании ошибки валидации: $e');
    }
  }

  /// Логировать ошибку UI
  Future<void> logUIError({
    required String message,
    required String widget,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final error = AppError(
        id: '', // Будет сгенерирован Firestore
        userId: userId,
        device: await _getDeviceInfo(),
        screen: _getCurrentScreen(),
        errorMessage: message,
        errorType: 'ui_error',
        timestamp: DateTime.now(),
        metadata: {'widget': widget, ...?metadata},
      );

      await _saveError(error);
    } catch (e) {
      developer.log('Ошибка при логировании ошибки UI: $e');
    }
  }

  /// Сохранить ошибку в Firestore
  Future<void> _saveError(AppError error) async {
    try {
      // В режиме разработки выводим ошибку в консоль
      if (kDebugMode) {
        developer.log(
          'Ошибка: ${error.errorMessage}',
          name: 'ErrorLogger',
          error: error.stackTrace,
        );
      }

      // Сохраняем в Firestore только в продакшене или если включено логирование
      if (!kDebugMode || await _isLoggingEnabled()) {
        await _firestore.collection('appErrors').add(error.toMap());
      }

      // Отправляем в поток
      _errorController.add(error);
    } catch (e) {
      developer.log('Ошибка при сохранении ошибки в Firestore: $e');
    }
  }

  /// Получить информацию об устройстве
  Future<String> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return '${androidInfo.brand} ${androidInfo.model} (Android ${androidInfo.version.release})';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model} (iOS ${iosInfo.systemVersion})';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return '${windowsInfo.computerName} (Windows ${windowsInfo.displayVersion})';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macosInfo = await _deviceInfo.macOSInfo;
        return '${macosInfo.computerName} (macOS ${macosInfo.osRelease})';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return '${linuxInfo.name} (Linux ${linuxInfo.version})';
      } else {
        return 'Unknown device';
      }
    } catch (e) {
      return 'Unknown device';
    }
  }

  /// Получить текущий экран
  String _getCurrentScreen() {
    try {
      // TODO(developer): Реализовать получение текущего экрана из роутера
      return 'Unknown screen';
    } catch (e) {
      return 'Unknown screen';
    }
  }

  /// Проверить, включено ли логирование
  Future<bool> _isLoggingEnabled() async {
    try {
      // TODO(developer): Реализовать проверку настроек логирования
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить все ошибки
  Future<List<AppError>> getAllErrors({
    int limit = 100,
    bool resolvedOnly = false,
    bool unresolvedOnly = false,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('appErrors');

      if (resolvedOnly) {
        query = query.where('resolved', isEqualTo: true);
      } else if (unresolvedOnly) {
        query = query.where('resolved', isEqualTo: false);
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs.map(AppError.fromDocument).toList();
    } catch (e) {
      developer.log('Ошибка при получении ошибок: $e');
      return [];
    }
  }

  /// Получить ошибки по типу
  Future<List<AppError>> getErrorsByType(String errorType) async {
    try {
      final snapshot = await _firestore
          .collection('appErrors')
          .where('errorType', isEqualTo: errorType)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map(AppError.fromDocument).toList();
    } catch (e) {
      developer.log('Ошибка при получении ошибок по типу: $e');
      return [];
    }
  }

  /// Получить ошибки по экрану
  Future<List<AppError>> getErrorsByScreen(String screen) async {
    try {
      final snapshot = await _firestore
          .collection('appErrors')
          .where('screen', isEqualTo: screen)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map(AppError.fromDocument).toList();
    } catch (e) {
      developer.log('Ошибка при получении ошибок по экрану: $e');
      return [];
    }
  }

  /// Получить ошибки пользователя
  Future<List<AppError>> getUserErrors(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('appErrors')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map(AppError.fromDocument).toList();
    } catch (e) {
      developer.log('Ошибка при получении ошибок пользователя: $e');
      return [];
    }
  }

  /// Отметить ошибку как решенную
  Future<void> markErrorAsResolved(String errorId) async {
    try {
      await _firestore
          .collection('appErrors')
          .doc(errorId)
          .update({'resolved': true});
    } catch (e) {
      developer.log('Ошибка при отметке ошибки как решенной: $e');
    }
  }

  /// Отметить ошибку как нерешенную
  Future<void> markErrorAsUnresolved(String errorId) async {
    try {
      await _firestore
          .collection('appErrors')
          .doc(errorId)
          .update({'resolved': false});
    } catch (e) {
      developer.log('Ошибка при отметке ошибки как нерешенной: $e');
    }
  }

  /// Получить статистику ошибок
  Future<ErrorStatistics> getErrorStatistics() async {
    try {
      final snapshot = await _firestore.collection('appErrors').get();

      var totalErrors = 0;
      var resolvedErrors = 0;
      var unresolvedErrors = 0;
      var criticalErrors = 0;
      var recentErrors = 0;
      final errorsByType = <String, int>{};
      final errorsByScreen = <String, int>{};
      final errorsByDevice = <String, int>{};

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final error = AppError.fromDocument(doc);
        totalErrors++;

        if (error.resolved) {
          resolvedErrors++;
        } else {
          unresolvedErrors++;
        }

        if (error.isCritical) {
          criticalErrors++;
        }

        if (error.isRecent) {
          recentErrors++;
        }

        errorsByType[error.errorType] =
            (errorsByType[error.errorType] ?? 0) + 1;
        errorsByScreen[error.screen] = (errorsByScreen[error.screen] ?? 0) + 1;
        errorsByDevice[error.device] = (errorsByDevice[error.device] ?? 0) + 1;
      }

      return ErrorStatistics(
        totalErrors: totalErrors,
        resolvedErrors: resolvedErrors,
        unresolvedErrors: unresolvedErrors,
        criticalErrors: criticalErrors,
        recentErrors: recentErrors,
        errorsByType: errorsByType,
        errorsByScreen: errorsByScreen,
        errorsByDevice: errorsByDevice,
      );
    } catch (e) {
      developer.log('Ошибка при получении статистики ошибок: $e');
      return const ErrorStatistics(
        totalErrors: 0,
        resolvedErrors: 0,
        unresolvedErrors: 0,
        criticalErrors: 0,
        recentErrors: 0,
        errorsByType: {},
        errorsByScreen: {},
        errorsByDevice: {},
      );
    }
  }

  /// Экспортировать ошибки в CSV
  Future<String> exportErrorsToCSV(List<AppError> errors) async {
    try {
      final csv = StringBuffer();

      // Заголовки
      csv.writeln(
          'ID,User ID,Device,Screen,Error Message,Error Type,Resolved,Timestamp',);

      // Данные
      for (final error in errors) {
        csv.writeln(
          [
            error.id,
            error.userId ?? '',
            error.device,
            error.screen,
            error.errorMessage.replaceAll(',', ';'),
            error.errorType,
            error.resolved,
            error.timestamp.toIso8601String(),
          ].join(','),
        );
      }

      return csv.toString();
    } catch (e) {
      developer.log('Ошибка при экспорте ошибок в CSV: $e');
      return '';
    }
  }

  /// Очистить старые ошибки
  Future<void> cleanupOldErrors({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('appErrors')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      developer.log('Ошибка при очистке старых ошибок: $e');
    }
  }

  /// Закрыть сервис
  void dispose() {
    _errorController.close();
  }
}
