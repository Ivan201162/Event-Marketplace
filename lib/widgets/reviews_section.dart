import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/review.dart';
import '../services/review_service.dart';
import '../widgets/create_review_dialog.dart';
import '../widgets/review_card.dart';
import '../widgets/review_stats_widget.dart';

/// Раздел отзывов в профиле специалиста
class ReviewsSection extends ConsumerStatefulWidget {
  const ReviewsSection({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.showAllReviews = false,
  });

  final String specialistId;
  final String specialistName;
  final bool showAllReviews;

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  SpecialistReviewStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await _reviewService.getSpecialistReviews(
        widget.specialistId,
      );

      final stats = await _reviewService.getSpecialistReviewStats(widget.specialistId);

      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки отзывов',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReviews,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок с количеством отзывов и кнопкой добавления
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Отзывы',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                if (_stats != null)
                  Text(
                    '${_stats!.totalReviews} отзывов',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                const SizedBox(width: 12),
                CreateReviewButton(
                  specialistId: widget.specialistId,
                  specialistName: widget.specialistName,
                  onReviewAdded: _loadReviews,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Статистика отзывов
        if (_stats != null && _stats!.totalReviews > 0) ...[
          ReviewStatsWidget(stats: _stats!),
          const SizedBox(height: 24),
        ],

        // Список отзывов
        if (_reviews.isEmpty)
          _buildEmptyState()
        else
          Column(
            children: [
              ..._reviews.map(
                (review) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ReviewCard(review: review),
                ),
              ),

              // Кнопка "Показать все отзывы"
              if (!widget.showAllReviews && _stats != null && _stats!.totalReviews > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showAllReviews,
                      child: Text(
                        'Показать все отзывы (${_stats!.totalReviews})',
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
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
              'Станьте первым, кто оставит отзыв об этом специалисте',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void _showAllReviews() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => AllReviewsScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
        ),
      ),
    );
  }
}

/// Экран со всеми отзывами специалиста
class AllReviewsScreen extends ConsumerStatefulWidget {
  const AllReviewsScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });

  final String specialistId;
  final String specialistName;

  @override
  ConsumerState<AllReviewsScreen> createState() => _AllReviewsScreenState();
}

class _AllReviewsScreenState extends ConsumerState<AllReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  List<Review> _reviews = [];
  ReviewStats? _stats;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAllReviews();
  }

  Future<void> _loadAllReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reviews = await _reviewService.getSpecialistReviews(
        widget.specialistId,
      );

      final stats = await _reviewService.getSpecialistReviewStats(widget.specialistId);

      setState(() {
        _reviews = reviews;
        _stats = stats;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('Отзывы ${widget.specialistName}'),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка загрузки отзывов',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAllReviews,
                          child: const Text('Повторить'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadAllReviews,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Статистика
                        if (_stats != null) ...[
                          ReviewStatsWidget(stats: _stats!),
                          const SizedBox(height: 24),
                        ],

                        // Список отзывов
                        if (_reviews.isEmpty)
                          _buildEmptyState()
                        else
                          ..._reviews.map(
                            (review) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ReviewCard(review: review),
                            ),
                          ),
                      ],
                    ),
                  ),
      );

  Widget _buildEmptyState() => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
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
              'Станьте первым, кто оставит отзыв об этом специалисте',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
