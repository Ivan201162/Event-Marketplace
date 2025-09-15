import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/security.dart';
import '../services/security_service.dart';

/// Провайдер сервиса безопасности
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

/// Провайдер настроек безопасности
final securitySettingsProvider = StateProvider<SecuritySettings?>((ref) {
  return null;
});

/// Провайдер аудита безопасности
final securityAuditLogsProvider = StreamProvider.family<List<SecurityAuditLog>, String>((ref, userId) {
  return ref.watch(securityServiceProvider).getSecurityAuditLogs(userId);
});

/// Провайдер устройств пользователя
final userDevicesProvider = StreamProvider.family<List<SecurityDevice>, String>((ref, userId) {
  return ref.watch(securityServiceProvider).getUserDevices(userId);
});

/// Провайдер доступности биометрической аутентификации
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(securityServiceProvider).isBiometricAvailable();
});

/// Провайдер доступных биометрических методов
final availableBiometricsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(securityServiceProvider).getAvailableBiometrics();
});

/// Провайдер для проверки наличия PIN-кода
final hasPinCodeProvider = FutureProvider<bool>((ref) {
  return ref.watch(securityServiceProvider).hasPinCode();
});

/// Провайдер для аутентификации по биометрии
final biometricAuthProvider = FutureProvider.family<bool, String>((ref, reason) {
  return ref.watch(securityServiceProvider).authenticateWithBiometrics(reason: reason);
});

/// Провайдер для проверки PIN-кода
final pinVerificationProvider = FutureProvider.family<bool, String>((ref, pin) {
  return ref.watch(securityServiceProvider).verifyPinCode(pin);
});

/// Провайдер для установки PIN-кода
final setPinCodeProvider = FutureProvider.family<bool, String>((ref, pin) {
  return ref.watch(securityServiceProvider).setPinCode(pin);
});

/// Провайдер для удаления PIN-кода
final removePinCodeProvider = FutureProvider<bool>((ref) {
  return ref.watch(securityServiceProvider).removePinCode();
});

/// Провайдер для шифрования данных
final encryptDataProvider = FutureProvider.family<String, String>((ref, data) {
  return ref.watch(securityServiceProvider).encryptData(data);
});

/// Провайдер для расшифровки данных
final decryptDataProvider = FutureProvider.family<String, String>((ref, encryptedData) {
  return ref.watch(securityServiceProvider).decryptData(encryptedData);
});

/// Провайдер для безопасного сохранения
final secureStoreProvider = FutureProvider.family<void, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return Future.wait(
    data.entries.map((entry) => service.secureStore(entry.key, entry.value)),
  );
});

/// Провайдер для безопасного чтения
final secureReadProvider = FutureProvider.family<String?, String>((ref, key) {
  return ref.watch(securityServiceProvider).secureRead(key);
});

/// Провайдер для удаления безопасных данных
final secureDeleteProvider = FutureProvider.family<void, String>((ref, key) {
  return ref.watch(securityServiceProvider).secureDelete(key);
});

/// Провайдер для получения настроек безопасности
final getSecuritySettingsProvider = FutureProvider.family<SecuritySettings?, String>((ref, userId) {
  return ref.watch(securityServiceProvider).getSecuritySettings(userId);
});

/// Провайдер для обновления настроек безопасности
final updateSecuritySettingsProvider = FutureProvider.family<bool, SecuritySettings>((ref, settings) {
  return ref.watch(securityServiceProvider).updateSecuritySettings(settings);
});

/// Провайдер для блокировки устройства
final blockDeviceProvider = FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.blockDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для разблокировки устройства
final unblockDeviceProvider = FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.unblockDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для доверия устройству
final trustDeviceProvider = FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.trustDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для проверки силы пароля
final passwordStrengthProvider = Provider<SecurityPasswordStrength Function(String)>((ref) {
  final service = ref.watch(securityServiceProvider);
  return (String password) => service.checkPasswordStrength(password);
});

/// Провайдер для генерации безопасного пароля
final generatePasswordProvider = Provider<String Function({
  int length,
  bool includeUppercase,
  bool includeLowercase,
  bool includeNumbers,
  bool includeSymbols,
})>((ref) {
  final service = ref.watch(securityServiceProvider);
  return ({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSymbols = true,
  }) => service.generateSecurePassword(
    length: length,
    includeUppercase: includeUppercase,
    includeLowercase: includeLowercase,
    includeNumbers: includeNumbers,
    includeSymbols: includeSymbols,
  );
});

/// Провайдер для очистки всех безопасных данных
final clearAllSecureDataProvider = FutureProvider<void>((ref) {
  return ref.watch(securityServiceProvider).clearAllSecureData();
});

/// Провайдер для инициализации сервиса безопасности
final securityInitializationProvider = FutureProvider<void>((ref) async {
  final service = ref.watch(securityServiceProvider);
  await service.initialize();
});

/// Провайдер для получения статистики безопасности
final securityStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Реализовать получение статистики безопасности
  return {
    'totalEvents': 0,
    'criticalEvents': 0,
    'warningEvents': 0,
    'infoEvents': 0,
    'lastLogin': null,
    'securityScore': 0,
  };
});

/// Провайдер для получения рекомендаций по безопасности
final securityRecommendationsProvider = FutureProvider<List<SecurityRecommendation>>((ref) async {
  // TODO: Реализовать получение рекомендаций по безопасности
  return [
    SecurityRecommendation(
      id: '1',
      title: 'Включить биометрическую аутентификацию',
      description: 'Используйте отпечаток пальца или Face ID для быстрого и безопасного входа',
      priority: SecurityRecommendationPriority.high,
      action: 'Включить',
      isCompleted: false,
    ),
    SecurityRecommendation(
      id: '2',
      title: 'Установить PIN-код',
      description: 'Добавьте дополнительный уровень защиты с помощью PIN-кода',
      priority: SecurityRecommendationPriority.medium,
      action: 'Установить',
      isCompleted: false,
    ),
    SecurityRecommendation(
      id: '3',
      title: 'Включить двухфакторную аутентификацию',
      description: 'Защитите свой аккаунт с помощью двухфакторной аутентификации',
      priority: SecurityRecommendationPriority.high,
      action: 'Включить',
      isCompleted: false,
    ),
  ];
});

/// Модель рекомендации по безопасности
class SecurityRecommendation {
  final String id;
  final String title;
  final String description;
  final SecurityRecommendationPriority priority;
  final String action;
  final bool isCompleted;

  const SecurityRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.name,
      'action': action,
      'isCompleted': isCompleted,
    };
  }

  factory SecurityRecommendation.fromMap(Map<String, dynamic> map) {
    return SecurityRecommendation(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      priority: SecurityRecommendationPriority.values.firstWhere(
        (p) => p.name == map['priority'],
        orElse: () => SecurityRecommendationPriority.medium,
      ),
      action: map['action'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  SecurityRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    SecurityRecommendationPriority? priority,
    String? action,
    bool? isCompleted,
  }) {
    return SecurityRecommendation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      action: action ?? this.action,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Приоритеты рекомендаций по безопасности
enum SecurityRecommendationPriority {
  low,
  medium,
  high,
  critical,
}
