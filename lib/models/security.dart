import 'package:cloud_firestore/cloud_firestore.dart';

/// Назначение роли пользователю
class UserRoleAssignment {
  const UserRoleAssignment({
    required this.id,
    required this.userId,
    required this.roleName,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserRoleAssignment.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserRoleAssignment(
      id: doc.id,
      userId: data['userId'] ?? '',
      roleName: data['roleName'] ?? '',
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String roleName;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'roleName': roleName,
        'permissions': permissions,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

/// Аудит-лог
class AuditLog {
  const AuditLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    required this.metadata, required this.timestamp, this.resourceId,
    this.ipAddress,
    this.userAgent,
  });

  factory AuditLog.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      resource: data['resource'] ?? '',
      resourceId: data['resourceId'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
  final String id;
  final String userId;
  final String action;
  final String resource;
  final String? resourceId;
  final Map<String, dynamic> metadata;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'action': action,
        'resource': resource,
        'resourceId': resourceId,
        'metadata': metadata,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

/// Сессия безопасности
class SecuritySession {
  const SecuritySession({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.status, required this.createdAt, required this.lastActivityAt, required this.expiresAt, required this.metadata, this.ipAddress,
    this.userAgent,
  });

  factory SecuritySession.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SecuritySession(
      id: doc.id,
      userId: data['userId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      status: SecuritySessionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SecuritySessionStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActivityAt: (data['lastActivityAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final String deviceId;
  final String? ipAddress;
  final String? userAgent;
  final SecuritySessionStatus status;
  final DateTime createdAt;
  final DateTime lastActivityAt;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'deviceId': deviceId,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastActivityAt': Timestamp.fromDate(lastActivityAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'metadata': metadata,
      };

  SecuritySession copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? ipAddress,
    String? userAgent,
    SecuritySessionStatus? status,
    DateTime? createdAt,
    DateTime? lastActivityAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
  }) =>
      SecuritySession(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        deviceId: deviceId ?? this.deviceId,
        ipAddress: ipAddress ?? this.ipAddress,
        userAgent: userAgent ?? this.userAgent,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        lastActivityAt: lastActivityAt ?? this.lastActivityAt,
        expiresAt: expiresAt ?? this.expiresAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Предупреждение безопасности
class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.userId,
    required this.type,
    required this.description,
    required this.status,
    required this.severity,
    required this.createdAt,
    required this.metadata, this.resolvedAt,
  });

  factory SecurityAlert.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return SecurityAlert(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SecurityAlertType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => SecurityAlertType.suspiciousActivity,
      ),
      description: data['description'] ?? '',
      status: SecurityAlertStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SecurityAlertStatus.active,
      ),
      severity: SecurityAlertSeverity.values.firstWhere(
        (e) => e.name == data['severity'],
        orElse: () => SecurityAlertSeverity.medium,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final SecurityAlertType type;
  final String description;
  final SecurityAlertStatus status;
  final SecurityAlertSeverity severity;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'description': description,
        'status': status.name,
        'severity': severity.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'metadata': metadata,
      };
}

/// Блокировка пользователя
class UserBlock {
  const UserBlock({
    required this.id,
    required this.userId,
    required this.reason,
    required this.status, required this.createdAt, required this.expiresAt, required this.metadata, this.blockedBy,
  });

  factory UserBlock.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserBlock(
      id: doc.id,
      userId: data['userId'] ?? '',
      reason: data['reason'] ?? '',
      blockedBy: data['blockedBy'],
      status: UserBlockStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserBlockStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String userId;
  final String reason;
  final String? blockedBy;
  final UserBlockStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'reason': reason,
        'blockedBy': blockedBy,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'metadata': metadata,
      };
}

/// Статусы сессий безопасности
enum SecuritySessionStatus { active, expired, revoked }

/// Типы предупреждений безопасности
enum SecurityAlertType {
  suspiciousActivity,
  multipleFailedLogins,
  suspiciousIp,
  userBlocked,
  dataBreach,
}

/// Статусы предупреждений безопасности
enum SecurityAlertStatus { active, resolved, dismissed }

/// Уровни серьезности предупреждений
enum SecurityAlertSeverity { low, medium, high, critical }

/// Статусы блокировки пользователей
enum UserBlockStatus { active, expired, revoked }
