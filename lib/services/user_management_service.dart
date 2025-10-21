import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';
import '../models/user_management.dart';

/// Сервис управления пользователями и ролями
class UserManagementService {
  factory UserManagementService() => _instance;
  UserManagementService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static final UserManagementService _instance = UserManagementService._internal();

  final Map<String, ManagedUser> _usersCache = {};
  final Map<String, UserRoleDefinition> _rolesCache = {};
  final Map<String, Permission> _permissionsCache = {};

  /// Инициализация сервиса
  Future<void> initialize() async {
    try {
      await _loadUsersCache();
      await _loadRolesCache();
      await _loadPermissionsCache();

      if (kDebugMode) {
        debugPrint('User management service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка инициализации сервиса управления пользователями: $e');
      }
    }
  }

  /// Создать пользователя
  Future<String> createUser({
    required String email,
    String? displayName,
    String? photoUrl,
    UserRole role = UserRole.customer,
    Map<String, dynamic>? profile,
    List<String>? permissions,
    String? createdBy,
  }) async {
    try {
      final userId = _uuid.v4();
      final now = DateTime.now();

      final user = ManagedUser(
        id: userId,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        role: role,
        profile: profile ?? {},
        permissions: permissions ?? [],
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('managedUsers').doc(userId).set(user.toMap());
      _usersCache[userId] = user;

      // Логируем действие
      await _logUserAction(
        userId: createdBy ?? 'system',
        action: 'user_created',
        targetId: userId,
        targetType: 'user',
        details: {'email': email, 'role': role.toString()},
      );

      if (kDebugMode) {
        debugPrint('User created: $email');
      }

      return userId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания пользователя: $e');
      }
      rethrow;
    }
  }

