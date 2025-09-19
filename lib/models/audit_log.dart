import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/utils.dart';

/// Модель для аудита действий пользователей
class AuditLog {
  const AuditLog({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.resource,
    required this.resourceId,
    this.oldData,
    this.newData,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    required this.level,
    required this.category,
    this.description,
    this.metadata,
    required this.timestamp,
    this.errorMessage,
    required this.isSuccess,
  });

  factory AuditLog.fromMap(Map<String, dynamic> map) => AuditLog(
        id: (map['id'] as String?) ?? '',
        userId: (map['userId'] as String?) ?? '',
        userEmail: (map['userEmail'] as String?) ?? '',
        action: (map['action'] as String?) ?? '',
        resource: (map['resource'] as String?) ?? '',
        resourceId: (map['resourceId'] as String?) ?? '',
        oldData: safeMapFromDynamic(map['oldData'] as Map<dynamic, dynamic>?),
        newData: safeMapFromDynamic(map['newData'] as Map<dynamic, dynamic>?),
        ipAddress: safeStringFromDynamic(map['ipAddress']),
        userAgent: safeStringFromDynamic(map['userAgent']),
        sessionId: safeStringFromDynamic(map['sessionId']),
        level: AuditLogLevel.fromString((map['level'] as String?) ?? 'info'),
        category: AuditLogCategory.fromString(
          (map['category'] as String?) ?? 'general',
        ),
        description: safeStringFromDynamic(map['description']),
        metadata: safeMapFromDynamic(map['metadata'] as Map<dynamic, dynamic>?),
        timestamp: safeDateTimeFromTimestamp(map['timestamp']),
        errorMessage: safeStringFromDynamic(map['errorMessage']),
        isSuccess: safeBoolFromDynamic(map['isSuccess'], true),
      );
  final String id;
  final String userId;
  final String userEmail;
  final String action;
  final String resource;
  final String resourceId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final AuditLogLevel level;
  final AuditLogCategory category;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final String? errorMessage;
  final bool isSuccess;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userEmail': userEmail,
        'action': action,
        'resource': resource,
        'resourceId': resourceId,
        'oldData': oldData,
        'newData': newData,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'sessionId': sessionId,
        'level': level.value,
        'category': category.value,
        'description': description,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
        'errorMessage': errorMessage,
        'isSuccess': isSuccess,
      };

  AuditLog copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? action,
    String? resource,
    String? resourceId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    AuditLogLevel? level,
    AuditLogCategory? category,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? errorMessage,
    bool? isSuccess,
  }) =>
      AuditLog(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        userEmail: userEmail ?? this.userEmail,
        action: action ?? this.action,
        resource: resource ?? this.resource,
        resourceId: resourceId ?? this.resourceId,
        oldData: oldData ?? this.oldData,
        newData: newData ?? this.newData,
        ipAddress: ipAddress ?? this.ipAddress,
        userAgent: userAgent ?? this.userAgent,
        sessionId: sessionId ?? this.sessionId,
        level: level ?? this.level,
        category: category ?? this.category,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
        timestamp: timestamp ?? this.timestamp,
        errorMessage: errorMessage ?? this.errorMessage,
        isSuccess: isSuccess ?? this.isSuccess,
      );

  @override
  String toString() =>
      'AuditLog(id: $id, userId: $userId, action: $action, resource: $resource, level: $level, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuditLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Уровни логирования
enum AuditLogLevel {
  debug('debug', 'Отладка'),
  info('info', 'Информация'),
  warning('warning', 'Предупреждение'),
  error('error', 'Ошибка'),
  critical('critical', 'Критическая ошибка');

  const AuditLogLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  static AuditLogLevel fromString(String value) =>
      AuditLogLevel.values.firstWhere(
        (level) => level.value == value,
        orElse: () => AuditLogLevel.info,
      );

  String get icon {
    switch (this) {
      case AuditLogLevel.debug:
        return '🐛';
      case AuditLogLevel.info:
        return 'ℹ️';
      case AuditLogLevel.warning:
        return '⚠️';
      case AuditLogLevel.error:
        return '❌';
      case AuditLogLevel.critical:
        return '🚨';
    }
  }

