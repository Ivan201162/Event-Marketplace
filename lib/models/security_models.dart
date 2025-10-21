import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель аудита безопасности
class SecurityAudit {
  const SecurityAudit({
    required this.id,
    required this.userId,
    required this.action,
    required this.resource,
    this.details,
    this.ipAddress,
    this.userAgent,
    this.location,
    this.riskLevel,
    required this.timestamp,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String action;
  final String resource;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final String? location;
  final String? riskLevel;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory SecurityAudit.fromMap(Map<String, dynamic> data) {
    return SecurityAudit(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      action: data['action'] as String? ?? '',
      resource: data['resource'] as String? ?? '',
      details: data['details'] as String?,
      ipAddress: data['ipAddress'] as String?,
      userAgent: data['userAgent'] as String?,
      location: data['location'] as String?,
      riskLevel: data['riskLevel'] as String?,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] is Timestamp
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.parse(data['timestamp'].toString()))
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из документа Firestore
  factory SecurityAudit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return SecurityAudit.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'action': action,
    'resource': resource,
    'details': details,
    'ipAddress': ipAddress,
    'userAgent': userAgent,
    'location': location,
    'riskLevel': riskLevel,
    'timestamp': Timestamp.fromDate(timestamp),
    'metadata': metadata,
  };

  /// Копировать с изменениями
  SecurityAudit copyWith({
    String? id,
    String? userId,
    String? action,
    String? resource,
    String? details,
    String? ipAddress,
    String? userAgent,
    String? location,
    String? riskLevel,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) => SecurityAudit(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    action: action ?? this.action,
    resource: resource ?? this.resource,
    details: details ?? this.details,
    ipAddress: ipAddress ?? this.ipAddress,
    userAgent: userAgent ?? this.userAgent,
    location: location ?? this.location,
    riskLevel: riskLevel ?? this.riskLevel,
    timestamp: timestamp ?? this.timestamp,
    metadata: metadata ?? this.metadata,
  );

  /// Проверить, является ли действие высокорисковым
  bool get isHighRisk {
    return riskLevel == 'high' || riskLevel == 'critical';
  }

  /// Получить отображаемое название уровня риска
  String get riskLevelDisplayName {
    switch (riskLevel) {
      case 'low':
        return 'Низкий';
      case 'medium':
        return 'Средний';
      case 'high':
        return 'Высокий';
      case 'critical':
        return 'Критический';
      default:
        return 'Неизвестно';
    }
  }
}

/// Модель устройства безопасности
class SecurityDevice {
  const SecurityDevice({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.os,
    this.browser,
    this.isTrusted = false,
    this.lastSeen,
    required this.createdAt,
    this.metadata = const {},
  });

  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String? os;
  final String? browser;
  final bool isTrusted;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  /// Создать из Map
  factory SecurityDevice.fromMap(Map<String, dynamic> data) {
    return SecurityDevice(
      id: data['id'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      deviceId: data['deviceId'] as String? ?? '',
      deviceName: data['deviceName'] as String? ?? '',
      deviceType: data['deviceType'] as String? ?? '',
      os: data['os'] as String?,
      browser: data['browser'] as String?,
      isTrusted: data['isTrusted'] as bool? ?? false,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] is Timestamp
                ? (data['lastSeen'] as Timestamp).toDate()
                : DateTime.tryParse(data['lastSeen'].toString()))
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.parse(data['createdAt'].toString()))
          : DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из документа Firestore
  factory SecurityDevice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Document data is null');
    }

    return SecurityDevice.fromMap({'id': doc.id, ...data});
  }

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
    'userId': userId,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'deviceType': deviceType,
    'os': os,
    'browser': browser,
    'isTrusted': isTrusted,
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'metadata': metadata,
  };

  /// Копировать с изменениями
  SecurityDevice copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? os,
    String? browser,
    bool? isTrusted,
    DateTime? lastSeen,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) => SecurityDevice(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    deviceId: deviceId ?? this.deviceId,
    deviceName: deviceName ?? this.deviceName,
    deviceType: deviceType ?? this.deviceType,
    os: os ?? this.os,
    browser: browser ?? this.browser,
    isTrusted: isTrusted ?? this.isTrusted,
    lastSeen: lastSeen ?? this.lastSeen,
    createdAt: createdAt ?? this.createdAt,
    metadata: metadata ?? this.metadata,
  );

  /// Получить отображаемое название устройства
  String get displayName {
    if (os != null && browser != null) {
      return '$deviceName ($os, $browser)';
    } else if (os != null) {
      return '$deviceName ($os)';
    } else if (browser != null) {
      return '$deviceName ($browser)';
    }
    return deviceName;
  }

  /// Проверить, активно ли устройство
  bool get isActive {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inDays < 30; // Активно, если последний раз видели менее 30 дней назад
  }
}

