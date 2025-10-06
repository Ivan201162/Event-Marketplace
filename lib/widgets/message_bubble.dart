import 'package:flutter/material.dart';
import '../models/chat_message.dart';

/// Виджет для отображения сообщения в чате
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.onTap,
    this.onLongPress,
  });
  final ChatMessage message;
  final bool isFromCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: isFromCurrentUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isFromCurrentUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.grey[200],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isFromCurrentUser ? 20 : 4),
                      bottomRight: Radius.circular(isFromCurrentUser ? 4 : 20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isFromCurrentUser)
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (!isFromCurrentUser) const SizedBox(height: 4),
                      _buildMessageContent(context),
                      const SizedBox(height: 4),
                      _buildMessageFooter(context),
                    ],
                  ),
                ),
              ),
              if (isFromCurrentUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    message.senderName.isNotEmpty
                        ? message.senderName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      );

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isFromCurrentUser ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.video:
        return _buildVideoMessage(context);
      case MessageType.audio:
        return _buildAudioMessage(context);
      case MessageType.document:
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      case MessageType.system:
        return _buildSystemMessage(context);
      default:
        return _buildAttachmentMessage(context);
    }
  }

  Widget _buildImageMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.fileUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.fileUrl!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 200,
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ],
      );

  Widget _buildVideoMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.fileUrl != null)
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  if (message.thumbnailUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.thumbnailUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          if (message.content.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
          ],
        ],
      );

  Widget _buildAudioMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.audiotrack,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildFileMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getFileIcon(),
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? message.content,
                    style: TextStyle(
                      color: isFromCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (message.fileSize != null)
                    Text(
                      message.formattedFileSize,
                      style: TextStyle(
                        color: isFromCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildLocationMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildSystemMessage(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info,
              color: Colors.blue[600],
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildAttachmentMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.attachment,
              color: isFromCurrentUser ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              message.content,
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );

  Widget _buildMessageFooter(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: TextStyle(
              color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 16,
              color: _getStatusColor(),
            ),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              'изменено',
              style: TextStyle(
                color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );

  IconData _getFileIcon() {
    final fileName = message.fileName?.toLowerCase() ?? '';

    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (fileName.endsWith('.doc') || fileName.endsWith('.docx')) {
      return Icons.description;
    }
    if (fileName.endsWith('.xls') || fileName.endsWith('.xlsx')) {
      return Icons.table_chart;
    }
    if (fileName.endsWith('.ppt') || fileName.endsWith('.pptx')) {
      return Icons.slideshow;
    }
    if (fileName.endsWith('.zip') || fileName.endsWith('.rar')) {
      return Icons.archive;
    }
    if (fileName.endsWith('.txt')) return Icons.text_snippet;

    return Icons.insert_drive_file;
  }

  IconData _getStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.done;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  Color _getStatusColor() {
    switch (message.status) {
      case MessageStatus.sending:
        return Colors.grey;
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

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}.${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
