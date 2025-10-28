import 'package:event_marketplace_app/models/enhanced_chat.dart';
import 'package:event_marketplace_app/models/enhanced_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Виджет элемента списка чатов
class ChatListItemWidget extends StatelessWidget {
  const ChatListItemWidget({required this.chat, super.key, this.onTap, this.onPin, this.onDelete});
  final EnhancedChat chat;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: chat.isPinned 
                ? Theme.of(context).primaryColor.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: chat.isPinned ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: chat.isPinned 
                  ? Theme.of(context).primaryColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: chat.isPinned ? 12 : 6,
              offset: Offset(0, chat.isPinned ? 6 : 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Улучшенный аватар с онлайн статусом
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: chat.avatarUrl != null
                              ? null
                              : LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).primaryColor.withOpacity(0.7),
                                  ],
                                ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage:
                              chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
                          child: chat.avatarUrl == null
                              ? Text(
                                  chat.name?.substring(0, 1).toUpperCase() ?? '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      if (chat.members.any((member) => member.isOnline))
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                const SizedBox(width: 12),

                  const SizedBox(width: 16),

                  // Улучшенная информация о чате
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Имя, время и статус
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  if (chat.isPinned)
                                    Icon(
                                      Icons.push_pin,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  if (chat.isPinned) const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      chat.name ?? 'Без имени',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.lastMessage != null
                                    ? _formatTime(chat.lastMessage!.createdAt)
                                    : '',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Последнее сообщение с индикаторами
                        Row(
                          children: [
                            // Индикатор типа сообщения
                            if (chat.lastMessage != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: _getMessageTypeIcon(chat.lastMessage!.type),
                              ),
                            Expanded(
                              child: Text(
                                _getLastMessageText(),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Индикатор прочтения
                            if (chat.lastMessage != null)
                              _getReadStatusIcon(),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Действия
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'pin':
                        onPin?.call();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(chat.isPinned ? 'Открепить' : 'Закрепить'),
                        ],
                      ),
                    ),
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
            ),
          ),
        ),
      );

  String _getLastMessageText() {
    if (chat.lastMessage == null) {
      return 'Нет сообщений';
    }

    if (chat.lastMessage!.type == MessageType.text) {
      return chat.lastMessage!.text;
    } else if (chat.lastMessage!.type == MessageType.image) {
      return '📷 Фото';
    } else if (chat.lastMessage!.type == MessageType.video) {
      return '🎥 Видео';
    } else if (chat.lastMessage!.type == MessageType.audio) {
      return '🎵 Голосовое сообщение';
    } else if (chat.lastMessage!.type == MessageType.document) {
      return '📄 Документ';
    } else if (chat.lastMessage!.type == MessageType.location) {
      return '📍 Местоположение';
    } else if (chat.lastMessage!.type == MessageType.contact) {
      return '👤 Контакт';
    } else if (chat.lastMessage!.type == MessageType.sticker) {
      return '😊 Стикер';
    } else if (chat.lastMessage!.type == MessageType.system) {
      return '⚙️ Системное сообщение';
    } else {
      return 'Неизвестный тип сообщения';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('dd.MM').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }

  Widget _getMessageTypeIcon(MessageType type) {
    IconData icon;
    Color color;

    switch (type) {
      case MessageType.text:
        return const SizedBox.shrink();
      case MessageType.image:
        icon = Icons.image;
        color = Colors.blue;
      case MessageType.video:
        icon = Icons.videocam;
        color = Colors.purple;
      case MessageType.audio:
        icon = Icons.mic;
        color = Colors.orange;
      case MessageType.document:
        icon = Icons.description;
        color = Colors.grey;
      case MessageType.location:
        icon = Icons.location_on;
        color = Colors.red;
      case MessageType.contact:
        icon = Icons.person;
        color = Colors.green;
      case MessageType.sticker:
        icon = Icons.emoji_emotions;
        color = Colors.pink;
      case MessageType.system:
        icon = Icons.settings;
        color = Colors.grey;
      default:
        icon = Icons.message;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 12, color: color),
    );
  }

  Widget _getReadStatusIcon() {
    // Симуляция статуса прочтения
    const isRead = true; // В реальном приложении это будет из данных
    const isDelivered = true;

    if (isRead) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue,
        ),
      );
    } else if (isDelivered) {
      return Icon(
        Icons.done_all,
        size: 12,
        color: Colors.grey[400],
      );
    } else {
      return Icon(
        Icons.done,
        size: 12,
        color: Colors.grey[400],
      );
    }
  }
}
