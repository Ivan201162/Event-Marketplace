import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/offline_service.dart';

/// Провайдер для статуса подключения к интернету
final connectivityProvider = StreamProvider<bool>((ref) => OfflineService.isOnline().asStream());

/// Провайдер для статуса офлайн-режима
final offlineModeProvider = NotifierProvider<OfflineModeNotifier, OfflineModeState>(
  (ref) => OfflineModeNotifier(),
);

/// Провайдер для информации о кэше
final cacheInfoProvider = NotifierProvider<CacheInfoNotifier, CacheInfoState>(
  (ref) => CacheInfoNotifier(),
);

/// Провайдер для синхронизации данных
final syncProvider = NotifierProvider<SyncNotifier, SyncState>((ref) => SyncNotifier());

/// Состояние офлайн-режима
class OfflineModeState {
  const OfflineModeState({
    this.isOfflineMode = false,
    this.isOnline = true,
    this.lastSyncTime,
    this.isCacheStale = false,
    this.error,
  });
  final bool isOfflineMode;
  final bool isOnline;
  final DateTime? lastSyncTime;
  final bool isCacheStale;
  final String? error;

  OfflineModeState copyWith({
    bool? isOfflineMode,
    bool? isOnline,
    DateTime? lastSyncTime,
    bool? isCacheStale,
    String? error,
  }) => OfflineModeState(
    isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    isOnline: isOnline ?? this.isOnline,
    lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    isCacheStale: isCacheStale ?? this.isCacheStale,
    error: error ?? this.error,
  );

  /// Получить статус подключения
  String get connectionStatus {
    if (isOfflineMode) return 'Офлайн-режим';
    if (isOnline) return 'Подключено';
    return 'Нет подключения';
  }

  /// Получить иконку статуса
  String get statusIcon {
    if (isOfflineMode) return '📱';
    if (isOnline) return '🌐';
    return '❌';
  }

  /// Получить цвет статуса
  int get statusColor {
    if (isOfflineMode) return 0xFFFF9800; // Оранжевый
    if (isOnline) return 0xFF4CAF50; // Зеленый
    return 0xFFF44336; // Красный
  }
}

/// Состояние информации о кэше
class CacheInfoState {
  const CacheInfoState({
    this.isLoading = false,
    this.cacheSize = 0,
    this.cacheKeys = const [],
    this.cacheVersion = 0,
    this.error,
  });
  final bool isLoading;
  final int cacheSize;
  final List<String> cacheKeys;
  final int cacheVersion;
  final String? error;

  CacheInfoState copyWith({
    bool? isLoading,
    int? cacheSize,
    List<String>? cacheKeys,
    int? cacheVersion,
    String? error,
  }) => CacheInfoState(
    isLoading: isLoading ?? this.isLoading,
    cacheSize: cacheSize ?? this.cacheSize,
    cacheKeys: cacheKeys ?? this.cacheKeys,
    cacheVersion: cacheVersion ?? this.cacheVersion,
    error: error ?? this.error,
  );

  /// Получить отформатированный размер кэша
  String get formattedCacheSize => OfflineService.formatBytes(cacheSize);

  /// Получить количество элементов в кэше
  int get cacheItemsCount => cacheKeys.length;
}

/// Состояние синхронизации
class SyncState {
  const SyncState({
    this.isSyncing = false,
    this.lastSyncTime,
    this.error,
    this.syncProgress = 0,
    this.currentOperation,
  });
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final String? error;
  final int syncProgress;
  final String? currentOperation;

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncTime,
    String? error,
    int? syncProgress,
    String? currentOperation,
  }) => SyncState(
    isSyncing: isSyncing ?? this.isSyncing,
    lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    error: error ?? this.error,
    syncProgress: syncProgress ?? this.syncProgress,
    currentOperation: currentOperation ?? this.currentOperation,
  );

  /// Получить время последней синхронизации в читаемом виде
  String get formattedLastSyncTime {
    if (lastSyncTime == null) return 'Никогда';

    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);

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
}

/// Нотификатор для офлайн-режима
class OfflineModeNotifier extends Notifier<OfflineModeState> {
  OfflineModeNotifier() : super() {
    _initialize();
  }

  /// Инициализация
  Future<void> _initialize() async {
    await _updateConnectionStatus();
    await _updateOfflineMode();
    await _updateLastSyncTime();
    await _updateCacheStatus();
  }

