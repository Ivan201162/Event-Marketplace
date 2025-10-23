import 'package:flutter/material.dart';

/// Виджет для отображения рейтинга звездами
class RatingWidget extends StatelessWidget {
  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.starSize = 20.0,
    this.color = Colors.amber,
    this.onRatingChanged,
    this.isInteractive = false,
  });

  final double rating;
  final int maxRating;
  final double starSize;
  final Color color;
  final ValueChanged<double>? onRatingChanged;
  final bool isInteractive;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(maxRating, (index) {
          final starIndex = index + 1;
          final isFilled = starIndex <= rating;
          final isHalfFilled = starIndex - 0.5 <= rating && starIndex > rating;

          return GestureDetector(
            onTap: isInteractive && onRatingChanged != null
                ? () => onRatingChanged!(starIndex.toDouble())
                : null,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                isFilled
                    ? Icons.star
                    : isHalfFilled
                        ? Icons.star_half
                        : Icons.star_border,
                size: starSize,
                color: color,
              ),
            ),
          );
        }),
      );
}

/// Виджет для отображения рейтинга с числом
class RatingDisplayWidget extends StatelessWidget {
  const RatingDisplayWidget({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.showCount = true,
    this.starSize = 16.0,
    this.textStyle,
  });

  final double rating;
  final int reviewCount;
  final bool showCount;
  final double starSize;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle =
        theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingWidget(rating: rating, starSize: starSize),
        const SizedBox(width: 4),
        Text(rating.toStringAsFixed(1), style: textStyle ?? defaultTextStyle),
        if (showCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: (textStyle ?? defaultTextStyle)?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ],
    );
  }
}

/// Виджет для отображения распределения рейтингов
class RatingDistributionWidget extends StatelessWidget {
  const RatingDistributionWidget({
    super.key,
    required this.ratingDistribution,
    required this.totalReviews,
    this.maxRating = 5,
  });

  final Map<int, int> ratingDistribution;
  final int totalReviews;
  final int maxRating;

  @override
  Widget build(BuildContext context) {
    if (totalReviews == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(maxRating, (index) {
        final rating = maxRating - index;
        final count = ratingDistribution[rating] ?? 0;
        final percentage = totalReviews > 0 ? count / totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '$rating',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                textWidthBasis: TextWidthBasis.longestLine,
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, size: 12, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Виджет для выбора рейтинга
class RatingSelectorWidget extends StatelessWidget {
  const RatingSelectorWidget({
    super.key,
    required this.rating,
    required this.onRatingChanged,
    this.maxRating = 5,
    this.starSize = 32.0,
    this.color = Colors.amber,
  });

  final double rating;
  final ValueChanged<double> onRatingChanged;
  final int maxRating;
  final double starSize;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(maxRating, (index) {
          final starIndex = index + 1;
          final isFilled = starIndex <= rating;

          return GestureDetector(
            onTap: () => onRatingChanged(starIndex.toDouble()),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(isFilled ? Icons.star : Icons.star_border,
                  size: starSize, color: color),
            ),
          );
        }),
      );
}
