import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/chat.dart';

class ChatHeader extends StatelessWidget {
  final Chat chat;
  final String currentUserId;

  const ChatHeader({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherParticipant = chat.getOtherParticipant(currentUserId);
    
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            _getDisplayName().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDisplayName(),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (chat.lastMessageAt != null)
                Text(
                  _getLastSeenText(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
        if (chat.getUnreadCount(currentUserId) > 0)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.error,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${chat.getUnreadCount(currentUserId)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  String _getDisplayName() {
    if (chat.chatType == 'support') {
      return 'Техподдержка';
    }
    
    if (chat.participants.length == 2) {
      final otherParticipant = chat.getOtherParticipant(currentUserId);
      if (otherParticipant != null) {
        // In a real app, you would fetch the user's display name from Firestore
        return 'Пользователь ${otherParticipant.substring(0, 8)}';
      }
    }
    
    return 'Групповой чат';
  }

  String _getLastSeenText() {
    if (chat.lastMessageAt == null) return '';
    
    final now = DateTime.now();
    final lastMessageAt = chat.lastMessageAt!;
    final difference = now.difference(lastMessageAt);
    
    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return DateFormat('dd.MM.yyyy').format(lastMessageAt);
    }
  }
}
