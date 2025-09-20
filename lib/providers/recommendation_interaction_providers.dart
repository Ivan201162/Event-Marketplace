import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_interaction.dart';
import '../services/recommendation_service.dart';

/// Провайдер сервиса рекомендаций
final recommendationServiceProvider =
    Provider<RecommendationService>((ref) => RecommendationService());

/// Провайдер для взаимодействий с рекомендациями
final recommendationInteractionProvider = NotifierProvider<
    RecommendationInteractionNotifier, RecommendationInteractionState>(
  (ref) => RecommendationInteractionNotifier(),
);

/// Состояние взаимодействий с рекомендациями
class RecommendationInteractionState {
  const RecommendationInteractionState({
    this.interactions = const {},
    this.isLoading = false,
    this.error,
  });
  final Map<String, List<RecommendationInteraction>> interactions;
  final bool isLoading;
  final String? error;

  RecommendationInteractionState copyWith({
    Map<String, List<RecommendationInteraction>>? interactions,
    bool? isLoading,
    String? error,
  }) =>
      RecommendationInteractionState(
        interactions: interactions ?? this.interactions,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Нотификатор для взаимодействий с рекомендациями
class RecommendationInteractionNotifier
    extends Notifier<RecommendationInteractionState> {
  RecommendationInteractionNotifier()
      : super();

  void addInteraction(RecommendationInteraction interaction) {
    final updatedInteractions =
        Map<String, List<RecommendationInteraction>>.from(state.interactions);
    final userId = interaction.userId;
    final userInteractions = updatedInteractions[userId] ?? [];
    updatedInteractions[userId] = [...userInteractions, interaction];
    state = state.copyWith(interactions: updatedInteractions);
  }

  void removeInteraction(String userId, String interactionId) {
    final updatedInteractions =
        Map<String, List<RecommendationInteraction>>.from(state.interactions);
    final userInteractions = updatedInteractions[userId] ?? [];
    updatedInteractions[userId] =
        userInteractions.where((i) => i.id != interactionId).toList();
    state = state.copyWith(interactions: updatedInteractions);
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

/// Провайдер для похожих специалистов
final similarSpecialistsRecommendationsProvider =
    FutureProvider.family<List<Specialist>, String>((ref, specialistId) async {
  final recommendationService = ref.read(recommendationServiceProvider);
  return recommendationService.getSimilarSpecialists(specialistId);
});
