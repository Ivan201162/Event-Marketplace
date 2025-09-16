import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recommendation.dart';
import '../models/specialist.dart';
import '../providers/recommendation_providers.dart';
import 'animated_page_transition.dart';

/// Виджет для отображения рекомендации специалиста
class SpecialistRecommendationWidget extends ConsumerWidget {
  final SpecialistRecommendation recommendation;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onSave;

  const SpecialistRecommendationWidget({
    super.key,
    required this.recommendation,
    this.onTap,
    this.onDismiss,
    this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialist = recommendation.specialist;
    final rec = recommendation.recommendation;

    return AnimatedCard(
      onTap: () {
        // Записываем взаимодействие
        ref.read(recommendationInteractionProvider.notifier).recordInteraction(
              RecommendationInteraction(
                recommendationId: rec.id,
                specialistId: specialist.id,
                type: RecommendationInteractionType.viewed,
                timestamp: DateTime.now(),
              ),
            );
        onTap?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с типом рекомендации
          _buildRecommendationHeader(context, rec),

          const SizedBox(height: 12),

          // Информация о специалисте
          _buildSpecialistInfo(context, specialist),

          const SizedBox(height: 12),

          // Причина рекомендации
          _buildRecommendationReason(context, rec),

          const SizedBox(height: 12),

          // Действия
          _buildActions(context, ref),
        ],
      ),
    );
  }

  /// Заголовок рекомендации
  Widget _buildRecommendationHeader(
      BuildContext context, Recommendation recommendation) {
    final typeInfo = recommendation.type.info;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _parseColor(typeInfo.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            typeInfo.icon,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeInfo.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _parseColor(typeInfo.color),
                    ),
              ),
              Text(
                'Релевантность: ${(recommendation.score * 100).toInt()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Информация о специалисте
  Widget _buildSpecialistInfo(BuildContext context, Specialist specialist) {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundImage: specialist.avatarUrl != null
              ? NetworkImage(specialist.avatarUrl!)
              : null,
          child: specialist.avatarUrl == null
              ? Text(specialist.name[0].toUpperCase())
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                specialist.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                specialist.categoryDisplayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    specialist.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${specialist.reviewCount} отзывов)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${specialist.hourlyRate.toInt()} ₽/ч',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            if (specialist.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Доступен',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Причина рекомендации
  Widget _buildRecommendationReason(
      BuildContext context, Recommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              recommendation.reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Действия
  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: AnimatedButton(
            onPressed: () {
              ref
                  .read(recommendationInteractionProvider.notifier)
                  .recordInteraction(
                    RecommendationInteraction(
                      recommendationId: recommendation.recommendation.id,
                      specialistId: recommendation.specialist.id,
                      type: RecommendationInteractionType.clicked,
                      timestamp: DateTime.now(),
                    ),
                  );
              onTap?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Посмотреть профиль',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () {
            ref
                .read(recommendationInteractionProvider.notifier)
                .recordInteraction(
                  RecommendationInteraction(
                    recommendationId: recommendation.recommendation.id,
                    specialistId: recommendation.specialist.id,
                    type: RecommendationInteractionType.saved,
                    timestamp: DateTime.now(),
                  ),
                );
            onSave?.call();
          },
          icon: const Icon(Icons.bookmark_border),
          tooltip: 'Сохранить',
        ),
        IconButton(
          onPressed: () {
            ref
                .read(recommendationInteractionProvider.notifier)
                .recordInteraction(
                  RecommendationInteraction(
                    recommendationId: recommendation.recommendation.id,
                    specialistId: recommendation.specialist.id,
                    type: RecommendationInteractionType.dismissed,
                    timestamp: DateTime.now(),
                  ),
                );
            onDismiss?.call();
          },
          icon: const Icon(Icons.close),
          tooltip: 'Скрыть',
        ),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }
}

/// Виджет для отображения коллекции рекомендаций
class RecommendationCollectionWidget extends ConsumerWidget {
  final String userId;
  final RecommendationType? type;
  final int? limit;
  final bool showTitle;
  final String? title;

  const RecommendationCollectionWidget({
    super.key,
    required this.userId,
    this.type,
    this.limit,
    this.showTitle = true,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(userRecommendationsProvider(userId));

    return recommendationsAsync.when(
      data: (recommendations) {
        var filteredRecommendations = recommendations;

        if (type != null) {
          filteredRecommendations = filteredRecommendations.byType(type!);
        }

        if (limit != null) {
          filteredRecommendations =
              filteredRecommendations.take(limit!).toList();
        }

        if (filteredRecommendations.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                title ?? _getTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],
            ...filteredRecommendations
                .map((recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SpecialistRecommendationWidget(
                        recommendation: recommendation,
                        onTap: () => _showSpecialistProfile(
                            context, recommendation.specialist),
                        onDismiss: () => _dismissRecommendation(
                            context, ref, recommendation),
                        onSave: () =>
                            _saveRecommendation(context, ref, recommendation),
                      ),
                    ))
                .toList(),
          ],
        );
      },
      loading: () => _buildLoadingState(context),
      error: (error, stack) => _buildErrorState(context, error),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.recommend_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Нет рекомендаций',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Мы подберём для вас подходящих специалистов!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки рекомендаций',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    if (type == null) return 'Рекомендации для вас';

    switch (type!) {
      case RecommendationType.similarSpecialists:
        return 'Похожие специалисты';
      case RecommendationType.popularInCategory:
        return 'Популярные в категории';
      case RecommendationType.recentlyViewed:
        return 'Недавно просмотренные';
      case RecommendationType.basedOnHistory:
        return 'На основе истории';
      case RecommendationType.trending:
        return 'Трендовые';
      case RecommendationType.nearby:
        return 'Рядом с вами';
      case RecommendationType.priceRange:
        return 'В вашем ценовом диапазоне';
      case RecommendationType.availability:
        return 'Доступные сейчас';
    }
  }

  void _showSpecialistProfile(BuildContext context, Specialist specialist) {
    // Здесь будет навигация к профилю специалиста
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть профиль ${specialist.name}')),
    );
  }

  void _dismissRecommendation(BuildContext context, WidgetRef ref,
      SpecialistRecommendation recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Рекомендация скрыта')),
    );
  }

  void _saveRecommendation(BuildContext context, WidgetRef ref,
      SpecialistRecommendation recommendation) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Рекомендация сохранена')),
    );
  }
}

/// Виджет для отображения блока "Похожие специалисты"
class SimilarSpecialistsWidget extends ConsumerWidget {
  final String specialistId;
  final int limit;

  const SimilarSpecialistsWidget({
    super.key,
    required this.specialistId,
    this.limit = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similarAsync =
        ref.watch(similarSpecialistsRecommendationsProvider(specialistId));

    return similarAsync.when(
      data: (similar) {
        if (similar.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Похожие специалисты',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                itemBuilder: (context, index) {
                  final recommendation = similar[index];
                  return SizedBox(
                    width: 280,
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < similar.length - 1 ? 16 : 0,
                      ),
                      child: SpecialistRecommendationWidget(
                        recommendation: recommendation,
                        onTap: () => _showSpecialistProfile(
                            context, recommendation.specialist),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showSpecialistProfile(BuildContext context, Specialist specialist) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть профиль ${specialist.name}')),
    );
  }
}
