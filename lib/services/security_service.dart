import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart' hide Digest;
import 'package:uuid/uuid.dart';

import '../models/security_audit.dart';

/// Сервис безопасности и шифрования
class SecurityService {
  factory SecurityService() => _instance;
  SecurityService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final Random _random = Random.secure();

  static final SecurityService _instance = SecurityService._internal();

  final Map<String, String> _encryptionKeys = {};
  final Map<String, SecurityPolicy> _policies = {};
  final List<SecurityAudit> _recentAudits = [];

  /// Инициализация сервиса безопасности
  Future<void> initialize() async {
    try {
      // Загружаем политики безопасности
      await _loadSecurityPolicies();

      // Загружаем ключи шифрования
      await _loadEncryptionKeys();

      if (kDebugMode) {
        print('Security service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка инициализации сервиса безопасности: $e');
      }
    }
  }

  /// Записать событие аудита безопасности
  Future<void> logSecurityEvent({
    required String eventType,
    required String description,
    required SecurityLevel level,
    String? userId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final audit = SecurityAudit(
        id: _uuid.v4(),
        eventType: eventType,
        description: description,
        level: level,
        userId: userId,
        sessionId: sessionId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        metadata: metadata ?? {},
        timestamp: DateTime.now(),
      );

      // Сохраняем в Firestore
      await _firestore.collection('securityAudits').add(audit.toMap());

      // Добавляем в локальный кэш
      _recentAudits.add(audit);
      if (_recentAudits.length > 100) {
        _recentAudits.removeAt(0);
      }

      // Проверяем политики безопасности
      await _checkSecurityPolicies(audit);

      if (kDebugMode) {
        print('Security event logged: $eventType - $description');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка записи события аудита: $e');
      }
    }
  }

  /// Проверить политики безопасности
  Future<void> _checkSecurityPolicies(SecurityAudit audit) async {
    try {
      for (final policy in _policies.values) {
        if (!policy.isEnabled) continue;

        // Проверяем, применима ли политика к событию
        if (_isPolicyApplicable(policy, audit)) {
          await _enforcePolicy(policy, audit);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка проверки политик безопасности: $e');
      }
    }
  }

  /// Проверить, применима ли политика к событию
  bool _isPolicyApplicable(SecurityPolicy policy, SecurityAudit audit) {
    // Проверяем тип события
    if (policy.rules.containsKey('eventTypes')) {
      final allowedTypes = List<String>.from(policy.rules['eventTypes']);
      if (!allowedTypes.contains(audit.eventType)) return false;
    }

    // Проверяем уровень события
    if (policy.rules.containsKey('minLevel')) {
      final minLevel = SecurityLevel.values.firstWhere(
        (e) => e.toString().split('.').last == policy.rules['minLevel'],
        orElse: () => SecurityLevel.info,
      );
      if (audit.level.priority < minLevel.priority) return false;
    }

    // Проверяем роли пользователя
    if (policy.affectedRoles.isNotEmpty && audit.userId != null) {
      // TODO(developer): Получить роли пользователя и проверить пересечение
    }

    return true;
  }

  /// Применить политику безопасности
  Future<void> _enforcePolicy(
    SecurityPolicy policy,
    SecurityAudit audit,
  ) async {
    try {
      final action = policy.rules['action'] as String?;

      switch (action) {
        case 'block':
          await _blockUser(audit.userId, policy.name);
          break;
        case 'alert':
          await _sendSecurityAlert(policy, audit);
          break;
        case 'log':
          // Уже логируется
          break;
        case 'rate_limit':
          await _applyRateLimit(audit.userId, policy.rules);
          break;
        default:
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка применения политики: $e');
      }
    }
  }

  /// Заблокировать пользователя
  Future<void> _blockUser(String? userId, String reason) async {
    if (userId == null) return;

    try {
      await _firestore.collection('blockedUsers').doc(userId).set({
        'userId': userId,
        'reason': reason,
        'blockedAt': Timestamp.fromDate(DateTime.now()),
        'isActive': true,
      });

      await logSecurityEvent(
        eventType: 'user_blocked',
        description: 'Пользователь заблокирован: $reason',
        level: SecurityLevel.high,
        userId: userId,
        metadata: {'reason': reason},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка блокировки пользователя: $e');
      }
    }
  }

  /// Отправить алерт безопасности
  Future<void> _sendSecurityAlert(
    SecurityPolicy policy,
    SecurityAudit audit,
  ) async {
    try {
      // TODO(developer): Интеграция с системой уведомлений
      if (kDebugMode) {
        print('Security alert: ${policy.name} - ${audit.description}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отправки алерта безопасности: $e');
      }
    }
  }

  /// Применить ограничение скорости
  Future<void> _applyRateLimit(
    String? userId,
    Map<String, dynamic> rules,
  ) async {
    if (userId == null) return;

    try {
      final limit = rules['limit'] as int? ?? 10;
      final window = Duration(minutes: rules['windowMinutes'] as int? ?? 5);

      // TODO(developer): Реализовать rate limiting
      if (kDebugMode) {
        print(
          'Rate limit applied to user $userId: $limit requests per ${window.inMinutes} minutes',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка применения rate limit: $e');
      }
    }
  }

  /// Зашифровать данные
  Future<String> encrypt(String data, {String? keyId}) async {
    try {
      final key = await _getEncryptionKey(keyId);
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);

      // Используем AES-256-CBC
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      final keyParam = KeyParameter(keyBytes);
      final iv = _generateIV();
      final ivParam = ParametersWithIV(keyParam, iv);

      cipher.init(true, PaddedBlockCipherParameters(ivParam, null));
      final encrypted = cipher.process(Uint8List.fromList(dataBytes));

      // Объединяем IV и зашифрованные данные
      final result = Uint8List((iv.length + encrypted.length).toInt());
      result.setRange(0, iv.length, iv);
      result.setRange(iv.length, result.length, encrypted);

      return base64.encode(result);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка шифрования: $e');
      }
      rethrow;
    }
  }

