import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/security_settings.dart';
import '../services/security_service.dart';

/// Провайдер сервиса безопасности
final securityServiceProvider =
    Provider<SecurityService>((ref) => SecurityService());

/// Нотификатор для настроек безопасности
class SecuritySettingsNotifier extends Notifier<SecuritySettings?> {
  @override
  SecuritySettings? build() => null;

  void updateSettings(SecuritySettings? settings) {
    state = settings;
  }

  void clearSettings() {
    state = null;
  }
}

/// Провайдер настроек безопасности
final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettings?>(
  SecuritySettingsNotifier.new,
);

/// Провайдер аудита безопасности
final securityAuditLogsProvider =
    StreamProvider.family<List<SecurityAuditLog>, String>(
  (ref, userId) =>
      ref.watch(securityServiceProvider).getSecurityAuditLogs(),
);

/// Провайдер устройств пользователя
final userDevicesProvider = StreamProvider.family<List<SecurityDevice>, String>(
  (ref, userId) => ref.watch(securityServiceProvider).getUserDevices(userId),
);

/// Провайдер доступности биометрической аутентификации
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(securityServiceProvider).isBiometricAvailable(),
);

/// Провайдер доступных биометрических методов
final availableBiometricsProvider = FutureProvider<List<dynamic>>(
  (ref) => ref.watch(securityServiceProvider).getAvailableBiometrics(),
);

/// Провайдер для проверки наличия PIN-кода
final hasPinCodeProvider = FutureProvider<bool>(
  (ref) => ref.watch(securityServiceProvider).hasPinCode(),
);

/// Провайдер для аутентификации по биометрии
final biometricAuthProvider = FutureProvider<bool>(
  (ref) => ref.watch(securityServiceProvider).authenticateWithBiometrics(),
);

/// Провайдер для проверки PIN-кода
final pinVerificationProvider = FutureProvider.family<bool, String>(
  (ref, pin) => ref.watch(securityServiceProvider).verifyPinCode(pin),
);

/// Провайдер для установки PIN-кода
final setPinCodeProvider = FutureProvider.family<bool, String>(
  (ref, pin) => ref.watch(securityServiceProvider).setPinCode(pin),
);

/// Провайдер для удаления PIN-кода
final removePinCodeProvider = FutureProvider<bool>(
  (ref) => ref.watch(securityServiceProvider).removePinCode(),
);

/// Провайдер для шифрования данных
final encryptDataProvider = FutureProvider.family<String, String>(
  (ref, data) => ref.watch(securityServiceProvider).encryptData(data),
);

/// Провайдер для расшифровки данных
final decryptDataProvider = FutureProvider.family<String, String>(
  (ref, encryptedData) =>
      ref.watch(securityServiceProvider).decryptData(encryptedData),
);

/// Провайдер для безопасного сохранения
final secureStoreProvider =
    FutureProvider.family<void, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return Future.wait(
    data.entries.map((entry) => service.secureStore(entry.key, entry.value)),
  );
});

/// Провайдер для безопасного чтения
final secureReadProvider = FutureProvider.family<String?, String>(
  (ref, key) => ref.watch(securityServiceProvider).secureRead(key),
);

/// Провайдер для удаления безопасных данных
final secureDeleteProvider = FutureProvider.family<void, String>(
  (ref, key) => ref.watch(securityServiceProvider).secureDelete(key),
);

/// Провайдер для получения настроек безопасности
final getSecuritySettingsProvider =
    FutureProvider.family<SecuritySettings?, String>(
  (ref, userId) =>
      ref.watch(securityServiceProvider).getSecuritySettings(),
);

/// Провайдер для обновления настроек безопасности
final updateSecuritySettingsProvider =
    FutureProvider.family<bool, SecuritySettings>(
  (ref, settings) =>
      ref.watch(securityServiceProvider).updateSecuritySettings(settings),
);

/// Провайдер для блокировки устройства
final blockDeviceProvider =
    FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.blockDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для разблокировки устройства
final unblockDeviceProvider =
    FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.unblockDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для доверия устройству
final trustDeviceProvider =
    FutureProvider.family<bool, Map<String, String>>((ref, data) {
  final service = ref.watch(securityServiceProvider);
  return service.trustDevice(data['deviceId']!, data['userId']!);
});

/// Провайдер для проверки силы пароля
final passwordStrengthProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, password) {
  final service = ref.watch(securityServiceProvider);
  return service.checkPasswordStrength(password);
});

/// Провайдер для генерации безопасного пароля
final generatePasswordProvider = Provider<
    String Function({
      int length,
      bool includeUppercase,
      bool includeLowercase,
      bool includeNumbers,
      bool includeSymbols,
    })>((ref) {
  final service = ref.watch(securityServiceProvider);
  return service.generateSecurePassword;
});

/// Провайдер для очистки всех безопасных данных
final clearAllSecureDataProvider = FutureProvider<void>(
  (ref) => ref.watch(securityServiceProvider).clearAllSecureData(),
);

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
final securityRecommendationsProvider =
    FutureProvider<List<SecurityRecommendation>>((ref) async {
  // TODO: Реализовать получение рекомендаций по безопасности
  return [
    const SecurityRecommendation(
      id: '1',
      title: 'Включить биометрическую аутентификацию',
      description:
          'Используйте отпечаток пальца или Face ID для быстрого и безопасного входа',
      priority: SecurityRecommendationPriority.high,
      action: 'Включить',
    ),
    const SecurityRecommendation(
      id: '2',
      title: 'Установить PIN-код',
      description: 'Добавьте дополнительный уровень защиты с помощью PIN-кода',
      priority: SecurityRecommendationPriority.medium,
      action: 'Установить',
    ),
    const SecurityRecommendation(
      id: '3',
      title: 'Включить двухфакторную аутентификацию',
      description:
          'Защитите свой аккаунт с помощью двухфакторной аутентификации',
      priority: SecurityRecommendationPriority.high,
      action: 'Включить',
    ),
  ];
});

/// Модель рекомендации по безопасности
class SecurityRecommendation {
  const SecurityRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.action,
    this.isCompleted = false,
  });

  factory SecurityRecommendation.fromMap(Map<String, dynamic> map) =>
      SecurityRecommendation(
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
  final String id;
  final String title;
  final String description;
  final SecurityRecommendationPriority priority;
  final String action;
  final bool isCompleted;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'action': action,
        'isCompleted': isCompleted,
      };

  SecurityRecommendation copyWith({
    String? id,
    String? title,
    String? description,
    SecurityRecommendationPriority? priority,
    String? action,
    bool? isCompleted,
  }) =>
      SecurityRecommendation(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        priority: priority ?? this.priority,
        action: action ?? this.action,
        isCompleted: isCompleted ?? this.isCompleted,
      );
}

/// Приоритеты рекомендаций по безопасности
enum SecurityRecommendationPriority {
  low,
  medium,
  high,
  critical,
}
