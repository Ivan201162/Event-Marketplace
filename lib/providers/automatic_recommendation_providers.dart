import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist.dart';
import '../services/automatic_recommendation_service.dart';

/// Провайдер сервиса автоматических рекомендаций
final automaticRecommendationServiceProvider = Provider<AutomaticRecommendationService>(
  (ref) => AutomaticRecommendationService(),
);

/// Провайдер состояния автоматических рекомендаций (мигрирован с StateNotifierProvider)
final automaticRecommendationsProvider =
    NotifierProvider<AutomaticRecommendationsNotifier, AutomaticRecommendationsState>(() {
      return AutomaticRecommendationsNotifier();
    });

/// Состояние автоматических рекомендаций
class AutomaticRecommendationsState {
  const AutomaticRecommendationsState({
    this.recommendations = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final List<SpecialistRecommendation> recommendations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  AutomaticRecommendationsState copyWith({
    List<SpecialistRecommendation>? recommendations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) => AutomaticRecommendationsState(
    recommendations: recommendations ?? this.recommendations,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );
}

/// Notifier для управления автоматическими рекомендациями (мигрирован с StateNotifier)
class AutomaticRecommendationsNotifier extends Notifier<AutomaticRecommendationsState> {
  @override
  AutomaticRecommendationsState build() {
    return const AutomaticRecommendationsState();
  }

  AutomaticRecommendationService get _service => ref.read(automaticRecommendationServiceProvider);

  /// Загрузить рекомендации для выбранных специалистов
  Future<void> loadRecommendations({
    required List<String> selectedSpecialistIds,
    required String userId,
  }) async {
    if (selectedSpecialistIds.isEmpty) {
      state = state.copyWith(recommendations: [], isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final recommendations = await _service.getRecommendationsForSelectedSpecialists(
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

  /// Загрузить рекомендации для конкретной категории
  Future<void> loadRecommendationsForCategory({
    required SpecialistCategory category,
    required String userId,
    List<String> excludeIds = const [],
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final recommendations = await _service.getRecommendationsForCategory(
        category: category,
        userId: userId,
        excludeIds: excludeIds,
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

  /// Отметить рекомендацию как показанную
  Future<void> markAsShown(String recommendationId) async {
    try {
      await _service.markRecommendationAsShown(recommendationId);

      // Обновляем состояние
      final updatedRecommendations = state.recommendations.map((rec) {
        if (rec.id == recommendationId) {
          return SpecialistRecommendation(
            id: rec.id,
            specialistId: rec.specialistId,
            specialist: rec.specialist,
            reason: rec.reason,
            score: rec.score,
            timestamp: rec.timestamp,
            category: rec.category,
            isAutomatic: rec.isAutomatic,
            isShown: true,
            isAccepted: rec.isAccepted,
          );
        }
        return rec;
      }).toList();

      state = state.copyWith(recommendations: updatedRecommendations);
    } on Exception catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Отметить рекомендацию как принятую
  Future<void> markAsAccepted(String recommendationId) async {
    try {
      await _service.markRecommendationAsAccepted(recommendationId);

      // Обновляем состояние
      final updatedRecommendations = state.recommendations.map((rec) {
        if (rec.id == recommendationId) {
          return SpecialistRecommendation(
            id: rec.id,
            specialistId: rec.specialistId,
            specialist: rec.specialist,
            reason: rec.reason,
            score: rec.score,
            timestamp: rec.timestamp,
            category: rec.category,
            isAutomatic: rec.isAutomatic,
            isShown: rec.isShown,
            isAccepted: true,
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

/// Провайдер для получения рекомендаций по выбранным специалистам
final selectedSpecialistsRecommendationsProvider =
    FutureProvider.family<List<SpecialistRecommendation>, SelectedSpecialistsParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(automaticRecommendationServiceProvider);

      if (params.selectedSpecialistIds.isEmpty) {
        return [];
      }

      return service.getRecommendationsForSelectedSpecialists(
        selectedSpecialistIds: params.selectedSpecialistIds,
        userId: params.userId,
      );
    });

/// Параметры для получения рекомендаций по выбранным специалистам
class SelectedSpecialistsParams {
  const SelectedSpecialistsParams({required this.selectedSpecialistIds, required this.userId});

  final List<String> selectedSpecialistIds;
  final String userId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SelectedSpecialistsParams &&
        other.selectedSpecialistIds == selectedSpecialistIds &&
        other.userId == userId;
  }

  @override
  int get hashCode => Object.hash(selectedSpecialistIds, userId);
}

/// Провайдер для получения рекомендаций по категории
final categoryRecommendationsProvider =
    FutureProvider.family<List<SpecialistRecommendation>, CategoryRecommendationsParams>((
      ref,
      params,
    ) async {
      final service = ref.watch(automaticRecommendationServiceProvider);

      return service.getRecommendationsForCategory(
        category: params.category,
        userId: params.userId,
        excludeIds: params.excludeIds,
      );
    });

/// Параметры для получения рекомендаций по категории
class CategoryRecommendationsParams {
  const CategoryRecommendationsParams({
    required this.category,
    required this.userId,
    this.excludeIds = const [],
  });

  final SpecialistCategory category;
  final String userId;
  final List<String> excludeIds;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryRecommendationsParams &&
        other.category == category &&
        other.userId == userId &&
        other.excludeIds == excludeIds;
  }

  @override
  int get hashCode => Object.hash(category, userId, excludeIds);
}
