import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/security.dart';

/// Сервис безопасности
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _pinKey = 'user_pin';
  static const String _encryptionKey = 'encryption_key';
  static const String _deviceIdKey = 'device_id';

  /// Инициализация сервиса безопасности
  Future<void> initialize() async {
    await _initializeEncryption();
    await _registerDevice();
  }

  /// Инициализация шифрования
  Future<void> _initializeEncryption() async {
    try {
      final existingKey = await _secureStorage.read(key: _encryptionKey);
      if (existingKey == null) {
        final key = Key.fromSecureRandom(32);
        await _secureStorage.write(key: _encryptionKey, value: key.base64);
      }
    } catch (e) {
      print('Ошибка инициализации шифрования: $e');
    }
  }

  /// Регистрация устройства
  Future<void> _registerDevice() async {
    try {
      final deviceId = await _getDeviceId();
      await _getDeviceInfo();

      // TODO: Отправить информацию об устройстве на сервер
      print('Устройство зарегистрировано: $deviceId');
    } catch (e) {
      print('Ошибка регистрации устройства: $e');
    }
  }

  /// Получить ID устройства
  Future<String> _getDeviceId() async {
    try {
      String? deviceId = await _secureStorage.read(key: _deviceIdKey);
      if (deviceId == null) {
        deviceId = _generateDeviceId();
        await _secureStorage.write(key: _deviceIdKey, value: deviceId);
      }
      return deviceId;
    } catch (e) {
      print('Ошибка получения ID устройства: $e');
      return _generateDeviceId();
    }
  }

  /// Генерация ID устройства
  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Получить информацию об устройстве
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = await _deviceInfo.deviceInfo;

      return {
        'appVersion': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
        'deviceInfo': deviceInfo.data,
      };
    } catch (e) {
      print('Ошибка получения информации об устройстве: $e');
      return {};
    }
  }

  /// Проверить доступность биометрической аутентификации
  Future<bool> isBiometricAvailable() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Ошибка проверки биометрической аутентификации: $e');
      return false;
    }
  }

  /// Получить доступные биометрические методы
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Ошибка получения доступных биометрических методов: $e');
      return [];
    }
  }

  /// Аутентификация по биометрии
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final result = await _localAuth.authenticate(
        localizedReason: reason ?? 'Подтвердите свою личность',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (result) {
        await _logSecurityEvent(
          eventType: SecurityEventType.biometricAuth,
          description: 'Успешная биометрическая аутентификация',
          severity: SecurityEventSeverity.info,
        );
      }

      return result;
    } catch (e) {
      print('Ошибка биометрической аутентификации: $e');
      await _logSecurityEvent(
        eventType: SecurityEventType.biometricAuth,
        description: 'Ошибка биометрической аутентификации: $e',
        severity: SecurityEventSeverity.error,
      );
      return false;
    }
  }

  /// Установить PIN-код
  Future<bool> setPinCode(String pin) async {
    try {
      if (pin.length < 4) return false;

      final hashedPin = _hashPin(pin);
      await _secureStorage.write(key: _pinKey, value: hashedPin);

      await _logSecurityEvent(
        eventType: SecurityEventType.passwordChange,
        description: 'PIN-код установлен',
        severity: SecurityEventSeverity.info,
      );

      return true;
    } catch (e) {
      print('Ошибка установки PIN-кода: $e');
      return false;
    }
  }

  /// Проверить PIN-код
  Future<bool> verifyPinCode(String pin) async {
    try {
      final storedPin = await _secureStorage.read(key: _pinKey);
      if (storedPin == null) return false;

      final hashedPin = _hashPin(pin);
      final isValid = hashedPin == storedPin;

      if (isValid) {
        await _logSecurityEvent(
          eventType: SecurityEventType.pinAuth,
          description: 'Успешная аутентификация по PIN-коду',
          severity: SecurityEventSeverity.info,
        );
      } else {
        await _logSecurityEvent(
          eventType: SecurityEventType.pinAuth,
          description: 'Неудачная попытка аутентификации по PIN-коду',
          severity: SecurityEventSeverity.warning,
        );
      }

      return isValid;
    } catch (e) {
      print('Ошибка проверки PIN-кода: $e');
      return false;
    }
  }

  /// Хеширование PIN-кода
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Проверить, установлен ли PIN-код
  Future<bool> hasPinCode() async {
    try {
      final pin = await _secureStorage.read(key: _pinKey);
      return pin != null;
    } catch (e) {
      print('Ошибка проверки наличия PIN-кода: $e');
      return false;
    }
  }

  /// Удалить PIN-код
  Future<bool> removePinCode() async {
    try {
      await _secureStorage.delete(key: _pinKey);

      await _logSecurityEvent(
        eventType: SecurityEventType.passwordChange,
        description: 'PIN-код удален',
        severity: SecurityEventSeverity.info,
      );

      return true;
    } catch (e) {
      print('Ошибка удаления PIN-кода: $e');
      return false;
    }
  }

  /// Шифрование данных
  Future<String> encryptData(String data) async {
    try {
      final keyString = await _secureStorage.read(key: _encryptionKey);
      if (keyString == null) throw Exception('Ключ шифрования не найден');

      final key = Key.fromBase64(keyString);
      final encrypter = Encrypter(AES(key));
      final iv = IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(data, iv: iv);

      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Ошибка шифрования данных: $e');
      throw Exception('Ошибка шифрования');
    }
  }

  /// Расшифровка данных
  Future<String> decryptData(String encryptedData) async {
    try {
      final keyString = await _secureStorage.read(key: _encryptionKey);
      if (keyString == null) throw Exception('Ключ шифрования не найден');

      final parts = encryptedData.split(':');
      if (parts.length != 2)
        throw Exception('Неверный формат зашифрованных данных');

      final key = Key.fromBase64(keyString);
      final encrypter = Encrypter(AES(key));
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Ошибка расшифровки данных: $e');
      throw Exception('Ошибка расшифровки');
    }
  }

  /// Безопасное сохранение данных
  Future<void> secureStore(String key, String value) async {
    try {
      final encryptedValue = await encryptData(value);
      await _secureStorage.write(key: key, value: encryptedValue);
    } catch (e) {
      print('Ошибка безопасного сохранения: $e');
      throw Exception('Ошибка сохранения данных');
    }
  }

  /// Безопасное чтение данных
  Future<String?> secureRead(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;

      return await decryptData(encryptedValue);
    } catch (e) {
      print('Ошибка безопасного чтения: $e');
      return null;
    }
  }

  /// Удалить безопасные данные
  Future<void> secureDelete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      print('Ошибка удаления безопасных данных: $e');
    }
  }

  /// Получить настройки безопасности пользователя
  Future<SecuritySettings?> getSecuritySettings(String userId) async {
    try {
      final doc =
          await _firestore.collection('security_settings').doc(userId).get();

      if (doc.exists) {
        return SecuritySettings.fromDocument(doc);
      }
      return null;
    } catch (e) {
      print('Ошибка получения настроек безопасности: $e');
      return null;
    }
  }

  /// Обновить настройки безопасности
  Future<bool> updateSecuritySettings(SecuritySettings settings) async {
    try {
      await _firestore
          .collection('security_settings')
          .doc(settings.userId)
          .set(settings.toMap());

      await _logSecurityEvent(
        eventType: SecurityEventType.securitySettingsChange,
        description: 'Настройки безопасности обновлены',
        severity: SecurityEventSeverity.info,
      );

      return true;
    } catch (e) {
      print('Ошибка обновления настроек безопасности: $e');
      return false;
    }
  }

  /// Получить аудит безопасности
  Stream<List<SecurityAuditLog>> getSecurityAuditLogs(String userId) {
    return _firestore
        .collection('security_audit_logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SecurityAuditLog.fromDocument(doc))
          .toList();
    });
  }

  /// Логирование события безопасности
  Future<void> _logSecurityEvent({
    required SecurityEventType eventType,
    required String description,
    required SecurityEventSeverity severity,
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      await _getDeviceInfo();

      final log = SecurityAuditLog(
        id: '',
        userId: userId ?? 'anonymous',
        eventType: eventType,
        description: description,
        deviceId: deviceId,
        metadata: metadata,
        severity: severity,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('security_audit_logs').add(log.toMap());
    } catch (e) {
      print('Ошибка логирования события безопасности: $e');
    }
  }

  /// Получить устройства пользователя
  Stream<List<SecurityDevice>> getUserDevices(String userId) {
    return _firestore
        .collection('security_devices')
        .where('userId', isEqualTo: userId)
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SecurityDevice.fromDocument(doc))
          .toList();
    });
  }

  /// Заблокировать устройство
  Future<bool> blockDevice(String deviceId, String userId) async {
    try {
      await _firestore.collection('security_devices').doc(deviceId).update({
        'isBlocked': true,
        'lastSeen': Timestamp.now(),
      });

      await _logSecurityEvent(
        eventType: SecurityEventType.deviceBlocked,
        description: 'Устройство заблокировано: $deviceId',
        severity: SecurityEventSeverity.warning,
        userId: userId,
      );

      return true;
    } catch (e) {
      print('Ошибка блокировки устройства: $e');
      return false;
    }
  }

  /// Разблокировать устройство
  Future<bool> unblockDevice(String deviceId, String userId) async {
    try {
      await _firestore.collection('security_devices').doc(deviceId).update({
        'isBlocked': false,
        'lastSeen': Timestamp.now(),
      });

      await _logSecurityEvent(
        eventType: SecurityEventType.deviceRegistration,
        description: 'Устройство разблокировано: $deviceId',
        severity: SecurityEventSeverity.info,
        userId: userId,
      );

      return true;
    } catch (e) {
      print('Ошибка разблокировки устройства: $e');
      return false;
    }
  }

  /// Доверять устройству
  Future<bool> trustDevice(String deviceId, String userId) async {
    try {
      await _firestore.collection('security_devices').doc(deviceId).update({
        'isTrusted': true,
        'lastSeen': Timestamp.now(),
      });

      await _logSecurityEvent(
        eventType: SecurityEventType.deviceRegistration,
        description: 'Устройство добавлено в доверенные: $deviceId',
        severity: SecurityEventSeverity.info,
        userId: userId,
      );

      return true;
    } catch (e) {
      print('Ошибка добавления устройства в доверенные: $e');
      return false;
    }
  }

  /// Проверить безопасность пароля
  SecurityPasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    final issues = <String>[];

    // Длина пароля
    if (password.length >= 8) {
      score += 1;
    } else {
      issues.add('Пароль должен содержать минимум 8 символов');
    }

    // Наличие заглавных букв
    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 1;
    } else {
      issues.add('Добавьте заглавные буквы');
    }

    // Наличие строчных букв
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 1;
    } else {
      issues.add('Добавьте строчные буквы');
    }

    // Наличие цифр
    if (password.contains(RegExp(r'[0-9]'))) {
      score += 1;
    } else {
      issues.add('Добавьте цифры');
    }

    // Наличие специальных символов
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
    } else {
      issues.add('Добавьте специальные символы');
    }

    // Определение уровня безопасности
    SecurityPasswordLevel level;
    if (score <= 2) {
      level = SecurityPasswordLevel.weak;
    } else if (score <= 3) {
      level = SecurityPasswordLevel.medium;
    } else if (score <= 4) {
      level = SecurityPasswordLevel.strong;
    } else {
      level = SecurityPasswordLevel.veryStrong;
    }

    return SecurityPasswordStrength(
      level: level,
      score: score,
      maxScore: 5,
      issues: issues,
    );
  }

  /// Генерация безопасного пароля
  String generateSecurePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) {
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) chars = lowercase + numbers;

    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Очистить все безопасные данные
  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
      await _logSecurityEvent(
        eventType: SecurityEventType.securitySettingsChange,
        description: 'Все безопасные данные очищены',
        severity: SecurityEventSeverity.warning,
      );
    } catch (e) {
      print('Ошибка очистки безопасных данных: $e');
    }
  }
}

/// Модель силы пароля
class SecurityPasswordStrength {
  final SecurityPasswordLevel level;
  final int score;
  final int maxScore;
  final List<String> issues;

  const SecurityPasswordStrength({
    required this.level,
    required this.score,
    required this.maxScore,
    required this.issues,
  });

  double get percentage => (score / maxScore) * 100;
}

/// Уровни безопасности пароля
enum SecurityPasswordLevel {
  weak,
  medium,
  strong,
  veryStrong,
}
