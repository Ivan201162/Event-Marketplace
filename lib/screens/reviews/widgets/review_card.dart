import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/review.dart';

class ReviewCard extends StatefulWidget {
  const ReviewCard(
      {super.key, required this.review, this.onLike, this.onReport});
  final Review review;
  final VoidCallback? onLike;
  final VoidCallback? onReport;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final bool _isLiked = false;
  bool _showResponses = false;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок отзыва
              _buildReviewHeader(),
              const SizedBox(height: 12),

              // Рейтинг
              _buildRating(),
              const SizedBox(height: 12),

              // Текст отзыва
              _buildReviewText(),
              const SizedBox(height: 12),

              // Фото отзыва
              if (widget.review.photos.isNotEmpty) ...[
                _buildReviewPhotos(),
                const SizedBox(height: 12),
              ],

              // Действия
              _buildReviewActions(),

              // Ответы на отзыв
              if (widget.review.responses.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildResponses(),
              ],
            ],
          ),
        ),
      );

  Widget _buildReviewHeader() => Row(
        children: [
          // Аватар заказчика
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.review.customerAvatar != null
                ? NetworkImage(widget.review.customerAvatar!)
                : null,
            child: widget.review.customerAvatar == null
                ? Text(
                    widget.review.customerName.isNotEmpty
                        ? widget.review.customerName[0].toUpperCase()
                        : '?',
                  )
                : null,
          ),
          const SizedBox(width: 12),

          // Информация о заказчике
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.review.customerName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeago.format(widget.review.date, locale: 'ru'),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Меню действий
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'report':
                  widget.onReport?.call();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag, size: 16),
                    SizedBox(width: 8),
                    Text('Пожаловаться')
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
          ...List.generate(
            5,
            (index) => Icon(
              index < widget.review.rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            widget.review.rating.toStringAsFixed(1),
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          // Верифицированный отзыв
          if (widget.review.isVerified) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.green, borderRadius: BorderRadius.circular(12)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Проверен',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      );

  Widget _buildReviewText() =>
      Text(widget.review.text, style: Theme.of(context).textTheme.bodyMedium);

  Widget _buildReviewPhotos() => SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: widget.review.photos.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.review.photos[index],
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _buildReviewActions() => Row(
        children: [
          // Лайк
          InkWell(
            onTap: widget.onLike,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(widget.review.likes.toString(),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Ответы
          if (widget.review.responses.isNotEmpty)
            InkWell(
              onTap: () {
                setState(() {
                  _showResponses = !_showResponses;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline,
                      color: Colors.grey, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.review.responses.length} ответ${widget.review.responses.length == 1 ? '' : widget.review.responses.length < 5 ? 'а' : 'ов'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          const Spacer(),

          // Флаг редактирования
          if (widget.review.isEdited)
            Text(
              'Отредактировано',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
        ],
      );

  Widget _buildResponses() {
    if (!_showResponses) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ответы специалиста:',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.review.responses.map(
            (response) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        response.authorName,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(response.date, locale: 'ru'),
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(response.text,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
