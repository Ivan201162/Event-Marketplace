import 'package:cloud_firestore/cloud_firestore.dart';

/// Настройки безопасности пользователя
class SecuritySettings {
  const SecuritySettings({
    required this.id,
    required this.userId,
    required this.twoFactorEnabled,
    required this.biometricEnabled,
    required this.pinCodeEnabled,
    required this.sessionTimeout,
    required this.loginNotifications,
    required this.securityAlerts,
    required this.dataEncryption,
    required this.auditLogging,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SecuritySettings.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecuritySettings(
      id: doc.id,
      userId: data['userId'] ?? '',
      twoFactorEnabled: data['twoFactorEnabled'] ?? false,
      biometricEnabled: data['biometricEnabled'] ?? false,
      pinCodeEnabled: data['pinCodeEnabled'] ?? false,
      sessionTimeout: data['sessionTimeout'] ?? 30,
      loginNotifications: data['loginNotifications'] ?? true,
      securityAlerts: data['securityAlerts'] ?? true,
      dataEncryption: data['dataEncryption'] ?? true,
      auditLogging: data['auditLogging'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  final String id;
  final String userId;
  final bool twoFactorEnabled;
  final bool biometricEnabled;
  final bool pinCodeEnabled;
  final int sessionTimeout; // в минутах
  final bool loginNotifications;
  final bool securityAlerts;
  final bool dataEncryption;
  final bool auditLogging;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'twoFactorEnabled': twoFactorEnabled,
        'biometricEnabled': biometricEnabled,
        'pinCodeEnabled': pinCodeEnabled,
        'sessionTimeout': sessionTimeout,
        'loginNotifications': loginNotifications,
        'securityAlerts': securityAlerts,
        'dataEncryption': dataEncryption,
        'auditLogging': auditLogging,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  SecuritySettings copyWith({
    String? id,
    String? userId,
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? pinCodeEnabled,
    int? sessionTimeout,
    bool? loginNotifications,
    bool? securityAlerts,
    bool? dataEncryption,
    bool? auditLogging,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SecuritySettings(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinCodeEnabled: pinCodeEnabled ?? this.pinCodeEnabled,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      loginNotifications: loginNotifications ?? this.loginNotifications,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      dataEncryption: dataEncryption ?? this.dataEncryption,
      auditLogging: auditLogging ?? this.auditLogging,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Устройство безопасности
class SecurityDevice {
  const SecurityDevice({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.platform,
    required this.isTrusted,
    required this.lastSeen,
    required this.createdAt,
    this.metadata,
  });

  factory SecurityDevice.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SecurityDevice(
      id: doc.id,
      userId: data['userId'] ?? '',
      deviceId: data['deviceId'] ?? '',
      deviceName: data['deviceName'] ?? '',
      deviceType: data['deviceType'] ?? '',
      platform: data['platform'] ?? '',
      isTrusted: data['isTrusted'] ?? false,
      lastSeen: (data['lastSeen'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  final String id;
  final String userId;
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String platform;
  final bool isTrusted;
  final DateTime lastSeen;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'deviceType': deviceType,
        'platform': platform,
        'isTrusted': isTrusted,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
      };

  SecurityDevice copyWith({
    String? id,
    String? userId,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    String? platform,
    bool? isTrusted,
    DateTime? lastSeen,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return SecurityDevice(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      platform: platform ?? this.platform,
      isTrusted: isTrusted ?? this.isTrusted,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Сила пароля
enum SecurityPasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// Расширение для SecurityPasswordStrength
extension SecurityPasswordStrengthExtension on SecurityPasswordStrength {
  String get displayName {
    switch (this) {
      case SecurityPasswordStrength.weak:
        return 'Слабый';
      case SecurityPasswordStrength.medium:
        return 'Средний';
      case SecurityPasswordStrength.strong:
        return 'Сильный';
      case SecurityPasswordStrength.veryStrong:
        return 'Очень сильный';
    }
  }
}
