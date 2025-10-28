import 'package:event_marketplace_app/models/recommendation_interaction.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для управления взаимодействиями с рекомендациями (мигрирован с StateNotifierProvider)
final recommendationInteractionProvider = NotifierProvider<
    RecommendationInteractionNotifier, List<RecommendationInteraction>>(
  RecommendationInteractionNotifier.new,
);

/// Нотификатор для взаимодействий с рекомендациями (мигрирован с StateNotifier)
class RecommendationInteractionNotifier
    extends Notifier<List<RecommendationInteraction>> {
  @override
  List<RecommendationInteraction> build() {
    return [];
  }

  /// Записать взаимодействие
  void recordInteraction(RecommendationInteraction interaction) {
    state = [...state, interaction];
  }

  /// Получить взаимодействия для рекомендации
  List<RecommendationInteraction> getInteractionsForRecommendation(
          String recommendationId,) =>
      state
          .where(
              (interaction) => interaction.recommendationId == recommendationId,)
          .toList();

  /// Получить взаимодействия для специалиста
  List<RecommendationInteraction> getInteractionsForSpecialist(
          String specialistId,) =>
      state
          .where((interaction) => interaction.specialistId == specialistId)
          .toList();

  /// Очистить все взаимодействия
  void clearInteractions() {
    state = [];
  }
}
