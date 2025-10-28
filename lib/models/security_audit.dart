import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель аудита безопасности
class SecurityAudit {
  const SecurityAudit({
    required this.id,
    required this.eventType,
    required this.description,
    required this.level,
    required this.timestamp, this.userId,
    this.sessionId,
    this.ipAddress,
    this.userAgent,
    this.metadata = const {},
    this.resolvedBy,
    this.resolvedAt,
    this.isResolved = false,
  });

  /// Создать из документа Firestore
  factory SecurityAudit.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SecurityAudit(
      id: doc.id,
      eventType: data['eventType'] as String? ?? '',
      description: data['description'] as String? ?? '',
      level: SecurityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == (data['level'] as String?),
        orElse: () => SecurityLevel.info,
      ),
      userId: data['userId'] as String?,
      sessionId: data['sessionId'] as String?,
      ipAddress: data['ipAddress'] as String?,
      userAgent: data['userAgent'] as String?,
      metadata: Map<String, dynamic>.from(
          data['metadata'] as Map<dynamic, dynamic>? ?? {},),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      resolvedBy: data['resolvedBy'] as String?,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      isResolved: data['isResolved'] as bool? ?? false,
    );
  }

  /// Создать из Map
  factory SecurityAudit.fromMap(Map<String, dynamic> data) => SecurityAudit(
        id: data['id'] as String? ?? '',
        eventType: data['eventType'] as String? ?? '',
        description: data['description'] as String? ?? '',
        level: SecurityLevel.values.firstWhere(
          (e) => e.toString().split('.').last == data['level'],
          orElse: () => SecurityLevel.info,
        ),
        userId: data['userId'],
        sessionId: data['sessionId'],
        ipAddress: data['ipAddress'],
        userAgent: data['userAgent'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        resolvedBy: data['resolvedBy'],
        resolvedAt: data['resolvedAt'] != null
            ? (data['resolvedAt'] as Timestamp).toDate()
            : null,
        isResolved: data['isResolved'] as bool? ?? false,
      );
  final String id;
  final String eventType;
  final String description;
  final SecurityLevel level;
  final String? userId;
  final String? sessionId;
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final bool isResolved;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'eventType': eventType,
        'description': description,
        'level': level.toString().split('.').last,
        'userId': userId,
        'sessionId': sessionId,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
        'resolvedBy': resolvedBy,
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'isResolved': isResolved,
      };

  /// Создать копию с изменениями
  SecurityAudit copyWith({
    String? id,
    String? eventType,
    String? description,
    SecurityLevel? level,
    String? userId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    String? resolvedBy,
    DateTime? resolvedAt,
    bool? isResolved,
  }) =>
      SecurityAudit(
        id: id ?? this.id,
        eventType: eventType ?? this.eventType,
        description: description ?? this.description,
        level: level ?? this.level,
        userId: userId ?? this.userId,
        sessionId: sessionId ?? this.sessionId,
        ipAddress: ipAddress ?? this.ipAddress,
        userAgent: userAgent ?? this.userAgent,
        metadata: metadata ?? this.metadata,
        timestamp: timestamp ?? this.timestamp,
        resolvedBy: resolvedBy ?? this.resolvedBy,
        resolvedAt: resolvedAt ?? this.resolvedAt,
        isResolved: isResolved ?? this.isResolved,
      );

  /// Проверить, критично ли событие
  bool get isCritical => level == SecurityLevel.critical;

  /// Проверить, требует ли внимания
  bool get requiresAttention =>
      level == SecurityLevel.critical || level == SecurityLevel.high;

  /// Получить время до разрешения
  Duration? get timeToResolution {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(timestamp);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityAudit &&
        other.id == id &&
        other.eventType == eventType &&
        other.description == description &&
        other.level == level &&
        other.userId == userId &&
        other.sessionId == sessionId &&
        other.ipAddress == ipAddress &&
        other.userAgent == userAgent &&
        other.metadata == metadata &&
        other.timestamp == timestamp &&
        other.resolvedBy == resolvedBy &&
        other.resolvedAt == resolvedAt &&
        other.isResolved == isResolved;
  }

  @override
  int get hashCode => Object.hash(
        id,
        eventType,
        description,
        level,
        userId,
        sessionId,
        ipAddress,
        userAgent,
        metadata,
        timestamp,
        resolvedBy,
        resolvedAt,
        isResolved,
      );

  @override
  String toString() =>
      'SecurityAudit(id: $id, eventType: $eventType, level: $level)';
}

