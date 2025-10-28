import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/review.dart';
import 'package:event_marketplace_app/services/review_service.dart';
import 'package:event_marketplace_app/widgets/review_card.dart';
import 'package:flutter/material.dart';

/// Экран отзывов пользователя
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({required this.userId, super.key});
  final String userId;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() => _isLoading = true);

      final reviews = await _reviewService.getUserReviews(widget.userId);

      setState(() {
        _reviews = reviews;
        _isLoading = false;
        _hasMore = reviews.length == 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки отзывов: $e');
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMore || _isLoading) return;

    try {
      setState(() => _isLoading = true);

      final moreReviews = await _reviewService.getUserReviews(
        widget.userId,
        lastDocument: _lastDocument,
      );

      setState(() {
        _reviews.addAll(moreReviews);
        _isLoading = false;
        _hasMore = moreReviews.length == 20;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Ошибка загрузки отзывов: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Мои отзывы'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: _isLoading && _reviews.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
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
                        );
                      },
                    ),
                  ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'У вас пока нет отзывов',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Завершите заказ, чтобы оставить отзыв специалисту',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/reviews-to-write');
              },
              icon: const Icon(Icons.rate_review),
              label: const Text('Оставить отзыв'),
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
                  child: const Text('Загрузить еще'),),
        ),
      );

  void _editReview(Review review) {
    // TODO(developer): Переход к экрану редактирования отзыва
    Navigator.pushNamed(context, '/edit-review', arguments: review);
  }

  void _deleteReview(Review review) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены, что хотите удалить этот отзыв?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _reviewService.deleteReview(review.id);
                _loadReviews();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Отзыв удален')));
              } catch (e) {
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
