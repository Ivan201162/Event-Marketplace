import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель пользователя с расширенными полями
class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.role = UserRole.customer,
    this.status = UserStatus.active,
    this.profile = const {},
    this.permissions = const [],
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.createdBy,
    this.lastModifiedBy,
    this.metadata = const {},
  });

  /// Создать из документа Firestore
  factory ManagedUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return ManagedUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == data['role'],
        orElse: () => UserRole.customer,
      ),
      status: UserStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => UserStatus.active,
      ),
      profile: Map<String, dynamic>.from(data['profile'] ?? {}),
      permissions: List<String>.from(data['permissions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      createdBy: data['createdBy'],
      lastModifiedBy: data['lastModifiedBy'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Создать из Map
  factory ManagedUser.fromMap(Map<String, dynamic> data) => ManagedUser(
        id: data['id'] ?? '',
        email: data['email'] ?? '',
        displayName: data['displayName'],
        photoUrl: data['photoUrl'],
        role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == data['role'],
          orElse: () => UserRole.customer,
        ),
        status: UserStatus.values.firstWhere(
          (e) => e.toString().split('.').last == data['status'],
          orElse: () => UserStatus.active,
        ),
        profile: Map<String, dynamic>.from(data['profile'] ?? {}),
        permissions: List<String>.from(data['permissions'] ?? []),
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        lastLoginAt: data['lastLoginAt'] != null
            ? (data['lastLoginAt'] as Timestamp).toDate()
            : null,
        createdBy: data['createdBy'],
        lastModifiedBy: data['lastModifiedBy'],
        metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      );
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final UserRole role;
  final UserStatus status;
  final Map<String, dynamic> profile;
  final List<String> permissions;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final String? createdBy;
  final String? lastModifiedBy;
  final Map<String, dynamic> metadata;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'role': role.toString().split('.').last,
        'status': status.toString().split('.').last,
        'profile': profile,
        'permissions': permissions,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'lastLoginAt':
            lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
        'createdBy': createdBy,
        'lastModifiedBy': lastModifiedBy,
        'metadata': metadata,
      };

  /// Создать копию с изменениями
  ManagedUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    UserRole? role,
    UserStatus? status,
    Map<String, dynamic>? profile,
    List<String>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    String? createdBy,
    String? lastModifiedBy,
    Map<String, dynamic>? metadata,
  }) =>
      ManagedUser(
        id: id ?? this.id,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        status: status ?? this.status,
        profile: profile ?? this.profile,
        permissions: permissions ?? this.permissions,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        createdBy: createdBy ?? this.createdBy,
        lastModifiedBy: lastModifiedBy ?? this.lastModifiedBy,
        metadata: metadata ?? this.metadata,
      );

  /// Проверить, активен ли пользователь
  bool get isActive => status == UserStatus.active;

  /// Проверить, заблокирован ли пользователь
  bool get isBlocked => status == UserStatus.blocked;

  /// Проверить, имеет ли пользователь разрешение
  bool hasPermission(String permission) =>
      permissions.contains(permission) || role.hasPermission(permission);

  /// Проверить, является ли пользователь администратором
  bool get isAdmin => role == UserRole.admin;

  /// Проверить, является ли пользователь модератором
  bool get isModerator => role == UserRole.moderator;

  /// Проверить, является ли пользователь специалистом
  bool get isSpecialist => role == UserRole.specialist;

  /// Проверить, является ли пользователь организатором
  bool get isOrganizer => role == UserRole.organizer;

  /// Получить время с последнего входа
  Duration? get timeSinceLastLogin {
    if (lastLoginAt == null) return null;
    return DateTime.now().difference(lastLoginAt!);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ManagedUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.role == role &&
        other.status == status &&
        other.profile == profile &&
        other.permissions == permissions &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastLoginAt == lastLoginAt &&
        other.createdBy == createdBy &&
        other.lastModifiedBy == lastModifiedBy &&
        other.metadata == metadata;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        photoUrl,
        role,
        status,
        profile,
        permissions,
        createdAt,
        updatedAt,
        lastLoginAt,
        createdBy,
        lastModifiedBy,
        metadata,
      );

  @override
  String toString() =>
      'ManagedUser(id: $id, email: $email, role: $role, status: $status)';
}

/// Модель роли пользователя
class UserRoleDefinition {
  const UserRoleDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.permissions,
    this.isSystemRole = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  /// Создать из документа Firestore
  factory UserRoleDefinition.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserRoleDefinition(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      permissions: List<String>.from(data['permissions'] ?? []),
      isSystemRole: data['isSystemRole'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
    );
  }

