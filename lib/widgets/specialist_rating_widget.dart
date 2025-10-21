import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../providers/review_providers.dart';

/// Виджет для отображения рейтинга специалиста
class SpecialistRatingWidget extends ConsumerWidget {
  const SpecialistRatingWidget({
    super.key,
    required this.specialistId,
    this.showDetails = true,
    this.compact = false,
  });

  final String specialistId;
  final bool showDetails;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewStats = ref.watch(specialistReviewStatsProvider(specialistId));

    return reviewStats.when(
      data: (stats) => stats != null ? _buildRatingContent(context, stats) : _buildNoDataState(),
      loading: _buildLoadingState,
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildRatingContent(BuildContext context, SpecialistReviewStats stats) {
    if (compact) {
      return _buildCompactRating(context, stats);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Рейтинг',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Основной рейтинг
            Row(
              children: [
                // Звезды
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < stats.averageRating.floor()
                          ? Icons.star
                          : index < stats.averageRating
                          ? Icons.star_half
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Цифровой рейтинг
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.averageRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                    Text(
                      '${stats.totalReviews} отзывов',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),

            if (showDetails && stats.totalReviews > 0) ...[
              const SizedBox(height: 16),
              _buildRatingBreakdown(context, stats),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactRating(BuildContext context, SpecialistReviewStats stats) => Row(
    children: [
      const Icon(Icons.star, color: Colors.amber, size: 16),
      const SizedBox(width: 4),
      Text(
        stats.averageRating.toStringAsFixed(1),
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[700]),
      ),
      const SizedBox(width: 4),
      Text(
        '(${stats.totalReviews})',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    ],
  );

  Widget _buildRatingBreakdown(BuildContext context, SpecialistReviewStats stats) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Распределение оценок',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),

      // Распределение по звездам
      ...List.generate(5, (index) {
        final starCount = 5 - index;
        final count = stats.ratingDistribution[starCount] ?? 0;
        final percentage = stats.totalReviews > 0 ? count / stats.totalReviews : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              // Звезда
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text('$starCount', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),

              // Прогресс-бар
              Expanded(
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(width: 8),

              // Количество
              Text('$count', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }),
    ],
  );

  Widget _buildLoadingState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Text('Загрузка рейтинга...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    ),
  );

  Widget _buildErrorState(Object error) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Ошибка загрузки рейтинга', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    ),
  );
}

/// Виджет для отображения отзывов специалиста
class SpecialistReviewsWidget extends ConsumerWidget {
  const SpecialistReviewsWidget({
    super.key,
    required this.specialistId,
    this.limit = 5,
    this.showAllButton = true,
  });

  final String specialistId;
  final int limit;
  final bool showAllButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(specialistReviewsProvider(specialistId));

    return reviews.when(
      data: (reviewsList) => _buildReviewsContent(context, reviewsList),
      loading: _buildLoadingState,
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildReviewsContent(BuildContext context, List<Review> reviews) {
    if (reviews.isEmpty) {
      return _buildEmptyState(context);
    }

    final displayReviews = limit > 0 ? reviews.take(limit).toList() : reviews;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Отзывы',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (showAllButton && reviews.length > limit)
                  TextButton(
                    onPressed: () => _showAllReviews(context),
                    child: Text('Все ${reviews.length}'),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Список отзывов
            ...displayReviews.map((review) => _buildReviewItem(context, review)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, Review review) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.grey[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[200]!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок отзыва
        Row(
          children: [
            // Аватар
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: Text(
                review.clientName.isNotEmpty ? review.clientName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),

            // Имя и рейтинг
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    review.clientName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Текст отзыва
        if (review.comment != null && review.comment!.isNotEmpty) ...[
          Text(review.comment!, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
        ],

        // Теги услуг
        if (review.serviceTags.isNotEmpty) ...[
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: review.serviceTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    ),
  );

  Widget _buildEmptyState(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Пока нет отзывов',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Отзывы появятся после выполнения заказов',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildLoadingState() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 16),
          Text('Загрузка отзывов...', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    ),
  );

  Widget _buildErrorState(Object error) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text('Ошибка загрузки отзывов', style: TextStyle(color: Colors.red[600])),
          ),
        ],
      ),
    ),
  );

  void _showAllReviews(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Заголовок
              Row(
                children: [
                  Text(
                    'Все отзывы',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Список отзывов
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final reviews = ref.watch(specialistReviewsProvider(specialistId));
                    return reviews.when(
                      data: (reviewsList) => ListView.builder(
                        controller: scrollController,
                        itemCount: reviewsList.length,
                        itemBuilder: (context, index) =>
                            _buildReviewItem(context, reviewsList[index]),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Ошибка загрузки отзывов: $error')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  Widget _buildNoDataState() {
    return const Center(child: Text('Нет данных о рейтинге'));
  }
}
