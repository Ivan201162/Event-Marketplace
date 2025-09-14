import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/recommendation_service.dart';
import '../models/recommendation.dart';
import '../models/specialist.dart';

/// Провайдер для сервиса рекомендаций
final recommendationServiceProvider = Provider<RecommendationService>((ref) {
  return RecommendationService();
});

/// Провайдер для рекомендаций пользователя
final userRecommendationsProvider = FutureProvider.family<List<SpecialistRecommendation>, String>((ref, userId) {
  final service = ref.read(recommendationServiceProvider);
  return service.getRecommendations(userId, limit: 20);
});

/// Провайдер для рекомендаций по типу
final recommendationsByTypeProvider = FutureProvider.family<List<SpecialistRecommendation>, RecommendationParams>((ref, params) {
  final service = ref.read(recommendationServiceProvider);
  return service.getRecommendations(
    params.userId,
    limit: params.limit,
    types: params.types,
  );
});

/// Параметры для получения рекомендаций
class RecommendationParams {
  final String userId;
  final int limit;
  final List<RecommendationType>? types;

  const RecommendationParams({
    required this.userId,
    this.limit = 10,
    this.types,
  });
}

/// Провайдер для похожих специалистов
final similarSpecialistsProvider = FutureProvider.family<List<Specialist>, String>((ref, specialistId) {
  final service = ref.read(recommendationServiceProvider);
  // Здесь можно добавить логику для получения похожих специалистов
  // Пока возвращаем пустой список
  return Future.value([]);
});

/// Провайдер для популярных в категории
final popularInCategoryProvider = FutureProvider.family<List<Specialist>, SpecialistCategory>((ref, category) {
  final service = ref.read(recommendationServiceProvider);
  // Здесь можно добавить логику для получения популярных в категории
  // Пока возвращаем пустой список
  return Future.value([]);
});

/// Провайдер для управления рекомендациями
final recommendationManagerProvider = Provider<RecommendationManager>((ref) {
  return RecommendationManager(ref.read(recommendationServiceProvider));
});

/// Менеджер рекомендаций
class RecommendationManager {
  final RecommendationService _service;

  RecommendationManager(this._service);

  /// Получить рекомендации для пользователя
  Future<List<SpecialistRecommendation>> getRecommendations(
    String userId, {
    int limit = 10,
    List<RecommendationType>? types,
  }) async {
    return await _service.getRecommendations(
      userId,
      limit: limit,
      types: types,
    );
  }

  /// Обновить рекомендации
  Future<void> refreshRecommendations(String userId) async {
    await _service.refreshRecommendations(userId);
  }

  /// Получить рекомендации по типу
  Future<List<SpecialistRecommendation>> getRecommendationsByType(
    String userId,
    RecommendationType type, {
    int limit = 10,
  }) async {
    return await _service.getRecommendations(
      userId,
      limit: limit,
      types: [type],
    );
  }
}

/// Провайдер для статистики рекомендаций
final recommendationStatsProvider = FutureProvider.family<RecommendationStats, String>((ref, userId) {
  final recommendationsAsync = ref.watch(userRecommendationsProvider(userId));
  
  return recommendationsAsync.when(
    data: (recommendations) async {
      final stats = RecommendationStats(
        totalRecommendations: recommendations.length,
        byType: recommendations.groupedByType.map(
          (type, recs) => MapEntry(type, recs.length),
        ),
        averageScore: recommendations.isNotEmpty
            ? recommendations.map((r) => r.relevanceScore).reduce((a, b) => a + b) / recommendations.length
            : 0.0,
        topTypes: recommendations.groupedByType.entries
            .toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length))
            ..take(3)
            .map((e) => e.key)
            .toList(),
      );
      return stats;
    },
    loading: () => Future.value(RecommendationStats.empty()),
    error: (_, __) => Future.value(RecommendationStats.empty()),
  );
});

/// Статистика рекомендаций
class RecommendationStats {
  final int totalRecommendations;
  final Map<RecommendationType, int> byType;
  final double averageScore;
  final List<RecommendationType> topTypes;

  const RecommendationStats({
    required this.totalRecommendations,
    required this.byType,
    required this.averageScore,
    required this.topTypes,
  });

  factory RecommendationStats.empty() {
    return const RecommendationStats(
      totalRecommendations: 0,
      byType: {},
      averageScore: 0.0,
      topTypes: [],
    );
  }
}

/// Провайдер для отслеживания взаимодействий с рекомендациями
final recommendationInteractionProvider = StateNotifierProvider<RecommendationInteractionNotifier, RecommendationInteractionState>((ref) {
  return RecommendationInteractionNotifier();
});

