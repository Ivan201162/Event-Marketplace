import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель настроек безопасности
class SecuritySettings {
  final String userId;
  final bool biometricAuth;
  final bool pinAuth;
  final bool twoFactorAuth;
  final bool autoLock;
  final int autoLockTimeout; // в минутах
  final bool secureStorage;
  final bool dataEncryption;
  final bool auditLogging;
  final List<String> allowedDevices;
  final List<String> blockedDevices;
  final DateTime lastPasswordChange;
  final DateTime lastSecurityUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SecuritySettings({
    required this.userId,
    this.biometricAuth = false,
    this.pinAuth = false,
    this.twoFactorAuth = false,
    this.autoLock = true,
    this.autoLockTimeout = 5,
    this.secureStorage = true,
    this.dataEncryption = true,
    this.auditLogging = true,
    this.allowedDevices = const [],
    this.blockedDevices = const [],
    required this.lastPasswordChange,
    required this.lastSecurityUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecuritySettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SecuritySettings(
      userId: data['userId'] ?? '',
      biometricAuth: data['biometricAuth'] ?? false,
      pinAuth: data['pinAuth'] ?? false,
      twoFactorAuth: data['twoFactorAuth'] ?? false,
      autoLock: data['autoLock'] ?? true,
      autoLockTimeout: data['autoLockTimeout'] ?? 5,
      secureStorage: data['secureStorage'] ?? true,
      dataEncryption: data['dataEncryption'] ?? true,
      auditLogging: data['auditLogging'] ?? true,
      allowedDevices: List<String>.from(data['allowedDevices'] ?? []),
      blockedDevices: List<String>.from(data['blockedDevices'] ?? []),
      lastPasswordChange: (data['lastPasswordChange'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSecurityUpdate: (data['lastSecurityUpdate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'biometricAuth': biometricAuth,
      'pinAuth': pinAuth,
      'twoFactorAuth': twoFactorAuth,
      'autoLock': autoLock,
      'autoLockTimeout': autoLockTimeout,
      'secureStorage': secureStorage,
      'dataEncryption': dataEncryption,
      'auditLogging': auditLogging,
      'allowedDevices': allowedDevices,
      'blockedDevices': blockedDevices,
      'lastPasswordChange': Timestamp.fromDate(lastPasswordChange),
      'lastSecurityUpdate': Timestamp.fromDate(lastSecurityUpdate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SecuritySettings copyWith({
    String? userId,
    bool? biometricAuth,
    bool? pinAuth,
    bool? twoFactorAuth,
    bool? autoLock,
    int? autoLockTimeout,
    bool? secureStorage,
    bool? dataEncryption,
    bool? auditLogging,
    List<String>? allowedDevices,
    List<String>? blockedDevices,
    DateTime? lastPasswordChange,
    DateTime? lastSecurityUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecuritySettings(
      userId: userId ?? this.userId,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      pinAuth: pinAuth ?? this.pinAuth,
      twoFactorAuth: twoFactorAuth ?? this.twoFactorAuth,
      autoLock: autoLock ?? this.autoLock,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      secureStorage: secureStorage ?? this.secureStorage,
      dataEncryption: dataEncryption ?? this.dataEncryption,
      auditLogging: auditLogging ?? this.auditLogging,
      allowedDevices: allowedDevices ?? this.allowedDevices,
      blockedDevices: blockedDevices ?? this.blockedDevices,
      lastPasswordChange: lastPasswordChange ?? this.lastPasswordChange,
      lastSecurityUpdate: lastSecurityUpdate ?? this.lastSecurityUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Модель аудита безопасности
class SecurityAuditLog {
  final String id;
  final String userId;
  final SecurityEventType eventType;
  final String description;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final Map<String, dynamic>? metadata;
  final SecurityEventSeverity severity;
  final DateTime timestamp;

  const SecurityAuditLog({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.description,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    this.metadata,
    required this.severity,
    required this.timestamp,
  });

  factory SecurityAuditLog.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SecurityAuditLog(
      id: doc.id,
      userId: data['userId'] ?? '',
      eventType: SecurityEventType.values.firstWhere(
        (type) => type.name == data['eventType'],
        orElse: () => SecurityEventType.other,
      ),
      description: data['description'] ?? '',
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      deviceId: data['deviceId'],
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
      severity: SecurityEventSeverity.values.firstWhere(
        (severity) => severity.name == data['severity'],
        orElse: () => SecurityEventSeverity.info,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'eventType': eventType.name,
      'description': description,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceId': deviceId,
      'metadata': metadata,
      'severity': severity.name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  SecurityAuditLog copyWith({
    String? id,
    String? userId,
    SecurityEventType? eventType,
    String? description,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    Map<String, dynamic>? metadata,
    SecurityEventSeverity? severity,
    DateTime? timestamp,
  }) {
    return SecurityAuditLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      description: description ?? this.description,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      deviceId: deviceId ?? this.deviceId,
      metadata: metadata ?? this.metadata,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Типы событий безопасности
enum SecurityEventType {
  login,
  logout,
  passwordChange,
  biometricAuth,
  pinAuth,
  twoFactorAuth,
  deviceRegistration,
  deviceBlocked,
  suspiciousActivity,
  dataAccess,
  dataModification,
  securitySettingsChange,
  other,
}

/// Уровни серьезности событий безопасности
enum SecurityEventSeverity {
  info,
  warning,
  error,
  critical,
}

/// Модель устройства
class SecurityDevice {
  final String id;
  final String userId;
  final String deviceName;
  final String deviceType;
  final String osVersion;
  final String appVersion;
  final String? fingerprint;
  final bool isTrusted;
  final bool isBlocked;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final String? lastIpAddress;
  final String? lastUserAgent;

  const SecurityDevice({
    required this.id,
    required this.userId,
    required this.deviceName,
    required this.deviceType,
    required this.osVersion,
    required this.appVersion,
    this.fingerprint,
    this.isTrusted = false,
    this.isBlocked = false,
    required this.firstSeen,
    required this.lastSeen,
    this.lastIpAddress,
    this.lastUserAgent,
  });

  factory SecurityDevice.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SecurityDevice(
      id: doc.id,
      userId: data['userId'] ?? '',
      deviceName: data['deviceName'] ?? '',
      deviceType: data['deviceType'] ?? '',
      osVersion: data['osVersion'] ?? '',
      appVersion: data['appVersion'] ?? '',
      fingerprint: data['fingerprint'],
      isTrusted: data['isTrusted'] ?? false,
      isBlocked: data['isBlocked'] ?? false,
      firstSeen: (data['firstSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastIpAddress: data['lastIpAddress'],
      lastUserAgent: data['lastUserAgent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'fingerprint': fingerprint,
      'isTrusted': isTrusted,
      'isBlocked': isBlocked,
      'firstSeen': Timestamp.fromDate(firstSeen),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'lastIpAddress': lastIpAddress,
      'lastUserAgent': lastUserAgent,
    };
  }

  SecurityDevice copyWith({
    String? id,
    String? userId,
    String? deviceName,
    String? deviceType,
    String? osVersion,
    String? appVersion,
    String? fingerprint,
    bool? isTrusted,
    bool? isBlocked,
    DateTime? firstSeen,
    DateTime? lastSeen,
    String? lastIpAddress,
    String? lastUserAgent,
  }) {
    return SecurityDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      fingerprint: fingerprint ?? this.fingerprint,
      isTrusted: isTrusted ?? this.isTrusted,
      isBlocked: isBlocked ?? this.isBlocked,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      lastIpAddress: lastIpAddress ?? this.lastIpAddress,
      lastUserAgent: lastUserAgent ?? this.lastUserAgent,
    );
  }
}

/// Модель PIN-кода
class PinCode {
  final String userId;
  final String hashedPin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attempts;
  final DateTime? lockedUntil;

  const PinCode({
    required this.userId,
    required this.hashedPin,
    required this.createdAt,
    required this.updatedAt,
    this.attempts = 0,
    this.lockedUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'hashedPin': hashedPin,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'attempts': attempts,
      'lockedUntil': lockedUntil?.millisecondsSinceEpoch,
    };
  }

  factory PinCode.fromMap(Map<String, dynamic> map) {
    return PinCode(
      userId: map['userId'] ?? '',
      hashedPin: map['hashedPin'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      attempts: map['attempts'] ?? 0,
      lockedUntil: map['lockedUntil'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lockedUntil'])
          : null,
    );
  }

  PinCode copyWith({
    String? userId,
    String? hashedPin,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? attempts,
    DateTime? lockedUntil,
  }) {
    return PinCode(
      userId: userId ?? this.userId,
      hashedPin: hashedPin ?? this.hashedPin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attempts: attempts ?? this.attempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }
}

/// Модель двухфакторной аутентификации
class TwoFactorAuth {
  final String userId;
  final String secretKey;
  final bool isEnabled;
  final List<String> backupCodes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TwoFactorAuth({
    required this.userId,
    required this.secretKey,
    this.isEnabled = false,
    this.backupCodes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'secretKey': secretKey,
      'isEnabled': isEnabled,
      'backupCodes': backupCodes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TwoFactorAuth.fromMap(Map<String, dynamic> map) {
    return TwoFactorAuth(
      userId: map['userId'] ?? '',
      secretKey: map['secretKey'] ?? '',
      isEnabled: map['isEnabled'] ?? false,
      backupCodes: List<String>.from(map['backupCodes'] ?? []),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  TwoFactorAuth copyWith({
    String? userId,
    String? secretKey,
    bool? isEnabled,
    List<String>? backupCodes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TwoFactorAuth(
      userId: userId ?? this.userId,
      secretKey: secretKey ?? this.secretKey,
      isEnabled: isEnabled ?? this.isEnabled,
      backupCodes: backupCodes ?? this.backupCodes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Модель зашифрованных данных
class EncryptedData {
  final String key;
  final String encryptedValue;
  final String algorithm;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EncryptedData({
    required this.key,
    required this.encryptedValue,
    required this.algorithm,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'encryptedValue': encryptedValue,
      'algorithm': algorithm,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory EncryptedData.fromMap(Map<String, dynamic> map) {
    return EncryptedData(
      key: map['key'] ?? '',
      encryptedValue: map['encryptedValue'] ?? '',
      algorithm: map['algorithm'] ?? 'AES-256',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }
}
