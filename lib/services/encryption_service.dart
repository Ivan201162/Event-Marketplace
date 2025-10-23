import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:pointycastle/export.dart';

/// Сервис для шифрования данных
class EncryptionService {
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits
  static const int _saltLength = 32; // 256 bits
  static const int _iterations = 10000;

  /// Генерировать случайный ключ
  static Uint8List generateKey() {
    final random = Random.secure();
    final key = Uint8List(_keyLength);
    for (var i = 0; i < _keyLength; i++) {
      key[i] = random.nextInt(256);
    }
    return key;
  }

  /// Генерировать случайный IV
  static Uint8List generateIV() {
    final random = Random.secure();
    final iv = Uint8List(_ivLength);
    for (var i = 0; i < _ivLength; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// Генерировать случайную соль
  static Uint8List generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(_saltLength);
    for (var i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// Получить ключ из пароля с использованием PBKDF2
  static Uint8List deriveKeyFromPassword(String password, Uint8List salt) {
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, _iterations, _keyLength));
    return pbkdf2.process(utf8.encode(password));
  }

  /// Шифровать данные с использованием AES-256-CBC
  static EncryptedData encrypt(String plaintext, Uint8List key) {
    try {
      final iv = generateIV();
      final cipher =
          PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

      final params = PaddedBlockCipherParameters(
          ParametersWithIV(KeyParameter(key), iv), null);

      cipher.init(true, params);

      final plaintextBytes = utf8.encode(plaintext);
      final ciphertext = cipher.process(Uint8List.fromList(plaintextBytes));

      return EncryptedData(
        ciphertext: ciphertext,
        iv: iv,
        salt: Uint8List(0), // Не используется для простого шифрования
      );
    } catch (e) {
      debugPrint('Ошибка шифрования: $e');
      rethrow;
    }
  }

  /// Расшифровать данные с использованием AES-256-CBC
  static String decrypt(EncryptedData encryptedData, Uint8List key) {
    try {
      final cipher =
          PaddedBlockCipherImpl(PKCS7Padding(), CBCBlockCipher(AESEngine()));

      final params = PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), encryptedData.iv),
        null,
      );

      cipher.init(false, params);

      final plaintext = cipher.process(encryptedData.ciphertext);
      return utf8.decode(plaintext);
    } catch (e) {
      debugPrint('Ошибка расшифровки: $e');
      rethrow;
    }
  }

  /// Шифровать данные с паролем
  static EncryptedDataWithPassword encryptWithPassword(
      String plaintext, String password) {
    try {
      final salt = generateSalt();
      final key = deriveKeyFromPassword(password, salt);
      final encryptedData = encrypt(plaintext, key);

      return EncryptedDataWithPassword(
        ciphertext: encryptedData.ciphertext,
        iv: encryptedData.iv,
        salt: salt,
      );
    } catch (e) {
      debugPrint('Ошибка шифрования с паролем: $e');
      rethrow;
    }
  }

  /// Расшифровать данные с паролем
  static String decryptWithPassword(
      EncryptedDataWithPassword encryptedData, String password) {
    try {
      final key = deriveKeyFromPassword(password, encryptedData.salt);
      final data = EncryptedData(
        ciphertext: encryptedData.ciphertext,
        iv: encryptedData.iv,
        salt: Uint8List(0),
      );

      return decrypt(data, key);
    } catch (e) {
      debugPrint('Ошибка расшифровки с паролем: $e');
      rethrow;
    }
  }

  /// Хешировать данные с использованием SHA-256
  static String hashData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Хешировать данные с солью
  static String hashDataWithSalt(String data, String salt) =>
      hashData(data + salt);

  /// Проверить хеш
  static bool verifyHash(String data, String hash) => hashData(data) == hash;

  /// Проверить хеш с солью
  static bool verifyHashWithSalt(String data, String salt, String hash) =>
      hashDataWithSalt(data, salt) == hash;

  /// Генерировать безопасный токен
  static String generateSecureToken(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
          length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Генерировать UUID v4
  static String generateUUID() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }

    // Устанавливаем версию (4) и вариант (10)
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Проверить силу пароля
  static PasswordStrength checkPasswordStrength(String password) {
    var score = 0;
    final requirements = <String, bool>{};

    // Длина пароля
    if (password.length >= 8) {
      score += 1;
      requirements['length'] = true;
    } else {
      requirements['length'] = false;
    }

    // Содержит заглавные буквы
    if (password.contains(RegExp('[A-Z]'))) {
      score += 1;
      requirements['uppercase'] = true;
    } else {
      requirements['uppercase'] = false;
    }

    // Содержит строчные буквы
    if (password.contains(RegExp('[a-z]'))) {
      score += 1;
      requirements['lowercase'] = true;
    } else {
      requirements['lowercase'] = false;
    }

    // Содержит цифры
    if (password.contains(RegExp('[0-9]'))) {
      score += 1;
      requirements['numbers'] = true;
    } else {
      requirements['numbers'] = false;
    }

    // Содержит специальные символы
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      score += 1;
      requirements['special'] = true;
    } else {
      requirements['special'] = false;
    }

    // Определяем уровень силы
    PasswordStrengthLevel level;
    if (score < 2) {
      level = PasswordStrengthLevel.weak;
    } else if (score < 4) {
      level = PasswordStrengthLevel.medium;
    } else if (score < 5) {
      level = PasswordStrengthLevel.strong;
    } else {
      level = PasswordStrengthLevel.veryStrong;
    }

    return PasswordStrength(
        level: level, score: score, requirements: requirements);
  }

  /// Валидировать пароль
  static PasswordValidation validatePassword(String password) {
    final strength = checkPasswordStrength(password);
    final errors = <String>[];

    if (!strength.requirements['length']!) {
      errors.add('Пароль должен содержать минимум 8 символов');
    }
    if (!strength.requirements['uppercase']!) {
      errors.add('Пароль должен содержать заглавные буквы');
    }
    if (!strength.requirements['lowercase']!) {
      errors.add('Пароль должен содержать строчные буквы');
    }
    if (!strength.requirements['numbers']!) {
      errors.add('Пароль должен содержать цифры');
    }
    if (!strength.requirements['special']!) {
      errors.add('Пароль должен содержать специальные символы');
    }

    return PasswordValidation(
        isValid: errors.isEmpty, errors: errors, strength: strength);
  }
}

