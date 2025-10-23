import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Widget for displaying specialist reviews
class ReviewsList extends ConsumerStatefulWidget {
  final String specialistId;
  final VoidCallback onWriteReview;

  const ReviewsList(
      {super.key, required this.specialistId, required this.onWriteReview});

  @override
  ConsumerState<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends ConsumerState<ReviewsList> {
  @override
  Widget build(BuildContext context) {
    // Mock reviews data - in real app this would come from a provider
    final reviews = _getMockReviews();

    return Column(
      children: [
        // Header with write review button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Отзывы (${reviews.length})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: widget.onWriteReview,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Написать отзыв'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child: reviews.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return _buildReviewCard(review);
                  },
                ),
        ),
      ],
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
            style: TextStyle(
                fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text('Будьте первым, кто оставит отзыв!',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewData review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: review.userAvatarUrl != null
                      ? NetworkImage(review.userAvatarUrl!)
                      : null,
                  child: review.userAvatarUrl == null
                      ? Text(review.userName.substring(0, 1))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _formatDate(review.date),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildRatingStars(review.rating),
              ],
            ),

            const SizedBox(height: 12),

            // Review text
            Text(review.text, style: const TextStyle(fontSize: 14)),

            if (review.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildReviewImages(review.images),
            ],

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    review.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: review.isLiked ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    // TODO: Toggle like
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(
                        content: Text('Лайк пока не реализован')));
                  },
                ),
                Text(
                  '${review.likesCount}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.reply, size: 20),
                  onPressed: () {
                    // TODO: Reply to review
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ответ на отзыв пока не реализован')),
                    );
                  },
                ),
                const Text('Ответить', style: TextStyle(fontSize: 12)),
              ],
            ),
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
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }

  Widget _buildReviewImages(List<String> images) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                images[index],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  List<ReviewData> _getMockReviews() {
    return [
      ReviewData(
        id: '1',
        userId: 'user1',
        userName: 'Анна Петрова',
        specialistId: widget.specialistId,
        rating: 5,
        text:
            'Отличный специалист! Очень профессионально подошел к организации нашего мероприятия. Все прошло идеально, гости были в восторге. Рекомендую!',
        date: DateTime.now().subtract(const Duration(days: 2)),
        likesCount: 3,
        isLiked: false,
        images: [],
      ),
      ReviewData(
        id: '2',
        userId: 'user2',
        userName: 'Михаил Иванов',
        specialistId: widget.specialistId,
        rating: 4,
        text:
            'Хорошая работа, но были небольшие задержки. В целом доволен результатом.',
        date: DateTime.now().subtract(const Duration(days: 5)),
        likesCount: 1,
        isLiked: true,
        images: [],
      ),
      ReviewData(
        id: '3',
        userId: 'user3',
        userName: 'Елена Смирнова',
        specialistId: widget.specialistId,
        rating: 5,
        text:
            'Потрясающий профессионал! Организовал свадьбу моей мечты. Каждая деталь была продумана до мелочей. Спасибо большое!',
        date: DateTime.now().subtract(const Duration(days: 10)),
        likesCount: 7,
        isLiked: false,
        images: [
          'https://picsum.photos/200/200?random=1',
          'https://picsum.photos/200/200?random=2',
        ],
      ),
    ];
  }
}

/// Data class for review information
class ReviewData {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String specialistId;
  final int rating;
  final String text;
  final DateTime date;
  final int likesCount;
  final bool isLiked;
  final List<String> images;

  ReviewData({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.specialistId,
    required this.rating,
    required this.text,
    required this.date,
    required this.likesCount,
    required this.isLiked,
    required this.images,
  });
}
