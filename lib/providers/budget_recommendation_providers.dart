import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../services/budget_recommendation_service.dart';

/// Провайдер сервиса рекомендаций по бюджету
final budgetRecommendationServiceProvider =
    Provider<BudgetRecommendationService>(
  (ref) => BudgetRecommendationService(),
);

/// Провайдер состояния рекомендаций по бюджету (мигрирован с StateNotifierProvider)
final budgetRecommendationsProvider =
    NotifierProvider<BudgetRecommendationsNotifier, BudgetRecommendationsState>(
        () {
  return BudgetRecommendationsNotifier();
});

/// Состояние рекомендаций по бюджету
class BudgetRecommendationsState {
  const BudgetRecommendationsState({
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final List<BudgetRecommendation> recommendations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  BudgetRecommendationsState copyWith({
    List<BudgetRecommendation>? recommendations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      BudgetRecommendationsState(
        recommendations: recommendations ?? this.recommendations,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Notifier для управления рекомендациями по бюджету (мигрирован с StateNotifier)
class BudgetRecommendationsNotifier
    extends Notifier<BudgetRecommendationsState> {
  @override
  BudgetRecommendationsState build() {
    return const BudgetRecommendationsState();
  }

  BudgetRecommendationService get _service =>
      ref.read(budgetRecommendationServiceProvider);

  /// Загрузить рекомендации по бюджету
  Future<void> loadBudgetRecommendations({
    required double currentBudget,
    required List<String> selectedSpecialistIds,
    required String userId,
  }) async {
    if (selectedSpecialistIds.isEmpty) {
      state = state.copyWith(recommendations: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final recommendations = await _service.getBudgetRecommendations(
        currentBudget: currentBudget,
        selectedSpecialistIds: selectedSpecialistIds,
        userId: userId,
      );

      state = state.copyWith(
        recommendations: recommendations,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Получить минимальную цену для категории
  Future<double> getMinimumPriceForCategory(SpecialistCategory category) async {
    try {
      return await _service.getMinimumPriceForCategory(category);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Получить среднюю цену для категории
  Future<double> getAveragePriceForCategory(SpecialistCategory category) async {
    try {
      return await _service.getAveragePriceForCategory(category);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
      return 0.0;
    }
  }

  /// Отметить рекомендацию как показанную
  Future<void> markAsShown(String recommendationId) async {
    try {
      await _service.markBudgetRecommendationAsShown(recommendationId);

      // Обновляем состояние
      final updatedRecommendations = state.recommendations.map((rec) {
        if (rec.id == recommendationId) {
          return BudgetRecommendation(
            id: rec.id,
            category: rec.category,
            currentBudget: rec.currentBudget,
            additionalBudget: rec.additionalBudget,
            totalBudget: rec.totalBudget,
            reason: rec.reason,
            priority: rec.priority,
            timestamp: rec.timestamp,
            isShown: true,
          );
        }
        return rec;
      }).toList();

      state = state.copyWith(recommendations: updatedRecommendations);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }

  /// Очистить рекомендации
  void clearRecommendations() {
    state = state.copyWith(recommendations: []);
  }
}

/// Провайдер для получения рекомендаций по бюджету
final budgetRecommendationsForParamsProvider = FutureProvider.family<
    List<BudgetRecommendation>, BudgetRecommendationsParams>((
  ref,
  params,
) async {
  final service = ref.watch(budgetRecommendationServiceProvider);

  if (params.selectedSpecialistIds.isEmpty) {
    return [];
  }

  return service.getBudgetRecommendations(
    currentBudget: params.currentBudget,
    selectedSpecialistIds: params.selectedSpecialistIds,
    userId: params.userId,
  );
});

/// Параметры для получения рекомендаций по бюджету
class BudgetRecommendationsParams {
  const BudgetRecommendationsParams({
    required this.currentBudget,
    required this.selectedSpecialistIds,
    required this.userId,
  });

  final double currentBudget;
  final List<String> selectedSpecialistIds;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BudgetRecommendationsParams &&
        other.currentBudget == currentBudget &&
        other.selectedSpecialistIds == selectedSpecialistIds &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(currentBudget, selectedSpecialistIds, userId);
}

/// Провайдер для получения минимальной цены категории
final minimumPriceForCategoryProvider =
    FutureProvider.family<double, SpecialistCategory>((
  ref,
  category,
) async {
  final service = ref.watch(budgetRecommendationServiceProvider);
  return service.getMinimumPriceForCategory(category);
});

/// Провайдер для получения средней цены категории
final averagePriceForCategoryProvider =
    FutureProvider.family<double, SpecialistCategory>((
  ref,
  category,
) async {
  final service = ref.watch(budgetRecommendationServiceProvider);
  return service.getAveragePriceForCategory(category);
});
