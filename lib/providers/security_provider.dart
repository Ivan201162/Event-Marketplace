import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';
import '../services/encryption_service.dart';

/// Провайдер для управления безопасностью
final securityProvider =
    NotifierProvider<SecurityNotifier, SecurityState>((ref) {
  return SecurityNotifier();
});

/// Провайдер для статистики безопасности
final securityStatsProvider = FutureProvider<SecurityStats>((ref) async {
  return await SecureStorageService.getSecurityStats();
});

/// Провайдер для валидации пароля
final passwordValidationProvider =
    NotifierProvider<PasswordValidationNotifier, PasswordValidationState>(
        (ref) {
  return PasswordValidationNotifier();
});

/// Состояние безопасности
class SecurityState {
  final bool isEncryptionEnabled;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdate;
  final bool hasEncryptionKey;

  const SecurityState({
    this.isEncryptionEnabled = false,
    this.isLoading = false,
    this.error,
    this.lastUpdate,
    this.hasEncryptionKey = false,
  });

  SecurityState copyWith({
    bool? isEncryptionEnabled,
    bool? isLoading,
    String? error,
    DateTime? lastUpdate,
    bool? hasEncryptionKey,
  }) {
    return SecurityState(
      isEncryptionEnabled: isEncryptionEnabled ?? this.isEncryptionEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      hasEncryptionKey: hasEncryptionKey ?? this.hasEncryptionKey,
    );
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

/// Состояние валидации пароля
class PasswordValidationState {
  final String password;
  final PasswordValidation? validation;
  final bool isVisible;
  final String? error;

  const PasswordValidationState({
    this.password = '',
    this.validation,
    this.isVisible = false,
    this.error,
  });

  PasswordValidationState copyWith({
    String? password,
    PasswordValidation? validation,
    bool? isVisible,
    String? error,
  }) {
    return PasswordValidationState(
      password: password ?? this.password,
      validation: validation ?? this.validation,
      isVisible: isVisible ?? this.isVisible,
      error: error ?? this.error,
    );
  }

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
    if (validation == null) return 0.0;
    return validation!.strength.score / 5.0;
  }
}

/// Нотификатор для управления безопасностью
class SecurityNotifier extends Notifier<SecurityState> {
  SecurityNotifier() : super(const SecurityState()) {
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
        error: null,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Включить шифрование
  Future<void> enableEncryption() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.enableEncryption();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Отключить шифрование
  Future<void> disableEncryption() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.disableEncryption();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить ключ шифрования
  Future<void> updateEncryptionKey() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.updateEncryptionKey();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Очистить все безопасные данные
  Future<void> clearAllSecureData() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SecureStorageService.clearAllSecure();
      await _updateSecurityStatus();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Обновить статус
  Future<void> refresh() async {
    await _updateSecurityStatus();
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Нотификатор для валидации пароля
class PasswordValidationNotifier extends Notifier<PasswordValidationState> {
  PasswordValidationNotifier() : super(const PasswordValidationState());

  /// Обновить пароль
  void updatePassword(String password) {
    final validation = EncryptionService.validatePassword(password);
    state = state.copyWith(
      password: password,
      validation: validation,
      error: null,
    );
  }

  /// Переключить видимость пароля
  void toggleVisibility() {
    state = state.copyWith(isVisible: !state.isVisible);
  }

  /// Очистить пароль
  void clearPassword() {
    state = state.copyWith(
      password: '',
      validation: null,
      error: null,
    );
  }

  /// Установить ошибку
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Проверить, валиден ли пароль
  bool get isValidPassword {
    return state.validation?.isValid ?? false;
  }

  /// Получить ошибки валидации
  List<String> get validationErrors {
    return state.validation?.errors ?? [];
  }
}

/// Провайдер для проверки безопасности данных
final dataSecurityProvider = Provider<DataSecurityChecker>((ref) {
  return DataSecurityChecker();
});

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
        return [
          'Опциональное шифрование',
          'Базовые меры безопасности',
        ];
      case SecurityLevel.low:
        return [
          'Стандартные меры безопасности',
        ];
    }
  }
}

/// Уровни безопасности
enum SecurityLevel {
  low,
  medium,
  high,
  critical,
}

/// Провайдер для генерации безопасных токенов
final secureTokenProvider = Provider<SecureTokenGenerator>((ref) {
  return SecureTokenGenerator();
});

/// Генератор безопасных токенов
class SecureTokenGenerator {
  /// Генерировать токен сессии
  String generateSessionToken() {
    return EncryptionService.generateSecureToken(32);
  }

  /// Генерировать API ключ
  String generateApiKey() {
    return EncryptionService.generateSecureToken(64);
  }

  /// Генерировать UUID
  String generateUUID() {
    return EncryptionService.generateUUID();
  }

  /// Генерировать хеш для данных
  String generateHash(String data) {
    return EncryptionService.hashData(data);
  }

  /// Генерировать хеш с солью
  String generateHashWithSalt(String data, String salt) {
    return EncryptionService.hashDataWithSalt(data, salt);
  }
}
