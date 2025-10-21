import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/review_extended.dart';
import '../services/review_extended_service.dart';
import '../widgets/review_extended_widget.dart';
import 'create_review_extended_screen.dart';

/// Экран расширенных отзывов
class ReviewsExtendedScreen extends ConsumerStatefulWidget {
  const ReviewsExtendedScreen({super.key, required this.specialistId, this.currentUserId});
  final String specialistId;
  final String? currentUserId;

  @override
  ConsumerState<ReviewsExtendedScreen> createState() => _ReviewsExtendedScreenState();
}

class _ReviewsExtendedScreenState extends ConsumerState<ReviewsExtendedScreen> {
  final ReviewExtendedService _reviewService = ReviewExtendedService();
  final TextEditingController _searchController = TextEditingController();

  ReviewFilter _filter = const ReviewFilter();
  String _searchQuery = '';
  final bool _showCreateButton = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Отзывы'),
      actions: [
        IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog),
        if (_showCreateButton)
          IconButton(icon: const Icon(Icons.add), onPressed: _showCreateReviewDialog),
      ],
    ),
    body: Column(
      children: [
        // Поиск
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск отзывов...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Статистика
        _buildStatsSection(),

        // Список отзывов
        Expanded(
          child: StreamBuilder<List<ReviewExtended>>(
            stream: _reviewService.getSpecialistReviews(widget.specialistId, _filter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Ошибка: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                );
              }

              final allReviews = snapshot.data ?? [];
              final filteredReviews = _filterReviews(allReviews);

              if (filteredReviews.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: filteredReviews.length,
                itemBuilder: (context, index) {
                  final review = filteredReviews[index];
                  return ReviewExtendedWidget(
                    review: review,
                    currentUserId: widget.currentUserId,
                    onLike: _handleLike,
                    onShare: _handleShare,
                    onReport: _handleReport,
                    onViewMedia: _handleViewMedia,
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: _showCreateButton
        ? FloatingActionButton(onPressed: _showCreateReviewDialog, child: const Icon(Icons.add))
        : null,
  );

  Widget _buildStatsSection() => FutureBuilder<SpecialistReviewStats>(
    future: _reviewService.getSpecialistReviewStats(widget.specialistId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox.shrink();
      }

      final stats = snapshot.data ?? SpecialistReviewStats.empty();
      if (stats.totalReviews == 0) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Общая статистика
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Рейтинг',
                        stats.averageRating.toStringAsFixed(1),
                        Icons.star,
                        Colors.amber,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Отзывов',
                        stats.totalReviews.toString(),
                        Icons.reviews,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Лайков',
                        stats.totalLikes.toString(),
                        Icons.favorite,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Распределение рейтингов
                if (stats.ratingDistribution.isNotEmpty) ...[
                  const Text(
                    'Распределение рейтингов',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...stats.ratingDistribution.entries.map((entry) {
                    final percentage = (entry.value / stats.totalReviews) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text('${entry.key} ⭐'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(_getRatingColor(entry.key)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${percentage.toStringAsFixed(1)}%'),
                        ],
                      ),
                    );
                  }),
                ],

                // Топ теги
                if (stats.topTags.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Популярные теги',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: stats.topTags
                        .map(
                          (tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _buildStatItem(String label, String value, IconData icon, Color color) => Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
    ],
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.reviews, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        const Text('Пока нет отзывов', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Станьте первым, кто оставит отзыв', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        if (_showCreateButton)
          ElevatedButton.icon(
            onPressed: _showCreateReviewDialog,
            icon: const Icon(Icons.add),
            label: const Text('Оставить отзыв'),
          ),
      ],
    ),
  );

  List<ReviewExtended> _filterReviews(List<ReviewExtended> reviews) {
    if (_searchQuery.isEmpty) return reviews;

    final query = _searchQuery.toLowerCase();
    return reviews
        .where(
          (review) =>
              review.comment.toLowerCase().contains(query) ||
              review.customerName.toLowerCase().contains(query) ||
              review.tags.any((tag) => tag.toLowerCase().contains(query)),
        )
        .toList();
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 5:
        return Colors.green;
      case 4:
        return Colors.lightGreen;
      case 3:
        return Colors.orange;
      case 2:
        return Colors.deepOrange;
      case 1:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showCreateReviewDialog() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<bool>(
            builder: (context) => CreateReviewExtendedScreen(
              specialistId: widget.specialistId,
              bookingId: 'demo_booking_id', // TODO(developer): Получить из контекста
            ),
          ),
        )
        .then((result) {
          if (result == true) {
            setState(() {});
          }
        });
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _FilterDialog(
        filter: _filter,
        onFilterChanged: (newFilter) {
          setState(() {
            _filter = newFilter;
          });
        },
      ),
    );
  }

  void _handleLike(String reviewId) {
    // TODO(developer): Реализовать лайк
    _showInfoSnackBar('Лайк добавлен');
  }

  void _handleShare(String reviewId) {
    // TODO(developer): Реализовать шаринг
    _showInfoSnackBar('Отзыв скопирован в буфер обмена');
  }

  void _handleReport(String reviewId) {
    // TODO(developer): Реализовать жалобу
    _showInfoSnackBar('Жалоба отправлена');
  }

  void _handleViewMedia(String reviewId) {
    // TODO(developer): Реализовать просмотр медиа
    _showInfoSnackBar('Просмотр медиа');
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Диалог фильтра отзывов
class _FilterDialog extends StatefulWidget {
  const _FilterDialog({required this.filter, required this.onFilterChanged});
  final ReviewFilter filter;
  final Function(ReviewFilter) onFilterChanged;

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late ReviewFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.filter;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Фильтр отзывов'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Рейтинг
        Row(
          children: [
            const Text('Рейтинг:'),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.minRating,
                decoration: const InputDecoration(labelText: 'От', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(child: Text('Любой')),
                  ...List.generate(
                    5,
                    (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1} ⭐')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(minRating: value);
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: _filter.maxRating,
                decoration: const InputDecoration(labelText: 'До', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(child: Text('Любой')),
                  ...List.generate(
                    5,
                    (index) => DropdownMenuItem(value: index + 1, child: Text('${index + 1} ⭐')),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(maxRating: value);
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Медиа
        CheckboxListTile(
          title: const Text('Только с медиа'),
          value: _filter.hasMedia ?? false,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(hasMedia: value);
            });
          },
        ),

        // Верифицированные
        CheckboxListTile(
          title: const Text('Только верифицированные'),
          value: _filter.isVerified ?? false,
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(isVerified: value);
            });
          },
        ),

        const SizedBox(height: 16),

        // Сортировка
        DropdownButtonFormField<ReviewSortBy>(
          initialValue: _filter.sortBy,
          decoration: const InputDecoration(labelText: 'Сортировка', border: OutlineInputBorder()),
          items: ReviewSortBy.values
              .map((sort) => DropdownMenuItem(value: sort, child: Text(_getSortText(sort))))
              .toList(),
          onChanged: (value) {
            setState(() {
              _filter = _filter.copyWith(sortBy: value);
            });
          },
        ),
      ],
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
      ElevatedButton(
        onPressed: () {
          widget.onFilterChanged(_filter);
          Navigator.pop(context);
        },
        child: const Text('Применить'),
      ),
    ],
  );

  String _getSortText(ReviewSortBy sort) {
    switch (sort) {
      case ReviewSortBy.date:
        return 'По дате';
      case ReviewSortBy.rating:
        return 'По рейтингу';
      case ReviewSortBy.likes:
        return 'По лайкам';
      case ReviewSortBy.helpfulness:
        return 'По полезности';
    }
  }
}
