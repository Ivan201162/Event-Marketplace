import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../providers/review_providers.dart';
import '../services/enhanced_review_service.dart';
import '../widgets/review_card.dart';
import '../widgets/review_form.dart';
import 'create_review_screen.dart';

/// Улучшенный экран отзывов с полным функционалом
class EnhancedReviewsScreen extends ConsumerStatefulWidget {
  const EnhancedReviewsScreen(
      {super.key, required this.specialistId, this.specialistName});

  final String specialistId;
  final String? specialistName;

  @override
  ConsumerState<EnhancedReviewsScreen> createState() =>
      _EnhancedReviewsScreenState();
}

class _EnhancedReviewsScreenState extends ConsumerState<EnhancedReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedRatingFilter = 0; // 0 = все, 1-5 = конкретный рейтинг

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.specialistName != null
              ? 'Отзывы о ${widget.specialistName}'
              : 'Отзывы'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Все отзывы'),
              Tab(text: 'Статистика'),
            ],
          ),
        ),
        body: Column(
          children: [
            // Поиск и фильтры
            _buildSearchAndFilters(),

            // Контент
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildReviewsTab(), _buildStatsTab()],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      );

  /// Построить поиск и фильтры
  Widget _buildSearchAndFilters() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          children: [
            // Поисковая строка
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск по отзывам...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 12),

            // Фильтр по рейтингу
            _buildRatingFilter(),
          ],
        ),
      );

  /// Построить фильтр по рейтингу
  Widget _buildRatingFilter() => Row(
        children: [
          const Text('Фильтр по рейтингу: '),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRatingChip('Все', 0),
                  const SizedBox(width: 8),
                  ...List.generate(5, (index) {
                    final rating = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildRatingChip('$rating⭐', rating),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      );

  /// Построить чип рейтинга
  Widget _buildRatingChip(String label, int rating) {
    final isSelected = _selectedRatingFilter == rating;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRatingFilter = selected ? rating : 0;
        });
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
    );
  }

  /// Построить вкладку отзывов
  Widget _buildReviewsTab() {
    final reviewsAsync =
        ref.watch(specialistReviewsProvider(widget.specialistId));

    return reviewsAsync.when(
      data: (reviews) {
        final filteredReviews = _filterReviews(reviews);

        if (filteredReviews.isEmpty) {
          return _buildEmptyReviewsState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(specialistReviewsProvider(widget.specialistId));
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredReviews.length,
            itemBuilder: (context, index) {
              final review = filteredReviews[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewCard(
                  review: review,
                  onEdit: () => _editReview(review),
                  onDelete: () => _deleteReview(review),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка отзывов...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отзывов: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(specialistReviewsProvider(widget.specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить вкладку статистики
  Widget _buildStatsTab() {
    final statsAsync =
        ref.watch(specialistReviewStatsProvider(widget.specialistId));

    return statsAsync.when(
      data: (stats) {
        if (stats.totalReviews == 0) {
          return _buildEmptyStatsState();
        }

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

              // Последние отзывы
              _buildRecentReviews(),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Загрузка статистики...'),
          ],
        ),
      ),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки статистики: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.invalidate(
                    specialistReviewStatsProvider(widget.specialistId));
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить общую статистику
  Widget _buildOverallStats(ReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Общая статистика',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Средний рейтинг',
                      stats.averageRating.toStringAsFixed(1),
                      Icons.star,
                      Colors.amber,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Всего отзывов',
                      stats.totalReviews.toString(),
                      Icons.reviews,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  /// Построить элемент статистики
  Widget _buildStatItem(
          String label, String value, IconData icon, Color color) =>
      Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            )
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      );

  /// Построить распределение рейтингов
  Widget _buildRatingDistribution(ReviewStats stats) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Распределение рейтингов',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...List.generate(5, (index) {
                final rating = 5 - index; // От 5 до 1
                final count = stats.getRatingCount(rating);
                final percentage = stats.getRatingPercentage(rating);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('$rating⭐'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              _getRatingColor(rating)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$count (${percentage.toStringAsFixed(1)}%)'),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      );

  /// Построить последние отзывы
  Widget _buildRecentReviews() {
    final reviewsAsync =
        ref.watch(specialistReviewsProvider(widget.specialistId));

    return reviewsAsync.when(
      data: (reviews) {
        final recentReviews = reviews.take(3).toList();

        if (recentReviews.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Последние отзывы',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...recentReviews.map(
                  (review) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ReviewCard(review: review, compact: true),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Построить пустое состояние отзывов
  Widget _buildEmptyReviewsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reviews, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Пока нет отзывов',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('Станьте первым, кто оставит отзыв',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );

  /// Построить пустое состояние статистики
  Widget _buildEmptyStatsState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет данных для статистики',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('Отзывы появятся после первых оценок',
                style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );

  /// Построить кнопку добавления отзыва
  Widget _buildFloatingActionButton() => FutureBuilder<bool>(
        future: ref.read(enhancedReviewServiceProvider.future).then(
              (service) => service.canUserLeaveReview(
                specialistId: widget.specialistId,
                customerId: ref.read(currentUserProvider).value?.uid ?? '',
              ),
            ),
        builder: (context, snapshot) {
          final canLeaveReview = snapshot.data ?? false;

          if (!canLeaveReview) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton(
              onPressed: _createReview, child: const Icon(Icons.add));
        },
      );

  /// Фильтровать отзывы
  List<Review> _filterReviews(List<Review> reviews) {
    var filtered = reviews;

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      final searchLower = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (review) =>
                review.comment.toLowerCase().contains(searchLower) ||
                review.customerName.toLowerCase().contains(searchLower),
          )
          .toList();
    }

    // Фильтр по рейтингу
    if (_selectedRatingFilter > 0) {
      filtered = filtered
          .where((review) => review.rating == _selectedRatingFilter)
          .toList();
    }

    return filtered;
  }

  /// Получить цвет рейтинга
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

  /// Создать отзыв
  void _createReview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CreateReviewScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
        ),
      ),
    );
  }

  /// Редактировать отзыв
  void _editReview(Review review) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CreateReviewScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
          existingReview: review,
        ),
      ),
    );
  }

  /// Удалить отзыв
  void _deleteReview(Review review) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить отзыв'),
        content: const Text('Вы уверены, что хотите удалить этот отзыв?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(enhancedReviewServiceProvider)
                    .deleteReview(review.id);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Отзыв удален')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}

/// Провайдер для улучшенного сервиса отзывов
final enhancedReviewServiceProvider = Provider<EnhancedReviewService>(
  (ref) => EnhancedReviewService(),
);

/// Провайдер для отзывов специалиста
final specialistReviewsProvider =
    StreamProvider.family<List<Review>, String>((ref, specialistId) {
  final service = ref.watch(enhancedReviewServiceProvider);
  return service.getSpecialistReviewsStream(specialistId);
});

/// Провайдер для статистики отзывов специалиста
final specialistReviewStatsProvider =
    StreamProvider.family<ReviewStats, String>((
  ref,
  specialistId,
) {
  final service = ref.watch(enhancedReviewServiceProvider);
  return service.getSpecialistReviewStatsStream(specialistId);
});
