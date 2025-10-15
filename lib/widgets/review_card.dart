import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/review.dart';

/// Карточка отзыва
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.compact = false,
  });

  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с информацией о пользователе
              _buildHeader(context),

              if (!compact) const SizedBox(height: 12),

              // Рейтинг
              _buildRating(),

              if (!compact) const SizedBox(height: 8),

              // Комментарий
              _buildComment(),

              if (!compact) ...[
                const SizedBox(height: 12),

                // Теги услуг
                if (review.serviceTags.isNotEmpty) _buildServiceTags(),

                const SizedBox(height: 12),

                // Футер с датой и действиями
                _buildFooter(context),
              ],
            ],
          ),
        ),
      );

  /// Построить заголовок
  Widget _buildHeader(BuildContext context) => Row(
        children: [
          // Аватар пользователя
          CircleAvatar(
            radius: compact ? 16 : 20,
            backgroundColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            backgroundImage: review.customerAvatar != null
                ? NetworkImage(review.customerAvatar!)
                : null,
            child: review.customerAvatar == null
                ? Text(
                    review.customerName.isNotEmpty
                        ? review.customerName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: compact ? 12 : 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
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
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (!compact && review.eventTitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    review.eventTitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Действия
          if (!compact && (onEdit != null || onDelete != null))
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
                if (onEdit != null && review.canEdit)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16),
                        SizedBox(width: 8),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                if (onDelete != null && review.canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Удалить', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      );

  /// Построить рейтинг
  Widget _buildRating() => Row(
        children: [
          // Звезды рейтинга
          ...List.generate(5, (index) {
            final isFilled = index < review.rating;
            return Icon(
              isFilled ? Icons.star : Icons.star_border,
              size: compact ? 16 : 18,
              color: isFilled ? Colors.amber : Colors.grey[300],
            );
          }),

          const SizedBox(width: 8),

          // Числовой рейтинг
          Text(
            '${review.rating}/5',
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),

          // Индикатор редактирования
          if (review.isEdited) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'изменен',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      );

  /// Построить комментарий
  Widget _buildComment() => Text(
        review.text,
        style: TextStyle(
          fontSize: compact ? 13 : 14,
          height: 1.4,
        ),
      );

  /// Построить теги услуг
  Widget _buildServiceTags() => Wrap(
        spacing: 6,
        runSpacing: 4,
        children: review.serviceTags
            .map(
              (tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            )
            .toList(),
      );

  /// Построить футер
  Widget _buildFooter(BuildContext context) => Row(
        children: [
          // Дата создания
          Icon(
            Icons.access_time,
            size: 14,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 4),
          Text(
            _formatDate(review.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),

          const Spacer(),

          // Ответ специалиста
          if (review.responses.isNotEmpty) ...[
            Icon(
              Icons.reply,
              size: 14,
              color: Colors.green[600],
            ),
            const SizedBox(width: 4),
            Text(
              'Есть ответ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      );

  /// Форматировать дату
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Сегодня в ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${DateFormat('HH:mm').format(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} нед. назад';
    } else {
      return DateFormat('dd.MM.yyyy').format(date);
    }
  }
}
