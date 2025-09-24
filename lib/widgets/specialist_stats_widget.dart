import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/specialist_content_service.dart';
import '../services/specialist_service.dart';

/// Виджет статистики специалиста
class SpecialistStatsWidget extends ConsumerWidget {
  const SpecialistStatsWidget({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return FutureBuilder<Map<String, dynamic>>(
      future: _getStats(ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = snapshot.data ?? {};
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Посты',
                      '${stats['postsCount'] ?? 0}',
                      Icons.post_add,
                      theme.colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Сторис',
                      '${stats['storiesCount'] ?? 0}',
                      Icons.video_call,
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Лайки',
                      '${stats['totalLikes'] ?? 0}',
                      Icons.favorite,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Комментарии',
                      '${stats['totalComments'] ?? 0}',
                      Icons.comment,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Просмотры',
                      '${stats['totalViews'] ?? 0}',
                      Icons.visibility,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Заказы',
                      '${stats['completedOrders'] ?? 0}',
                      Icons.check_circle,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getStats(WidgetRef ref) async {
    try {
      // Получаем статистику контента
      final contentStats = await ref.read(specialistContentServiceProvider).getContentStats(specialistId);
      
      // Получаем информацию о специалисте
      final specialist = await ref.read(specialistServiceProvider).getSpecialist(specialistId);
      
      return {
        ...contentStats,
        'completedOrders': specialist?.completedOrders ?? 0,
        'rating': specialist?.rating ?? 0.0,
        'reviewsCount': specialist?.reviewsCount ?? 0,
      };
    } catch (e) {
      return {};
    }
  }
}