  /// Создать из Map
  factory UserRoleDefinition.fromMap(Map<String, dynamic> data) =>
      UserRoleDefinition(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        permissions: List<String>.from(data['permissions'] ?? []),
        isSystemRole: data['isSystemRole'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: (data['updatedAt'] as Timestamp).toDate(),
        createdBy: data['createdBy'],
      );
  final String id;
  final String name;
  final String description;
  final List<String> permissions;
  final bool isSystemRole;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'permissions': permissions,
        'isSystemRole': isSystemRole,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
      };

  /// Создать копию с изменениями
  UserRoleDefinition copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? permissions,
    bool? isSystemRole,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) =>
      UserRoleDefinition(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        permissions: permissions ?? this.permissions,
        isSystemRole: isSystemRole ?? this.isSystemRole,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
      );

  /// Проверить, имеет ли роль разрешение
  bool hasPermission(String permission) => permissions.contains(permission);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRoleDefinition &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.permissions == permissions &&
        other.isSystemRole == isSystemRole &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.createdBy == createdBy;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        permissions,
        isSystemRole,
        createdAt,
        updatedAt,
        createdBy,
      );

  @override
  String toString() =>
      'UserRoleDefinition(id: $id, name: $name, permissions: ${permissions.length})';
}

/// Модель разрешения
class Permission {
  const Permission({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.type,
    this.isSystemPermission = false,
    required this.createdAt,
  });

  /// Создать из документа Firestore
  factory Permission.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return Permission(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      type: PermissionType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => PermissionType.read,
      ),
      isSystemPermission: data['isSystemPermission'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Создать из Map
  factory Permission.fromMap(Map<String, dynamic> data) => Permission(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        category: data['category'] ?? '',
        type: PermissionType.values.firstWhere(
          (e) => e.toString().split('.').last == data['type'],
          orElse: () => PermissionType.read,
        ),
        isSystemPermission: data['isSystemPermission'] ?? false,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
  final String id;
  final String name;
  final String description;
  final String category;
  final PermissionType type;
  final bool isSystemPermission;
  final DateTime createdAt;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'category': category,
        'type': type.toString().split('.').last,
        'isSystemPermission': isSystemPermission,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Создать копию с изменениями
  Permission copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    PermissionType? type,
    bool? isSystemPermission,
    DateTime? createdAt,
  }) =>
      Permission(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        category: category ?? this.category,
        type: type ?? this.type,
        isSystemPermission: isSystemPermission ?? this.isSystemPermission,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Permission &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.category == category &&
        other.type == type &&
        other.isSystemPermission == isSystemPermission &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        category,
        type,
        isSystemPermission,
        createdAt,
      );

  @override
  String toString() => 'Permission(id: $id, name: $name, type: $type)';
}

/// Модель действия пользователя
class UserAction {
  const UserAction({
    required this.id,
    required this.userId,
    required this.action,
    this.targetId,
    this.targetType,
    this.details = const {},
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.sessionId,
  });

  /// Создать из документа Firestore
  factory UserAction.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return UserAction(
      id: doc.id,
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      targetId: data['targetId'],
      targetType: data['targetType'],
      details: Map<String, dynamic>.from(data['details'] ?? {}),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      sessionId: data['sessionId'],
    );
  }

  /// Создать из Map
  factory UserAction.fromMap(Map<String, dynamic> data) => UserAction(
        id: data['id'] ?? '',
        userId: data['userId'] ?? '',
        action: data['action'] ?? '',
        targetId: data['targetId'],
        targetType: data['targetType'],
        details: Map<String, dynamic>.from(data['details'] ?? {}),
        ipAddress: data['ipAddress'],
        userAgent: data['userAgent'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        sessionId: data['sessionId'],
      );
  final String id;
  final String userId;
  final String action;
  final String? targetId;
  final String? targetType;
  final Map<String, dynamic> details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final String? sessionId;

  /// Преобразовать в Map для Firestore
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'action': action,
        'targetId': targetId,
        'targetType': targetType,
        'details': details,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'timestamp': Timestamp.fromDate(timestamp),
        'sessionId': sessionId,
      };

  /// Создать копию с изменениями
  UserAction copyWith({
    String? id,
    String? userId,
    String? action,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    DateTime? timestamp,
    String? sessionId,
  }) =>
      UserAction(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        action: action ?? this.action,
        targetId: targetId ?? this.targetId,
        targetType: targetType ?? this.targetType,
        details: details ?? this.details,
        ipAddress: ipAddress ?? this.ipAddress,
        userAgent: userAgent ?? this.userAgent,
        timestamp: timestamp ?? this.timestamp,
        sessionId: sessionId ?? this.sessionId,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAction &&
        other.id == id &&
        other.userId == userId &&
        other.action == action &&
        other.targetId == targetId &&
        other.targetType == targetType &&
        other.details == details &&
        other.ipAddress == ipAddress &&
        other.userAgent == userAgent &&
        other.timestamp == timestamp &&
        other.sessionId == sessionId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        userId,
        action,
        targetId,
        targetType,
        details,
        ipAddress,
        userAgent,
        timestamp,
        sessionId,
      );

  @override
  String toString() => 'UserAction(id: $id, userId: $userId, action: $action)';
}