/// Модель настроек безопасности
class SecuritySettings {
  const SecuritySettings({
    this.twoFactorEnabled = false,
    this.loginNotifications = true,
    this.deviceNotifications = true,
    this.suspiciousActivityAlerts = true,
    this.dataEncryption = true,
    this.sessionTimeout = 30, // минуты
    this.maxFailedAttempts = 5,
    this.lockoutDuration = 15, // минуты
    this.requireStrongPassword = true,
    this.allowRememberDevice = true,
  });

  final bool twoFactorEnabled;
  final bool loginNotifications;
  final bool deviceNotifications;
  final bool suspiciousActivityAlerts;
  final bool dataEncryption;
  final int sessionTimeout;
  final int maxFailedAttempts;
  final int lockoutDuration;
  final bool requireStrongPassword;
  final bool allowRememberDevice;

  /// Создать из Map
  factory SecuritySettings.fromMap(Map<String, dynamic> data) {
    return SecuritySettings(
      twoFactorEnabled: data['twoFactorEnabled'] as bool? ?? false,
      loginNotifications: data['loginNotifications'] as bool? ?? true,
      deviceNotifications: data['deviceNotifications'] as bool? ?? true,
      suspiciousActivityAlerts: data['suspiciousActivityAlerts'] as bool? ?? true,
      dataEncryption: data['dataEncryption'] as bool? ?? true,
      sessionTimeout: data['sessionTimeout'] as int? ?? 30,
      maxFailedAttempts: data['maxFailedAttempts'] as int? ?? 5,
      lockoutDuration: data['lockoutDuration'] as int? ?? 15,
      requireStrongPassword: data['requireStrongPassword'] as bool? ?? true,
      allowRememberDevice: data['allowRememberDevice'] as bool? ?? true,
    );
  }

  /// Преобразовать в Map
  Map<String, dynamic> toMap() => {
    'twoFactorEnabled': twoFactorEnabled,
    'loginNotifications': loginNotifications,
    'deviceNotifications': deviceNotifications,
    'suspiciousActivityAlerts': suspiciousActivityAlerts,
    'dataEncryption': dataEncryption,
    'sessionTimeout': sessionTimeout,
    'maxFailedAttempts': maxFailedAttempts,
    'lockoutDuration': lockoutDuration,
    'requireStrongPassword': requireStrongPassword,
    'allowRememberDevice': allowRememberDevice,
  };

  /// Копировать с изменениями
  SecuritySettings copyWith({
    bool? twoFactorEnabled,
    bool? loginNotifications,
    bool? deviceNotifications,
    bool? suspiciousActivityAlerts,
    bool? dataEncryption,
    int? sessionTimeout,
    int? maxFailedAttempts,
    int? lockoutDuration,
    bool? requireStrongPassword,
    bool? allowRememberDevice,
  }) => SecuritySettings(
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    loginNotifications: loginNotifications ?? this.loginNotifications,
    deviceNotifications: deviceNotifications ?? this.deviceNotifications,
    suspiciousActivityAlerts: suspiciousActivityAlerts ?? this.suspiciousActivityAlerts,
    dataEncryption: dataEncryption ?? this.dataEncryption,
    sessionTimeout: sessionTimeout ?? this.sessionTimeout,
    maxFailedAttempts: maxFailedAttempts ?? this.maxFailedAttempts,
    lockoutDuration: lockoutDuration ?? this.lockoutDuration,
    requireStrongPassword: requireStrongPassword ?? this.requireStrongPassword,
    allowRememberDevice: allowRememberDevice ?? this.allowRememberDevice,
  );

  /// Проверить, включена ли двухфакторная аутентификация
  bool get isTwoFactorEnabled => twoFactorEnabled;

  /// Проверить, включены ли уведомления о входе
  bool get isLoginNotificationsEnabled => loginNotifications;

  /// Проверить, включены ли уведомления об устройствах
  bool get isDeviceNotificationsEnabled => deviceNotifications;

  /// Проверить, включены ли уведомления о подозрительной активности
  bool get isSuspiciousActivityAlertsEnabled => suspiciousActivityAlerts;

  /// Проверить, включено ли шифрование данных
  bool get isDataEncryptionEnabled => dataEncryption;

  /// Получить отформатированное время сессии
  String get formattedSessionTimeout {
    if (sessionTimeout < 60) {
      return '$sessionTimeout мин';
    } else {
      final hours = sessionTimeout ~/ 60;
      final minutes = sessionTimeout % 60;
      if (minutes == 0) {
        return '$hours ч';
      } else {
        return '$hours ч $minutes мин';
      }
    }
  }

  /// Получить отформатированное время блокировки
  String get formattedLockoutDuration {
    if (lockoutDuration < 60) {
      return '$lockoutDuration мин';
    } else {
      final hours = lockoutDuration ~/ 60;
      final minutes = lockoutDuration % 60;
      if (minutes == 0) {
        return '$hours ч';
      } else {
        return '$hours ч $minutes мин';
      }
    }
  }
}