  String get color {
    switch (this) {
      case AuditLogLevel.debug:
        return 'grey';
      case AuditLogLevel.info:
        return 'blue';
      case AuditLogLevel.warning:
        return 'orange';
      case AuditLogLevel.error:
        return 'red';
      case AuditLogLevel.critical:
        return 'darkred';
    }
  }
}

/// Категории аудита
enum AuditLogCategory {
  authentication('authentication', 'Аутентификация'),
  authorization('authorization', 'Авторизация'),
  userManagement('userManagement', 'Управление пользователями'),
  bookingManagement('bookingManagement', 'Управление бронированиями'),
  paymentProcessing('paymentProcessing', 'Обработка платежей'),
  specialistManagement('specialistManagement', 'Управление специалистами'),
  contentManagement('contentManagement', 'Управление контентом'),
  systemConfiguration('systemConfiguration', 'Конфигурация системы'),
  security('security', 'Безопасность'),
  dataExport('dataExport', 'Экспорт данных'),
  dataImport('dataImport', 'Импорт данных'),
  apiAccess('apiAccess', 'Доступ к API'),
  general('general', 'Общее');

  const AuditLogCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static AuditLogCategory fromString(String value) =>
      AuditLogCategory.values.firstWhere(
        (category) => category.value == value,
        orElse: () => AuditLogCategory.general,
      );

  String get icon {
    switch (this) {
      case AuditLogCategory.authentication:
        return '🔐';
      case AuditLogCategory.authorization:
        return '🛡️';
      case AuditLogCategory.userManagement:
        return '👥';
      case AuditLogCategory.bookingManagement:
        return '📅';
      case AuditLogCategory.paymentProcessing:
        return '💳';
      case AuditLogCategory.specialistManagement:
        return '👨‍💼';
      case AuditLogCategory.contentManagement:
        return '📝';
      case AuditLogCategory.systemConfiguration:
        return '⚙️';
      case AuditLogCategory.security:
        return '🔒';
      case AuditLogCategory.dataExport:
        return '📤';
      case AuditLogCategory.dataImport:
        return '📥';
      case AuditLogCategory.apiAccess:
        return '🔌';
      case AuditLogCategory.general:
        return '📋';
    }
  }
}

/// Модель для системных логов
class SystemLog {
  const SystemLog({
    required this.id,
    required this.component,
    required this.message,
    required this.level,
    required this.category,
    this.context,
    this.stackTrace,
    required this.timestamp,
    this.sessionId,
    this.requestId,
    this.metadata,
  });

  factory SystemLog.fromMap(Map<String, dynamic> map) => SystemLog(
        id: map['id'] ?? '',
        component: map['component'] ?? '',
        message: map['message'] ?? '',
        level: SystemLogLevel.fromString(map['level'] ?? 'info'),
        category: SystemLogCategory.fromString(map['category'] ?? 'general'),
        context: map['context'],
        stackTrace: map['stackTrace'],
        timestamp: (map['timestamp'] as Timestamp).toDate(),
        sessionId: map['sessionId'],
        requestId: map['requestId'],
        metadata: map['metadata'],
      );
  final String id;
  final String component;
  final String message;
  final SystemLogLevel level;
  final SystemLogCategory category;
  final Map<String, dynamic>? context;
  final String? stackTrace;
  final DateTime timestamp;
  final String? sessionId;
  final String? requestId;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'component': component,
        'message': message,
        'level': level.value,
        'category': category.value,
        'context': context,
        'stackTrace': stackTrace,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
        'requestId': requestId,
        'metadata': metadata,
      };

  SystemLog copyWith({
    String? id,
    String? component,
    String? message,
    SystemLogLevel? level,
    SystemLogCategory? category,
    Map<String, dynamic>? context,
    String? stackTrace,
    DateTime? timestamp,
    String? sessionId,
    String? requestId,
    Map<String, dynamic>? metadata,
  }) =>
      SystemLog(
        id: id ?? this.id,
        component: component ?? this.component,
        message: message ?? this.message,
        level: level ?? this.level,
        category: category ?? this.category,
        context: context ?? this.context,
        stackTrace: stackTrace ?? this.stackTrace,
        timestamp: timestamp ?? this.timestamp,
        sessionId: sessionId ?? this.sessionId,
        requestId: requestId ?? this.requestId,
        metadata: metadata ?? this.metadata,
      );

  @override
  String toString() =>
      'SystemLog(id: $id, component: $component, message: $message, level: $level, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Уровни системных логов
