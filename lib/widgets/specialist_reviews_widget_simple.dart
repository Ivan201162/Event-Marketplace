import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/services/reviews_service.dart';
import 'package:flutter/material.dart';

/// Упрощенный виджет отзывов специалиста
class SpecialistReviewsWidgetSimple extends StatefulWidget {
  const SpecialistReviewsWidgetSimple({required this.specialistId, super.key});

  final String specialistId;

  @override
  State<SpecialistReviewsWidgetSimple> createState() =>
      _SpecialistReviewsWidgetSimpleState();
}

class _SpecialistReviewsWidgetSimpleState
    extends State<SpecialistReviewsWidgetSimple> {
  final _reviewsService = ReviewsService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final reviews =
          await _reviewsService.getSpecialistReviews(widget.specialistId);

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Отзывы',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (_reviews.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Навигация к полному списку отзывов
                    },
                    child: const Text('Все отзывы'),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Контент
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error.isNotEmpty)
              _buildErrorWidget()
            else if (_reviews.isEmpty)
              _buildEmptyWidget()
            else
              _buildReviewsList(),
          ],
        ),
      );

  Widget _buildErrorWidget() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 32),
            const SizedBox(height: 8),
            Text(
              'Ошибка загрузки отзывов',
              style: TextStyle(
                  color: Colors.red.shade600, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 4),
            Text(
              _error,
              style: TextStyle(color: Colors.red.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
                onPressed: _loadReviews, child: const Text('Повторить'),),
          ],
        ),
      );

  Widget _buildEmptyWidget() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined,
                color: Colors.grey.shade400, size: 32,),
            const SizedBox(height: 8),
            Text(
              'Пока нет отзывов',
              style: TextStyle(
                  color: Colors.grey.shade600, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 4),
            Text(
              'Станьте первым, кто оставит отзыв',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );

  Widget _buildReviewsList() {
    // Показываем только первые 3 отзыва
    final displayReviews = _reviews.take(3).toList();

    return Column(
      children: [
        ...displayReviews.map(_buildReviewCard),
        if (_reviews.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: () {
                // TODO: Навигация к полному списку отзывов
              },
              child: Text('Показать еще ${_reviews.length - 3} отзывов'),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок отзыва
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      review.clientName.isNotEmpty
                          ? review.clientName[0].toUpperCase()
                          : 'П',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold,),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.clientName,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold,),
                        ),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 10,),
                        ),
                      ],
                    ),
                  ),
                  // Рейтинг
                  Row(
                    children: [
                      ...List.generate(
                        5,
                        (index) => Icon(
                          index < review.rating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12,),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Текст отзыва
              Text(
                review.comment ?? '',
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Фотографии (если есть)
              if (review.photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: review.photos.length,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(right: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          review.photos[index],
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 40,
                            height: 40,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              // Ответы специалиста
              if (review.responses.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: review.responses
                        .map(
                          (response) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.business,
                                      size: 12, color: Colors.blue.shade600,),
                                  const SizedBox(width: 4),
                                  Text(
                                    response['authorName'] ?? 'Специалист',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                response['text'] ?? '',
                                style: const TextStyle(fontSize: 10),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (response != review.responses.last)
                                const SizedBox(height: 4),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
