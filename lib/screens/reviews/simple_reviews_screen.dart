import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/review.dart';
import '../../services/reviews_service.dart';
import 'add_review_screen.dart';

class SimpleReviewsScreen extends ConsumerStatefulWidget {

  const SimpleReviewsScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
  });
  final String specialistId;
  final String specialistName;

  @override
  ConsumerState<SimpleReviewsScreen> createState() => _SimpleReviewsScreenState();
}

class _SimpleReviewsScreenState extends ConsumerState<SimpleReviewsScreen> {
  final _reviewsService = ReviewsService();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final reviews = await _reviewsService.getSpecialistReviews(widget.specialistId);
      
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addReview() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddReviewScreen(
          specialistId: widget.specialistId,
          specialistName: widget.specialistName,
        ),
      ),
    );

    if (result ?? false) {
      _loadReviews();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: Text('Отзывы о ${widget.specialistName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addReview,
            tooltip: 'Добавить отзыв',
          ),
        ],
      ),
      body: _buildBody(),
    );

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки отзывов',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              style: TextStyle(
                color: Colors.grey.shade500,
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
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Пока нет отзывов',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Станьте первым, кто оставит отзыв об этом специалисте',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addReview,
              icon: const Icon(Icons.add),
              label: const Text('Добавить отзыв'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) => Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок отзыва
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    review.customerName.isNotEmpty 
                        ? review.customerName[0].toUpperCase()
                        : 'П',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(review.date),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Рейтинг
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                        index < review.rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      ),),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Текст отзыва
            Text(
              review.text,
              style: const TextStyle(fontSize: 14),
            ),
            
            // Фотографии
            if (review.photos.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.photos.length,
                  itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          review.photos[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image),
                            ),
                        ),
                      ),
                    ),
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Действия
            Row(
              children: [
                // Лайки
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    // TODO: Реализовать лайки
                  },
                ),
                Text(
                  review.likes.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Ответы
                IconButton(
                  icon: Icon(
                    Icons.reply,
                    color: Colors.grey.shade600,
                  ),
                  onPressed: () {
                    // TODO: Реализовать ответы
                  },
                ),
                Text(
                  review.responses.length.toString(),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                
                const Spacer(),
                
                // Кнопка "Полезно"
                TextButton.icon(
                  onPressed: () {
                    // TODO: Реализовать отметку "Полезно"
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Полезно'),
                ),
              ],
            ),
            
            // Ответы специалиста
            if (review.responses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: review.responses.map((response) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              response.authorName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('dd.MM.yyyy').format(response.date),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          response.text,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (response != review.responses.last)
                          const SizedBox(height: 8),
                      ],
                    ),).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
}
