import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/review.dart';
import '../models/specialist.dart';
import '../services/review_service.dart';
import '../widgets/rating_summary_widget.dart';
import '../widgets/review_card.dart';

/// Экран отзывов специалиста
class SpecialistReviewsScreen extends StatefulWidget {
  const SpecialistReviewsScreen({
    super.key,
    required this.specialist,
  });
  final Specialist specialist;

  @override
  State<SpecialistReviewsScreen> createState() =>
      _SpecialistReviewsScreenState();
}

class _SpecialistReviewsScreenState extends State<SpecialistReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadStats();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);

      final reviews = await _reviewService.getSpecialistReviews(
        widget.specialist.id,
      );

      setState(() {
        _reviews = reviews;
        _isLoading = false;
        _hasMore = reviews.length == 20;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки отзывов: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats =
          await _reviewService.getSpecialistReviewStats(widget.specialist.id);
      setState(() => _stats = stats);
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки статистики: $e');
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);

      final moreReviews = await _reviewService.getSpecialistReviews(
        widget.specialist.id,
        lastDocument: _lastDocument,
      );

      setState(() {
        _reviews.addAll(moreReviews);
        _isLoading = false;
        _hasMore = moreReviews.length == 20;
      });
    } on Exception catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки отзывов: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Отзывы ${widget.specialist.name}'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: _isLoading && _reviews.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Сводка по рейтингу
                  if (_stats.isNotEmpty)
                    RatingSummaryWidget(
                      averageRating: _stats['averageRating']?.toDouble() ?? 0.0,
                      totalReviews: _stats['totalReviews'] ?? 0,
                      ratingDistribution: Map<int, int>.from(
                        _stats['ratingDistribution'] ?? {},
                      ),
                    ),

                  // Список отзывов
                  Expanded(
                    child: _reviews.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadReviews,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reviews.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _reviews.length) {
                                  // Кнопка "Загрузить еще"
                                  return _buildLoadMoreButton();
                                }

                                final review = _reviews[index];
                                return ReviewCard(
                                  review: review,
                                  showSpecialistInfo: false,
                                  onEdit: review.canEdit
                                      ? () => _editReview(review)
                                      : null,
                                  onDelete: review.canDelete
                                      ? () => _deleteReview(review)
                                      : null,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
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
              'Станьте первым, кто оставит отзыв об этом специалисте',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildLoadMoreButton() => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _loadMoreReviews,
                  child: const Text('Загрузить еще'),
                ),
        ),
      );

  void _editReview(Review review) {
    // TODO(developer): Переход к экрану редактирования отзыва
    context.push('/edit-review', extra: review);
  }

  void _deleteReview(Review review) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены, что хотите удалить этот отзыв?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () async {
              context.pop();
              try {
                await _reviewService.deleteReview(review.id);
                _loadReviews();
                _loadStats();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Отзыв удален')),
                );
              } on Exception catch (e) {
                _showErrorSnackBar('Ошибка удаления отзыва: $e');
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
