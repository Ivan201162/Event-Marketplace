import 'package:flutter/material.dart';
import '../services/review_service.dart';

class ReviewStats extends StatefulWidget {
  const ReviewStats({
    super.key,
    required this.specialistId,
  });

  final String specialistId;

  @override
  State<ReviewStats> createState() => _ReviewStatsState();
}

class _ReviewStatsState extends State<ReviewStats> {
  final ReviewService _reviewService = ReviewService();
  
  double _averageRating = 0.0;
  Map<int, int> _ratingDistribution = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait([
        _reviewService.getSpecialistAverageRating(widget.specialistId),
        _reviewService.getRatingDistribution(widget.specialistId),
      ]);

      setState(() {
        _averageRating = results[0] as double;
        _ratingDistribution = results[1] as Map<int, int>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final totalReviews = _ratingDistribution.values.fold<int>(0, (sum, count) => sum + count);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // Общий рейтинг
          Row(
            children: [
              // Числовой рейтинг
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '/ 5',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildStarRating(_averageRating),
                      const SizedBox(width: 8),
                      Text(
                        '$totalReviews отзывов',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(width: 32),
              
              // Распределение по звездам
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final stars = 5 - index;
                    final count = _ratingDistribution[stars] ?? 0;
                    final percentage = totalReviews > 0 ? (count / totalReviews) : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '$stars',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        } else if (index < rating) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        } else {
          return const Icon(Icons.star_border, size: 18, color: Colors.amber);
        }
      }),
    );
  }
}
