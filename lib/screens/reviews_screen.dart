import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../providers/auth_providers.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Экран отзывов
class ReviewsScreen extends ConsumerStatefulWidget {
  final String targetId;
  final ReviewType type;
  final String targetName;

  const ReviewsScreen({
    super.key,
    required this.targetId,
    required this.type,
    required this.targetName,
  });

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewService _reviewService = ReviewService();
  late TabController _tabController;
  
  ReviewFilter _filter = ReviewFilter.empty();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы: ${widget.targetName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все отзывы'),
            Tab(text: 'Статистика'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          if (currentUser != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _createReview,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewsList(currentUser),
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  Widget _buildReviewsList(currentUser) {
    return StreamBuilder<List<Review>>(
      stream: _reviewService.getReviewsForTarget(
        widget.targetId,
        widget.type,
        filter: _filter,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки отзывов: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
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
                const Icon(Icons.reviews, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'Пока нет отзывов',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Станьте первым, кто оставит отзыв!',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (currentUser != null)
                  ElevatedButton.icon(
                    onPressed: _createReview,
                    icon: const Icon(Icons.add),
                    label: const Text('Оставить отзыв'),
                  ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Информация о фильтрах
            if (_filter.hasActiveFilters || _searchQuery.isNotEmpty)
              _buildFilterInfo(),
            
            // Список отзывов
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _buildReviewCard(review, currentUser);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatisticsTab() {
    return StreamBuilder<ReviewStats>(
      stream: _reviewService.getReviewStatsStream(widget.targetId, widget.type),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки статистики: ${snapshot.error}'),
              ],
            ),
          );
        }

        final stats = snapshot.data ?? ReviewStats(
          averageRating: 0.0,
          totalReviews: 0,
          ratingDistribution: {},
          verifiedReviews: 0,
          helpfulReviews: 0,
          helpfulPercentage: 0.0,
          lastUpdated: DateTime.now(),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Общая статистика
              _buildOverallStats(stats),
              const SizedBox(height: 24),
              
              // Распределение рейтингов
              _buildRatingDistribution(stats),
              const SizedBox(height: 24),
              
              // Дополнительная статистика
              _buildAdditionalStats(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getFilterDescription(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review, currentUser) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок отзыва
            Row(
              children: [
                Expanded(
                  child: Text(
                    review.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (review.isVerified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Проверено',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Рейтинг и автор
            Row(
              children: [
                _buildRatingStars(review.rating),
                const SizedBox(width: 8),
                Text(
                  review.reviewerName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '•',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Содержимое отзыва
            Text(
              review.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // Изображения
            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReviewImages(review.images),
            ],
            
            // Теги
            if (review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReviewTags(review.tags),
            ],
            
            // Ответ на отзыв
            if (review.hasResponse) ...[
              const SizedBox(height: 16),
              _buildReviewResponse(review),
            ],
            
            const SizedBox(height: 12),
            
            // Действия
            _buildReviewActions(review, currentUser),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReviewImages(List<String> images) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[index],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: tags.map((tag) => Chip(
        label: Text(tag),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        labelStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      )).toList(),
    );
  }

  Widget _buildReviewResponse(Review review) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.business,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Ответ владельца',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (review.responseDate != null)
                Text(
                  _formatDate(review.responseDate!),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.response!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewActions(Review review, currentUser) {
    return Row(
      children: [
        // Голосование за полезность
        if (currentUser != null && review.canVoteHelpful(currentUser.id)) ...[
          TextButton.icon(
            onPressed: () => _voteHelpful(review, true),
            icon: const Icon(Icons.thumb_up, size: 16),
            label: Text('${review.helpfulCount}'),
          ),
          TextButton.icon(
            onPressed: () => _voteHelpful(review, false),
            icon: const Icon(Icons.thumb_down, size: 16),
            label: Text('${review.notHelpfulCount}'),
          ),
        ] else ...[
          Icon(
            Icons.thumb_up,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '${review.helpfulCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            Icons.thumb_down,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '${review.notHelpfulCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
        
        const Spacer(),
        
        // Действия пользователя
        if (currentUser != null && currentUser.id == review.reviewerId) ...[
          TextButton(
            onPressed: () => _editReview(review),
            child: const Text('Редактировать'),
          ),
        ],
      ],
    );
  }

  Widget _buildOverallStats(ReviewStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Общая оценка',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Средний рейтинг
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.roundedAverageRating.toString(),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    _buildRatingStars(stats.averageRating.round()),
                    const SizedBox(height: 4),
                    Text(
                      '${stats.totalReviews} отзывов',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 32),
                
                // Дополнительная информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem('Проверенные отзывы', '${stats.verifiedReviews}'),
                      _buildStatItem('Полезные отзывы', '${stats.helpfulReviews}'),
                      _buildStatItem('Процент полезности', '${stats.helpfulPercentage.toStringAsFixed(1)}%'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDistribution(ReviewStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Распределение оценок',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (index) {
              final rating = 5 - index;
              final count = stats.ratingDistribution[rating] ?? 0;
              final percentage = stats.getRatingPercentage(rating);
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      '$rating',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$count (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalStats(ReviewStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дополнительная информация',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatItem('Последнее обновление', _formatDate(stats.lastUpdated)),
            _buildStatItem('Всего отзывов', '${stats.totalReviews}'),
            _buildStatItem('Проверенные отзывы', '${stats.verifiedReviews}'),
            _buildStatItem('Полезные отзывы', '${stats.helpfulReviews}'),
          ],
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

  String _getFilterDescription() {
    final parts = <String>[];
    
    if (_searchQuery.isNotEmpty) {
      parts.add('поиск: "$_searchQuery"');
    }
    
    if (_filter.minRating != null && _filter.maxRating != null) {
      if (_filter.minRating == _filter.maxRating) {
        parts.add('рейтинг: ${_filter.minRating}');
      } else {
        parts.add('рейтинг: ${_filter.minRating}-${_filter.maxRating}');
      }
    }
    
    if (_filter.verifiedOnly == true) {
      parts.add('только проверенные');
    }
    
    if (_filter.withImages == true) {
      parts.add('с изображениями');
    }
    
    if (_filter.withResponse == true) {
      parts.add('с ответами');
    }
    
    return parts.isEmpty ? 'Нет фильтров' : parts.join(', ');
  }

  void _clearFilters() {
    setState(() {
      _filter = ReviewFilter.empty();
      _searchQuery = '';
    });
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск отзывов'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите поисковый запрос',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _searchQuery = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
            },
            child: const Text('Поиск'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: const Text('Фильтры будут реализованы в следующей версии'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ОК'),
          ),
        ],
      ),
    );
  }

  void _createReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewFormScreen(
          targetId: widget.targetId,
          type: widget.type,
          targetName: widget.targetName,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _editReview(Review review) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReviewFormScreen(
          targetId: widget.targetId,
          type: widget.type,
          targetName: widget.targetName,
          existingReview: review,
        ),
      ),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  Future<void> _voteHelpful(Review review, bool isHelpful) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    try {
      await _reviewService.voteHelpful(review.id, currentUser.id, isHelpful);
    } catch (e, stackTrace) {
      SafeLog.error('ReviewsScreen: Error voting helpful', e, stackTrace);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка голосования: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}