/// Модель политики безопасности
class SecurityPolicy {
  const SecurityPolicy({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.rules,
    required this.createdAt, required this.updatedAt, this.isEnabled = true,
    this.severity = SecurityLevel.medium,
    this.affectedRoles = const [],
    this.createdBy,
  });

  /// Создать из документа Firestore
  factory SecurityPolicy.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SecurityPolicy(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: SecurityPolicyType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => SecurityPolicyType.authentication,
      ),
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      isEnabled: data['isEnabled'] as bool? ?? true,
      severity: SecurityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == data['severity'],
        orElse: () => SecurityLevel.medium,
      ),
      affectedRoles: List<String>.from(data['affectedRoles'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  /// Создать из Map
  factory SecurityPolicy.fromMap(Map<String, dynamic> data) => SecurityPolicy(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        type: SecurityPolicyType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => SecurityPolicyType.authentication,
        ),
        rules: Map<String, dynamic>.from(data['rules'] ?? {}),
        isEnabled: data['isEnabled'] as bool? ?? true,
        severity: SecurityLevel.values.firstWhere(
          (e) => e.toString().split('.').last == data['severity'],
          orElse: () => SecurityLevel.medium,
        ),
        affectedRoles: List<String>.from(data['affectedRoles'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        createdBy: data['createdBy'],
      );
  final String id;
  final String name;
  final String description;
  final SecurityPolicyType type;
  final Map<String, dynamic> rules;
  final bool isEnabled;
  final SecurityLevel severity;
  final List<String> affectedRoles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'type': type.toString().split('.').last,
        'rules': rules,
        'isEnabled': isEnabled,
        'severity': severity.toString().split('.').last,
        'affectedRoles': affectedRoles,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
      };

  /// Создать копию с изменениями
  SecurityPolicy copyWith({
    String? id,
    String? name,
    String? description,
    SecurityPolicyType? type,
    Map<String, dynamic>? rules,
    bool? isEnabled,
    SecurityLevel? severity,
    List<String>? affectedRoles,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) =>
      SecurityPolicy(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        type: type ?? this.type,
        rules: rules ?? this.rules,
        isEnabled: isEnabled ?? this.isEnabled,
        severity: severity ?? this.severity,
        affectedRoles: affectedRoles ?? this.affectedRoles,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SecurityPolicy &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.type == type &&
        other.rules == rules &&
        other.isEnabled == isEnabled &&
        other.severity == severity &&
        other.affectedRoles == affectedRoles &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        type,
        rules,
        isEnabled,
        severity,
        affectedRoles,
        createdAt,
        updatedAt,
        createdBy,
      );

  @override
  String toString() => 'SecurityPolicy(id: $id, name: $name, type: $type)';
}

/// Модель шифрования
class EncryptionKey {
  const EncryptionKey({
    required this.id,
    required this.name,
    required this.algorithm,
    required this.keyType,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.description,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory EncryptionKey.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EncryptionKey(
      id: doc.id,
      name: data['name'] ?? '',
      algorithm: data['algorithm'] ?? '',
      keyType: data['keyType'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      description: data['description'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из Map
  factory EncryptionKey.fromMap(Map<String, dynamic> data) => EncryptionKey(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        algorithm: data['algorithm'] ?? '',
        keyType: data['keyType'] ?? '',
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
        isActive: data['isActive'] as bool? ?? true,
        description: data['description'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String name;
  final String algorithm;
  final String keyType;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String? description;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'algorithm': algorithm,
        'keyType': keyType,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
        'isActive': isActive,
        'description': description,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  EncryptionKey copyWith({
    String? id,
    String? name,
    String? algorithm,
    String? keyType,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isActive,
    String? description,
    Map<String, dynamic>? metadata,
  }) =>
      EncryptionKey(
        id: id ?? this.id,
        name: name ?? this.name,
        algorithm: algorithm ?? this.algorithm,
        keyType: keyType ?? this.keyType,
        createdAt: createdAt ?? this.createdAt,
        expiresAt: expiresAt ?? this.expiresAt,
        isActive: isActive ?? this.isActive,
        description: description ?? this.description,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, истек ли срок действия
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// Проверить, действителен ли ключ
  bool get isValid => isActive && !isExpired;

  /// Получить время жизни
  Duration get age => DateTime.now().difference(createdAt);

  /// Получить оставшееся время
  Duration? get timeToExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncryptionKey &&
        other.id == id &&
        other.name == name &&
        other.algorithm == algorithm &&
        other.keyType == keyType &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt &&
        other.isActive == isActive &&
        other.description == description &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        algorithm,
        keyType,
        createdAt,
        expiresAt,
        isActive,
        description,
        metadata,
      );

  @override
  String toString() =>
      'EncryptionKey(id: $id, name: $name, algorithm: $algorithm)';
}

/// Уровни безопасности
enum SecurityLevel { info, low, medium, high, critical }

/// Расширение для уровней безопасности
extension SecurityLevelExtension on SecurityLevel {
  String get displayName {
    switch (this) {
      case SecurityLevel.info:
        return 'Информация';
      case SecurityLevel.low:
        return 'Низкий';
      case SecurityLevel.medium:
        return 'Средний';
      case SecurityLevel.high:
        return 'Высокий';
      case SecurityLevel.critical:
        return 'Критический';
    }
  }

  String get description {
    switch (this) {
      case SecurityLevel.info:
        return 'Информационное сообщение';
      case SecurityLevel.low:
        return 'Низкий риск безопасности';
      case SecurityLevel.medium:
        return 'Средний риск безопасности';
      case SecurityLevel.high:
        return 'Высокий риск безопасности';
      case SecurityLevel.critical:
        return 'Критический риск безопасности';
    }
  }

  String get color {
    switch (this) {
      case SecurityLevel.info:
        return 'blue';
      case SecurityLevel.low:
        return 'green';
      case SecurityLevel.medium:
        return 'orange';
      case SecurityLevel.high:
        return 'red';
      case SecurityLevel.critical:
        return 'purple';
    }
  }

  int get priority {
    switch (this) {
      case SecurityLevel.info:
        return 1;
      case SecurityLevel.low:
        return 2;
      case SecurityLevel.medium:
        return 3;
      case SecurityLevel.high:
        return 4;
      case SecurityLevel.critical:
        return 5;
    }
  }
}

/// Типы политик безопасности
enum SecurityPolicyType {
  authentication,
  authorization,
  dataProtection,
  networkSecurity,
  auditLogging,
  encryption,
  accessControl,
  sessionManagement,
}

/// Расширение для типов политик безопасности
extension SecurityPolicyTypeExtension on SecurityPolicyType {
  String get displayName {
    switch (this) {
      case SecurityPolicyType.authentication:
        return 'Аутентификация';
      case SecurityPolicyType.authorization:
        return 'Авторизация';
      case SecurityPolicyType.dataProtection:
        return 'Защита данных';
      case SecurityPolicyType.networkSecurity:
        return 'Сетевая безопасность';
      case SecurityPolicyType.auditLogging:
        return 'Аудит и логирование';
      case SecurityPolicyType.encryption:
        return 'Шифрование';
      case SecurityPolicyType.accessControl:
        return 'Контроль доступа';
      case SecurityPolicyType.sessionManagement:
        return 'Управление сессиями';
    }
  }

  String get description {
    switch (this) {
      case SecurityPolicyType.authentication:
        return 'Политики аутентификации пользователей';
      case SecurityPolicyType.authorization:
        return 'Политики авторизации и разрешений';
      case SecurityPolicyType.dataProtection:
        return 'Политики защиты персональных данных';
      case SecurityPolicyType.networkSecurity:
        return 'Политики сетевой безопасности';
      case SecurityPolicyType.auditLogging:
        return 'Политики аудита и логирования';
      case SecurityPolicyType.encryption:
        return 'Политики шифрования данных';
      case SecurityPolicyType.accessControl:
        return 'Политики контроля доступа';
      case SecurityPolicyType.sessionManagement:
        return 'Политики управления сессиями';
    }
  }
}

/// Статистика безопасности
class SecurityStatistics {
  const SecurityStatistics({
    required this.totalEvents,
    required this.criticalEvents,
    required this.highEvents,
    required this.mediumEvents,
    required this.lowEvents,
    required this.infoEvents,
    required this.resolvedEvents,
    required this.unresolvedEvents,
    required this.lastEvent,
    required this.eventsByType,
    required this.eventsByLevel,
    required this.resolutionRate,
  });

  /// Создать из списка событий
  factory SecurityStatistics.fromEvents(List<SecurityAudit> events) {
    if (events.isEmpty) {
      return SecurityStatistics(
        totalEvents: 0,
        criticalEvents: 0,
        highEvents: 0,
        mediumEvents: 0,
        lowEvents: 0,
        infoEvents: 0,
        resolvedEvents: 0,
        unresolvedEvents: 0,
        lastEvent: DateTime.now(),
        eventsByType: {},
        eventsByLevel: {},
        resolutionRate: 0,
      );
    }

    var criticalEvents = 0;
    var highEvents = 0;
    var mediumEvents = 0;
    var lowEvents = 0;
    var infoEvents = 0;
    var resolvedEvents = 0;

    final eventsByType = <String, int>{};
    final eventsByLevel = <String, int>{};

    var lastEvent = events.first.timestamp;

    for (final event in events) {
      // Подсчет по уровням
      switch (event.level) {
        case SecurityLevel.critical:
          criticalEvents++;
        case SecurityLevel.high:
          highEvents++;
        case SecurityLevel.medium:
          mediumEvents++;
        case SecurityLevel.low:
          lowEvents++;
        case SecurityLevel.info:
          infoEvents++;
      }

      // Подсчет разрешенных
      if (event.isResolved) {
        resolvedEvents++;
      }

      // Подсчет по типам
      eventsByType[event.eventType] = (eventsByType[event.eventType] ?? 0) + 1;

      // Подсчет по уровням
      final levelName = event.level.displayName;
      eventsByLevel[levelName] = (eventsByLevel[levelName] ?? 0) + 1;

      // Последнее событие
      if (event.timestamp.isAfter(lastEvent)) {
        lastEvent = event.timestamp;
      }
    }

    final totalEvents = events.length;
    final unresolvedEvents = totalEvents - resolvedEvents;
    final resolutionRate = totalEvents > 0 ? resolvedEvents / totalEvents : 0.0;

    return SecurityStatistics(
      totalEvents: totalEvents,
      criticalEvents: criticalEvents,
      highEvents: highEvents,
      mediumEvents: mediumEvents,
      lowEvents: lowEvents,
      infoEvents: infoEvents,
      resolvedEvents: resolvedEvents,
      unresolvedEvents: unresolvedEvents,
      lastEvent: lastEvent,
      eventsByType: eventsByType,
      eventsByLevel: eventsByLevel,
      resolutionRate: resolutionRate,
    );
  }
  final int totalEvents;
  final int criticalEvents;
  final int highEvents;
  final int mediumEvents;
  final int lowEvents;
  final int infoEvents;
  final int resolvedEvents;
  final int unresolvedEvents;
  final DateTime lastEvent;
  final Map<String, int> eventsByType;
  final Map<String, int> eventsByLevel;
  final double resolutionRate;

  /// Получить общий уровень риска
  SecurityLevel get overallRiskLevel {
    if (criticalEvents > 0) return SecurityLevel.critical;
    if (highEvents > 5) return SecurityLevel.high;
    if (mediumEvents > 10) return SecurityLevel.medium;
    if (lowEvents > 20) return SecurityLevel.low;
    return SecurityLevel.info;
  }

  /// Проверить, есть ли критические события
  bool get hasCriticalIssues => criticalEvents > 0;

  /// Проверить, нужны ли действия
  bool get requiresAction => criticalEvents > 0 || highEvents > 3;

  @override
  String toString() =>
      'SecurityStatistics(totalEvents: $totalEvents, criticalEvents: $criticalEvents, resolutionRate: ${(resolutionRate * 100).toStringAsFixed(1)}%)';
}
