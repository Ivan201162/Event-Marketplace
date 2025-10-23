import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/recommendation.dart';
import '../services/recommendation_service.dart';

/// Провайдер для RecommendationService
final recommendationServiceProvider = Provider<RecommendationService>(
  (ref) => RecommendationService(),
);

/// Провайдер для получения рекомендаций пользователя
final userRecommendationsProvider =
    FutureProvider.family<List<Recommendation>, String>(
  (ref, userId) => ref
      .watch(recommendationServiceProvider)
      .getRecommendationsForUser(userId),
);

/// Провайдер для получения популярных специалистов
final popularSpecialistsProvider =
    FutureProvider.family<List<Recommendation>, String?>(
  (ref, userId) => ref
      .watch(recommendationServiceProvider)
      .getPopularSpecialists(userId: userId),
);

/// Провайдер для получения рекомендаций на основе истории
final historyBasedRecommendationsProvider =
    FutureProvider.family<List<Recommendation>, String>(
  (ref, userId) => ref
      .watch(recommendationServiceProvider)
      .getRecommendationsBasedOnHistory(userId),
);

/// Провайдер для получения статистики рекомендаций
final recommendationStatsProvider =
    FutureProvider.family<RecommendationStats, String>(
  (ref, userId) =>
      ref.watch(recommendationServiceProvider).getRecommendationStats(userId),
);

/// Провайдер для группированных рекомендаций
final groupedRecommendationsProvider =
    FutureProvider.family<List<RecommendationGroup>, String>((
  ref,
  userId,
) async {
  final service = ref.watch(recommendationServiceProvider);

  // Получаем все типы рекомендаций
  final userRecommendations = await service.getRecommendationsForUser(userId);
  final popularRecommendations =
      await service.getPopularSpecialists(userId: userId);
  final historyRecommendations =
      await service.getRecommendationsBasedOnHistory(userId);

  // Группируем по типам
  final groups = <RecommendationGroup>[];

  // Рекомендации на основе истории
  if (historyRecommendations.isNotEmpty) {
    groups.add(
      RecommendationGroup(
        type: RecommendationType.basedOnHistory,
        title: 'На основе ваших заказов',
        recommendations: historyRecommendations.take(6).toList(),
        description: 'Специалисты, похожие на тех, кого вы уже заказывали',
        icon: '📋',
      ),
    );
  }

  // Популярные специалисты
  if (popularRecommendations.isNotEmpty) {
    groups.add(
      RecommendationGroup(
        type: RecommendationType.popular,
        title: 'Популярные специалисты',
        recommendations: popularRecommendations.take(6).toList(),
        description: 'Самые популярные специалисты в приложении',
        icon: '⭐',
      ),
    );
  }

  // Общие рекомендации
  if (userRecommendations.isNotEmpty) {
    final otherRecommendations = userRecommendations
        .where(
          (r) =>
              r.type != RecommendationType.basedOnHistory &&
              r.type != RecommendationType.popular,
        )
        .take(6)
        .toList();

    if (otherRecommendations.isNotEmpty) {
      groups.add(
        RecommendationGroup(
          type: RecommendationType.categoryBased,
          title: 'Рекомендуем для вас',
          recommendations: otherRecommendations,
          description: 'Персональные рекомендации',
          icon: '🎯',
        ),
      );
    }
  }

  return groups;
});

/// Провайдер для получения рекомендаций по категориям
final categoryRecommendationsProvider =
    FutureProvider.family<List<Recommendation>, Map<String, dynamic>>(
        (ref, params) {
  final userId = params['userId'] as String;
  final categoryPreferences = params['categoryPreferences'] as Map<String, int>;

  return ref
      .watch(recommendationServiceProvider)
      .getRecommendationsByCategories(userId, categoryPreferences);
});

/// Провайдер для управления состоянием рекомендаций (мигрирован с StateNotifierProvider)
final recommendationStateProvider =
    NotifierProvider<RecommendationStateNotifier, RecommendationState>(
  () => RecommendationStateNotifier(),
);

/// Состояние рекомендаций
class RecommendationState {
  const RecommendationState(
      {this.isLoading = false, this.error, this.lastUpdated});

  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  RecommendationState copyWith(
          {bool? isLoading, String? error, DateTime? lastUpdated}) =>
      RecommendationState(
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Notifier для управления состоянием рекомендаций (мигрирован с StateNotifier)
class RecommendationStateNotifier extends Notifier<RecommendationState> {
  @override
  RecommendationState build() {
    return const RecommendationState();
  }

  RecommendationService get _service => ref.read(recommendationServiceProvider);

  /// Обновить рекомендации
  Future<void> refreshRecommendations(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _service.getRecommendationsForUser(userId);
      state = state.copyWith(isLoading: false, lastUpdated: DateTime.now());
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Отметить рекомендацию как просмотренную
  Future<void> markAsViewed(String recommendationId) async {
    try {
      await _service.markAsViewed(recommendationId);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Отметить рекомендацию как кликнутую
  Future<void> markAsClicked(String recommendationId) async {
    try {
      await _service.markAsClicked(recommendationId);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Отметить рекомендацию как забронированную
  Future<void> markAsBooked(String recommendationId) async {
    try {
      await _service.markAsBooked(recommendationId);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Очистить ошибку
  void clearError() {
    state = state.copyWith();
  }
}
