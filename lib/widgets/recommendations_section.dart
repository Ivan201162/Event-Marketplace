import 'package:event_marketplace_app/core/constants/app_routes.dart';
import 'package:event_marketplace_app/providers/recommendation_providers.dart';
import 'package:event_marketplace_app/widgets/recommendation_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Секция рекомендаций на главном экране
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(
      userRecommendationsProvider('current_user_id'),
    ); // TODO(developer): Get actual user ID

    return recommendationsAsync.when(
      data: (recommendations) {
        if (recommendations.isEmpty) {
          return _buildEmptyState();
        }

        return RecommendationSection(
          title: 'Мы рекомендуем',
          subtitle: 'Специалисты, которые могут вам понравиться',
          icon: '🎯',
          recommendations: recommendations,
          compact: true,
          onViewAll: () {
            context.push(AppRoutes.recommendations);
          },
          onRecommendationTap: (recommendation) {
            _onRecommendationTap(context, recommendation);
          },
          onRecommendationBook: (recommendation) {
            _onRecommendationBook(context, recommendation);
          },
        );
      },
      loading: _buildLoadingState,
      error: (error, stack) => _buildErrorState(error),
    );
  }

  void _onRecommendationTap(BuildContext context, dynamic recommendation) {
    // TODO(developer): Navigate to specialist profile
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Переход к профилю: ${recommendation.specialist.name}'),),);
  }

  void _onRecommendationBook(BuildContext context, dynamic recommendation) {
    // TODO(developer): Navigate to booking form
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
        content: Text('Бронирование: ${recommendation.specialist.name}'),),);
  }

  Widget _buildLoadingState() => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _buildErrorState(Object error) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Ошибка загрузки рекомендаций',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Widget _buildEmptyState() => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.recommend_outlined,
                  size: 48, color: Colors.grey,),
              const SizedBox(height: 16),
              const Text(
                'Пока нет рекомендаций',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Закажите услуги, чтобы получать персональные рекомендации',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
