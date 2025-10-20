import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/review.dart';

/// Widget for displaying review information in a card
class ReviewCard extends StatelessWidget {
  final Review review;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  const ReviewCard({
    super.key,
    required this.review,
    this.onTap,
    this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    backgroundImage: review.clientAvatarUrl != null
                        ? CachedNetworkImageProvider(review.clientAvatarUrl!)
                        : null,
                    child: review.clientAvatarUrl == null
                        ? Text(review.clientName.substring(0, 1))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review.clientName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          review.formattedDate,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildRatingStars(),
                ],
              ),

              const SizedBox(height: 12),

              // Review text
              Text(
                review.text,
                style: const TextStyle(fontSize: 14),
              ),

              // Images
              if (review.hasImages) ...[
                const SizedBox(height: 12),
                _buildImagesGrid(),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      review.likesCount > 0 ? Icons.thumb_up : Icons.thumb_up_outlined,
                      color: review.likesCount > 0 ? Colors.blue : Colors.grey,
                      size: 20,
                    ),
                    onPressed: onLike,
                  ),
                  if (review.likesCount > 0)
                    Text(
                      '${review.likesCount}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.reply, size: 20),
                    onPressed: onReply,
                  ),
                  const Text(
                    'Ответить',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < review.rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
          size: 16,
        );
      }),
    );
  }

  Widget _buildImagesGrid() {
    if (review.images.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: review.images.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: review.images[index],
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
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
}
