import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/review_providers.dart';
import '../providers/auth_providers.dart';
import '../widgets/review_widgets.dart';
import '../models/review.dart';

class ReviewsScreen extends ConsumerStatefulWidget {
  const ReviewsScreen({super.key});

  @override
  ConsumerState<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends ConsumerState<ReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Отзывы'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Мои отзывы'),
            Tab(icon: Icon(Icons.rate_review), text: 'Отзывы обо мне'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Топ специалистов'),
          ],
        ),
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Необходима авторизация',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMyReviewsTab(user.id),
              _buildReviewsAboutMeTab(user.id, user.isSpecialist),
              _buildTopSpecialistsTab(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }

  /// Вкладка моих отзывов
  Widget _buildMyReviewsTab(String userId) {
    final reviewsAsync = ref.watch(customerReviewsProvider(userId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rate_review, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Вы еще не оставляли отзывы',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Отзывы можно оставить после завершения заявок',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ReviewCard(
                review: review,
                showActions: true,
                onTap: () => _showEditReviewDialog(context, review),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки отзывов: $error'),
          ],
        ),
      ),
    );
  }

  /// Вкладка отзывов обо мне
  Widget _buildReviewsAboutMeTab(String userId, bool isSpecialist) {
    if (!isSpecialist) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Доступно только для специалистов',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Статистика
        Expanded(
          flex: 1,
          child: _buildStatisticsSection(userId),
        ),
        
        // Список отзывов
        Expanded(
          flex: 2,
          child: ReviewListWidget(specialistId: userId),
        ),
      ],
    );
  }

  /// Вкладка топ специалистов
  Widget _buildTopSpecialistsTab() {
    final topSpecialistsAsync = ref.watch(topSpecialistsProvider(const TopSpecialistsParams()));

    return topSpecialistsAsync.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.leaderboard, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет данных о специалистах',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: specialists.length,
          itemBuilder: (context, index) {
            final specialist = specialists[index];
            return _buildTopSpecialistCard(context, specialist, index + 1);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки топ специалистов: $error'),
          ],
        ),
      ),
    );
  }

  /// Секция статистики
  Widget _buildStatisticsSection(String specialistId) {
    final statisticsAsync = ref.watch(specialistReviewStatisticsProvider(specialistId));

    return statisticsAsync.when(
      data: (statistics) {
        if (!statistics.hasReviews) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет отзывов для статистики',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ReviewStatisticsWidget(statistics: statistics),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки статистики: $error'),
          ],
        ),
      ),
    );
  }

  /// Карточка топ специалиста
  Widget _buildTopSpecialistCard(BuildContext context, Map<String, dynamic> specialist, int position) {
    final specialistId = specialist['specialistId'] as String;
    final averageRating = specialist['averageRating'] as double;
    final reviewCount = specialist['reviewCount'] as int;

    return Card(
      elevation: position <= 3 ? 6 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Позиция
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getPositionColor(position),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  position.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Информация о специалисте
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Специалист $specialistId',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildRatingStars(averageRating.round()),
                      const SizedBox(width: 8),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$reviewCount отзывов',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Кнопка просмотра
            IconButton(
              onPressed: () => _viewSpecialistReviews(context, specialistId),
              icon: const Icon(Icons.visibility),
              tooltip: 'Посмотреть отзывы',
            ),
          ],
        ),
      ),
    );
  }

  /// Получить цвет позиции
  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return Colors.amber; // Золото
      case 2:
        return Colors.grey; // Серебро
      case 3:
        return Colors.brown; // Бронза
      default:
        return Colors.blue;
    }
  }

  /// Построить звезды рейтинга
  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  /// Показать диалог редактирования отзыва
  void _showEditReviewDialog(BuildContext context, Review review) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать отзыв'),
        content: const Text('Функция редактирования отзывов будет добавлена в следующих версиях'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  /// Посмотреть отзывы специалиста
  void _viewSpecialistReviews(BuildContext context, String specialistId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SpecialistReviewsScreen(specialistId: specialistId),
      ),
    );
  }
}

/// Экран отзывов специалиста
class SpecialistReviewsScreen extends ConsumerWidget {
  final String specialistId;

  const SpecialistReviewsScreen({
    super.key,
    required this.specialistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отзывы специалиста $specialistId'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Статистика
          Expanded(
            flex: 1,
            child: _buildStatisticsSection(context, ref),
          ),
          
          // Список отзывов
          Expanded(
            flex: 2,
            child: ReviewListWidget(specialistId: specialistId),
          ),
        ],
      ),
    );
  }

  /// Секция статистики
  Widget _buildStatisticsSection(BuildContext context, WidgetRef ref) {
    final statisticsAsync = ref.watch(specialistReviewStatisticsProvider(specialistId));

    return statisticsAsync.when(
      data: (statistics) {
        if (!statistics.hasReviews) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Нет отзывов для статистики',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ReviewStatisticsWidget(statistics: statistics),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка загрузки статистики: $error'),
          ],
        ),
      ),
    );
  }
}