  /// Обновить статус подключения
  Future<void> _updateConnectionStatus() async {
    try {
      final isOnline = await OfflineService.isOnline();
      state = state.copyWith(isOnline: isOnline);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить статус офлайн-режима
  Future<void> _updateOfflineMode() async {
    try {
      final isOfflineMode = await OfflineService.isOfflineMode();
      state = state.copyWith(isOfflineMode: isOfflineMode);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить время последней синхронизации
  Future<void> _updateLastSyncTime() async {
    try {
      final lastSyncTime = await OfflineService.getLastSyncTime();
      state = state.copyWith(lastSyncTime: lastSyncTime);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить статус кэша
  Future<void> _updateCacheStatus() async {
    try {
      final isCacheStale = await OfflineService.isCacheStale();
      state = state.copyWith(isCacheStale: isCacheStale);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Переключить офлайн-режим
  Future<void> toggleOfflineMode() async {
    try {
      final newMode = !state.isOfflineMode;
      await OfflineService.setOfflineMode(newMode);
      state = state.copyWith(isOfflineMode: newMode);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Включить офлайн-режим
  Future<void> enableOfflineMode() async {
    try {
      await OfflineService.setOfflineMode(true);
      state = state.copyWith(isOfflineMode: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Отключить офлайн-режим
  Future<void> disableOfflineMode() async {
    try {
      await OfflineService.setOfflineMode(false);
      state = state.copyWith(isOfflineMode: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Обновить статус подключения
  Future<void> updateConnectionStatus() async {
    await _updateConnectionStatus();
  }

  /// Обновить все данные
  Future<void> refresh() async {
    await _initialize();
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith();
  }
}

/// Нотификатор для информации о кэше
class CacheInfoNotifier extends Notifier<CacheInfoState> {
  CacheInfoNotifier() : super() {
    _loadCacheInfo();
  }

  /// Загрузить информацию о кэше
  Future<void> _loadCacheInfo() async {
    state = state.copyWith(isLoading: true);

    try {
      final cacheSize = await OfflineService.getCacheSize();
      final cacheKeys = await OfflineService.getCacheKeys();
      final cacheVersion = await OfflineService.getCacheVersion();

      state = state.copyWith(
        isLoading: false,
        cacheSize: cacheSize,
        cacheKeys: cacheKeys,
        cacheVersion: cacheVersion,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Очистить кэш
  Future<void> clearCache() async {
    state = state.copyWith(isLoading: true);

    try {
      await OfflineService.clearCache();
      state = state.copyWith(isLoading: false, cacheSize: 0, cacheKeys: []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Обновить информацию о кэше
  Future<void> refresh() async {
    await _loadCacheInfo();
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith();
  }
}

/// Нотификатор для синхронизации
class SyncNotifier extends Notifier<SyncState> {
  SyncNotifier() : super() {
    _loadLastSyncTime();
  }

  /// Загрузить время последней синхронизации
  Future<void> _loadLastSyncTime() async {
    try {
      final lastSyncTime = await OfflineService.getLastSyncTime();
      state = state.copyWith(lastSyncTime: lastSyncTime);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Запустить синхронизацию
  Future<void> startSync() async {
    if (state.isSyncing) return;

    state = state.copyWith(
      isSyncing: true,
      syncProgress: 0,
      currentOperation: 'Подготовка к синхронизации...',
    );

    try {
      // Проверяем подключение
      final isOnline = await OfflineService.isOnline();
      if (!isOnline) {
        state = state.copyWith(isSyncing: false, error: 'Нет подключения к интернету');
        return;
      }

      // Обновляем прогресс
      state = state.copyWith(
        syncProgress: 25,
        currentOperation: 'Синхронизация пользовательских данных...',
      );

      // TODO(developer): Реализовать синхронизацию пользовательских данных
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(syncProgress: 50, currentOperation: 'Синхронизация бронирований...');

      // TODO(developer): Реализовать синхронизацию бронирований
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(syncProgress: 75, currentOperation: 'Синхронизация сообщений...');

      // TODO(developer): Реализовать синхронизацию сообщений
      await Future.delayed(const Duration(seconds: 1));

      state = state.copyWith(syncProgress: 100, currentOperation: 'Завершение синхронизации...');

      // Обновляем время последней синхронизации
      await OfflineService.updateLastSyncTime();
      await OfflineService.updateCacheVersion();

      state = state.copyWith(isSyncing: false, lastSyncTime: DateTime.now(), syncProgress: 0);
    } catch (e) {
      state = state.copyWith(isSyncing: false, error: e.toString(), syncProgress: 0);
    }
  }

  /// Остановить синхронизацию
  void stopSync() {
    state = state.copyWith(isSyncing: false, syncProgress: 0);
  }

  /// Очистить ошибки
  void clearError() {
    state = state.copyWith();
  }
}

/// Провайдер для проверки возможности выполнения операции
final canPerformOperationProvider = Provider.family<bool, String>((ref, operation) {
  final offlineState = ref.watch(offlineModeProvider);

  if (offlineState.isOfflineMode) {
    return OfflineUtils.canPerformOffline(operation);
  }

  return true; // В онлайн-режиме все операции доступны
});

/// Провайдер для получения сообщения об ограничениях
final operationLimitationProvider = Provider.family<String, String>((ref, operation) {
  final offlineState = ref.watch(offlineModeProvider);

  if (offlineState.isOfflineMode && !OfflineUtils.canPerformOffline(operation)) {
    return OfflineUtils.getOfflineLimitationMessage(operation);
  }

  return '';
});

/// Провайдер для рекомендаций офлайн-режима
final offlineRecommendationsProvider = Provider<List<String>>(
  (ref) => OfflineUtils.getOfflineRecommendations(),
);
