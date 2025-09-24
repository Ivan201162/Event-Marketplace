import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Уровни логирования ошибок
enum ErrorLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Типы ошибок
enum ErrorType {
  authentication,
  network,
  database,
  validation,
  payment,
  fileUpload,
  unknown,
}

/// Модель ошибки для логирования
class ErrorLog {
  final String id;
  final ErrorLevel level;
  final ErrorType type;
  final String message;
  final String? stackTrace;
  final String? userId;
  final String? deviceInfo;
  final String? appVersion;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const ErrorLog({
    required this.id,
    required this.level,
    required this.type,
    required this.message,
    this.stackTrace,
    this.userId,
    this.deviceInfo,
    this.appVersion,
    this.metadata,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'level': level.name,
        'type': type.name,
        'message': message,
        'stackTrace': stackTrace,
        'userId': userId,
        'deviceInfo': deviceInfo,
        'appVersion': appVersion,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory ErrorLog.fromMap(Map<String, dynamic> map) => ErrorLog(
        id: map['id'] as String,
        level: ErrorLevel.values.firstWhere(
          (e) => e.name == map['level'],
          orElse: () => ErrorLevel.error,
        ),
        type: ErrorType.values.firstWhere(
          (e) => e.name == map['type'],
          orElse: () => ErrorType.unknown,
        ),
        message: map['message'] as String,
        stackTrace: map['stackTrace'] as String?,
        userId: map['userId'] as String?,
        deviceInfo: map['deviceInfo'] as String?,
        appVersion: map['appVersion'] as String?,
        metadata: map['metadata'] as Map<String, dynamic>?,
        timestamp: (map['timestamp'] as Timestamp).toDate(),
      );
}

/// Сервис для логирования ошибок в Firestore
class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  factory ErrorLogger() => _instance;
  ErrorLogger._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  String? _appVersion;
  String? _deviceInfoString;

  /// Инициализация логгера
  Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

      if (kIsWeb) {
        final webBrowserInfo = await _deviceInfo.webBrowserInfo;
        _deviceInfoString =
            'Web: ${webBrowserInfo.browserName.name} ${webBrowserInfo.appVersion}';
      } else {
        _deviceInfoString = await _getDeviceInfo();
      }
    } catch (e) {
      debugPrint('Error initializing ErrorLogger: $e');
    }
  }

  /// Получение информации об устройстве
  Future<String> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return 'Android: ${androidInfo.model} ${androidInfo.version.release}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return 'iOS: ${iosInfo.model} ${iosInfo.systemVersion}';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return 'Windows: ${windowsInfo.computerName} ${windowsInfo.displayVersion}';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macosInfo = await _deviceInfo.macOsInfo;
        return 'macOS: ${macosInfo.model} ${macosInfo.osRelease}';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return 'Linux: ${linuxInfo.name} ${linuxInfo.version}';
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }
    return 'Unknown device';
  }

  /// Логирование ошибки
  Future<void> logError({
    required ErrorLevel level,
    required ErrorType type,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final errorLog = ErrorLog(
        id: _generateId(),
        level: level,
        type: type,
        message: message,
        stackTrace: stackTrace,
        userId: _auth.currentUser?.uid,
        deviceInfo: _deviceInfoString,
        appVersion: _appVersion,
        metadata: metadata,
        timestamp: DateTime.now(),
      );

      await _firestore
          .collection('errors_log')
          .doc(errorLog.id)
          .set(errorLog.toMap());

      // Также логируем в консоль для разработки
      if (kDebugMode) {
        debugPrint(
            'Error logged: ${errorLog.level.name} - ${errorLog.message}');
      }
    } catch (e) {
      // Если не удалось записать в Firestore, логируем в консоль
      debugPrint('Failed to log error to Firestore: $e');
      debugPrint('Original error: $message');
    }
  }

  /// Логирование критической ошибки
  Future<void> logCriticalError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.critical,
      type: ErrorType.unknown,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование ошибки аутентификации
  Future<void> logAuthError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.error,
      type: ErrorType.authentication,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование сетевой ошибки
  Future<void> logNetworkError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.warning,
      type: ErrorType.network,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование ошибки базы данных
  Future<void> logDatabaseError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.error,
      type: ErrorType.database,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование ошибки валидации
  Future<void> logValidationError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.warning,
      type: ErrorType.validation,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование ошибки платежа
  Future<void> logPaymentError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.error,
      type: ErrorType.payment,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Логирование ошибки загрузки файла
  Future<void> logFileUploadError({
    required String message,
    String? stackTrace,
    Map<String, dynamic>? metadata,
  }) async {
    await logError(
      level: ErrorLevel.warning,
      type: ErrorType.fileUpload,
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Генерация уникального ID
  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_auth.currentUser?.uid ?? 'anonymous'}';
  }

  /// Получение логов ошибок (только для администраторов)
  Future<List<ErrorLog>> getErrorLogs({
    ErrorLevel? level,
    ErrorType? type,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore.collection('errors_log');

      if (level != null) {
        query = query.where('level', isEqualTo: level.name);
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      query = query.orderBy('timestamp', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ErrorLog.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getting error logs: $e');
      return [];
    }
  }

  /// Очистка старых логов (только для администраторов)
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      final query = _firestore
          .collection('errors_log')
          .where('timestamp', isLessThan: cutoffTimestamp);

      final snapshot = await query.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('Cleaned up ${snapshot.docs.length} old error logs');
    } catch (e) {
      debugPrint('Error cleaning up old logs: $e');
    }
  }
}

/// Глобальный экземпляр логгера ошибок
final errorLogger = ErrorLogger();

/// Расширение для удобного логирования исключений
extension ExceptionLogging on Exception {
  /// Логирование исключения как ошибки
  Future<void> logAsError({
    ErrorType type = ErrorType.unknown,
    Map<String, dynamic>? metadata,
  }) async {
    await errorLogger.logError(
      level: ErrorLevel.error,
      type: type,
      message: toString(),
      stackTrace: StackTrace.current.toString(),
      metadata: metadata,
    );
  }

  /// Логирование исключения как критической ошибки
  Future<void> logAsCritical({
    Map<String, dynamic>? metadata,
  }) async {
    await errorLogger.logCriticalError(
      message: toString(),
      stackTrace: StackTrace.current.toString(),
      metadata: metadata,
    );
  }
}

/// Расширение для удобного логирования ошибок
extension ErrorLogging on Error {
  /// Логирование ошибки как критической
  Future<void> logAsCritical({
    Map<String, dynamic>? metadata,
  }) async {
    await errorLogger.logCriticalError(
      message: toString(),
      stackTrace: stackTrace?.toString(),
      metadata: metadata,
    );
  }
}
