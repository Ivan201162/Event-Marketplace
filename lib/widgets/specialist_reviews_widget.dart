import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/providers/review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет отзывов специалиста
class SpecialistReviewsWidget extends ConsumerWidget {
  const SpecialistReviewsWidget({required this.specialistId, super.key});

  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(specialistReviewsProvider(specialistId));
    final statisticsAsync =
        ref.watch(specialistReviewStatsProvider(specialistId));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Text(
            'Отзывы',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          // Статистика отзывов
          statisticsAsync.when(
            data: (stats) => stats != null
                ? _buildReviewStatistics(stats)
                : const SizedBox.shrink(),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(error),
          ),

          const SizedBox(height: 24),

          // Список отзывов
          reviewsAsync.when(
            data: _buildReviewsList,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorWidget(error),
          ),
        ],
      ),
    );
  }

  /// Построить статистику отзывов
  Widget _buildReviewStatistics(SpecialistReviewStats statistics) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.grey[50], borderRadius: BorderRadius.circular(12),),
        child: Column(
          children: [
            // Общий рейтинг
            Row(
              children: [
                // Большой рейтинг
                Column(
                  children: [
                    Text(
                      statistics.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold,),
                    ),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < statistics.averageRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      '${statistics.totalReviews} отзывов',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(width: 24),

                // Распределение рейтингов
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(5, (index) {
                      final rating = 5 - index;
                      const count =
                          0; // TODO(developer): Implement ratingCounts
                      final percentage = statistics.totalReviews > 0
                          ? (count / statistics.totalReviews * 100)
                          : 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Text('$rating',
                                style: const TextStyle(fontSize: 12),),
                            const SizedBox(width: 8),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 12,),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber,),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('$count',
                                style: TextStyle(fontSize: 12),),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Построить список отзывов
  Widget _buildReviewsList(List<Review> reviews) {
    if (reviews.isEmpty) {
      return _buildEmptyReviews();
    }

    return Column(
      children: [
        // Заголовок списка
        Row(
          children: [
            Text(
              'Все отзывы (${reviews.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _showAllReviews(reviews),
              child: const Text('Показать все'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Список отзывов
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviews.length > 3 ? 3 : reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildReviewCard(review),
            );
          },
        ),
      ],
    );
  }

  /// Построить карточку отзыва
  Widget _buildReviewCard(Review review) => Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок отзыва
              Row(
                children: [
                  // Аватар клиента
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    child: const Text(
                      'К', // Заглушка для имени клиента
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white,),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Информация о клиенте
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Клиент ${review.clientId.substring(0, 8)}...', // Заглушка
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            // Рейтинг
                            Row(
                              children: List.generate(
                                5,
                                (index) => Icon(
                                  index < review.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${review.rating}.0',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold,),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Дата
                  Text(
                    _formatDate(review.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Заголовок отзыва
              if (review.title?.isNotEmpty ?? false) ...[
                Text(review.title!,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,),),
                const SizedBox(height: 8),
              ],

              // Комментарий
              ...[
                Text(
                  review.comment ?? '',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[700], height: 1.4,),
                ),
                const SizedBox(height: 12),
              ],

              // Теги
              if (review.tags.isNotEmpty) ...[
                // TODO(developer): Implement tags
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: review.tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4,),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      );

  /// Построить пустые отзывы
  Widget _buildEmptyReviews() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
            color: Colors.grey[50], borderRadius: BorderRadius.circular(12),),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Отзывов пока нет',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],),
            ),
            const SizedBox(height: 8),
            Text(
              'Станьте первым, кто оставит отзыв об этом специалисте',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  /// Построить виджет ошибки
  Widget _buildErrorWidget(Object error) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Ошибка загрузки отзывов: $error',
                style: TextStyle(color: Colors.red[700], fontSize: 14),
              ),
            ),
          ],
        ),
      );

  /// Показать все отзывы
  void _showAllReviews(List<Review> reviews) {
    // TODO(developer): Реализовать экран со всеми отзывами
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} нед. назад';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} мес. назад';
    } else {
      return '${(difference.inDays / 365).floor()} г. назад';
    }
  }
}