  /// Обновить пользователя
  Future<void> updateUser(String userId, ManagedUser updatedUser) async {
    try {
      final oldUser = _usersCache[userId];
      if (oldUser == null) {
        throw Exception('Пользователь не найден');
      }

      await _firestore.collection('managedUsers').doc(userId).update({
        ...updatedUser.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _usersCache[userId] = updatedUser.copyWith(updatedAt: DateTime.now());

      // Логируем действие
      await _logUserAction(
        userId: updatedUser.lastModifiedBy ?? 'system',
        action: 'user_updated',
        targetId: userId,
        targetType: 'user',
        details: {'changes': _getUserChanges(oldUser, updatedUser)},
      );

      if (kDebugMode) {
        debugPrint('User updated: ${updatedUser.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления пользователя: $e');
      }
      rethrow;
    }
  }

  /// Изменить роль пользователя
  Future<void> changeUserRole(String userId, UserRole newRole, String changedBy) async {
    try {
      final user = _usersCache[userId];
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      final updatedUser = user.copyWith(
        role: newRole,
        lastModifiedBy: changedBy,
        updatedAt: DateTime.now(),
      );

      await updateUser(userId, updatedUser);

      if (kDebugMode) {
        debugPrint('User role changed: ${user.email} -> $newRole');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка изменения роли пользователя: $e');
      }
      rethrow;
    }
  }

  /// Изменить статус пользователя
  Future<void> changeUserStatus(String userId, UserStatus newStatus, String changedBy) async {
    try {
      final user = _usersCache[userId];
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      final updatedUser = user.copyWith(
        status: newStatus,
        lastModifiedBy: changedBy,
        updatedAt: DateTime.now(),
      );

      await updateUser(userId, updatedUser);

      if (kDebugMode) {
        debugPrint('User status changed: ${user.email} -> $newStatus');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка изменения статуса пользователя: $e');
      }
      rethrow;
    }
  }

  /// Заблокировать пользователя
  Future<void> blockUser(String userId, String reason, String blockedBy) async {
    try {
      await changeUserStatus(userId, UserStatus.blocked, blockedBy);

      // Добавляем причину блокировки в метаданные
      final user = _usersCache[userId];
      if (user != null) {
        final updatedMetadata = Map<String, dynamic>.from(user.metadata);
        updatedMetadata['blockReason'] = reason;
        updatedMetadata['blockedBy'] = blockedBy;
        updatedMetadata['blockedAt'] = DateTime.now().toIso8601String();

        final updatedUser = user.copyWith(
          metadata: updatedMetadata,
          lastModifiedBy: blockedBy,
          updatedAt: DateTime.now(),
        );

        await updateUser(userId, updatedUser);
      }

      if (kDebugMode) {
        debugPrint('User blocked: $userId, reason: $reason');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка блокировки пользователя: $e');
      }
      rethrow;
    }
  }

  /// Разблокировать пользователя
  Future<void> unblockUser(String userId, String unblockedBy) async {
    try {
      await changeUserStatus(userId, UserStatus.active, unblockedBy);

      // Удаляем информацию о блокировке из метаданных
      final user = _usersCache[userId];
      if (user != null) {
        final updatedMetadata = Map<String, dynamic>.from(user.metadata);
        updatedMetadata.remove('blockReason');
        updatedMetadata.remove('blockedBy');
        updatedMetadata.remove('blockedAt');
        updatedMetadata['unblockedBy'] = unblockedBy;
        updatedMetadata['unblockedAt'] = DateTime.now().toIso8601String();

        final updatedUser = user.copyWith(
          metadata: updatedMetadata,
          lastModifiedBy: unblockedBy,
          updatedAt: DateTime.now(),
        );

        await updateUser(userId, updatedUser);
      }

      if (kDebugMode) {
        debugPrint('User unblocked: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка разблокировки пользователя: $e');
      }
      rethrow;
    }
  }

  /// Добавить разрешение пользователю
  Future<void> addUserPermission(String userId, String permission, String addedBy) async {
    try {
      final user = _usersCache[userId];
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      if (user.permissions.contains(permission)) {
        return; // Разрешение уже есть
      }

      final updatedPermissions = [...user.permissions, permission];
      final updatedUser = user.copyWith(
        permissions: updatedPermissions,
        lastModifiedBy: addedBy,
        updatedAt: DateTime.now(),
      );

      await updateUser(userId, updatedUser);

      if (kDebugMode) {
        debugPrint('Permission added to user: $userId -> $permission');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка добавления разрешения пользователю: $e');
      }
      rethrow;
    }
  }

  /// Удалить разрешение у пользователя
  Future<void> removeUserPermission(String userId, String permission, String removedBy) async {
    try {
      final user = _usersCache[userId];
      if (user == null) {
        throw Exception('Пользователь не найден');
      }

      if (!user.permissions.contains(permission)) {
        return; // Разрешения нет
      }

      final updatedPermissions = user.permissions.where((p) => p != permission).toList();
      final updatedUser = user.copyWith(
        permissions: updatedPermissions,
        lastModifiedBy: removedBy,
        updatedAt: DateTime.now(),
      );

      await updateUser(userId, updatedUser);

      if (kDebugMode) {
        debugPrint('Permission removed from user: $userId -> $permission');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка удаления разрешения у пользователя: $e');
      }
      rethrow;
    }
  }

  /// Создать роль
  Future<String> createRole({
    required String name,
    required String description,
    required List<String> permissions,
    String? createdBy,
  }) async {
    try {
      final roleId = _uuid.v4();
      final now = DateTime.now();

      final role = UserRoleDefinition(
        id: roleId,
        name: name,
        description: description,
        permissions: permissions,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection('userRoles').doc(roleId).set(role.toMap());
      _rolesCache[roleId] = role;

      // Логируем действие
      await _logUserAction(
        userId: createdBy ?? 'system',
        action: 'role_created',
        targetId: roleId,
        targetType: 'role',
        details: {'name': name, 'permissions': permissions},
      );

      if (kDebugMode) {
        debugPrint('Role created: $name');
      }

      return roleId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания роли: $e');
      }
      rethrow;
    }
  }

  /// Обновить роль
  Future<void> updateRole(String roleId, UserRoleDefinition updatedRole) async {
    try {
      final oldRole = _rolesCache[roleId];
      if (oldRole == null) {
        throw Exception('Роль не найдена');
      }

      await _firestore.collection('userRoles').doc(roleId).update({
        ...updatedRole.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _rolesCache[roleId] = updatedRole.copyWith(updatedAt: DateTime.now());

      // Логируем действие
      await _logUserAction(
        userId: updatedRole.createdBy ?? 'system',
        action: 'role_updated',
        targetId: roleId,
        targetType: 'role',
        details: {'changes': _getRoleChanges(oldRole, updatedRole)},
      );

      if (kDebugMode) {
        debugPrint('Role updated: ${updatedRole.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка обновления роли: $e');
      }
      rethrow;
    }
  }

  /// Удалить роль
  Future<void> deleteRole(String roleId, String deletedBy) async {
    try {
      final role = _rolesCache[roleId];
      if (role == null) {
        throw Exception('Роль не найдена');
      }

      if (role.isSystemRole) {
        throw Exception('Системные роли нельзя удалять');
      }

      // Проверяем, используется ли роль
      final usersWithRole = _usersCache.values
          .where((user) => user.role.toString() == role.name)
          .toList();
      if (usersWithRole.isNotEmpty) {
        throw Exception('Роль используется ${usersWithRole.length} пользователями');
      }

      await _firestore.collection('userRoles').doc(roleId).delete();
      _rolesCache.remove(roleId);

      // Логируем действие
      await _logUserAction(
        userId: deletedBy,
        action: 'role_deleted',
        targetId: roleId,
        targetType: 'role',
        details: {'name': role.name},
      );

      if (kDebugMode) {
        debugPrint('Role deleted: ${role.name}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка удаления роли: $e');
      }
      rethrow;
    }
  }

  /// Создать разрешение
  Future<String> createPermission({
    required String name,
    required String description,
    required String category,
    required PermissionType type,
    String? createdBy,
  }) async {
    try {
      final permissionId = _uuid.v4();
      final now = DateTime.now();

      final permission = Permission(
        id: permissionId,
        name: name,
        description: description,
        category: category,
        type: type,
        createdAt: now,
      );

      await _firestore.collection('permissions').doc(permissionId).set(permission.toMap());
      _permissionsCache[permissionId] = permission;

      // Логируем действие
      await _logUserAction(
        userId: createdBy ?? 'system',
        action: 'permission_created',
        targetId: permissionId,
        targetType: 'permission',
        details: {'name': name, 'type': type.toString()},
      );

      if (kDebugMode) {
        debugPrint('Permission created: $name');
      }

      return permissionId;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка создания разрешения: $e');
      }
      rethrow;
    }
  }

  /// Получить пользователя по ID
  ManagedUser? getUser(String userId) => _usersCache[userId];

  /// Получить пользователей по роли
  List<ManagedUser> getUsersByRole(UserRole role) =>
      _usersCache.values.where((user) => user.role == role).toList();

  /// Получить пользователей по статусу
  List<ManagedUser> getUsersByStatus(UserStatus status) =>
      _usersCache.values.where((user) => user.status == status).toList();

  /// Получить всех пользователей
  List<ManagedUser> getAllUsers() => _usersCache.values.toList();

  /// Получить роль по ID
  UserRoleDefinition? getRole(String roleId) => _rolesCache[roleId];

  /// Получить все роли
  List<UserRoleDefinition> getAllRoles() => _rolesCache.values.toList();

  /// Получить разрешение по ID
  Permission? getPermission(String permissionId) => _permissionsCache[permissionId];

  /// Получить все разрешения
  List<Permission> getAllPermissions() => _permissionsCache.values.toList();

  /// Получить разрешения по категории
  List<Permission> getPermissionsByCategory(String category) =>
      _permissionsCache.values.where((p) => p.category == category).toList();

  /// Проверить разрешение пользователя
  bool hasUserPermission(String userId, String permission) {
    final user = _usersCache[userId];
    if (user == null) return false;
    return user.hasPermission(permission);
  }

  /// Получить действия пользователя
  Future<List<UserAction>> getUserActions(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection('userActions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(UserAction.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка получения действий пользователя: $e');
      }
      return [];
    }
  }

  /// Получить статистику пользователей
  Map<String, int> getUserStatistics() {
    final users = _usersCache.values.toList();

    final stats = <String, int>{
      'total': users.length,
      'active': users.where((u) => u.isActive).length,
      'blocked': users.where((u) => u.isBlocked).length,
      'pending': users.where((u) => u.status == UserStatus.pending).length,
    };

    // Статистика по ролям
    for (final role in UserRole.values) {
      stats['role_${role.toString().split('.').last}'] = users.where((u) => u.role == role).length;
    }

    return stats;
  }

  /// Логировать действие пользователя
  Future<void> _logUserAction({
    required String userId,
    required String action,
    String? targetId,
    String? targetType,
    Map<String, dynamic>? details,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
  }) async {
    try {
      final actionId = _uuid.v4();
      final userAction = UserAction(
        id: actionId,
        userId: userId,
        action: action,
        targetId: targetId,
        targetType: targetType,
        details: details ?? {},
        ipAddress: ipAddress,
        userAgent: userAgent,
        sessionId: sessionId,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('userActions').doc(actionId).set(userAction.toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка логирования действия пользователя: $e');
      }
    }
  }

  /// Получить изменения пользователя
  Map<String, dynamic> _getUserChanges(ManagedUser oldUser, ManagedUser newUser) {
    final changes = <String, dynamic>{};

    if (oldUser.email != newUser.email) {
      changes['email'] = {'old': oldUser.email, 'new': newUser.email};
    }
    if (oldUser.displayName != newUser.displayName) {
      changes['displayName'] = {'old': oldUser.displayName, 'new': newUser.displayName};
    }
    if (oldUser.role != newUser.role) {
      changes['role'] = {'old': oldUser.role.toString(), 'new': newUser.role.toString()};
    }
    if (oldUser.status != newUser.status) {
      changes['status'] = {'old': oldUser.status.toString(), 'new': newUser.status.toString()};
    }
    if (oldUser.permissions != newUser.permissions) {
      changes['permissions'] = {'old': oldUser.permissions, 'new': newUser.permissions};
    }

    return changes;
  }

  /// Получить изменения роли
  Map<String, dynamic> _getRoleChanges(UserRoleDefinition oldRole, UserRoleDefinition newRole) {
    final changes = <String, dynamic>{};

    if (oldRole.name != newRole.name) {
      changes['name'] = {'old': oldRole.name, 'new': newRole.name};
    }
    if (oldRole.description != newRole.description) {
      changes['description'] = {'old': oldRole.description, 'new': newRole.description};
    }
    if (oldRole.permissions != newRole.permissions) {
      changes['permissions'] = {'old': oldRole.permissions, 'new': newRole.permissions};
    }

    return changes;
  }

  /// Загрузить кэш пользователей
  Future<void> _loadUsersCache() async {
    try {
      final snapshot = await _firestore.collection('managedUsers').limit(1000).get();

      for (final doc in snapshot.docs) {
        final user = ManagedUser.fromDocument(doc);
        _usersCache[user.id] = user;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_usersCache.length} users');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша пользователей: $e');
      }
    }
  }

  /// Загрузить кэш ролей
  Future<void> _loadRolesCache() async {
    try {
      final snapshot = await _firestore.collection('userRoles').get();

      for (final doc in snapshot.docs) {
        final role = UserRoleDefinition.fromDocument(doc);
        _rolesCache[role.id] = role;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_rolesCache.length} roles');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша ролей: $e');
      }
    }
  }

  /// Загрузить кэш разрешений
  Future<void> _loadPermissionsCache() async {
    try {
      final snapshot = await _firestore.collection('permissions').get();

      for (final doc in snapshot.docs) {
        final permission = Permission.fromDocument(doc);
        _permissionsCache[permission.id] = permission;
      }

      if (kDebugMode) {
        debugPrint('Loaded ${_permissionsCache.length} permissions');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ошибка загрузки кэша разрешений: $e');
      }
    }
  }

  /// Закрыть сервис
  void dispose() {
    _usersCache.clear();
    _rolesCache.clear();
    _permissionsCache.clear();
  }
}
