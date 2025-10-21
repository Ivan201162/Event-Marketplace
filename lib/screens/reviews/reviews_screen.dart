import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/review.dart';
import '../../providers/auth_providers.dart';
import '../../providers/review_providers.dart';
import '../../widgets/review_card.dart';

/// Screen for viewing reviews
class ReviewsScreen extends ConsumerStatefulWidget {
  final String specialistId;
  final String specialistName;

  const ReviewsScreen({super.key, required this.specialistId, required this.specialistName});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _sortBy = 'newest';
  int _filterRating = 0; // 0 = all, 1-5 = specific rating

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы - ${widget.specialistName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все отзывы'),
            Tab(text: 'С фото'),
            Tab(text: 'Статистика'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
          IconButton(icon: const Icon(Icons.sort), onPressed: _showSortDialog),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildAllReviewsTab(), _buildReviewsWithPhotosTab(), _buildStatisticsTab()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _writeReview,
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildAllReviewsTab() {
    final reviewsAsync = ref.watch(specialistReviewsStreamProvider(widget.specialistId));

    return reviewsAsync.when(
      data: (reviews) {
        final filteredReviews = _filterAndSortReviews(reviews);

        if (filteredReviews.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(specialistReviewsStreamProvider(widget.specialistId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredReviews.length,
            itemBuilder: (context, index) {
              final review = filteredReviews[index];
              return ReviewCard(
                review: review,
                onTap: () => _showReviewDetails(review),
                onLike: () => _toggleLike(review),
                onReply: () => _replyToReview(review),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отзывов', style: TextStyle(fontSize: 18, color: Colors.red[700])),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(specialistReviewsStreamProvider(widget.specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsWithPhotosTab() {
    final reviewsAsync = ref.watch(reviewsWithImagesStreamProvider(widget.specialistId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет отзывов с фото',
                  style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 8),
                Text(
                  'Отзывы с фотографиями будут отображаться здесь',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reviewsWithImagesStreamProvider(widget.specialistId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return ReviewCard(
                review: review,
                onTap: () => _showReviewDetails(review),
                onLike: () => _toggleLike(review),
                onReply: () => _replyToReview(review),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отзывов', style: TextStyle(fontSize: 18, color: Colors.red[700])),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(reviewsWithImagesStreamProvider(widget.specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    final statsAsync = ref.watch(specialistReviewStatsProvider(widget.specialistId));

    return statsAsync.when(
      data: (stats) {
        final totalReviews = stats['totalReviews'] as int;
        final averageRating = stats['averageRating'] as double;
        final ratingDistribution = stats['ratingDistribution'] as Map<int, int>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall rating
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < averageRating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.orange,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'На основе $totalReviews отзывов',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Rating distribution
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Распределение оценок',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...List.generate(5, (index) {
                        final rating = 5 - index;
                        final count = ratingDistribution[rating] ?? 0;
                        final percentage = totalReviews > 0 ? (count / totalReviews * 100) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '$rating',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.star, color: Colors.orange, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getRatingColor(rating),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '$count',
                                  style: const TextStyle(fontSize: 12),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки статистики',
              style: TextStyle(fontSize: 18, color: Colors.red[700]),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(specialistReviewStatsProvider(widget.specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Пока нет отзывов',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text('Будьте первым, кто оставит отзыв!', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  List<Review> _filterAndSortReviews(List<Review> reviews) {
    var filteredReviews = reviews;

    // Filter by rating
    if (_filterRating > 0) {
      filteredReviews = filteredReviews.where((review) => review.rating == _filterRating).toList();
    }

    // Sort reviews
    switch (_sortBy) {
      case 'newest':
        filteredReviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        filteredReviews.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'highest':
        filteredReviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'lowest':
        filteredReviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case 'most_liked':
        filteredReviews.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
    }

    return filteredReviews;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтр по рейтингу'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<int>(
              title: const Text('Все отзывы'),
              value: 0,
              groupValue: _filterRating,
              onChanged: (value) {
                setState(() {
                  _filterRating = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            ...List.generate(5, (index) {
              final rating = index + 1;
              return RadioListTile<int>(
                title: Row(
                  children: [
                    ...List.generate(5, (starIndex) {
                      return Icon(
                        starIndex < rating ? Icons.star : Icons.star_border,
                        color: Colors.orange,
                        size: 16,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text('$rating звезд'),
                  ],
                ),
                value: rating,
                groupValue: _filterRating,
                onChanged: (value) {
                  setState(() {
                    _filterRating = value!;
                  });
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сортировка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Сначала новые'),
              value: 'newest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Сначала старые'),
              value: 'oldest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Высокий рейтинг'),
              value: 'highest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Низкий рейтинг'),
              value: 'lowest',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Больше лайков'),
              value: 'most_liked',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _writeReview() {
    // TODO: Navigate to write review screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Написание отзыва пока не реализовано')));
  }

  void _showReviewDetails(Review review) {
    // TODO: Show review details
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Отзыв: ${review.text}')));
  }

  void _toggleLike(Review review) {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Войдите в аккаунт для лайков')));
      return;
    }

    final reviewService = ref.read(reviewServiceProvider);
    reviewService.toggleReviewLike(review.id, currentUser.uid);
  }

  void _replyToReview(Review review) {
    // TODO: Reply to review
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ответ на отзыв пока не реализован')));
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}
