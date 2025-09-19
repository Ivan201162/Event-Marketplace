import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/app_update_service.dart';

/// Провайдер для управления обновлениями приложения
final appUpdateProvider = NotifierProvider<AppUpdateNotifier, AppUpdateState>(
    () => AppUpdateNotifier());

/// Провайдер для информации о текущей версии
final currentVersionProvider = FutureProvider<PackageInfo>(
    (ref) async => AppUpdateService.getCurrentVersionInfo());

/// Провайдер для проверки обновлений
final updateCheckProvider = FutureProvider<UpdateInfo?>(
    (ref) async => AppUpdateService.checkForUpdates());

/// Состояние обновлений приложения
class AppUpdateState {
  const AppUpdateState({
    this.isChecking = false,
    this.updateInfo,
    this.error,
    this.isDismissed = false,
    this.lastCheckTime,
  });
  final bool isChecking;
  final UpdateInfo? updateInfo;
  final String? error;
  final bool isDismissed;
  final DateTime? lastCheckTime;

  AppUpdateState copyWith({
    bool? isChecking,
    UpdateInfo? updateInfo,
    String? error,
    bool? isDismissed,
    DateTime? lastCheckTime,
  }) =>
      AppUpdateState(
        isChecking: isChecking ?? this.isChecking,
        updateInfo: updateInfo ?? this.updateInfo,
        error: error ?? this.error,
        isDismissed: isDismissed ?? this.isDismissed,
        lastCheckTime: lastCheckTime ?? this.lastCheckTime,
      );

  /// Получить статус обновления
  String get updateStatus {
    if (isChecking) return 'Проверка обновлений...';
    if (error != null) return 'Ошибка проверки';
    if (updateInfo?.isUpdateAvailable ?? false) return 'Доступно обновление';
    return 'Приложение актуально';
  }

  /// Получить цвет статуса
  int get statusColor {
    if (isChecking) return 0xFF2196F3; // Синий
    if (error != null) return 0xFFF44336; // Красный
    if (updateInfo?.isUpdateAvailable ?? false) return 0xFFFF9800; // Оранжевый
    return 0xFF4CAF50; // Зеленый
  }
}

/// Нотификатор для управления обновлениями
class AppUpdateNotifier extends Notifier<AppUpdateState> {
  @override
  AppUpdateState build() {
    _initialize();
    return const AppUpdateState();
  }

  /// Инициализация
  Future<void> _initialize() async {
    await checkForUpdates();
  }

  /// Проверить наличие обновлений
  Future<void> checkForUpdates() async {
    state = state.copyWith(isChecking: true);

    try {
      final updateInfo = await AppUpdateService.checkForUpdates();

      if (updateInfo != null) {
        // Проверяем, не была ли версия отклонена
        final isDismissed =
            await AppUpdateService.isVersionDismissed(updateInfo.latestVersion);

        state = state.copyWith(
          isChecking: false,
          updateInfo: updateInfo,
          isDismissed: isDismissed,
          lastCheckTime: updateInfo.checkTime,
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          error: 'Не удалось получить информацию об обновлениях',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  /// Принудительная проверка обновлений
  Future<void> forceCheckForUpdates() async {
    state = state.copyWith(isChecking: true);

    try {
      final updateInfo = await AppUpdateService.forceCheckForUpdates();

      if (updateInfo != null) {
        final isDismissed =
            await AppUpdateService.isVersionDismissed(updateInfo.latestVersion);

        state = state.copyWith(
          isChecking: false,
          updateInfo: updateInfo,
          isDismissed: isDismissed,
          lastCheckTime: updateInfo.checkTime,
        );
      } else {
        state = state.copyWith(
          isChecking: false,
          error: 'Не удалось получить информацию об обновлениях',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isChecking: false,
        error: e.toString(),
      );
    }
  }

  /// Отклонить обновление
  Future<void> dismissUpdate() async {
    if (state.updateInfo != null) {
      await AppUpdateService.dismissVersion(state.updateInfo!.latestVersion);
      state = state.copyWith(isDismissed: true);
    }
  }

  /// Открыть страницу загрузки
  Future<void> openDownloadPage() async {
    if (state.updateInfo?.downloadUrl != null) {
      await AppUpdateService.openDownloadPage(state.updateInfo!.downloadUrl);
    }
  }

  /// Очистить кэш обновлений
  Future<void> clearUpdateCache() async {
    await AppUpdateService.clearUpdateCache();
    state = state.copyWith(
      isDismissed: false,
    );
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith();
  }

  /// Сбросить состояние отклонения
  void resetDismissed() {
    state = state.copyWith(isDismissed: false);
  }
}

/// Провайдер для проверки, нужно ли показывать уведомление об обновлении
final shouldShowUpdateNotificationProvider = Provider<bool>((ref) {
  final updateState = ref.watch(appUpdateProvider);

  return updateState.updateInfo?.isUpdateAvailable ??
      false && !updateState.isDismissed && !updateState.isChecking;
});

/// Провайдер для получения информации о версии для отображения
final versionDisplayProvider = Provider<String>((ref) {
  final currentVersion = ref.watch(currentVersionProvider);

  return currentVersion.when(
    data: (packageInfo) =>
        'v${packageInfo.version} (${packageInfo.buildNumber})',
    loading: () => 'Загрузка...',
    error: (_, __) => 'Ошибка',
  );
});

/// Провайдер для получения детальной информации о версии
final versionDetailsProvider = Provider<VersionDetails?>((ref) {
  final currentVersion = ref.watch(currentVersionProvider);
  final updateState = ref.watch(appUpdateProvider);

  return currentVersion.when(
    data: (packageInfo) => VersionDetails(
      currentVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
      appName: packageInfo.appName,
      updateInfo: updateState.updateInfo,
    ),
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Детальная информация о версии
class VersionDetails {
  const VersionDetails({
    required this.currentVersion,
    required this.buildNumber,
    required this.packageName,
    required this.appName,
    this.updateInfo,
  });
  final String currentVersion;
  final String buildNumber;
  final String packageName;
  final String appName;
  final UpdateInfo? updateInfo;

  /// Получить полную информацию о версии
  String get fullVersionInfo =>
      '$appName v$currentVersion (build $buildNumber)';

  /// Проверить, доступно ли обновление
  bool get hasUpdateAvailable => updateInfo?.isUpdateAvailable ?? false;

  /// Получить тип обновления
  UpdateType? get updateType => updateInfo?.updateType;

  /// Получить описание обновления
  String get updateDescription {
    if (updateInfo == null) return 'Обновления не найдены';
    return 'Доступна версия ${updateInfo!.latestVersion}';
  }
}
