import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/widgets/rating_widget.dart';
import 'package:flutter/material.dart';

/// Виджет для отображения статистики отзывов
class ReviewStatsWidget extends StatelessWidget {
  const ReviewStatsWidget({required this.stats, super.key});

  final ReviewStats stats;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Общий рейтинг
            Row(
              children: [
                // Большой рейтинг
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                    ),
                    RatingWidget(rating: stats.averageRating, starSize: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalReviews} отзывов',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Распределение рейтингов
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Распределение оценок',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        final count =
                            stats.ratingDistribution[rating.toString()] ?? 0;
                        final percentage = stats.getRatingPercentage(rating);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              // Звезда
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber,),
                              const SizedBox(width: 8),

                              // Номер рейтинга
                              SizedBox(
                                width: 12,
                                child: Text(
                                  rating.toString(),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Прогресс-бар
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.amber.withValues(alpha: 0.7),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Количество
                              SizedBox(
                                width: 24,
                                child: Text(
                                  count.toString(),
                                  style: Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Компактный виджет рейтинга для карточек
class CompactRatingWidget extends StatelessWidget {
  const CompactRatingWidget({
    required this.rating, required this.reviewCount, super.key,
    this.showReviewCount = true,
  });

  final double rating;
  final int reviewCount;
  final bool showReviewCount;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingWidget(rating: rating, starSize: 16),
          if (showReviewCount && reviewCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '($reviewCount)',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      );
}
