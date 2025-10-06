import 'package:flutter/material.dart';
import '../models/review.dart';

/// Виджет карточки отзыва
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.showSpecialistInfo = true,
    this.onEdit,
    this.onDelete,
    this.onRespond,
  });
  final Review review;
  final bool showSpecialistInfo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRespond;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с информацией о пользователе
              _buildHeader(context),

              const SizedBox(height: 12),

              // Рейтинг
              _buildRating(),

              const SizedBox(height: 12),

              // Комментарий
              if (review.comment.isNotEmpty) ...[
                _buildComment(),
                const SizedBox(height: 12),
              ],

              // Теги услуг
              if (review.serviceTags.isNotEmpty) ...[
                _buildServiceTags(),
                const SizedBox(height: 12),
              ],

              // Информация о событии
              if (review.eventTitle != null) ...[
                _buildEventInfo(),
                const SizedBox(height: 12),
              ],

              // Ответ специалиста
              if (review.hasResponse) ...[
                _buildSpecialistResponse(),
                const SizedBox(height: 12),
              ],

              // Футер с датой и действиями
              _buildFooter(context),
            ],
          ),
        ),
      );

  Widget _buildHeader(BuildContext context) => Row(
        children: [
          // Аватар пользователя
          CircleAvatar(
            radius: 20,
            backgroundImage: review.customerAvatar != null
                ? NetworkImage(review.customerAvatar!)
                : null,
            child: review.customerAvatar == null
                ? Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : null,
          ),

          const SizedBox(width: 12),

          // Информация о пользователе
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  review.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  review.formattedCreatedAt,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),

          // Действия
          if (onEdit != null || onDelete != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit?.call();
                    break;
                  case 'delete':
                    onDelete?.call();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (onEdit != null)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      );

  Widget _buildRating() => Row(
        children: [
          // Звезды рейтинга
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Числовой рейтинг
          Text(
            '${review.rating}/5',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getRatingColor(),
            ),
          ),
        ],
      );

  Widget _buildComment() => Text(
        review.comment,
        style: const TextStyle(fontSize: 16),
      );

  Widget _buildServiceTags() => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: review.serviceTags
            .map(
              (tag) => Chip(
                label: Text(
                  tag,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue[50],
                side: BorderSide(color: Colors.blue[200]!),
              ),
            )
            .toList(),
      );

  Widget _buildEventInfo() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.event, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                review.eventTitle!,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSpecialistResponse() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.reply, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'Ответ специалиста',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.response!,
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 14,
              ),
            ),
            if (review.responseAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'отвечено ${_formatDate(review.responseAt!)}',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildFooter(BuildContext context) => Row(
        children: [
          // Информация о редактировании
          if (review.isEdited) ...[
            Icon(Icons.edit, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              review.formattedEditedAt ?? '',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],

          const Spacer(),

          // Кнопка ответа для специалиста
          if (onRespond != null && !review.hasResponse)
            TextButton(
              onPressed: onRespond,
              child: const Text('Ответить'),
            ),
        ],
      );

  Color _getRatingColor() {
    switch (review.ratingColor) {
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      return 'только что';
    }
  }
}
