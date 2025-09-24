import 'package:flutter/material.dart';
import '../models/review.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';

class ReviewCard extends StatefulWidget {
  const ReviewCard({
    super.key,
    required this.review,
    this.onReply,
    this.onMarkHelpful,
    this.onReport,
    this.showReplyButton = false,
  });

  final Review review;
  final Function(String reviewId, String reply)? onReply;
  final Function(String reviewId)? onMarkHelpful;
  final Function(String reviewId, String reason)? onReport;
  final bool showReplyButton;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final UserService _userService = UserService();
  final TextEditingController _replyController = TextEditingController();
  
  AppUser? _reviewer;
  bool _isLoadingUser = true;
  bool _showReplyField = false;
  bool _isSubmittingReply = false;

  @override
  void initState() {
    super.initState();
    _loadReviewer();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewer() async {
    try {
      final user = await _userService.getUserById(widget.review.customerId);
      setState(() {
        _reviewer = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с рейтингом и датой
            Row(
              children: [
                // Аватар пользователя
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: _isLoadingUser
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _reviewer?.displayName?.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                
                // Имя и рейтинг
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reviewer?.displayName ?? 'Пользователь',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          _buildStarRating(widget.review.rating),
                          const SizedBox(width: 8),
                          if (widget.review.isVerified)
                            const Icon(
                              Icons.verified,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Дата
                Text(
                  _formatDate(widget.review.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                // Меню
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onSelected: (value) => _handleMenuAction(value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'helpful',
                      child: Row(
                        children: [
                          Icon(Icons.thumb_up_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Полезно'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Пожаловаться', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Текст отзыва
            Text(
              widget.review.comment,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
              ),
            ),
            
            // Теги
            if (widget.review.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: widget.review.tags.map((tag) => Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey[100],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Действия
            Row(
              children: [
                // Полезность
                TextButton.icon(
                  onPressed: () => widget.onMarkHelpful?.call(widget.review.id),
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: Text('Полезно (${widget.review.isHelpful})'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                
                const Spacer(),
                
                // Кнопка ответа
                if (widget.showReplyButton && widget.review.reply == null)
                  TextButton.icon(
                    onPressed: () => setState(() => _showReplyField = !_showReplyField),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Ответить'),
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            
            // Ответ специалиста
            if (widget.review.reply != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Ответ специалиста',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const Spacer(),
                        if (widget.review.repliedAt != null)
                          Text(
                            _formatDate(widget.review.repliedAt!),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.review.reply!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            
            // Поле для ответа
            if (_showReplyField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _replyController,
                decoration: const InputDecoration(
                  hintText: 'Напишите ответ на отзыв...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                enabled: !_isSubmittingReply,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmittingReply ? null : () {
                      setState(() => _showReplyField = false);
                      _replyController.clear();
                    },
                    child: const Text('Отмена'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSubmittingReply ? null : _submitReply,
                    child: _isSubmittingReply
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Отправить'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
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
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} нед. назад';
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'helpful':
        widget.onMarkHelpful?.call(widget.review.id);
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пожаловаться на отзыв'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Выберите причину жалобы:'),
            const SizedBox(height: 16),
            ...['Спам', 'Неприемлемый контент', 'Фейковый отзыв', 'Другое']
                .map((reason) => ListTile(
                      title: Text(reason),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onReport?.call(widget.review.id, reason);
                      },
                    )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply() async {
    if (_replyController.text.trim().isEmpty) return;

    setState(() => _isSubmittingReply = true);

    try {
      await widget.onReply?.call(widget.review.id, _replyController.text.trim());
      setState(() {
        _showReplyField = false;
        _isSubmittingReply = false;
      });
      _replyController.clear();
    } catch (e) {
      setState(() => _isSubmittingReply = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки ответа: $e')),
        );
      }
    }
  }
}
