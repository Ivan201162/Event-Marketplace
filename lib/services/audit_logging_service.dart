import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/feature_flags.dart';
import '../models/audit_log.dart';

/// Сервис для аудита действий пользователей и системных логов
class AuditLoggingService {
  factory AuditLoggingService() => _instance;
  AuditLoggingService._internal();
  static final AuditLoggingService _instance = AuditLoggingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _auditLogsCollection = 'audit_logs';
  static const String _systemLogsCollection = 'system_logs';
  static const String _loggingConfigCollection = 'logging_config';

  // Потоки для real-time обновлений
  final StreamController<AuditLog> _auditLogStreamController =
      StreamController<AuditLog>.broadcast();
  final StreamController<SystemLog> _systemLogStreamController =
      StreamController<SystemLog>.broadcast();

  // Конфигурация логирования
  LoggingConfig? _config;
  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadConfig();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка конфигурации логирования
  Future<void> _loadConfig() async {
    try {
      final doc = await _firestore
          .collection(_loggingConfigCollection)
          .doc('default')
          .get();

      if (doc.exists) {
        _config = LoggingConfig.fromMap(doc.data()!);
      } else {
        // Создаем конфигурацию по умолчанию
        _config = LoggingConfig(
          id: 'default',
          enableAuditLogging: true,
          enableSystemLogging: true,
          enablePerformanceLogging: false,
          enableSecurityLogging: true,
          auditLogLevels: AuditLogLevel.values,
          systemLogLevels: SystemLogLevel.values,
          auditLogCategories: AuditLogCategory.values,
          systemLogCategories: SystemLogCategory.values,
          maxLogRetentionDays: 90,
          enableLogCompression: false,
          enableLogEncryption: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _saveConfig(_config!);
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      // Используем конфигурацию по умолчанию
      _config = LoggingConfig(
        id: 'default',
        enableAuditLogging: true,
        enableSystemLogging: true,
        enablePerformanceLogging: false,
        enableSecurityLogging: true,
        auditLogLevels: AuditLogLevel.values,
        systemLogLevels: SystemLogLevel.values,
        auditLogCategories: AuditLogCategory.values,
        systemLogCategories: SystemLogCategory.values,
        maxLogRetentionDays: 90,
        enableLogCompression: false,
        enableLogEncryption: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Сохранение конфигурации
  Future<void> _saveConfig(LoggingConfig config) async {
    await _firestore
        .collection(_loggingConfigCollection)
        .doc(config.id)
        .set(config.toMap());
  }

  /// Получение конфигурации
  LoggingConfig? get config => _config;

  /// Поток аудита логов
  Stream<AuditLog> get auditLogStream => _auditLogStreamController.stream;

  /// Поток системных логов
  Stream<SystemLog> get systemLogStream => _systemLogStreamController.stream;

  /// Логирование действия пользователя
  Future<void> logUserAction({
    required String action,
    required String resource,
    required String resourceId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    AuditLogLevel level = AuditLogLevel.info,
    AuditLogCategory category = AuditLogCategory.general,
    String? description,
    Map<String, dynamic>? metadata,
    String? errorMessage,
    bool isSuccess = true,
  }) async {
    if (!FeatureFlags.auditLoggingEnabled || !_isInitialized) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      if (!_config!.enableAuditLogging) return;
      if (!_config!.auditLogLevels.contains(level)) return;
      if (!_config!.auditLogCategories.contains(category)) return;

      final auditLog = AuditLog(
        id: _generateId(),
        userId: user.uid,
        userEmail: user.email ?? '',
        action: action,
        resource: resource,
        resourceId: resourceId,
        oldData: oldData,
        newData: newData,
        ipAddress: await _getClientIP(),
        userAgent: await _getUserAgent(),
        sessionId: await _getSessionId(),
        level: level,
        category: category,
        description: description,
        metadata: metadata,
        timestamp: DateTime.now(),
        errorMessage: errorMessage,
        isSuccess: isSuccess,
      );

      await _saveAuditLog(auditLog);
      _auditLogStreamController.add(auditLog);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Логирование системного события
  Future<void> logSystemEvent({
    required String component,
    required String message,
    SystemLogLevel level = SystemLogLevel.info,
    SystemLogCategory category = SystemLogCategory.general,
    Map<String, dynamic>? context,
    String? stackTrace,
    String? sessionId,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) async {
    if (!FeatureFlags.systemLoggingEnabled || !_isInitialized) return;

    try {
      if (!_config!.enableSystemLogging) return;
      if (!_config!.systemLogLevels.contains(level)) return;
      if (!_config!.systemLogCategories.contains(category)) return;

      final systemLog = SystemLog(
        id: _generateId(),
        component: component,
        message: message,
        level: level,
        category: category,
        context: context,
        stackTrace: stackTrace,
        timestamp: DateTime.now(),
        sessionId: sessionId,
        requestId: requestId,
        metadata: metadata,
      );

      await _saveSystemLog(systemLog);
      _systemLogStreamController.add(systemLog);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Сохранение аудита лога
  Future<void> _saveAuditLog(AuditLog auditLog) async {
    try {
      final data = auditLog.toMap();

      // Применяем фильтры
      if (_config!.filters != null) {
        data.addAll(_config!.filters!);
      }

      // Шифрование если включено
      if (_config!.enableLogEncryption && _config!.encryptionKey != null) {
        data['encrypted'] = true;
        data['encryptionKey'] = _config!.encryptionKey;
      }

      await _firestore
          .collection(_auditLogsCollection)
          .doc(auditLog.id)
          .set(data);
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Сохранение системного лога
  Future<void> _saveSystemLog(SystemLog systemLog) async {
    try {
      final data = systemLog.toMap();

      // Применяем фильтры
      if (_config!.filters != null) {
        data.addAll(_config!.filters!);
      }

      // Шифрование если включено
      if (_config!.enableLogEncryption && _config!.encryptionKey != null) {
        data['encrypted'] = true;
        data['encryptionKey'] = _config!.encryptionKey;
      }

      await _firestore
          .collection(_systemLogsCollection)
          .doc(systemLog.id)
          .set(data);
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение аудита логов
  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? action,
    String? resource,
    AuditLogLevel? level,
    AuditLogCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(_auditLogsCollection);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }
      if (resource != null) {
        query = query.where('resource', isEqualTo: resource);
      }
      if (level != null) {
        query = query.where('level', isEqualTo: level.value);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category.value);
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

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => AuditLog.fromMap(doc.data())).toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return [];
    }
  }

  /// Получение системных логов
  Future<List<SystemLog>> getSystemLogs({
    String? component,
    SystemLogLevel? level,
    SystemLogCategory? category,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection(_systemLogsCollection);

      if (component != null) {
        query = query.where('component', isEqualTo: component);
      }
      if (level != null) {
        query = query.where('level', isEqualTo: level.value);
      }
      if (category != null) {
        query = query.where('category', isEqualTo: category.value);
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

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => SystemLog.fromMap(doc.data())).toList();
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return [];
    }
  }

  /// Обновление конфигурации логирования
  Future<void> updateConfig(LoggingConfig config) async {
    try {
      final updatedConfig = config.copyWith(updatedAt: DateTime.now());
      await _saveConfig(updatedConfig);
      _config = updatedConfig;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Экспорт логов
  Future<String> exportLogs({
    required DateTime startDate,
    required DateTime endDate,
    bool includeAuditLogs = true,
    bool includeSystemLogs = true,
    String format = 'json',
  }) async {
    try {
      final exportData = <String, dynamic>{
        'exportDate': DateTime.now().toIso8601String(),
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'auditLogs': [],
        'systemLogs': [],
      };

      if (includeAuditLogs) {
        final auditLogs = await getAuditLogs(
            startDate: startDate, endDate: endDate, limit: 10000);
        exportData['auditLogs'] = auditLogs.map((log) => log.toMap()).toList();
      }

      if (includeSystemLogs) {
        final systemLogs = await getSystemLogs(
          startDate: startDate,
          endDate: endDate,
          limit: 10000,
        );
        exportData['systemLogs'] =
            systemLogs.map((log) => log.toMap()).toList();
      }

      if (format == 'json') {
        return jsonEncode(exportData);
      } else if (format == 'csv') {
        return _convertToCSV(exportData);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Конвертация в CSV
  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Заголовки для аудита логов
    if (data['auditLogs'].isNotEmpty) {
      buffer.writeln('Audit Logs:');
      buffer.writeln(
        'ID,User ID,User Email,Action,Resource,Resource ID,Level,Category,Timestamp,Success',
      );

      for (final log in data['auditLogs']) {
        buffer.writeln(
          '${log['id']},${log['userId']},${log['userEmail']},${log['action']},${log['resource']},${log['resourceId']},${log['level']},${log['category']},${log['timestamp']},${log['isSuccess']}',
        );
      }
      buffer.writeln();
    }

    // Заголовки для системных логов
    if (data['systemLogs'].isNotEmpty) {
      buffer.writeln('System Logs:');
      buffer.writeln('ID,Component,Message,Level,Category,Timestamp');

      for (final log in data['systemLogs']) {
        buffer.writeln(
          '${log['id']},${log['component']},${log['message']},${log['level']},${log['category']},${log['timestamp']}',
        );
      }
    }

    return buffer.toString();
  }

  /// Очистка старых логов
  Future<void> cleanupOldLogs() async {
    if (!_isInitialized) return;

    try {
      final cutoffDate =
          DateTime.now().subtract(Duration(days: _config!.maxLogRetentionDays));

      // Очистка аудита логов
      if (_config!.enableAuditLogging) {
        final auditQuery = _firestore
            .collection(_auditLogsCollection)
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate));

        final auditSnapshot = await auditQuery.get();
        final batch = _firestore.batch();

        for (final doc in auditSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }

      // Очистка системных логов
      if (_config!.enableSystemLogging) {
        final systemQuery = _firestore
            .collection(_systemLogsCollection)
            .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate));

        final systemSnapshot = await systemQuery.get();
        final batch = _firestore.batch();

        for (final doc in systemSnapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Получение статистики логов
  Future<Map<String, dynamic>> getLogStatistics(
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      // Статистика аудита логов
      final auditQuery = _firestore
          .collection(_auditLogsCollection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final auditSnapshot = await auditQuery.get();
      final auditLogs = auditSnapshot.docs
          .map((doc) => AuditLog.fromMap(doc.data()))
          .toList();

      // Статистика системных логов
      final systemQuery = _firestore
          .collection(_systemLogsCollection)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));

      final systemSnapshot = await systemQuery.get();
      final systemLogs = systemSnapshot.docs
          .map((doc) => SystemLog.fromMap(doc.data()))
          .toList();

      return {
        'auditLogs': {
          'total': auditLogs.length,
          'byLevel': _groupByLevel(auditLogs),
          'byCategory': _groupByCategory(auditLogs),
          'successRate': auditLogs.isNotEmpty
              ? auditLogs.where((log) => log.isSuccess).length /
                  auditLogs.length
              : 0.0,
        },
        'systemLogs': {
          'total': systemLogs.length,
          'byLevel': _groupBySystemLevel(systemLogs),
          'byCategory': _groupBySystemCategory(systemLogs),
        },
        'period': {
          'startDate': start.toIso8601String(),
          'endDate': end.toIso8601String()
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка по уровням аудита
  Map<String, int> _groupByLevel(List<AuditLog> logs) {
    final groups = <String, int>{};
    for (final log in logs) {
      groups[log.level.value] = (groups[log.level.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка по категориям аудита
  Map<String, int> _groupByCategory(List<AuditLog> logs) {
    final groups = <String, int>{};
    for (final log in logs) {
      groups[log.category.value] = (groups[log.category.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка по уровням системных логов
  Map<String, int> _groupBySystemLevel(List<SystemLog> logs) {
    final groups = <String, int>{};
    for (final log in logs) {
      groups[log.level.value] = (groups[log.level.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка по категориям системных логов
  Map<String, int> _groupBySystemCategory(List<SystemLog> logs) {
    final groups = <String, int>{};
    for (final log in logs) {
      groups[log.category.value] = (groups[log.category.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Получение IP адреса клиента
  Future<String?> _getClientIP() async {
    try {
      // В реальном приложении здесь будет логика получения IP
      return '127.0.0.1';
    } catch (e) {
      return null;
    }
  }

  /// Получение User Agent
  Future<String?> _getUserAgent() async {
    try {
      // В реальном приложении здесь будет логика получения User Agent
      return 'Flutter App';
    } catch (e) {
      return null;
    }
  }

  /// Получение ID сессии
  Future<String?> _getSessionId() async {
    try {
      // В реальном приложении здесь будет логика получения ID сессии
      return _generateId();
    } catch (e) {
      return null;
    }
  }

  /// Генерация уникального ID
  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
          .round()
          .toString();

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _auditLogStreamController.close();
    await _systemLogStreamController.close();
  }
}