enum SystemLogLevel {
  trace('trace', 'Трассировка'),
  debug('debug', 'Отладка'),
  info('info', 'Информация'),
  warning('warning', 'Предупреждение'),
  error('error', 'Ошибка'),
  fatal('fatal', 'Критическая ошибка');

  const SystemLogLevel(this.value, this.displayName);

  final String value;
  final String displayName;

  static SystemLogLevel fromString(String value) =>
      SystemLogLevel.values.firstWhere(
        (level) => level.value == value,
        orElse: () => SystemLogLevel.info,
      );

  String get icon {
    switch (this) {
      case SystemLogLevel.trace:
        return '🔍';
      case SystemLogLevel.debug:
        return '🐛';
      case SystemLogLevel.info:
        return 'ℹ️';
      case SystemLogLevel.warning:
        return '⚠️';
      case SystemLogLevel.error:
        return '❌';
      case SystemLogLevel.fatal:
        return '💀';
    }
  }

  String get color {
    switch (this) {
      case SystemLogLevel.trace:
        return 'grey';
      case SystemLogLevel.debug:
        return 'grey';
      case SystemLogLevel.info:
        return 'blue';
      case SystemLogLevel.warning:
        return 'orange';
      case SystemLogLevel.error:
        return 'red';
      case SystemLogLevel.fatal:
        return 'darkred';
    }
  }
}

/// Категории системных логов
enum SystemLogCategory {
  database('database', 'База данных'),
  network('network', 'Сеть'),
  authentication('authentication', 'Аутентификация'),
  authorization('authorization', 'Авторизация'),
  businessLogic('businessLogic', 'Бизнес-логика'),
  externalApi('externalApi', 'Внешние API'),
  fileSystem('fileSystem', 'Файловая система'),
  cache('cache', 'Кэш'),
  queue('queue', 'Очереди'),
  scheduler('scheduler', 'Планировщик'),
  general('general', 'Общее');

  const SystemLogCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static SystemLogCategory fromString(String value) =>
      SystemLogCategory.values.firstWhere(
        (category) => category.value == value,
        orElse: () => SystemLogCategory.general,
      );

  String get icon {
    switch (this) {
      case SystemLogCategory.database:
        return '🗄️';
      case SystemLogCategory.network:
        return '🌐';
      case SystemLogCategory.authentication:
        return '🔐';
      case SystemLogCategory.authorization:
        return '🛡️';
      case SystemLogCategory.businessLogic:
        return '⚙️';
      case SystemLogCategory.externalApi:
        return '🔌';
      case SystemLogCategory.fileSystem:
        return '📁';
      case SystemLogCategory.cache:
        return '💾';
      case SystemLogCategory.queue:
        return '📋';
      case SystemLogCategory.scheduler:
        return '⏰';
      case SystemLogCategory.general:
        return '📋';
    }
  }
}