/// Зашифрованные данные
class EncryptedData {
  const EncryptedData(
      {required this.ciphertext, required this.iv, required this.salt});

  /// Создать из JSON
  factory EncryptedData.fromJson(Map<String, dynamic> json) => EncryptedData(
        ciphertext: base64Decode(json['ciphertext']),
        iv: base64Decode(json['iv']),
        salt: base64Decode(json['salt']),
      );
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List salt;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
        'ciphertext': base64Encode(ciphertext),
        'iv': base64Encode(iv),
        'salt': base64Encode(salt),
      };
}

/// Зашифрованные данные с паролем
class EncryptedDataWithPassword {
  const EncryptedDataWithPassword(
      {required this.ciphertext, required this.iv, required this.salt});

  /// Создать из JSON
  factory EncryptedDataWithPassword.fromJson(Map<String, dynamic> json) =>
      EncryptedDataWithPassword(
        ciphertext: base64Decode(json['ciphertext']),
        iv: base64Decode(json['iv']),
        salt: base64Decode(json['salt']),
      );
  final Uint8List ciphertext;
  final Uint8List iv;
  final Uint8List salt;

  /// Преобразовать в JSON
  Map<String, dynamic> toJson() => {
        'ciphertext': base64Encode(ciphertext),
        'iv': base64Encode(iv),
        'salt': base64Encode(salt),
      };
}

/// Уровень силы пароля
enum PasswordStrengthLevel { weak, medium, strong, veryStrong }

/// Сила пароля
class PasswordStrength {
  const PasswordStrength(
      {required this.level, required this.score, required this.requirements});
  final PasswordStrengthLevel level;
  final int score;
  final Map<String, bool> requirements;

  /// Получить описание уровня
  String get levelDescription {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return 'Слабый';
      case PasswordStrengthLevel.medium:
        return 'Средний';
      case PasswordStrengthLevel.strong:
        return 'Сильный';
      case PasswordStrengthLevel.veryStrong:
        return 'Очень сильный';
    }
  }

  /// Получить цвет уровня
  int get levelColor {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return 0xFFF44336; // Красный
      case PasswordStrengthLevel.medium:
        return 0xFFFF9800; // Оранжевый
      case PasswordStrengthLevel.strong:
        return 0xFF4CAF50; // Зеленый
      case PasswordStrengthLevel.veryStrong:
        return 0xFF2196F3; // Синий
    }
  }
}

/// Валидация пароля
class PasswordValidation {
  const PasswordValidation(
      {required this.isValid, required this.errors, required this.strength});
  final bool isValid;
  final List<String> errors;
  final PasswordStrength strength;
}
