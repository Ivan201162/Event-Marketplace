import 'package:event_marketplace_app/features/reviews/data/models/review.dart';
import 'package:event_marketplace_app/features/reviews/data/repositories/review_repository.dart';
import 'package:event_marketplace_app/features/reviews/presentation/add_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Экран отзывов специалиста
class SpecialistReviewsScreen extends StatefulWidget {
  const SpecialistReviewsScreen({
    required this.specialistId, required this.specialistName, required this.avgRating, required this.reviewsCount, super.key,
  });
  final String specialistId;
  final String specialistName;
  final double avgRating;
  final int reviewsCount;

  @override
  State<SpecialistReviewsScreen> createState() =>
      _SpecialistReviewsScreenState();
}

class _SpecialistReviewsScreenState extends State<SpecialistReviewsScreen> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  late Stream<List<Review>> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream =
        _reviewRepository.getReviewsBySpecialistStream(widget.specialistId);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Отзывы о ${widget.specialistName}'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Column(
          children: [
            // Заголовок с рейтингом
            _buildRatingHeader(),

            // Список отзывов
            Expanded(
              child: StreamBuilder<List<Review>>(
                stream: _reviewsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline,
                              size: 64, color: Colors.grey[400],),
                          const SizedBox(height: 16),
                          Text(
                            'Ошибка загрузки отзывов',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final reviews = snapshot.data ?? [];

                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 64, color: Colors.grey[400],),
                          const SizedBox(height: 16),
                          Text('Пока нет отзывов',
                              style: Theme.of(context).textTheme.headlineSmall,),
                          const SizedBox(height: 8),
                          Text(
                            'Станьте первым, кто оставит отзыв об этом специалисте',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      setState(() {
                        _reviewsStream =
                            _reviewRepository.getReviewsBySpecialistStream(
                          widget.specialistId,
                        );
                      });
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: reviews.length,
                      itemBuilder: (context, index) =>
                          _buildReviewCard(reviews[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );

  /// Заголовок с рейтингом
  Widget _buildRatingHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Средний рейтинг
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.avgRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.amber, size: 40),
              ],
            ),

            const SizedBox(height: 8),

            // Количество отзывов
            Text(
              '${widget.reviewsCount} ${_getReviewsCountText(widget.reviewsCount)}',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const SizedBox(height: 16),

            // Кнопка "Оставить отзыв"
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                if (authProvider.user == null) {
                  return const SizedBox.shrink();
                }

                return FutureBuilder<bool>(
                  future: _canLeaveReview(authProvider.user?.uid ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.data ?? false) {
                      return ElevatedButton.icon(
                        onPressed: _navigateToAddReview,
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Оставить отзыв'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Theme.of(context).primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12,),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ],
        ),
      );

  /// Карточка отзыва
  Widget _buildReviewCard(Review review) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок отзыва
              Row(
                children: [
                  // Аватар заказчика
                  CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      review.customerId.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Информация о заказчике
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Заказчик',
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _formatDate(review.createdAt),
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  // Рейтинг
                  Row(
                    children: [
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Комментарий
              Text(review.comment,
                  style: Theme.of(context).textTheme.bodyMedium,),

              // Индикатор редактирования
              if (review.edited) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Отредактировано',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );

  /// Проверить, может ли пользователь оставить отзыв
  Future<bool> _canLeaveReview(String customerId) async {
    // Здесь нужно проверить, есть ли у пользователя завершенные заказы
    // с этим специалистом, для которых еще нет отзыва
    // Пока возвращаем true для демонстрации
    return true;
  }

  /// Переход к экрану добавления отзыва
  void _navigateToAddReview() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AddReviewScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
        ),
      ),
    ).then((_) {
      // Обновляем список отзывов после добавления
      setState(() {
        _reviewsStream =
            _reviewRepository.getReviewsBySpecialistStream(widget.specialistId);
      });
    });
  }

  /// Форматирование даты
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
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  /// Получить правильную форму слова "отзыв"
  String _getReviewsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'отзыв';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'отзыва';
    } else {
      return 'отзывов';
    }
  }
}