/// Модель для конфигурации логирования
class LoggingConfig {
  const LoggingConfig({
    required this.id,
    required this.enableAuditLogging,
    required this.enableSystemLogging,
    required this.enablePerformanceLogging,
    required this.enableSecurityLogging,
    required this.auditLogLevels,
    required this.systemLogLevels,
    required this.auditLogCategories,
    required this.systemLogCategories,
    required this.maxLogRetentionDays,
    required this.enableLogCompression,
    required this.enableLogEncryption,
    this.encryptionKey,
    this.filters,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LoggingConfig.fromMap(Map<String, dynamic> map) => LoggingConfig(
        id: map['id'] ?? '',
        enableAuditLogging: map['enableAuditLogging'] ?? true,
        enableSystemLogging: map['enableSystemLogging'] ?? true,
        enablePerformanceLogging: map['enablePerformanceLogging'] ?? false,
        enableSecurityLogging: map['enableSecurityLogging'] ?? true,
        auditLogLevels: (map['auditLogLevels'] as List<dynamic>?)
                ?.map((e) => AuditLogLevel.fromString(e as String))
                .toList() ??
            AuditLogLevel.values,
        systemLogLevels: (map['systemLogLevels'] as List<dynamic>?)
                ?.map((e) => SystemLogLevel.fromString(e as String))
                .toList() ??
            SystemLogLevel.values,
        auditLogCategories: (map['auditLogCategories'] as List<dynamic>?)
                ?.map((e) => AuditLogCategory.fromString(e as String))
                .toList() ??
            AuditLogCategory.values,
        systemLogCategories: (map['systemLogCategories'] as List<dynamic>?)
                ?.map((e) => SystemLogCategory.fromString(e as String))
                .toList() ??
            SystemLogCategory.values,
        maxLogRetentionDays: map['maxLogRetentionDays'] ?? 90,
        enableLogCompression: map['enableLogCompression'] ?? false,
        enableLogEncryption: map['enableLogEncryption'] ?? false,
        encryptionKey: map['encryptionKey'],
        filters: map['filters'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final bool enableAuditLogging;
  final bool enableSystemLogging;
  final bool enablePerformanceLogging;
  final bool enableSecurityLogging;
  final List<AuditLogLevel> auditLogLevels;
  final List<SystemLogLevel> systemLogLevels;
  final List<AuditLogCategory> auditLogCategories;
  final List<SystemLogCategory> systemLogCategories;
  final int maxLogRetentionDays;
  final bool enableLogCompression;
  final bool enableLogEncryption;
  final String? encryptionKey;
  final Map<String, dynamic>? filters;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'enableAuditLogging': enableAuditLogging,
        'enableSystemLogging': enableSystemLogging,
        'enablePerformanceLogging': enablePerformanceLogging,
        'enableSecurityLogging': enableSecurityLogging,
        'auditLogLevels': auditLogLevels.map((e) => e.value).toList(),
        'systemLogLevels': systemLogLevels.map((e) => e.value).toList(),
        'auditLogCategories': auditLogCategories.map((e) => e.value).toList(),
        'systemLogCategories': systemLogCategories.map((e) => e.value).toList(),
        'maxLogRetentionDays': maxLogRetentionDays,
        'enableLogCompression': enableLogCompression,
        'enableLogEncryption': enableLogEncryption,
        'encryptionKey': encryptionKey,
        'filters': filters,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  LoggingConfig copyWith({
    String? id,
    bool? enableAuditLogging,
    bool? enableSystemLogging,
    bool? enablePerformanceLogging,
    bool? enableSecurityLogging,
    List<AuditLogLevel>? auditLogLevels,
    List<SystemLogLevel>? systemLogLevels,
    List<AuditLogCategory>? auditLogCategories,
    List<SystemLogCategory>? systemLogCategories,
    int? maxLogRetentionDays,
    bool? enableLogCompression,
    bool? enableLogEncryption,
    String? encryptionKey,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      LoggingConfig(
        id: id ?? this.id,
        enableAuditLogging: enableAuditLogging ?? this.enableAuditLogging,
        enableSystemLogging: enableSystemLogging ?? this.enableSystemLogging,
        enablePerformanceLogging:
            enablePerformanceLogging ?? this.enablePerformanceLogging,
        enableSecurityLogging:
            enableSecurityLogging ?? this.enableSecurityLogging,
        auditLogLevels: auditLogLevels ?? this.auditLogLevels,
        systemLogLevels: systemLogLevels ?? this.systemLogLevels,
        auditLogCategories: auditLogCategories ?? this.auditLogCategories,
        systemLogCategories: systemLogCategories ?? this.systemLogCategories,
        maxLogRetentionDays: maxLogRetentionDays ?? this.maxLogRetentionDays,
        enableLogCompression: enableLogCompression ?? this.enableLogCompression,
        enableLogEncryption: enableLogEncryption ?? this.enableLogEncryption,
        encryptionKey: encryptionKey ?? this.encryptionKey,
        filters: filters ?? this.filters,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'LoggingConfig(id: $id, enableAuditLogging: $enableAuditLogging, enableSystemLogging: $enableSystemLogging)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoggingConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
