import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../services/reviews_service.dart';
import 'widgets/add_review_bottom_sheet.dart';
import 'widgets/review_card.dart';
import 'widgets/review_filters_bottom_sheet.dart';

class ReviewsScreen extends StatefulWidget {

  const ReviewsScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });
  final String specialistId;
  final String specialistName;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewsService _reviewsService = ReviewsService();
  final ScrollController _scrollController = ScrollController();
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  ReviewSortType _sortType = ReviewSortType.newest;
  ReviewFilter? _filter;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _loadFilters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  Future<void> _loadFilters() async {
    final sortType = await _reviewsService.loadReviewSortType();
    final filter = await _reviewsService.loadReviewFilters();
    
    setState(() {
      _sortType = sortType;
      _filter = filter;
    });
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      if (refresh) {
        _reviews.clear();
        _lastDocument = null;
        _hasMore = true;
      }
    });

    try {
      final reviews = await _reviewsService.getSpecialistReviews(
        widget.specialistId,
        lastDocument: _lastDocument,
        sortType: _sortType,
        filter: _filter,
      );

      setState(() {
        if (refresh) {
          _reviews = reviews;
        } else {
          _reviews.addAll(reviews);
        }
        _hasMore = reviews.length == 20;
        if (reviews.isNotEmpty) {
          _lastDocument = reviews.last as DocumentSnapshot?;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки отзывов: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreReviews() async {
    if (!_hasMore || _isLoading) return;
    await _loadReviews();
  }

  Future<void> _onSortChanged(ReviewSortType sortType) async {
    setState(() {
      _sortType = sortType;
    });
    await _reviewsService.saveReviewSortType(sortType);
    await _loadReviews(refresh: true);
  }

  Future<void> _onFilterChanged(ReviewFilter filter) async {
    setState(() {
      _filter = filter;
    });
    await _reviewsService.saveReviewFilters(filter);
    await _loadReviews(refresh: true);
  }

  Future<void> _onReviewAdded() async {
    await _loadReviews(refresh: true);
  }

  Future<void> _onReviewLiked(String reviewId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      try {
        await _reviewsService.likeReview(
          reviewId,
          currentUser.uid,
          currentUser.displayName ?? 'Пользователь',
        );
        
        // Обновляем локально
        setState(() {
          final index = _reviews.indexWhere((r) => r.id == reviewId);
          if (index != -1) {
            final review = _reviews[index];
            _reviews[index] = review.copyWith(
              likes: review.likes + 1,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при лайке: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('Отзывы о ${widget.specialistName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFiltersBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика отзывов
          _buildReviewsStats(),
          
          // Список отзывов
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadReviews(refresh: true),
              child: _reviews.isEmpty && !_isLoading
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _reviews.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _reviews.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        final review = _reviews[index];
                        return ReviewCard(
                          review: review,
                          onLike: () => _onReviewLiked(review.id),
                          onReport: () => _showReportDialog(review),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddReviewBottomSheet,
        child: const Icon(Icons.add),
      ),
    );

  Widget _buildReviewsStats() {
    if (_reviews.isEmpty) return const SizedBox.shrink();

    final totalReviews = _reviews.length;
    final averageRating = _reviews.fold(0, (sum, review) => sum + review.rating) / totalReviews;
    final ratingDistribution = <int, int>{};
    
    for (final review in _reviews) {
      final rating = review.rating.round();
      ratingDistribution[rating] = (ratingDistribution[rating] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Средняя оценка: ${averageRating.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              ...List.generate(5, (index) => Icon(
                  index < averageRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                ),),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Всего отзывов: $totalReviews',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          // Распределение рейтингов
          ...ratingDistribution.entries.map((entry) {
            final percentage = (entry.value / totalReviews) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text('${entry.key}★'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value}'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Станьте первым, кто оставит отзыв!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );

  void _showFiltersBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ReviewFiltersBottomSheet(
        currentFilter: _filter,
        onFilterChanged: _onFilterChanged,
      ),
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildSortBottomSheet(),
    );
  }

  Widget _buildSortBottomSheet() => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сортировка отзывов',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...ReviewSortType.values.map((sortType) => ListTile(
              title: Text(sortType.displayName),
              leading: Radio<ReviewSortType>(
                value: sortType,
                groupValue: _sortType,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.pop(context);
                    _onSortChanged(value);
                  }
                },
              ),
            ),),
        ],
      ),
    );

  void _showAddReviewBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddReviewBottomSheet(
        specialistId: widget.specialistId,
        specialistName: widget.specialistName,
        onReviewAdded: _onReviewAdded,
      ),
    );
  }

  void _showReportDialog(Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пожаловаться на отзыв'),
        content: const Text('Выберите причину жалобы:'),
        actions: [
          ...ReviewReportReason.values.map((reason) => TextButton(
              onPressed: () {
                Navigator.pop(context);
                _reportReview(review, reason);
              },
              child: Text(reason.displayName),
            ),),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _reportReview(Review review, ReviewReportReason reason) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      try {
        await _reviewsService.reportReview(
          reviewId: review.id,
          reporterId: currentUser.uid,
          reporterName: currentUser.displayName ?? 'Пользователь',
          reason: reason,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Жалоба отправлена')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при отправке жалобы: $e')),
          );
        }
      }
    }
  }
}
