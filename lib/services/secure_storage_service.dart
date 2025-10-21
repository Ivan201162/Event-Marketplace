import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

/// Сервис для безопасного хранения данных
class SecureStorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const String _encryptionKeyKey = 'encryption_key';
  static const String _isEncryptionEnabledKey = 'is_encryption_enabled';
  static const String _lastEncryptionUpdateKey = 'last_encryption_update';

  /// Проверить, включено ли шифрование
  static Future<bool> isEncryptionEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isEncryptionEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Ошибка проверки статуса шифрования: $e');
      return false;
    }
  }

  /// Включить шифрование
  static Future<void> enableEncryption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isEncryptionEnabledKey, true);
      await prefs.setInt(
        _lastEncryptionUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Генерируем новый ключ шифрования
      final key = EncryptionService.generateKey();
      await _secureStorage.write(
        key: _encryptionKeyKey,
        value: base64Encode(key),
      );

      debugPrint('Шифрование включено');
    } catch (e) {
      debugPrint('Ошибка включения шифрования: $e');
      rethrow;
    }
  }

  /// Отключить шифрование
  static Future<void> disableEncryption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isEncryptionEnabledKey, false);
      await prefs.setInt(
        _lastEncryptionUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Удаляем ключ шифрования
      await _secureStorage.delete(key: _encryptionKeyKey);

      debugPrint('Шифрование отключено');
    } catch (e) {
      debugPrint('Ошибка отключения шифрования: $e');
      rethrow;
    }
  }

  /// Получить ключ шифрования
  static Future<Uint8List?> getEncryptionKey() async {
    try {
      final keyString = await _secureStorage.read(key: _encryptionKeyKey);
      if (keyString != null) {
        return base64Decode(keyString);
      }
      return null;
    } catch (e) {
      debugPrint('Ошибка получения ключа шифрования: $e');
      return null;
    }
  }

  /// Сохранить данные безопасно
  static Future<void> storeSecure(String key, String value) async {
    try {
      final isEncryptionEnabled = await SecureStorageService.isEncryptionEnabled();

      if (isEncryptionEnabled) {
        final encryptionKey = await getEncryptionKey();
        if (encryptionKey != null) {
          final encryptedData = EncryptionService.encrypt(value, encryptionKey);
          final encryptedJson = jsonEncode(encryptedData.toJson());
          await _secureStorage.write(key: key, value: encryptedJson);
        } else {
          // Если ключ не найден, сохраняем без шифрования
          await _secureStorage.write(key: key, value: value);
        }
      } else {
        await _secureStorage.write(key: key, value: value);
      }

      debugPrint('Данные сохранены безопасно: $key');
    } catch (e) {
      debugPrint('Ошибка безопасного сохранения: $e');
      rethrow;
    }
  }

  /// Загрузить данные безопасно
  static Future<String?> loadSecure(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value == null) return null;

      final isEncryptionEnabled = await SecureStorageService.isEncryptionEnabled();

      if (isEncryptionEnabled) {
        final encryptionKey = await getEncryptionKey();
        if (encryptionKey != null) {
          try {
            final encryptedJson = jsonDecode(value);
            final encryptedData = EncryptedData.fromJson(encryptedJson);
            return EncryptionService.decrypt(encryptedData, encryptionKey);
          } catch (e) {
            // Если не удалось расшифровать, возвращаем как есть
            debugPrint('Ошибка расшифровки, возвращаем исходное значение: $e');
            return value;
          }
        }
      }

      return value;
    } catch (e) {
      debugPrint('Ошибка безопасной загрузки: $e');
      return null;
    }
  }

  /// Удалить данные безопасно
  static Future<void> deleteSecure(String key) async {
    try {
      await _secureStorage.delete(key: key);
      debugPrint('Данные удалены безопасно: $key');
    } catch (e) {
      debugPrint('Ошибка безопасного удаления: $e');
      rethrow;
    }
  }

  /// Очистить все безопасные данные
  static Future<void> clearAllSecure() async {
    try {
      await _secureStorage.deleteAll();
      debugPrint('Все безопасные данные очищены');
    } catch (e) {
      debugPrint('Ошибка очистки безопасных данных: $e');
      rethrow;
    }
  }

  /// Получить все ключи
  static Future<Map<String, String>> getAllSecure() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      debugPrint('Ошибка получения всех безопасных данных: $e');
      return {};
    }
  }

  /// Сохранить данные с паролем
  static Future<void> storeWithPassword(
    String key,
    String value,
    String password,
  ) async {
    try {
      final encryptedData = EncryptionService.encryptWithPassword(value, password);
      final encryptedJson = jsonEncode(encryptedData.toJson());
      await _secureStorage.write(key: key, value: encryptedJson);

      debugPrint('Данные сохранены с паролем: $key');
    } catch (e) {
      debugPrint('Ошибка сохранения с паролем: $e');
      rethrow;
    }
  }

  /// Загрузить данные с паролем
  static Future<String?> loadWithPassword(String key, String password) async {
    try {
      final value = await _secureStorage.read(key: key);
      if (value == null) return null;

      final encryptedJson = jsonDecode(value);
      final encryptedData = EncryptedDataWithPassword.fromJson(encryptedJson);
      return EncryptionService.decryptWithPassword(encryptedData, password);
    } catch (e) {
      debugPrint('Ошибка загрузки с паролем: $e');
      return null;
    }
  }

  /// Проверить, существует ли ключ
  static Future<bool> containsKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      debugPrint('Ошибка проверки существования ключа: $e');
      return false;
    }
  }

  /// Получить время последнего обновления шифрования
  static Future<DateTime?> getLastEncryptionUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastEncryptionUpdateKey);
      return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
    } catch (e) {
      debugPrint(
        'Ошибка получения времени последнего обновления шифрования: $e',
      );
      return null;
    }
  }

  /// Обновить ключ шифрования
  static Future<void> updateEncryptionKey() async {
    try {
      final isEncryptionEnabled = await SecureStorageService.isEncryptionEnabled();
      if (!isEncryptionEnabled) {
        throw Exception('Шифрование не включено');
      }

      // Получаем старый ключ
      final oldKey = await getEncryptionKey();
      if (oldKey == null) {
        throw Exception('Старый ключ не найден');
      }

      // Генерируем новый ключ
      final newKey = EncryptionService.generateKey();

      // Перешифровываем все данные
      final allData = await getAllSecure();
      for (final entry in allData.entries) {
        if (entry.key == _encryptionKeyKey) continue;

        try {
          // Расшифровываем старым ключом
          final encryptedJson = jsonDecode(entry.value);
          final encryptedData = EncryptedData.fromJson(encryptedJson);
          final decryptedValue = EncryptionService.decrypt(encryptedData, oldKey);

          // Шифруем новым ключом
          final newEncryptedData = EncryptionService.encrypt(decryptedValue, newKey);
          final newEncryptedJson = jsonEncode(newEncryptedData.toJson());

          await _secureStorage.write(key: entry.key, value: newEncryptedJson);
        } catch (e) {
          debugPrint('Ошибка перешифровки данных для ключа ${entry.key}: $e');
        }
      }

      // Сохраняем новый ключ
      await _secureStorage.write(
        key: _encryptionKeyKey,
        value: base64Encode(newKey),
      );

      // Обновляем время последнего обновления
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _lastEncryptionUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('Ключ шифрования обновлен');
    } catch (e) {
      debugPrint('Ошибка обновления ключа шифрования: $e');
      rethrow;
    }
  }

  /// Получить статистику безопасности
  static Future<SecurityStats> getSecurityStats() async {
    try {
      final isEncryptionEnabled = await SecureStorageService.isEncryptionEnabled();
      final lastUpdate = await getLastEncryptionUpdate();
      final allData = await getAllSecure();
      final encryptedCount = allData.length;

      return SecurityStats(
        isEncryptionEnabled: isEncryptionEnabled,
        lastEncryptionUpdate: lastUpdate,
        encryptedItemsCount: encryptedCount,
        hasEncryptionKey: await getEncryptionKey() != null,
      );
    } catch (e) {
      debugPrint('Ошибка получения статистики безопасности: $e');
      return const SecurityStats(
        isEncryptionEnabled: false,
        lastEncryptionUpdate: null,
        encryptedItemsCount: 0,
        hasEncryptionKey: false,
      );
    }
  }
}

