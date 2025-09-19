import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation_interaction.dart';

/// Провайдер для управления взаимодействиями с рекомендациями
final recommendationInteractionProvider = StateNotifierProvider<
        RecommendationInteractionNotifier, List<RecommendationInteraction>>(
    (ref) => RecommendationInteractionNotifier());

/// Нотификатор для взаимодействий с рекомендациями
class RecommendationInteractionNotifier
    extends StateNotifier<List<RecommendationInteraction>> {
  RecommendationInteractionNotifier() : super([]);

  /// Записать взаимодействие
  void recordInteraction(RecommendationInteraction interaction) {
    state = [...state, interaction];
  }

  /// Получить взаимодействия для рекомендации
  List<RecommendationInteraction> getInteractionsForRecommendation(
    String recommendationId,
  ) =>
      state
          .where(
            (interaction) => interaction.recommendationId == recommendationId,
          )
          .toList();

  /// Получить взаимодействия для специалиста
  List<RecommendationInteraction> getInteractionsForSpecialist(
    String specialistId,
  ) =>
      state
          .where((interaction) => interaction.specialistId == specialistId)
          .toList();

  /// Очистить все взаимодействия
  void clearInteractions() {
    state = [];
  }
}
