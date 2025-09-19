import 'package:cloud_firestore/cloud_firestore.dart';

/// Роль администратора
enum AdminRole {
  superAdmin, // Супер-администратор
  admin, // Администратор
  moderator, // Модератор
  support, // Поддержка
}

/// Статус пользователя
enum UserStatus {
  active, // Активный
  inactive, // Неактивный
  suspended, // Заблокирован
  pending, // На рассмотрении
  rejected, // Отклонен
}

/// Модель администратора
class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    required this.role,
    this.permissions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.isActive = true,
    this.notes,
  });

  /// Создать из документа Firestore
  factory AdminUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
      role: AdminRole.values.firstWhere(
        (e) => e.name == data['role'],
        orElse: () => AdminRole.moderator,
      ),
      permissions: List<String>.from(data['permissions'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp?)?.toDate()
          : null,
      isActive: data['isActive'] as bool? ?? true,
      notes: data['notes'] as String?,
    );
  }
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final AdminRole role;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? notes;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'profileImageUrl': profileImageUrl,
        'role': role.name,
        'permissions': permissions,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'isActive': isActive,
        'notes': notes,
      };

  /// Создать копию с обновлёнными полями
  AdminUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    AdminRole? role,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? notes,
  }) =>
      AdminUser(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        role: role ?? this.role,
        permissions: permissions ?? this.permissions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        isActive: isActive ?? this.isActive,
        notes: notes ?? this.notes,
      );

  /// Получить полное имя
  String get fullName => '$firstName $lastName';

  /// Получить описание роли
  String get roleDescription {
    switch (role) {
      case AdminRole.superAdmin:
        return 'Супер-администратор';
      case AdminRole.admin:
        return 'Администратор';
      case AdminRole.moderator:
        return 'Модератор';
      case AdminRole.support:
        return 'Поддержка';
    }
  }

  /// Проверить, есть ли разрешение
  bool hasPermission(String permission) => permissions.contains(permission);

  /// Проверить, может ли управлять пользователями
  bool get canManageUsers =>
      role == AdminRole.superAdmin || role == AdminRole.admin;

  /// Проверить, может ли модерировать контент
  bool get canModerateContent =>
      role == AdminRole.superAdmin ||
      role == AdminRole.admin ||
      role == AdminRole.moderator;

  /// Проверить, может ли управлять системой
  bool get canManageSystem => role == AdminRole.superAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'AdminUser(id: $id, email: $email, fullName: $fullName, role: $role)';
}

/// Модель пользователя для админ-панели
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.rating,
    this.isVerified = false,
    this.verificationNotes,
    this.reportedIssues = const [],
    this.banReason,
    this.bannedUntil,
    this.notes,
  });

  /// Создать из документа Firestore
  factory ManagedUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ManagedUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String?,
      status: UserStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => UserStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp?)?.toDate()
          : null,
      totalBookings: data['totalBookings'] as int? ?? 0,
      completedBookings: data['completedBookings'] as int? ?? 0,
      rating: (data['rating'] as num?)?.toDouble(),
      isVerified: data['isVerified'] as bool? ?? false,
      verificationNotes: data['verificationNotes'] as String?,
      reportedIssues: List<String>.from(data['reportedIssues'] as List? ?? []),
      banReason: data['banReason'] as String?,
      bannedUntil: data['bannedUntil'] != null
          ? (data['bannedUntil'] as Timestamp?)?.toDate()
          : null,
      notes: data['notes'] as String?,
    );
  }
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final UserStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final int totalBookings;
  final int completedBookings;
  final double? rating;
  final bool isVerified;
  final String? verificationNotes;
  final List<String> reportedIssues;
  final String? banReason;
  final DateTime? bannedUntil;
  final String? notes;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'profileImageUrl': profileImageUrl,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'rating': rating,
        'isVerified': isVerified,
        'verificationNotes': verificationNotes,
        'reportedIssues': reportedIssues,
        'banReason': banReason,
        'bannedUntil':
            bannedUntil != null ? Timestamp.fromDate(bannedUntil!) : null,
        'notes': notes,
      };

  /// Создать копию с обновлёнными полями
  ManagedUser copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    UserStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    int? totalBookings,
    int? completedBookings,
    double? rating,
    bool? isVerified,
    String? verificationNotes,
    List<String>? reportedIssues,
    String? banReason,
    DateTime? bannedUntil,
    String? notes,
  }) =>
      ManagedUser(
        id: id ?? this.id,
        email: email ?? this.email,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        totalBookings: totalBookings ?? this.totalBookings,
        completedBookings: completedBookings ?? this.completedBookings,
        rating: rating ?? this.rating,
        isVerified: isVerified ?? this.isVerified,
        verificationNotes: verificationNotes ?? this.verificationNotes,
        reportedIssues: reportedIssues ?? this.reportedIssues,
        banReason: banReason ?? this.banReason,
        bannedUntil: bannedUntil ?? this.bannedUntil,
        notes: notes ?? this.notes,
      );

  /// Получить полное имя
  String get fullName => '$firstName $lastName';

  /// Получить описание статуса
  String get statusDescription {
    switch (status) {
      case UserStatus.active:
        return 'Активный';
      case UserStatus.inactive:
        return 'Неактивный';
      case UserStatus.suspended:
        return 'Заблокирован';
      case UserStatus.pending:
        return 'На рассмотрении';
      case UserStatus.rejected:
        return 'Отклонен';
    }
  }

  /// Получить цвет статуса
  int get statusColor {
    switch (status) {
      case UserStatus.active:
        return 0xFF4CAF50; // Зеленый
      case UserStatus.inactive:
        return 0xFF9E9E9E; // Серый
      case UserStatus.suspended:
        return 0xFFF44336; // Красный
      case UserStatus.pending:
        return 0xFFFF9800; // Оранжевый
      case UserStatus.rejected:
        return 0xFFE91E63; // Розовый
    }
  }

  /// Проверить, заблокирован ли пользователь
  bool get isBanned =>
      status == UserStatus.suspended &&
      (bannedUntil == null || bannedUntil!.isAfter(DateTime.now()));

  /// Получить процент завершенных бронирований
  double get completionRate {
    if (totalBookings == 0) return 0;
    return (completedBookings / totalBookings) * 100;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManagedUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ManagedUser(id: $id, email: $email, fullName: $fullName, status: $status)';
}

/// Модель жалобы
class UserReport {
  const UserReport({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.evidenceUrls = const [],
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolution,
    this.isResolved = false,
  });

  /// Создать из документа Firestore
  factory UserReport.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserReport(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      reportedUserId: data['reportedUserId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      description: data['description'] as String? ?? '',
      evidenceUrls: List<String>.from(data['evidenceUrls'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp?)?.toDate()
          : null,
      resolvedBy: data['resolvedBy'] as String?,
      resolution: data['resolution'] as String?,
      isResolved: data['isResolved'] as bool? ?? false,
    );
  }
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String reason;
  final String description;
  final List<String> evidenceUrls;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolution;
  final bool isResolved;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'description': description,
        'evidenceUrls': evidenceUrls,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
        'resolvedBy': resolvedBy,
        'resolution': resolution,
        'isResolved': isResolved,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserReport && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserReport(id: $id, reporterId: $reporterId, reportedUserId: $reportedUserId, reason: $reason)';
}