/// Статистика безопасности
class SecurityStats {
  const SecurityStats({
    required this.isEncryptionEnabled,
    required this.lastEncryptionUpdate,
    required this.encryptedItemsCount,
    required this.hasEncryptionKey,
  });
  final bool isEncryptionEnabled;
  final DateTime? lastEncryptionUpdate;
  final int encryptedItemsCount;
  final bool hasEncryptionKey;

  /// Получить время последнего обновления в читаемом виде
  String get formattedLastUpdate {
    if (lastEncryptionUpdate == null) return 'Никогда';

    final now = DateTime.now();
    final difference = now.difference(lastEncryptionUpdate!);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч. назад';
    } else {
      return '${difference.inDays} дн. назад';
    }
  }

  /// Получить статус безопасности
  String get securityStatus {
    if (!isEncryptionEnabled) return 'Отключено';
    if (!hasEncryptionKey) return 'Ошибка';
    return 'Активно';
  }

  /// Получить цвет статуса
  int get statusColor {
    if (!isEncryptionEnabled) return 0xFFF44336; // Красный
    if (!hasEncryptionKey) return 0xFFFF9800; // Оранжевый
    return 0xFF4CAF50; // Зеленый
  }
}

/// Ключи для безопасного хранения
class SecureStorageKeys {
  static const String userToken = 'user_token';
  static const String userCredentials = 'user_credentials';
  static const String biometricData = 'biometric_data';
  static const String paymentInfo = 'payment_info';
  static const String personalData = 'personal_data';
  static const String chatMessages = 'chat_messages';
  static const String notifications = 'notifications';
  static const String settings = 'settings';
  static const String cache = 'cache';
  static const String logs = 'logs';
}
