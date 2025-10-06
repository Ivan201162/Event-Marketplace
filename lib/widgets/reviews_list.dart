import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';

/// Виджет для отображения списка отзывов специалиста
class ReviewsList extends ConsumerWidget {
  const ReviewsList({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(specialistReviewsProvider(specialistId));

    return reviewsAsync.when(
      data: (reviews) => _buildReviewsList(context, reviews),
      loading: _buildLoadingList,
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildReviewsList(BuildContext context, List<UserReview> reviews) {
    if (reviews.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO(developer): Обновить отзывы
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return _buildReviewItem(context, review);
        },
      ),
    );
  }

  Widget _buildReviewItem(BuildContext context, UserReview review) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок отзыва
            Row(
              children: [
                // Аватар заказчика
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: review.customerAvatarUrl != null
                      ? CachedNetworkImageProvider(review.customerAvatarUrl!)
                      : null,
                  child: review.customerAvatarUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                // Информация о заказчике
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        _formatTimestamp(review.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                // Рейтинг
                _buildRatingStars(review.rating),
              ],
            ),
            const SizedBox(height: 12),
            // Текст отзыва
            if (review.comment.isNotEmpty)
              Text(
                review.comment,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            // Кнопка "Полезно"
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _markAsHelpful(context, review.id),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Полезно'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _reportReview(context, review.id),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Пожаловаться'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildRatingStars(double rating) => Row(
        children: List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 20,
          ),
        ),
      );

  Widget _buildLoadingList() => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
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
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 120,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 80,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 100,
                      height: 20,
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 16,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 200,
                  height: 16,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildEmptyState(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет отзывов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Когда клиенты оставят отзывы,\nони появятся здесь',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки отзывов',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays < 1) {
      return 'Сегодня';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks нед. назад';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months мес. назад';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years г. назад';
    }
  }

  void _markAsHelpful(BuildContext context, String reviewId) {
    // TODO(developer): Реализовать отметку отзыва как полезного
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Отзыв отмечен как полезный')),
    );
  }

  void _reportReview(BuildContext context, String reviewId) {
    // TODO(developer): Реализовать жалобу на отзыв
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пожаловаться на отзыв'),
        content: const Text('Выберите причину жалобы:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Жалоба отправлена')),
              );
            },
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }
}
