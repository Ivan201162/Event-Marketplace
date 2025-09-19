import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recommendation_providers.dart';
import 'specialist_card.dart';

/// Секция рекомендаций на главном экране
class RecommendationsSection extends ConsumerWidget {
  const RecommendationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(userRecommendationsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Рекомендуем вам',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Переход к полному списку рекомендаций
                },
                child: const Text('Все рекомендации'),
              ),
            ],
          ),
        ),
        recommendationsAsync.when(
          data: (recommendations) {
            if (recommendations.isEmpty) {
              return _buildEmptyState();
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recommendations.length,
                itemBuilder: (context, index) {
                  final specialist = recommendations[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 12),
                    child: SpecialistCard(
                      specialist: specialist,
                      onTap: () {
                        // TODO: Переход к профилю специалиста
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: _buildLoadingState,
          error: (error, stack) => _buildErrorState(error.toString()),
        ),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.recommend,
                size: 48,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text(
                'Пока нет рекомендаций',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              Text(
                'Забронируйте услугу, чтобы получить персональные рекомендации',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingState() => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (context, index) => Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 16,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildErrorState(String error) => Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red[400],
              ),
              const SizedBox(height: 8),
              const Text(
                'Ошибка загрузки рекомендаций',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}
