import 'package:flutter/material.dart';

/// Виджет сводки по рейтингу
class RatingSummaryWidget extends StatelessWidget {
  const RatingSummaryWidget({
    required this.averageRating, required this.totalReviews, required this.ratingDistribution, super.key,
  });
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Основная информация о рейтинге
            _buildMainRating(context),

            const SizedBox(height: 20),

            // Распределение рейтингов
            _buildRatingDistribution(context),
          ],
        ),
      );

  Widget _buildMainRating(BuildContext context) => Row(
        children: [
          // Большой рейтинг
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getRatingColor(),
                    ),
              ),
              _buildStars(averageRating, size: 24),
              const SizedBox(height: 4),
              Text(
                '$totalReviews ${_getReviewsText(totalReviews)}',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(width: 30),

          // Дополнительная информация
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRatingInfo('Отлично', 5, Colors.green),
                const SizedBox(height: 8),
                _buildRatingInfo('Хорошо', 4, Colors.lightGreen),
                const SizedBox(height: 8),
                _buildRatingInfo('Удовлетворительно', 3, Colors.orange),
                const SizedBox(height: 8),
                _buildRatingInfo('Плохо', 2, Colors.red),
                const SizedBox(height: 8),
                _buildRatingInfo('Очень плохо', 1, Colors.red[700]!),
              ],
            ),
          ),
        ],
      );

  Widget _buildRatingInfo(String label, int rating, Color color) {
    final count = ratingDistribution[rating] ?? 0;
    final percentage = totalReviews > 0 ? (count / totalReviews * 100) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildRatingDistribution(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Распределение оценок',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // График распределения
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = 5 - index;
              final count = ratingDistribution[rating] ?? 0;
              final percentage =
                  totalReviews > 0 ? (count / totalReviews * 100) : 0.0;

              return Column(
                children: [
                  // Столбец
                  Container(
                    width: 30,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 30,
                          height: (percentage / 100) * 80,
                          decoration: BoxDecoration(
                            color: _getRatingColor(),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Рейтинг
                  Text('$rating',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,),),

                  const SizedBox(height: 4),

                  // Количество
                  Text('$count',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),),
                ],
              );
            }),
          ),
        ],
      );

  Widget _buildStars(double rating, {double size = 20}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starRating = index + 1;
          if (rating >= starRating) {
            return Icon(Icons.star, color: Colors.amber, size: size);
          } else if (rating > index) {
            return Icon(Icons.star_half, color: Colors.amber, size: size);
          } else {
            return Icon(Icons.star_border, color: Colors.amber, size: size);
          }
        }),
      );

  Color _getRatingColor() => averageRating >= 4.5
      ? Colors.green
      : averageRating >= 3.5
          ? Colors.lightGreen
          : averageRating >= 2.5
              ? Colors.orange
              : averageRating >= 1.5
                  ? Colors.red
                  : Colors.red[700]!;

  String _getReviewsText(int count) => count == 0
      ? 'отзывов'
      : count == 1
          ? 'отзыв'
          : count >= 2 && count <= 4
              ? 'отзыва'
              : 'отзывов';
}
