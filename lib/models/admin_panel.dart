import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для админ-панели
class AdminPanel {
  const AdminPanel({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.role,
    this.permissions = const [],
    required this.createdAt,
    required this.lastLogin,
    this.isActive = true,
  });

  factory AdminPanel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminPanel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      role: AdminRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => AdminRole.moderator,
      ),
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
  final String id;
  final String adminId;
  final String adminName;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime lastLogin;
  final bool isActive;

  Map<String, dynamic> toMap() => {
        'id': id,
        'adminId': adminId,
        'adminName': adminName,
        'role': role.name,
        'permissions': permissions,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLogin': Timestamp.fromDate(lastLogin),
        'isActive': isActive,
      };

  AdminPanel copyWith({
    String? id,
    String? adminId,
    String? adminName,
    AdminRole? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) =>
      AdminPanel(
        id: id ?? this.id,
        adminId: adminId ?? this.adminId,
        adminName: adminName ?? this.adminName,
        role: role ?? this.role,
        permissions: permissions ?? this.permissions,
        createdAt: createdAt ?? this.createdAt,
        lastLogin: lastLogin ?? this.lastLogin,
        isActive: isActive ?? this.isActive,
      );
}

/// Роли администратора
enum AdminRole {
  superAdmin, // Супер-администратор
  admin, // Администратор
  moderator, // Модератор
  support, // Поддержка
}

/// Разрешения администратора
enum AdminPermission {
  // Управление пользователями
  viewUsers,
  editUsers,
  deleteUsers,
  banUsers,

  // Управление специалистами
  viewSpecialists,
  editSpecialists,
  deleteSpecialists,
  verifySpecialists,

  // Управление бронированиями
  viewBookings,
  editBookings,
  deleteBookings,
  cancelBookings,

  // Управление платежами
  viewPayments,
  editPayments,
  refundPayments,

  // Управление отзывами
  viewReviews,
  editReviews,
  deleteReviews,
  moderateReviews,

  // Аналитика
  viewAnalytics,
  exportData,

  // Системные настройки
  viewSettings,
  editSettings,

  // Управление админами
  viewAdmins,
  editAdmins,
  deleteAdmins,
}

/// Статистика админ-панели
class AdminStats {
  const AdminStats({
    required this.totalUsers,
    required this.totalSpecialists,
    required this.totalBookings,
    required this.totalPayments,
    required this.totalReviews,
    required this.totalRevenue,
    required this.activeUsers,
    required this.pendingBookings,
    required this.pendingReviews,
    required this.bannedUsers,
    required this.lastUpdated,
  });

  factory AdminStats.empty() => AdminStats(
        totalUsers: 0,
        totalSpecialists: 0,
        totalBookings: 0,
        totalPayments: 0,
        totalReviews: 0,
        totalRevenue: 0,
        activeUsers: 0,
        pendingBookings: 0,
        pendingReviews: 0,
        bannedUsers: 0,
        lastUpdated: DateTime.now(),
      );

  factory AdminStats.fromMap(Map<String, dynamic> map) => AdminStats(
        totalUsers: map['totalUsers'] ?? 0,
        totalSpecialists: map['totalSpecialists'] ?? 0,
        totalBookings: map['totalBookings'] ?? 0,
        totalPayments: map['totalPayments'] ?? 0,
        totalReviews: map['totalReviews'] ?? 0,
        totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
        activeUsers: map['activeUsers'] ?? 0,
        pendingBookings: map['pendingBookings'] ?? 0,
        pendingReviews: map['pendingReviews'] ?? 0,
        bannedUsers: map['bannedUsers'] ?? 0,
        lastUpdated:
            (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final int totalUsers;
  final int totalSpecialists;
  final int totalBookings;
  final int totalPayments;
  final int totalReviews;
  final double totalRevenue;
  final int activeUsers;
  final int pendingBookings;
  final int pendingReviews;
  final int bannedUsers;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'totalUsers': totalUsers,
        'totalSpecialists': totalSpecialists,
        'totalBookings': totalBookings,
        'totalPayments': totalPayments,
        'totalReviews': totalReviews,
        'totalRevenue': totalRevenue,
        'activeUsers': activeUsers,
        'pendingBookings': pendingBookings,
        'pendingReviews': pendingReviews,
        'bannedUsers': bannedUsers,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}

/// Действие администратора
class AdminAction {
  const AdminAction({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.type,
    required this.targetId,
    required this.targetType,
    required this.description,
    this.metadata = const {},
    required this.timestamp,
  });

  factory AdminAction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminAction(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? '',
      type: AdminActionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AdminActionType.other,
      ),
      targetId: data['targetId'] ?? '',
      targetType: data['targetType'] ?? '',
      description: data['description'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String adminId;
  final String adminName;
  final AdminActionType type;
  final String targetId;
  final String targetType;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;

  Map<String, dynamic> toMap() => {
        'id': id,
        'adminId': adminId,
        'adminName': adminName,
        'type': type.name,
        'targetId': targetId,
        'targetType': targetType,
        'description': description,
        'metadata': metadata,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}

/// Типы действий администратора
enum AdminActionType {
  userCreated,
  userUpdated,
  userDeleted,
  userBanned,
  userUnbanned,
  specialistVerified,
  specialistUnverified,
  bookingCreated,
  bookingUpdated,
  bookingCancelled,
  paymentProcessed,
  paymentRefunded,
  reviewCreated,
  reviewUpdated,
  reviewDeleted,
  reviewModerated,
  settingsUpdated,
  adminCreated,
  adminUpdated,
  adminDeleted,
  other,
}

/// Уведомление для администратора
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetId,
    this.targetType,
    this.isRead = false,
    required this.createdAt,
    this.metadata = const {},
  });

  factory AdminNotification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminNotification(
      id: doc.id,
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: AdminNotificationType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => AdminNotificationType.info,
      ),
      targetId: data['targetId'],
      targetType: data['targetType'],
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }
  final String id;
  final String title;
  final String message;
  final AdminNotificationType type;
  final String? targetId;
  final String? targetType;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'targetId': targetId,
        'targetType': targetType,
        'isRead': isRead,
        'createdAt': Timestamp.fromDate(createdAt),
        'metadata': metadata,
      };

  AdminNotification copyWith({
    String? id,
    String? title,
    String? message,
    AdminNotificationType? type,
    String? targetId,
    String? targetType,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) =>
      AdminNotification(
        id: id ?? this.id,
        title: title ?? this.title,
        message: message ?? this.message,
        type: type ?? this.type,
        targetId: targetId ?? this.targetId,
        targetType: targetType ?? this.targetType,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt ?? this.createdAt,
        metadata: metadata ?? this.metadata,
      );
}

