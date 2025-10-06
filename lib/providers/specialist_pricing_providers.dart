import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../services/specialist_pricing_service.dart';

/// Провайдер сервиса цен специалистов
final specialistPricingServiceProvider =
    Provider<SpecialistPricingService>((ref) => SpecialistPricingService());

/// Провайдер состояния цен специалиста
final specialistPricingProvider =
    StateNotifierProvider<SpecialistPricingNotifier, SpecialistPricingState>(
        (ref) {
  final service = ref.watch(specialistPricingServiceProvider);
  return SpecialistPricingNotifier(service);
});

/// Состояние цен специалиста
class SpecialistPricingState {
  const SpecialistPricingState({
    this.stats,
    this.history = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final SpecialistPricingStats? stats;
  final List<PriceHistoryEntry> history;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  SpecialistPricingState copyWith({
    SpecialistPricingStats? stats,
    List<PriceHistoryEntry>? history,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      SpecialistPricingState(
        stats: stats ?? this.stats,
        history: history ?? this.history,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// StateNotifier для управления ценами специалиста
class SpecialistPricingNotifier extends StateNotifier<SpecialistPricingState> {
  SpecialistPricingNotifier(this._service)
      : super(const SpecialistPricingState());

  final SpecialistPricingService _service;

  /// Загрузить статистику цен специалиста
  Future<void> loadSpecialistPricingStats(String specialistId) async {
    state = state.copyWith(isLoading: true);

    try {
      final stats = await _service.getSpecialistPricingStats(specialistId);

      state = state.copyWith(
        stats: stats,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить историю цен специалиста
  Future<void> loadSpecialistPriceHistory(String specialistId) async {
    state = state.copyWith(isLoading: true);

    try {
      final history = await _service.getSpecialistPriceHistory(specialistId);

      state = state.copyWith(
        history: history,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Загрузить все данные о ценах специалиста
  Future<void> loadAllPricingData(String specialistId) async {
    state = state.copyWith(isLoading: true);

    try {
      final stats = await _service.getSpecialistPricingStats(specialistId);
      final history = await _service.getSpecialistPriceHistory(specialistId);

      state = state.copyWith(
        stats: stats,
        history: history,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Получить средний прайс специалиста
  Future<double> getAveragePriceForSpecialist(String specialistId) async {
    try {
      return await _service.getAveragePriceForSpecialist(specialistId);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Получить средний прайс по категории
  Future<double> getAveragePriceForCategory(SpecialistCategory category) async {
    try {
      return await _service.getAveragePriceForCategory(category);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Обновить средний прайс специалиста
  Future<void> updateSpecialistAveragePrice(String specialistId) async {
    try {
      await _service.updateSpecialistAveragePrice(specialistId);
      // Перезагружаем данные после обновления
      await loadAllPricingData(specialistId);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }

  /// Очистить данные
  void clearData() {
    state = state.copyWith(
      history: [],
    );
  }
}

/// Провайдер для получения статистики цен специалиста
final specialistPricingStatsProvider =
    FutureProvider.family<SpecialistPricingStats, String>(
        (ref, specialistId) async {
  final service = ref.watch(specialistPricingServiceProvider);
  return service.getSpecialistPricingStats(specialistId);
});

/// Провайдер для получения среднего прайса специалиста
final specialistAveragePriceProvider =
    FutureProvider.family<double, String>((ref, specialistId) async {
  final service = ref.watch(specialistPricingServiceProvider);
  return service.getAveragePriceForSpecialist(specialistId);
});

/// Провайдер для получения среднего прайса по категории
final categoryAveragePriceProvider =
    FutureProvider.family<double, SpecialistCategory>((ref, category) async {
  final service = ref.watch(specialistPricingServiceProvider);
  return service.getAveragePriceForCategory(category);
});

/// Провайдер для получения истории цен специалиста
final specialistPriceHistoryProvider =
    FutureProvider.family<List<PriceHistoryEntry>, String>(
        (ref, specialistId) async {
  final service = ref.watch(specialistPricingServiceProvider);
  return service.getSpecialistPriceHistory(specialistId);
});