  /// Расшифровать данные
  Future<String> decrypt(String encryptedData, {String? keyId}) async {
    try {
      final key = await _getEncryptionKey(keyId);
      final keyBytes = utf8.encode(key);
      final dataBytes = base64.decode(encryptedData);

      // Извлекаем IV
      final iv = dataBytes.sublist(0, 16);
      final encrypted = dataBytes.sublist(16);

      // Используем AES-256-CBC
      final cipher = PaddedBlockCipherImpl(
        PKCS7Padding(),
        CBCBlockCipher(AESEngine()),
      );

      final keyParam = KeyParameter(keyBytes);
      final ivParam = ParametersWithIV(keyParam, iv);

      cipher.init(false, PaddedBlockCipherParameters(ivParam, null));
      final decrypted = cipher.process(Uint8List.fromList(encrypted));

      return utf8.decode(decrypted);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка расшифровки: $e');
      }
      rethrow;
    }
  }

  /// Сгенерировать хеш
  String generateHash(String data, {String algorithm = 'sha256'}) {
    try {
      final bytes = utf8.encode(data);
      Digest digest;

      switch (algorithm.toLowerCase()) {
        case 'md5':
          digest = md5.convert(bytes);
          break;
        case 'sha1':
          digest = sha1.convert(bytes);
          break;
        case 'sha256':
          digest = sha256.convert(bytes);
          break;
        case 'sha512':
          digest = sha512.convert(bytes);
          break;
        default:
          digest = sha256.convert(bytes);
      }

      return digest.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка генерации хеша: $e');
      }
      rethrow;
    }
  }

  /// Сгенерировать случайную строку
  String generateRandomString(int length, {bool includeSpecialChars = false}) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    const specialChars = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

    final charSet = includeSpecialChars ? chars + specialChars : chars;
    final random = Random.secure();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => charSet.codeUnitAt(random.nextInt(charSet.length)),
      ),
    );
  }

  /// Сгенерировать IV
  Uint8List _generateIV() {
    final iv = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      iv[i] = _random.nextInt(256);
    }
    return iv;
  }

  /// Получить ключ шифрования
  Future<String> _getEncryptionKey(String? keyId) async {
    if (keyId != null && _encryptionKeys.containsKey(keyId)) {
      return _encryptionKeys[keyId]!;
    }

    // Используем ключ по умолчанию
    const defaultKey = 'default_encryption_key_32_chars!';
    return defaultKey;
  }

  /// Загрузить политики безопасности
  Future<void> _loadSecurityPolicies() async {
    try {
      final snapshot = await _firestore.collection('securityPolicies').get();

      for (final doc in snapshot.docs) {
        final policy = SecurityPolicy.fromDocument(doc);
        _policies[policy.id] = policy;
      }

      if (kDebugMode) {
        print('Loaded ${_policies.length} security policies');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки политик безопасности: $e');
      }
    }
  }

  /// Загрузить ключи шифрования
  Future<void> _loadEncryptionKeys() async {
    try {
      final snapshot = await _firestore.collection('encryptionKeys').get();

      for (final doc in snapshot.docs) {
        final key = EncryptionKey.fromDocument(doc);
        if (key.isValid) {
          // TODO(developer): Загрузить реальный ключ из безопасного хранилища
          _encryptionKeys[key.id] = 'key_${key.id}';
        }
      }

      if (kDebugMode) {
        print('Loaded ${_encryptionKeys.length} encryption keys');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка загрузки ключей шифрования: $e');
      }
    }
  }

  /// Получить события аудита
  Future<List<SecurityAudit>> getSecurityAudits({
    SecurityLevel? level,
    String? eventType,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query<Map<String, dynamic>> query =
          _firestore.collection('securityAudits');

      if (level != null) {
        query =
            query.where('level', isEqualTo: level.toString().split('.').last);
      }
      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }
      if (startDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }
      if (endDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      final snapshot =
          await query.orderBy('timestamp', descending: true).limit(limit).get();

      return snapshot.docs.map(SecurityAudit.fromDocument).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения событий аудита: $e');
      }
      return [];
    }
  }

  /// Получить статистику безопасности
  Future<SecurityStatistics> getSecurityStatistics() async {
    try {
      final audits = await getSecurityAudits(limit: 1000);
      return SecurityStatistics.fromEvents(audits);
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения статистики безопасности: $e');
      }
      return SecurityStatistics.fromEvents([]);
    }
  }

  /// Создать политику безопасности
  Future<String> createSecurityPolicy({
    required String name,
    required String description,
    required SecurityPolicyType type,
    required Map<String, dynamic> rules,
    SecurityLevel severity = SecurityLevel.medium,
    List<String> affectedRoles = const [],
    String? createdBy,
  }) async {
    try {
      final policyId = _uuid.v4();
      final now = DateTime.now();

      final policy = SecurityPolicy(
        id: policyId,
        name: name,
        description: description,
        type: type,
        rules: rules,
        severity: severity,
        affectedRoles: affectedRoles,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection('securityPolicies')
          .doc(policyId)
          .set(policy.toMap());
      _policies[policyId] = policy;

      await logSecurityEvent(
        eventType: 'policy_created',
        description: 'Создана политика безопасности: $name',
        level: SecurityLevel.info,
        userId: createdBy,
        metadata: {'policyId': policyId, 'policyType': type.toString()},
      );

      return policyId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания политики безопасности: $e');
      }
      rethrow;
    }
  }

  /// Обновить политику безопасности
  Future<void> updateSecurityPolicy(
    String policyId,
    SecurityPolicy updatedPolicy,
  ) async {
    try {
      await _firestore.collection('securityPolicies').doc(policyId).update({
        ...updatedPolicy.toMap(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      _policies[policyId] = updatedPolicy;

      await logSecurityEvent(
        eventType: 'policy_updated',
        description: 'Обновлена политика безопасности: ${updatedPolicy.name}',
        level: SecurityLevel.info,
        metadata: {'policyId': policyId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка обновления политики безопасности: $e');
      }
      rethrow;
    }
  }

  /// Удалить политику безопасности
  Future<void> deleteSecurityPolicy(String policyId) async {
    try {
      final policy = _policies[policyId];
      if (policy == null) return;

      await _firestore.collection('securityPolicies').doc(policyId).delete();
      _policies.remove(policyId);

      await logSecurityEvent(
        eventType: 'policy_deleted',
        description: 'Удалена политика безопасности: ${policy.name}',
        level: SecurityLevel.info,
        metadata: {'policyId': policyId},
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка удаления политики безопасности: $e');
      }
      rethrow;
    }
  }

  /// Создать ключ шифрования
  Future<String> createEncryptionKey({
    required String name,
    required String algorithm,
    required String keyType,
    String? description,
    DateTime? expiresAt,
  }) async {
    try {
      final keyId = _uuid.v4();
      final now = DateTime.now();

      final key = EncryptionKey(
        id: keyId,
        name: name,
        algorithm: algorithm,
        keyType: keyType,
        description: description,
        expiresAt: expiresAt,
        createdAt: now,
      );

      await _firestore.collection('encryptionKeys').doc(keyId).set(key.toMap());

      // Генерируем и сохраняем ключ
      final generatedKey = generateRandomString(32);
      _encryptionKeys[keyId] = generatedKey;

      await logSecurityEvent(
        eventType: 'encryption_key_created',
        description: 'Создан ключ шифрования: $name',
        level: SecurityLevel.info,
        metadata: {'keyId': keyId, 'algorithm': algorithm},
      );

      return keyId;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка создания ключа шифрования: $e');
      }
      rethrow;
    }
  }

  /// Проверить безопасность пароля
  bool validatePassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp('[A-Z]'))) return false;
    if (!password.contains(RegExp('[a-z]'))) return false;
    if (!password.contains(RegExp('[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  /// Генерировать безопасный пароль
  String generateSecurePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const specialChars = r'!@#$%^&*()_+-=[]{}|;:,.<>?';

    var chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecialChars) chars += specialChars;

    if (chars.isEmpty) {
      throw ArgumentError('At least one character type must be included');
    }

    var password = '';
    for (var i = 0; i < length; i++) {
      password += chars[_random.nextInt(chars.length)];
    }

    return password;
  }

  /// Проверить безопасность токена
  bool validateToken(String token) {
    if (token.length < 32) return false;
    if (!token.contains(RegExp('[A-Za-z0-9]'))) return false;
    return true;
  }

  /// Получить недавние события аудита
  List<SecurityAudit> getRecentAudits() => List.from(_recentAudits);

  /// Получить активные политики
  List<SecurityPolicy> getActivePolicies() =>
      _policies.values.where((policy) => policy.isEnabled).toList();

  /// Получить активные ключи шифрования
  List<String> getActiveEncryptionKeys() => _encryptionKeys.keys.toList();

  /// Очистить старые события аудита
  Future<void> cleanupOldAudits({int daysToKeep = 90}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

      final snapshot = await _firestore
          .collection('securityAudits')
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      await logSecurityEvent(
        eventType: 'audit_cleanup',
        description: 'Очищено ${snapshot.docs.length} старых событий аудита',
        level: SecurityLevel.info,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка очистки старых событий аудита: $e');
      }
    }
  }

  /// Получить логи аудита безопасности
  Future<List<SecurityAudit>> getSecurityAuditLogs({
    int limit = 50,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _firestore
          .collection('security_audits')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (fromDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
        );
      }

      if (toDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate),
        );
      }

      final snapshot = await query.get();
      return snapshot.docs.map(SecurityAudit.fromDocument).toList();
    } catch (e) {
      throw Exception('Ошибка получения логов аудита безопасности: $e');
    }
  }

  /// Получить устройства пользователя
  Future<List<Map<String, dynamic>>> getUserDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_devices')
          .where('userId', isEqualTo: userId)
          .orderBy('lastSeen', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      throw Exception('Ошибка получения устройств пользователя: $e');
    }
  }

  /// Проверить доступность биометрии
  Future<bool> isBiometricAvailable() async {
    try {
      // Заглушка для проверки биометрии
      // В реальном приложении здесь будет использоваться local_auth
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Получить доступные биометрические методы
  Future<List<String>> getAvailableBiometrics() async {
    try {
      // Заглушка для получения биометрических методов
      return ['fingerprint', 'face'];
    } catch (e) {
      return [];
    }
  }

  /// Проверить наличие PIN-кода
  Future<bool> hasPinCode() async {
    try {
      // Заглушка для проверки PIN-кода
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Аутентификация с биометрией
  Future<bool> authenticateWithBiometrics() async {
    try {
      // Заглушка для биометрической аутентификации
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Проверить PIN-код
  Future<bool> verifyPinCode(String pinCode) async {
    try {
      // Заглушка для проверки PIN-кода
      return pinCode.length >= 4;
    } catch (e) {
      return false;
    }
  }

  /// Установить PIN-код
  Future<void> setPinCode(String pinCode) async {
    try {
      // Заглушка для установки PIN-кода
      if (kDebugMode) {
        print('PIN code set: ${pinCode.length} digits');
      }
    } catch (e) {
      throw Exception('Ошибка установки PIN-кода: $e');
    }
  }

  /// Удалить PIN-код
  Future<void> removePinCode() async {
    try {
      // Заглушка для удаления PIN-кода
      if (kDebugMode) {
        print('PIN code removed');
      }
    } catch (e) {
      throw Exception('Ошибка удаления PIN-кода: $e');
    }
  }

  /// Зашифровать данные
  Future<String> encryptData(String data) async {
    try {
      // Заглушка для шифрования данных
      return base64Encode(utf8.encode(data));
    } catch (e) {
      throw Exception('Ошибка шифрования данных: $e');
    }
  }

  /// Расшифровать данные
  Future<String> decryptData(String encryptedData) async {
    try {
      // Заглушка для расшифровки данных
      return utf8.decode(base64Decode(encryptedData));
    } catch (e) {
      throw Exception('Ошибка расшифровки данных: $e');
    }
  }

  /// Безопасное хранение данных
  Future<void> secureStore(String key, String value) async {
    try {
      // Заглушка для безопасного хранения
      _encryptionKeys[key] = value;
    } catch (e) {
      throw Exception('Ошибка безопасного хранения: $e');
    }
  }

  /// Безопасное чтение данных
  Future<String?> secureRead(String key) async {
    try {
      // Заглушка для безопасного чтения
      return _encryptionKeys[key];
    } catch (e) {
      return null;
    }
  }

  /// Безопасное удаление данных
  Future<void> secureDelete(String key) async {
    try {
      // Заглушка для безопасного удаления
      _encryptionKeys.remove(key);
    } catch (e) {
      throw Exception('Ошибка безопасного удаления: $e');
    }
  }

  /// Получить настройки безопасности
  Future<Map<String, dynamic>> getSecuritySettings() async {
    try {
      // Заглушка для получения настроек безопасности
      return {
        'biometricEnabled': true,
        'pinCodeEnabled': false,
        'autoLock': 5,
        'sessionTimeout': 30,
      };
    } catch (e) {
      throw Exception('Ошибка получения настроек безопасности: $e');
    }
  }

  /// Обновить настройки безопасности
  Future<void> updateSecuritySettings(Map<String, dynamic> settings) async {
    try {
      // Заглушка для обновления настроек безопасности
      if (kDebugMode) {
        print('Security settings updated: $settings');
      }
    } catch (e) {
      throw Exception('Ошибка обновления настроек безопасности: $e');
    }
  }

  /// Заблокировать устройство
  Future<void> blockDevice(String deviceId) async {
    try {
      // Заглушка для блокировки устройства
      if (kDebugMode) {
        print('Device blocked: $deviceId');
      }
    } catch (e) {
      throw Exception('Ошибка блокировки устройства: $e');
    }
  }

  /// Разблокировать устройство
  Future<void> unblockDevice(String deviceId) async {
    try {
      // Заглушка для разблокировки устройства
      if (kDebugMode) {
        print('Device unblocked: $deviceId');
      }
    } catch (e) {
      throw Exception('Ошибка разблокировки устройства: $e');
    }
  }

  /// Доверенное устройство
  Future<void> trustDevice(String deviceId) async {
    try {
      // Заглушка для доверенного устройства
      if (kDebugMode) {
        print('Device trusted: $deviceId');
      }
    } catch (e) {
      throw Exception('Ошибка доверенного устройства: $e');
    }
  }

  /// Проверка силы пароля
  Future<Map<String, dynamic>> checkPasswordStrength(String password) async {
    try {
      // Заглушка для проверки силы пароля
      final score =
          password.length >= 8 ? 100 : (password.length * 12.5).round();
      return {
        'score': score,
        'strength': score >= 80
            ? 'strong'
            : score >= 60
                ? 'medium'
                : 'weak',
        'suggestions': password.length < 8 ? ['Use at least 8 characters'] : [],
      };
    } catch (e) {
      throw Exception('Ошибка проверки силы пароля: $e');
    }
  }

  /// Очистить все безопасные данные
  Future<void> clearAllSecureData() async {
    try {
      // Заглушка для очистки всех безопасных данных
      _encryptionKeys.clear();
      if (kDebugMode) {
        print('All secure data cleared');
      }
    } catch (e) {
      throw Exception('Ошибка очистки безопасных данных: $e');
    }
  }

  /// Включить двухфакторную аутентификацию
  Future<bool> enable2FA({
    required String userId,
    required String method, // 'sms' или 'email'
    required String contact, // номер телефона или email
  }) async {
    try {
      // Генерируем секретный ключ для 2FA
      final secretKey = generateRandomString(32);

      // Сохраняем настройки 2FA в Firestore
      await _firestore.collection('user_2fa').doc(userId).set({
        'userId': userId,
        'method': method,
        'contact': contact,
        'secretKey': secretKey,
        'isEnabled': true,
        'backupCodes': _generateBackupCodes(),
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Логируем событие
      await logSecurityEvent(
        eventType: '2fa_enabled',
        description: 'Двухфакторная аутентификация включена: $method',
        level: SecurityLevel.high,
        userId: userId,
        metadata: {'method': method, 'contact': contact},
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка включения 2FA: $e');
      }
      return false;
    }
  }

  /// Отключить двухфакторную аутентификацию
  Future<bool> disable2FA(String userId) async {
    try {
      // Удаляем настройки 2FA
      await _firestore.collection('user_2fa').doc(userId).delete();

      // Логируем событие
      await logSecurityEvent(
        eventType: '2fa_disabled',
        description: 'Двухфакторная аутентификация отключена',
        level: SecurityLevel.medium,
        userId: userId,
      );

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка отключения 2FA: $e');
      }
      return false;
    }
  }

  /// Проверить, включена ли 2FA
  Future<bool> is2FAEnabled(String userId) async {
    try {
      final doc = await _firestore.collection('user_2fa').doc(userId).get();
      return doc.exists && (doc.data()?['isEnabled'] ?? false);
    } catch (e) {
      return false;
    }
  }

  /// Логировать пользовательскую сессию
  Future<void> logUserSession({
    required String userId,
    required String sessionId,
    required String deviceInfo,
    required String ipAddress,
    required String userAgent,
    required String action, // 'login', 'logout', 'activity'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final sessionLog = {
        'userId': userId,
        'sessionId': sessionId,
        'deviceInfo': deviceInfo,
        'ipAddress': ipAddress,
        'userAgent': userAgent,
        'action': action,
        'metadata': metadata ?? {},
        'timestamp': Timestamp.fromDate(DateTime.now()),
      };

      // Сохраняем в коллекцию user_sessions
      await _firestore.collection('user_sessions').add(sessionLog);

      // Логируем событие безопасности
      await logSecurityEvent(
        eventType: 'user_session_$action',
        description: 'Пользовательская сессия: $action',
        level: _getSessionLogLevel(action),
        userId: userId,
        sessionId: sessionId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        metadata: metadata,
      );

      if (kDebugMode) {
        print('User session logged: $action for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка логирования сессии: $e');
      }
    }
  }

  /// Получить логи сессий пользователя
  Future<List<Map<String, dynamic>>> getUserSessionLogs({
    required String userId,
    int limit = 50,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (fromDate != null) {
        query = query.where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
        );
      }

      if (toDate != null) {
        query = query.where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(toDate),
        );
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка получения логов сессий: $e');
      }
      return [];
    }
  }

  /// Завершить все сессии пользователя
  Future<void> terminateAllUserSessions(String userId) async {
    try {
      // Получаем все активные сессии
      final sessions = await _firestore
          .collection('user_sessions')
          .where('userId', isEqualTo: userId)
          .where('action', isEqualTo: 'login')
          .get();

      // Завершаем каждую сессию
      final batch = _firestore.batch();
      for (final doc in sessions.docs) {
        batch.update(doc.reference, {
          'action': 'terminated',
          'terminatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();

      // Логируем событие
      await logSecurityEvent(
        eventType: 'all_sessions_terminated',
        description: 'Все сессии пользователя завершены',
        level: SecurityLevel.high,
        userId: userId,
        metadata: {'terminatedSessions': sessions.docs.length},
      );

      if (kDebugMode) {
        print('All sessions terminated for user $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ошибка завершения сессий: $e');
      }
    }
  }

  /// Генерировать резервные коды для 2FA
  List<String> _generateBackupCodes() {
    final codes = <String>[];
    for (var i = 0; i < 10; i++) {
      codes.add(generateRandomString(8));
    }
    return codes;
  }

  /// Получить уровень логирования для действия сессии
  SecurityLevel _getSessionLogLevel(String action) {
    switch (action) {
      case 'login':
        return SecurityLevel.info;
      case 'logout':
        return SecurityLevel.info;
      case 'activity':
        return SecurityLevel.low;
      case 'terminated':
        return SecurityLevel.medium;
      default:
        return SecurityLevel.low;
    }
  }

  /// Закрыть сервис
  void dispose() {
    _encryptionKeys.clear();
    _policies.clear();
    _recentAudits.clear();
  }
}
