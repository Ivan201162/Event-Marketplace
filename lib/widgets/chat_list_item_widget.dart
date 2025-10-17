import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/enhanced_chat.dart';
import '../models/enhanced_message.dart';

/// Виджет элемента списка чатов
class ChatListItemWidget extends StatelessWidget {
  const ChatListItemWidget({
    super.key,
    required this.chat,
    this.onTap,
    this.onPin,
    this.onDelete,
  });
  final EnhancedChat chat;
  final VoidCallback? onTap;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Аватар с онлайн статусом
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          chat.avatarUrl != null ? NetworkImage(chat.avatarUrl!) : null,
                      child: chat.avatarUrl == null
                          ? Text(
                              chat.name?.substring(0, 1).toUpperCase() ?? '?',
                            )
                          : null,
                    ),
                    if (chat.members.any((member) => member.isOnline))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 12),

                // Основная информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Имя и время
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.name ?? 'Без имени',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            chat.lastMessage != null
                                ? _formatTime(chat.lastMessage!.createdAt)
                                : '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Последнее сообщение
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getLastMessageText(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            chat.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 20,
                          ),
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
}
