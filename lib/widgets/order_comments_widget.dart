import 'package:flutter/material.dart';
import '../models/enhanced_order.dart';

/// Виджет комментариев к заявке
class OrderCommentsWidget extends StatefulWidget {
  const OrderCommentsWidget({
    super.key,
    required this.comments,
    required this.currentUserId,
    this.onAddComment,
    this.onAddAttachment,
  });

  final List<OrderComment> comments;
  final String currentUserId;
  final Function(String text, bool isInternal)? onAddComment;
  final Function(OrderAttachment attachment)? onAddAttachment;

  @override
  State<OrderCommentsWidget> createState() => _OrderCommentsWidgetState();
}

class _OrderCommentsWidgetState extends State<OrderCommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isInternal = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.comment, color: Colors.blue),
            const SizedBox(width: 8),
            const Text(
              'Комментарии',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.comments.length} комментариев',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Список комментариев
        if (widget.comments.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.comments.length,
            itemBuilder: (context, index) {
              final comment = widget.comments[index];
              return _buildCommentItem(comment);
            },
          ),
        
        const SizedBox(height: 16),
        
        // Форма добавления комментария
        _buildAddCommentForm(),
      ],
    );
  }

  Widget _buildCommentItem(OrderComment comment) {
    final isCurrentUser = comment.authorId == widget.currentUserId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Аватар
          CircleAvatar(
            radius: 20,
            backgroundColor: isCurrentUser ? Colors.blue : Colors.grey[300],
            child: Icon(
              isCurrentUser ? Icons.person : Icons.person_outline,
              color: isCurrentUser ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Содержимое комментария
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser ? Colors.blue[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentUser ? Colors.blue[200]! : Colors.grey[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок комментария
                  Row(
                    children: [
                      Text(
                        isCurrentUser ? 'Вы' : 'Автор',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isCurrentUser ? Colors.blue[700] : Colors.grey[700],
                        ),
                      ),
                      if (comment.isInternal) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Внутренний',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Текст комментария
                  Text(
                    comment.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // Вложения
                  if (comment.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildAttachments(comment.attachments),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments(List<OrderAttachment> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((attachment) {
        return GestureDetector(
          onTap: () {
            // TODO: Открыть вложение
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attachment.type.icon,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddCommentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Переключатель внутреннего комментария
          Row(
            children: [
              Checkbox(
                value: _isInternal,
                onChanged: (value) {
                  setState(() {
                    _isInternal = value ?? false;
                  });
                },
              ),
              const Text('Внутренний комментарий'),
              const Spacer(),
              if (_isInternal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Только для специалистов',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Поле ввода комментария
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Добавить комментарий...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Кнопки действий
          Row(
            children: [
              // Кнопка добавления вложения
              IconButton(
                onPressed: _addAttachment,
                icon: const Icon(Icons.attach_file),
                tooltip: 'Добавить вложение',
              ),
              
              const Spacer(),
              
              // Кнопка отправки
              ElevatedButton(
                onPressed: _commentController.text.trim().isEmpty
                    ? null
                    : _sendComment,
                child: const Text('Отправить'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isNotEmpty) {
      widget.onAddComment?.call(text, _isInternal);
      _commentController.clear();
      setState(() {
        _isInternal = false;
      });
    }
  }

  void _addAttachment() {
    // TODO: Реализовать добавление вложения
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить вложение'),
        content: const Text('Функция добавления вложений будет реализована позже'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

