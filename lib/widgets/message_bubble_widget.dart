import 'package:flutter/material.dart';
import '../models/enhanced_message.dart';

/// Виджет пузырька сообщения
class MessageBubbleWidget extends StatelessWidget {
  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.showAvatar,
    this.onTap,
    this.onLongPress,
    this.onReply,
    this.onForward,
    this.onEdit,
    this.onDelete,
    this.onReact,
  });

  final EnhancedMessage message;
  final bool isCurrentUser;
  final bool showAvatar;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String emoji)? onReact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isCurrentUser 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isCurrentUser && showAvatar) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.person, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            
            Flexible(
              child: Column(
                crossAxisAlignment: isCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  // Ответ на сообщение
                  if (message.replyTo != null) ...[
                    _buildReplyPreview(),
                    const SizedBox(height: 4),
                  ],
                  
                  // Пересланное сообщение
                  if (message.forwardedFrom != null) ...[
                    _buildForwardHeader(),
                    const SizedBox(height: 4),
                  ],
                  
                  // Основной контент сообщения
                  _buildMessageContent(context),
                  
                  const SizedBox(height: 4),
                  
                  // Метаданные сообщения
                  _buildMessageMetadata(),
                  
                  // Реакции
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildReactions(),
                  ],
                ],
              ),
            ),
            
            if (isCurrentUser && showAvatar) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.person, size: 16, color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Colors.blue,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ответ на сообщение',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message.replyTo!.text,
            style: const TextStyle(fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildForwardHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.forward, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'Пересланное сообщение',
            style: TextStyle(
              fontSize: 10,
              color: Colors.blue[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentUser ? Colors.blue : Colors.grey[200],
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomLeft: isCurrentUser ? const Radius.circular(18) : const Radius.circular(4),
          bottomRight: isCurrentUser ? const Radius.circular(4) : const Radius.circular(18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текст сообщения
          if (message.text.isNotEmpty) ...[
            Text(
              message.text,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            if (message.attachments.isNotEmpty) const SizedBox(height: 8),
          ],
          
          // Вложения
          if (message.attachments.isNotEmpty) ...[
            _buildAttachments(),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Column(
      children: message.attachments.map((attachment) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: _buildAttachment(attachment),
        );
      }).toList(),
    );
  }

  Widget _buildAttachment(MessageAttachment attachment) {
    switch (attachment.type) {
      case MessageAttachmentType.image:
        return _buildImageAttachment(attachment);
      case MessageAttachmentType.video:
        return _buildVideoAttachment(attachment);
      case MessageAttachmentType.audio:
      case MessageAttachmentType.voice:
        return _buildAudioAttachment(attachment);
      case MessageAttachmentType.document:
        return _buildDocumentAttachment(attachment);
      case MessageAttachmentType.sticker:
        return _buildStickerAttachment(attachment);
    }
  }

  Widget _buildImageAttachment(MessageAttachment attachment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        attachment.url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, size: 48),
          );
        },
      ),
    );
  }

  Widget _buildVideoAttachment(MessageAttachment attachment) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          if (attachment.thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                attachment.thumbnailUrl!,
                width: 200,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white,
              size: 48,
            ),
          ),
          if (attachment.duration != null)
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(attachment.duration!),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioAttachment(MessageAttachment attachment) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            attachment.type == MessageAttachmentType.voice 
                ? Icons.mic 
                : Icons.audiotrack,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (attachment.duration != null)
                  Text(
                    _formatDuration(attachment.duration!),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.play_arrow, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildDocumentAttachment(MessageAttachment attachment) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _formatFileSize(attachment.size),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.download, color: Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStickerAttachment(MessageAttachment attachment) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Image.network(
        attachment.url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Icon(Icons.emoji_emotions, size: 48),
          );
        },
      ),
    );
  }

  Widget _buildMessageMetadata() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Время отправки
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        
        // Статус сообщения (только для текущего пользователя)
        if (isCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(message.status),
            size: 12,
            color: _getStatusColor(message.status),
          ),
        ],
        
        // Индикатор редактирования
        if (message.editedAt != null) ...[
          const SizedBox(width: 4),
          Text(
            'ред.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReactions() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.entries.map((entry) {
        final emoji = entry.key;
        final users = entry.value;
        
        return GestureDetector(
          onTap: () => onReact?.call(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 2),
                Text(
                  users.length.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Colors.orange;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.grey;
      case MessageStatus.read:
        return Colors.blue;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}.${dateTime.month}';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
