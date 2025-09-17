import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/security.dart';

/// Сервис для улучшения безопасности и прав доступа
class SecurityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Проверить права доступа пользователя
  Future<bool> hasPermission({
    required String userId,
    required String resource,
    required String action,
    String? resourceId,
  }) async {
    if (!FeatureFlags.advancedSecurityEnabled) {
      return true; // Если расширенная безопасность отключена, разрешаем доступ
    }

    try {
      // Получаем роль пользователя
      final userRole = await _getUserRole(userId);
      if (userRole == null) {
        return false;
      }

      // Проверяем права доступа
      return _checkPermission(userRole, resource, action, resourceId);
    } catch (e) {
      return false;
    }
  }

  /// Создать аудит-запись
  Future<void> createAuditLog({
    required String userId,
    required String action,
    required String resource,
    String? resourceId,
    Map<String, dynamic>? metadata,
    String? ipAddress,
    String? userAgent,
  }) async {
    if (!FeatureFlags.auditLoggingEnabled) {
      return;
    }

    try {
      final auditLog = AuditLog(
        id: '',
        userId: userId,
        action: action,
        resource: resource,
        resourceId: resourceId,
        metadata: metadata ?? {},
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('audit_logs').add(auditLog.toMap());
    } catch (e) {
      // Игнорируем ошибки аудита
    }
  }

  /// Создать сессию безопасности
  Future<SecuritySession> createSecuritySession({
    required String userId,
    required String deviceId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final session = SecuritySession(
        id: '',
        userId: userId,
        deviceId: deviceId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        status: SecuritySessionStatus.active,
        createdAt: DateTime.now(),
        lastActivityAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        metadata: metadata ?? {},
      );

      final docRef =
          await _firestore.collection('security_sessions').add(session.toMap());

      return session.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания сессии безопасности: $e');
    }
  }

  /// Проверить сессию безопасности
  Future<bool> validateSecuritySession({
    required String sessionId,
    required String userId,
    String? ipAddress,
  }) async {
    try {
      final doc =
          await _firestore.collection('security_sessions').doc(sessionId).get();
      if (!doc.exists) {
        return false;
      }

      final session = SecuritySession.fromDocument(doc);

      // Проверяем пользователя
      if (session.userId != userId) {
        return false;
      }

      // Проверяем статус
      if (session.status != SecuritySessionStatus.active) {
        return false;
      }

      // Проверяем срок действия
      if (session.expiresAt.isBefore(DateTime.now())) {
        await _invalidateSession(sessionId);
        return false;
      }

      // Обновляем время последней активности
      await _updateSessionActivity(sessionId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Создать предупреждение безопасности
  Future<void> createSecurityAlert({
    required String userId,
    required SecurityAlertType type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final alert = SecurityAlert(
        id: '',
        userId: userId,
        type: type,
        description: description,
        status: SecurityAlertStatus.active,
        severity: _getAlertSeverity(type),
        createdAt: DateTime.now(),
        resolvedAt: null,
        metadata: metadata ?? {},
      );

      await _firestore.collection('security_alerts').add(alert.toMap());
    } catch (e) {
      // Игнорируем ошибки создания предупреждений
    }
  }

  /// Заблокировать пользователя
  Future<void> blockUser({
    required String userId,
    required String reason,
    required DateTime expiresAt,
    String? blockedBy,
  }) async {
    try {
      final block = UserBlock(
        id: '',
        userId: userId,
        reason: reason,
        blockedBy: blockedBy,
        status: UserBlockStatus.active,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
        metadata: {},
      );

      await _firestore.collection('user_blocks').add(block.toMap());
    } catch (e) {
      throw Exception('Ошибка блокировки пользователя: $e');
    }
  }

  /// Проверить, заблокирован ли пользователь
  Future<bool> isUserBlocked(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_blocks')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: UserBlockStatus.active.name)
          .where('expiresAt', isGreaterThan: DateTime.now())
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Приватные методы

  Future<UserRole?> _getUserRole(String userId) async {
    try {
      final doc = await _firestore.collection('user_roles').doc(userId).get();
      if (doc.exists) {
        return UserRole.fromDocument(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  bool _checkPermission(
      UserRole role, String resource, String action, String? resourceId) {
    // TODO: Реализовать проверку прав доступа на основе роли
    return true;
  }

  SecurityAlertSeverity _getAlertSeverity(SecurityAlertType type) {
    switch (type) {
      case SecurityAlertType.suspiciousActivity:
        return SecurityAlertSeverity.high;
      case SecurityAlertType.multipleFailedLogins:
        return SecurityAlertSeverity.medium;
      case SecurityAlertType.suspiciousIp:
        return SecurityAlertSeverity.medium;
      case SecurityAlertType.userBlocked:
        return SecurityAlertSeverity.high;
      case SecurityAlertType.dataBreach:
        return SecurityAlertSeverity.critical;
    }
  }

  Future<void> _invalidateSession(String sessionId) async {
    try {
      await _firestore.collection('security_sessions').doc(sessionId).update({
        'status': SecuritySessionStatus.expired.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки
    }
  }

  Future<void> _updateSessionActivity(String sessionId) async {
    try {
      await _firestore.collection('security_sessions').doc(sessionId).update({
        'lastActivityAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Игнорируем ошибки
    }
  }
}