// UserRole enum moved to user.dart to avoid conflicts

  String get description {
    switch (this) {
      case UserRole.admin:
        return 'Полный доступ ко всем функциям системы';
      case UserRole.moderator:
        return 'Модерация контента и управление пользователями';
      case UserRole.specialist:
        return 'Предоставление услуг и управление профилем';
      case UserRole.organizer:
        return 'Организация событий и предложение специалистов';
      case UserRole.customer:
        return 'Заказ услуг и участие в событиях';
      case UserRole.guest:
        return 'Просмотр публичного контента';
    }
  }

  String get icon {
    switch (this) {
      case UserRole.admin:
        return '👑';
      case UserRole.moderator:
        return '🛡️';
      case UserRole.specialist:
        return '🎨';
      case UserRole.organizer:
        return '🎉';
      case UserRole.customer:
        return '👤';
      case UserRole.guest:
        return '👥';
    }
  }

  int get priority {
    switch (this) {
      case UserRole.admin:
        return 100;
      case UserRole.moderator:
        return 80;
      case UserRole.specialist:
        return 60;
      case UserRole.organizer:
        return 40;
      case UserRole.customer:
        return 20;
      case UserRole.guest:
        return 0;
    }
  }

  List<String> get defaultPermissions {
    switch (this) {
      case UserRole.admin:
        return [
          'users.manage',
          'roles.manage',
          'permissions.manage',
          'content.moderate',
          'analytics.view',
          'settings.manage',
          'system.manage',
        ];
      case UserRole.moderator:
        return [
          'users.moderate',
          'content.moderate',
          'reports.view',
          'analytics.view',
        ];
      case UserRole.specialist:
        return [
          'profile.manage',
          'services.manage',
          'bookings.manage',
          'content.upload',
          'analytics.view',
        ];
      case UserRole.organizer:
        return [
          'profile.manage',
          'events.manage',
          'proposals.create',
          'analytics.view',
        ];
      case UserRole.customer:
        return [
          'profile.manage',
          'bookings.create',
          'reviews.create',
          'content.view',
        ];
      case UserRole.guest:
        return [
          'content.view',
        ];
    }
  }

  bool hasPermission(String permission) =>
      defaultPermissions.contains(permission);

/// Статусы пользователей
enum UserStatus {
  active,
  inactive,
  blocked,
  pending,
  suspended,
}

/// Расширение для статусов пользователей
extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.active:
        return 'Активен';
      case UserStatus.inactive:
        return 'Неактивен';
      case UserStatus.blocked:
        return 'Заблокирован';
      case UserStatus.pending:
        return 'Ожидает подтверждения';
      case UserStatus.suspended:
        return 'Приостановлен';
    }
  }

  String get color {
    switch (this) {
      case UserStatus.active:
        return 'green';
      case UserStatus.inactive:
        return 'grey';
      case UserStatus.blocked:
        return 'red';
      case UserStatus.pending:
        return 'orange';
      case UserStatus.suspended:
        return 'yellow';
    }
  }

  String get icon {
    switch (this) {
      case UserStatus.active:
        return '✅';
      case UserStatus.inactive:
        return '⏸️';
      case UserStatus.blocked:
        return '🚫';
      case UserStatus.pending:
        return '⏳';
      case UserStatus.suspended:
        return '⚠️';
    }
  }
}

/// Типы разрешений
enum PermissionType {
  read,
  write,
  delete,
  manage,
  moderate,
}

/// Расширение для типов разрешений
extension PermissionTypeExtension on PermissionType {
  String get displayName {
    switch (this) {
      case PermissionType.read:
        return 'Чтение';
      case PermissionType.write:
        return 'Запись';
      case PermissionType.delete:
        return 'Удаление';
      case PermissionType.manage:
        return 'Управление';
      case PermissionType.moderate:
        return 'Модерация';
    }
  }

  String get description {
    switch (this) {
      case PermissionType.read:
        return 'Просмотр данных';
      case PermissionType.write:
        return 'Создание и изменение данных';
      case PermissionType.delete:
        return 'Удаление данных';
      case PermissionType.manage:
        return 'Полное управление';
      case PermissionType.moderate:
        return 'Модерация контента';
    }
  }
}
