import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../models/specialist.dart';
import '../services/review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/review_stats.dart';
import '../widgets/write_review_dialog.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.specialistId,
    this.canWriteReview = false,
    this.bookingId,
  });

  final String specialistId;
  final bool canWriteReview;
  final String? bookingId;

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final ScrollController _scrollController = ScrollController();
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _reviewService.getSpecialistReviewsPaginated(
        widget.specialistId,
        limit: 10,
        lastDocument: _reviews.isNotEmpty ? null : null, // Simplified for demo
      );

      setState(() {
        if (reviews.isEmpty) {
          _hasMore = false;
        } else {
          _reviews.addAll(reviews);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadReviews();
    }
  }

  Future<void> _showWriteReviewDialog() async {
    if (widget.bookingId == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => WriteReviewDialog(
        bookingId: widget.bookingId!,
        specialistId: widget.specialistId,
      ),
    );

    if (result == true) {
      // Обновляем список отзывов
      setState(() {
        _reviews.clear();
        _hasMore = true;
      });
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
        elevation: 0,
        actions: [
          if (widget.canWriteReview)
            IconButton(
              icon: const Icon(Icons.rate_review),
              onPressed: _showWriteReviewDialog,
              tooltip: 'Написать отзыв',
            ),
        ],
      ),
      body: Column(
        children: [
          // Статистика отзывов
          ReviewStats(specialistId: widget.specialistId),
          
          const Divider(height: 1),
          
          // Список отзывов
          Expanded(
            child: _buildReviewsList(),
          ),
        ],
      ),
      floatingActionButton: widget.canWriteReview
          ? FloatingActionButton.extended(
              onPressed: _showWriteReviewDialog,
              icon: const Icon(Icons.rate_review),
              label: const Text('Написать отзыв'),
            )
          : null,
    );
  }

  Widget _buildReviewsList() {
    if (_error != null) {
      return Center(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _reviews.clear();
                  _hasMore = true;
                  _error = null;
                });
                _loadReviews();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_reviews.isEmpty && !_isLoading) {
      return Center(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Станьте первым, кто оставит отзыв',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            if (widget.canWriteReview) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: const Icon(Icons.rate_review),
                label: const Text('Написать отзыв'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _reviews.clear();
          _hasMore = true;
        });
        await _loadReviews();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _reviews.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final review = _reviews[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ReviewCard(
              review: review,
              onReply: (reviewId, reply) => _handleReply(reviewId, reply),
              onMarkHelpful: (reviewId) => _handleMarkHelpful(reviewId),
              onReport: (reviewId, reason) => _handleReport(reviewId, reason),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleReply(String reviewId, String reply) async {
    try {
      await _reviewService.addReplyToReview(reviewId, reply);
      
      // Обновляем отзыв в списке
      setState(() {
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index >= 0) {
          _reviews[index] = _reviews[index].copyWith(
            reply: reply,
            repliedAt: DateTime.now(),
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ответ добавлен')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления ответа: $e')),
        );
      }
    }
  }

  Future<void> _handleMarkHelpful(String reviewId) async {
    try {
      await _reviewService.markReviewHelpful(reviewId);
      
      // Обновляем счетчик в списке
      setState(() {
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index >= 0) {
          _reviews[index] = _reviews[index].copyWith(
            isHelpful: _reviews[index].isHelpful + 1,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  Future<void> _handleReport(String reviewId, String reason) async {
    try {
      await _reviewService.reportReview(reviewId, reason);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Жалоба отправлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки жалобы: $e')),
        );
      }
    }
  }
}