/// Состояние взаимодействий с рекомендациями
class RecommendationInteractionState {
  final Map<String, List<RecommendationInteraction>> interactions;
  final Map<String, double> specialistScores;

  const RecommendationInteractionState({
    this.interactions = const {},
    this.specialistScores = const {},
  });

  RecommendationInteractionState copyWith({
    Map<String, List<RecommendationInteraction>>? interactions,
    Map<String, double>? specialistScores,
  }) {
    return RecommendationInteractionState(
      interactions: interactions ?? this.interactions,
      specialistScores: specialistScores ?? this.specialistScores,
    );
  }
}

/// Взаимодействие с рекомендацией
class RecommendationInteraction {
  final String recommendationId;
  final String specialistId;
  final RecommendationInteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const RecommendationInteraction({
    required this.recommendationId,
    required this.specialistId,
    required this.type,
    required this.timestamp,
    this.metadata = const {},
  });
}

/// Типы взаимодействий с рекомендациями
enum RecommendationInteractionType {
  viewed,      // Просмотр
  clicked,     // Клик
  booked,      // Бронирование
  dismissed,   // Отклонение
  saved,       // Сохранение
}

/// Нотификатор для взаимодействий с рекомендациями
class RecommendationInteractionNotifier extends StateNotifier<RecommendationInteractionState> {
  RecommendationInteractionNotifier() : super(const RecommendationInteractionState());

  /// Записать взаимодействие
  void recordInteraction(RecommendationInteraction interaction) {
    final userId = 'current_user'; // В реальном приложении получать из контекста
    
    final userInteractions = state.interactions[userId] ?? [];
    userInteractions.add(interaction);
    
    // Обновляем оценки специалистов
    final specialistScores = Map<String, double>.from(state.specialistScores);
    final currentScore = specialistScores[interaction.specialistId] ?? 0.0;
    
    switch (interaction.type) {
      case RecommendationInteractionType.viewed:
        specialistScores[interaction.specialistId] = currentScore + 0.1;
        break;
      case RecommendationInteractionType.clicked:
        specialistScores[interaction.specialistId] = currentScore + 0.3;
        break;
      case RecommendationInteractionType.booked:
        specialistScores[interaction.specialistId] = currentScore + 1.0;
        break;
      case RecommendationInteractionType.dismissed:
        specialistScores[interaction.specialistId] = currentScore - 0.2;
        break;
      case RecommendationInteractionType.saved:
        specialistScores[interaction.specialistId] = currentScore + 0.5;
        break;
    }
    
    state = state.copyWith(
      interactions: {
        ...state.interactions,
        userId: userInteractions,
      },
      specialistScores: specialistScores,
    );
  }

  /// Получить оценку специалиста
  double getSpecialistScore(String specialistId) {
    return state.specialistScores[specialistId] ?? 0.0;
  }

  /// Получить взаимодействия пользователя
  List<RecommendationInteraction> getUserInteractions(String userId) {
    return state.interactions[userId] ?? [];
  }

  /// Очистить взаимодействия
  void clearInteractions() {
    state = const RecommendationInteractionState();
  }
}

/// Провайдер для персональных рекомендаций
final personalizedRecommendationsProvider = FutureProvider.family<List<SpecialistRecommendation>, String>((ref, userId) {
  final service = ref.read(recommendationServiceProvider);
  final interactionState = ref.watch(recommendationInteractionProvider);
  
  return service.getRecommendations(userId, limit: 15).then((recommendations) {
    // Сортируем рекомендации на основе взаимодействий пользователя
    return recommendations..sort((a, b) {
      final scoreA = interactionState.specialistScores[a.specialist.id] ?? 0.0;
      final scoreB = interactionState.specialistScores[b.specialist.id] ?? 0.0;
      
      // Комбинируем оценку рекомендации с оценкой взаимодействий
      final finalScoreA = a.relevanceScore + scoreA * 0.3;
      final finalScoreB = b.relevanceScore + scoreB * 0.3;
      
      return finalScoreB.compareTo(finalScoreA);
    });
  });
});

/// Провайдер для рекомендаций "Похожие специалисты"
final similarSpecialistsRecommendationsProvider = FutureProvider.family<List<SpecialistRecommendation>, String>((ref, specialistId) {
  final service = ref.read(recommendationServiceProvider);
  // Здесь можно добавить логику для получения похожих специалистов
  // Пока возвращаем пустой список
  return Future.value([]);
});

/// Провайдер для рекомендаций "Популярные в категории"
final categoryPopularRecommendationsProvider = FutureProvider.family<List<SpecialistRecommendation>, SpecialistCategory>((ref, category) {
  final service = ref.read(recommendationServiceProvider);
  // Здесь можно добавить логику для получения популярных в категории
  // Пока возвращаем пустой список
  return Future.value([]);
});
