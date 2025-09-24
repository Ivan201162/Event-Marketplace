import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBot = message.isFromBot;
    final isSystem = message.isSystemMessage;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && !isBot && !isSystem) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  message.senderId.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getBubbleColor(theme, isMe, isBot, isSystem),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBot || isSystem) ...[
                      Row(
                        children: [
                          Icon(
                            isBot ? Icons.smart_toy : Icons.info,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isBot ? 'Бот-помощник' : 'Система',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    _buildMessageContent(context, theme),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            'изменено',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (isMe) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getStatusIcon(message.status),
                            size: 12,
                            color: _getStatusColor(theme, message.status),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (isMe && !isBot && !isSystem) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.secondary,
                child: Text(
                  'Я',
                  style: TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, ThemeData theme) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.text ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _getTextColor(theme),
          ),
        );
      case MessageType.image:
        return _buildImageContent(context, theme);
      case MessageType.video:
        return _buildVideoContent(context, theme);
      case MessageType.file:
        return _buildFileContent(context, theme);
      case MessageType.bot:
        return _buildBotContent(context, theme);
      case MessageType.system:
        return _buildSystemContent(context, theme);
      case MessageType.location:
        return _buildLocationContent(context, theme);
      case MessageType.contact:
        return _buildContactContent(context, theme);
    }
  }

  Widget _buildImageContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text != null && message.text!.isNotEmpty) ...[
          Text(
            message.text!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getTextColor(theme),
            ),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.fileUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: theme.colorScheme.surfaceVariant,
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: theme.colorScheme.surfaceVariant,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.broken_image,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ошибка загрузки',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.text != null && message.text!.isNotEmpty) ...[
          Text(
            message.text!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: _getTextColor(theme),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
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
                    '🎥 Видео',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _getFileIcon(message.fileType ?? ''),
            color: theme.colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'Файл',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getTextColor(theme),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    message.fileSizeFormatted,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.download,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildBotContent(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.text ?? '',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: _getTextColor(theme),
          ),
        ),
        if (message.metadata['actions'] != null) ...[
          const SizedBox(height: 8),
          _buildBotActions(context, theme),
        ],
      ],
    );
  }

  Widget _buildSystemContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message.text ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildLocationContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '📍 Местоположение',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getTextColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactContent(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.person,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '👤 Контакт',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: _getTextColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotActions(BuildContext context, ThemeData theme) {
    final actions = message.metadata['actions'] as List<dynamic>? ?? [];
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: actions.map((action) {
        return ActionChip(
          label: Text(
            action['title'] ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          onPressed: () {
            // Handle bot action
          },
        );
      }).toList(),
    );
  }

  Color _getBubbleColor(ThemeData theme, bool isMe, bool isBot, bool isSystem) {
    if (isSystem) {
      return theme.colorScheme.primaryContainer.withOpacity(0.3);
    }
    if (isBot) {
      return theme.colorScheme.secondaryContainer;
    }
    if (isMe) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.surfaceVariant;
  }

  Color _getTextColor(ThemeData theme) {
    if (message.isFromBot || message.isSystemMessage) {
      return theme.colorScheme.onSurface;
    }
    if (isMe) {
      return theme.colorScheme.onPrimary;
    }
    return theme.colorScheme.onSurface;
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

  Color _getStatusColor(ThemeData theme, MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return theme.colorScheme.onSurface.withOpacity(0.6);
      case MessageStatus.sent:
        return theme.colorScheme.onSurface.withOpacity(0.6);
      case MessageStatus.delivered:
        return theme.colorScheme.onSurface.withOpacity(0.6);
      case MessageStatus.read:
        return theme.colorScheme.primary;
      case MessageStatus.failed:
        return theme.colorScheme.error;
    }
  }

  IconData _getFileIcon(String fileType) {
    if (fileType.contains('pdf')) return Icons.picture_as_pdf;
    if (fileType.contains('word') || fileType.contains('doc')) return Icons.description;
    if (fileType.contains('excel') || fileType.contains('sheet')) return Icons.table_chart;
    if (fileType.contains('powerpoint') || fileType.contains('presentation')) return Icons.slideshow;
    if (fileType.contains('image')) return Icons.image;
    if (fileType.contains('video')) return Icons.video_file;
    if (fileType.contains('audio')) return Icons.audio_file;
    if (fileType.contains('zip') || fileType.contains('rar')) return Icons.archive;
    return Icons.attach_file;
  }
}