/// Типы уведомлений для администратора
enum AdminNotificationType {
  info,
  warning,
  error,
  success,
  userReport,
  paymentIssue,
  systemAlert,
}

/// Настройки админ-панели
class AdminSettings {
  const AdminSettings({
    this.enableUserRegistration = true,
    this.enableSpecialistVerification = true,
    this.enableAutoModeration = false,
    this.enableEmailNotifications = true,
    this.enableSmsNotifications = false,
    this.maxFileSize = 10485760, // 10MB
    this.allowedFileTypes = const ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
    this.paymentSettings = const {},
    this.notificationSettings = const {},
    required this.lastUpdated,
  });

  factory AdminSettings.fromMap(Map<String, dynamic> map) => AdminSettings(
        enableUserRegistration: map['enableUserRegistration'] ?? true,
        enableSpecialistVerification:
            map['enableSpecialistVerification'] ?? true,
        enableAutoModeration: map['enableAutoModeration'] ?? false,
        enableEmailNotifications: map['enableEmailNotifications'] ?? true,
        enableSmsNotifications: map['enableSmsNotifications'] ?? false,
        maxFileSize: map['maxFileSize'] ?? 10485760,
        allowedFileTypes: List<String>.from(
          map['allowedFileTypes'] ??
              ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        ),
        paymentSettings:
            Map<String, dynamic>.from(map['paymentSettings'] ?? {}),
        notificationSettings:
            Map<String, dynamic>.from(map['notificationSettings'] ?? {}),
        lastUpdated:
            (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final bool enableUserRegistration;
  final bool enableSpecialistVerification;
  final bool enableAutoModeration;
  final bool enableEmailNotifications;
  final bool enableSmsNotifications;
  final int maxFileSize;
  final List<String> allowedFileTypes;
  final Map<String, dynamic> paymentSettings;
  final Map<String, dynamic> notificationSettings;
  final DateTime lastUpdated;

  Map<String, dynamic> toMap() => {
        'enableUserRegistration': enableUserRegistration,
        'enableSpecialistVerification': enableSpecialistVerification,
        'enableAutoModeration': enableAutoModeration,
        'enableEmailNotifications': enableEmailNotifications,
        'enableSmsNotifications': enableSmsNotifications,
        'maxFileSize': maxFileSize,
        'allowedFileTypes': allowedFileTypes,
        'paymentSettings': paymentSettings,
        'notificationSettings': notificationSettings,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };

  AdminSettings copyWith({
    bool? enableUserRegistration,
    bool? enableSpecialistVerification,
    bool? enableAutoModeration,
    bool? enableEmailNotifications,
    bool? enableSmsNotifications,
    int? maxFileSize,
    List<String>? allowedFileTypes,
    Map<String, dynamic>? paymentSettings,
    Map<String, dynamic>? notificationSettings,
    DateTime? lastUpdated,
  }) =>
      AdminSettings(
        enableUserRegistration:
            enableUserRegistration ?? this.enableUserRegistration,
        enableSpecialistVerification:
            enableSpecialistVerification ?? this.enableSpecialistVerification,
        enableAutoModeration: enableAutoModeration ?? this.enableAutoModeration,
        enableEmailNotifications:
            enableEmailNotifications ?? this.enableEmailNotifications,
        enableSmsNotifications:
            enableSmsNotifications ?? this.enableSmsNotifications,
        maxFileSize: maxFileSize ?? this.maxFileSize,
        allowedFileTypes: allowedFileTypes ?? this.allowedFileTypes,
        paymentSettings: paymentSettings ?? this.paymentSettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}
