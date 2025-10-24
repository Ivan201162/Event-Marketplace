import 'package:flutter/material.dart';

import '../models/chat.dart';

/// Элемент списка чатов
class ChatListItem extends StatelessWidget {
  final Chat chat;
  final VoidCallback? onTap;

  const ChatListItem({
    super.key,
    required this.chat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundImage: chat.otherUserAvatar != null
              ? NetworkImage(chat.otherUserAvatar!)
              : null,
          child: chat.otherUserAvatar == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.otherUserName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (chat.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                chat.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: chat.unreadCount > 0 
                      ? Colors.black87 
                      : Colors.grey[600],
                  fontWeight: chat.unreadCount > 0 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                ),
              ),
            ),
            if (chat.hasMedia)
              Icon(
                Icons.attach_file,
                size: 16,
                color: Colors.grey[600],
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chat.lastMessageAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (chat.unreadCount > 0)
              const Icon(
                Icons.circle,
                size: 8,
                color: Colors.blue,
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}д';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}м';
    } else {
      return 'сейчас';
    }
  }
}
