import 'package:event_marketplace_app/services/encryption_service.dart';
import 'package:event_marketplace_app/services/secure_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для управления безопасностью
final securityProvider = NotifierProvider<SecurityNotifier, SecurityState>(
  (ref) => SecurityNotifier(),
);

/// Провайдер для статистики безопасности
final securityStatsProvider = FutureProvider<SecurityStats>(
  (ref) async => SecureStorageService.getSecurityStats(),
);

/// Провайдер для валидации пароля
final passwordValidationProvider =
    NotifierProvider<PasswordValidationNotifier, PasswordValidationState>(
  (ref) => PasswordValidationNotifier(),
);

/// Состояние безопасности
class SecurityState {
  const SecurityState({
    this.isEncryptionEnabled = false,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
    this.hasEncryptionKey = false,
  });
  final bool isEncryptionEnabled;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;
  final bool hasEncryptionKey;

  SecurityState copyWith({
    bool? isEncryptionEnabled,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
    bool? hasEncryptionKey,
  }) =>
      SecurityState(
        isEncryptionEnabled: isEncryptionEnabled ?? this.isEncryptionEnabled,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdate: lastUpdate ?? this.lastUpdate,
        hasEncryptionKey: hasEncryptionKey ?? this.hasEncryptionKey,
      );

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

/// Состояние валидации пароля
class PasswordValidationState {
  const PasswordValidationState({
    this.password = '',
    this.validation,
    this.isVisible = false,
    this.error,
  });
  final String password;
  final PasswordValidation? validation;
  final bool isVisible;
  final String? error;

  PasswordValidationState copyWith({
    String? password,
    PasswordValidation? validation,
    bool? isVisible,
    String? error,
  }) =>
      PasswordValidationState(
        password: password ?? this.password,
        validation: validation ?? this.validation,
        isVisible: isVisible ?? this.isVisible,
        error: error ?? this.error,
      );

  /// Получить цвет силы пароля
  int get strengthColor {
    if (validation == null) return 0xFF9E9E9E; // Серый
    return validation!.strength.levelColor;
  }

  /// Получить описание силы пароля
  String get strengthDescription {
    if (validation == null) return '';
    return validation!.strength.levelDescription;
  }

  /// Получить прогресс силы пароля
  double get strengthProgress {
    if (validation == null) return 0;
    return validation!.strength.score / 5.0;
  }
}

/// Нотификатор для управления безопасностью
class SecurityNotifier extends Notifier<SecurityState> {
  SecurityNotifier() : super() {
    _initialize();
  }

  /// Инициализация
  Future<void> _initialize() async {
    await _updateSecurityStatus();
  }

  /// Обновить статус безопасности
  Future<void> _updateSecurityStatus() async {
    try {
      final isEncryptionEnabled =
          await SecureStorageService.isEncryptionEnabled();
      final hasEncryptionKey =
          await SecureStorageService.getEncryptionKey() != null;
      final lastUpdate = await SecureStorageService.getLastEncryptionUpdate();

      state = state.copyWith(
        isEncryptionEnabled: isEncryptionEnabled,
        hasEncryptionKey: hasEncryptionKey,
        lastUpdate: lastUpdate,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Включить шифрование
  Future<void> enableEncryption() async {
    state = state.copyWith(isLoading: true);

    try {
      await SecureStorageService.enableEncryption();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Отключить шифрование
  Future<void> disableEncryption() async {
    state = state.copyWith(isLoading: true);

    try {
      await SecureStorageService.disableEncryption();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Обновить ключ шифрования
  Future<void> updateEncryptionKey() async {
    state = state.copyWith(isLoading: true);

    try {
      await SecureStorageService.updateEncryptionKey();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Очистить все безопасные данные
  Future<void> clearAllSecureData() async {
    state = state.copyWith(isLoading: true);

    try {
      await SecureStorageService.clearAllSecure();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Обновить статус
  Future<void> refresh() async {
    await _updateSecurityStatus();
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith();
  }
}

/// Нотификатор для валидации пароля
class PasswordValidationNotifier extends Notifier<PasswordValidationState> {
  PasswordValidationNotifier() : super();

  /// Обновить пароль
  void updatePassword(String password) {
    final validation = EncryptionService.validatePassword(password);
    state = state.copyWith(password: password, validation: validation);
  }

  /// Переключить видимость пароля
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Очистить пароль
  void clearPassword() {
    state = state.copyWith(password: '');
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }

  /// Проверить, валиден ли пароль
  bool get isValidPassword => state.validation?.isValid ?? false;

  /// Получить ошибки валидации
  List<String> get validationErrors => state.validation?.errors ?? [];
}

/// Провайдер для проверки безопасности данных
final dataSecurityProvider =
    Provider<DataSecurityChecker>((ref) => DataSecurityChecker());

/// Класс для проверки безопасности данных
class DataSecurityChecker {
  /// Проверить, нужно ли шифровать данные
  bool shouldEncrypt(String dataType) {
    const sensitiveDataTypes = [
      'user_credentials',
      'payment_info',
      'personal_data',
      'biometric_data',
      'chat_messages',
      'notifications',
    ];

    return sensitiveDataTypes.contains(dataType);
  }

  /// Получить уровень безопасности для типа данных
  SecurityLevel getSecurityLevel(String dataType) {
    switch (dataType) {
      case 'user_credentials':
      case 'payment_info':
      case 'biometric_data':
        return SecurityLevel.critical;
      case 'personal_data':
      case 'chat_messages':
        return SecurityLevel.high;
      case 'notifications':
      case 'settings':
        return SecurityLevel.medium;
      default:
        return SecurityLevel.low;
    }
  }

  /// Получить рекомендации по безопасности
  List<String> getSecurityRecommendations(String dataType) {
    final level = getSecurityLevel(dataType);

    switch (level) {
      case SecurityLevel.critical:
        return [
          'Обязательное шифрование',
          'Использование сильного пароля',
          'Регулярное обновление ключей',
          'Двухфакторная аутентификация',
        ];
      case SecurityLevel.high:
        return [
          'Рекомендуемое шифрование',
          'Использование надежного пароля',
          'Периодическое обновление ключей',
        ];
      case SecurityLevel.medium:
        return ['Опциональное шифрование', 'Базовые меры безопасности'];
      case SecurityLevel.low:
        return ['Стандартные меры безопасности'];
    }
  }
}

/// Уровни безопасности
enum SecurityLevel { low, medium, high, critical }

/// Провайдер для генерации безопасных токенов
final secureTokenProvider =
    Provider<SecureTokenGenerator>((ref) => SecureTokenGenerator());

/// Генератор безопасных токенов
class SecureTokenGenerator {
  /// Генерировать токен сессии
  String generateSessionToken() => EncryptionService.generateSecureToken(32);

  /// Генерировать API ключ
  String generateApiKey() => EncryptionService.generateSecureToken(64);

  /// Генерировать UUID
  String generateUUID() => EncryptionService.generateUUID();

  /// Генерировать хеш для данных
  String generateHash(String data) => EncryptionService.hashData(data);

  /// Генерировать хеш с солью
  String generateHashWithSalt(String data, String salt) =>
      EncryptionService.hashDataWithSalt(data, salt);
}
