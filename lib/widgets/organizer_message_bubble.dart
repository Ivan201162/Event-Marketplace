import 'package:event_marketplace_app/models/organizer_chat.dart';
import 'package:flutter/material.dart';

class OrganizerMessageBubble extends StatelessWidget {
  const OrganizerMessageBubble(
      {required this.message, required this.isFromCurrentUser, super.key,});
  final OrganizerMessage message;
  final bool isFromCurrentUser;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromCurrentUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: !isFromCurrentUser
                    ? Border.all(color: Theme.of(context).dividerColor)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок сообщения (для специальных типов)
                  if (message.type != OrganizerMessageType.text) ...[
                    _buildMessageHeader(context),
                    const SizedBox(height: 8),
                  ],

                  // Текст сообщения
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Время и статус
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: isFromCurrentUser
                              ? Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.7)
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? Colors.blue
                              : Theme.of(context)
                                  .colorScheme
                                  .onPrimary
                                  .withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                message.senderName.isNotEmpty
                    ? message.senderName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,),
              ),
            ),
          ],
        ],
      );

  Widget _buildMessageHeader(BuildContext context) {
    Color headerColor;
    IconData headerIcon;

    switch (message.type) {
      case OrganizerMessageType.specialistProposal:
        headerColor = Colors.green;
        headerIcon = Icons.person_add;
      case OrganizerMessageType.specialistRejection:
        headerColor = Colors.red;
        headerIcon = Icons.person_remove;
      case OrganizerMessageType.bookingRequest:
        headerColor = Colors.blue;
        headerIcon = Icons.book_online;
      case OrganizerMessageType.bookingConfirmation:
        headerColor = Colors.green;
        headerIcon = Icons.check_circle;
      case OrganizerMessageType.bookingCancellation:
        headerColor = Colors.red;
        headerIcon = Icons.cancel;
      case OrganizerMessageType.file:
        headerColor = Colors.orange;
        headerIcon = Icons.attach_file;
      case OrganizerMessageType.image:
        headerColor = Colors.purple;
        headerIcon = Icons.image;
      case OrganizerMessageType.system:
        headerColor = Colors.grey;
        headerIcon = Icons.info;
      default:
        headerColor = Colors.blue;
        headerIcon = Icons.message;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: headerColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: headerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(headerIcon, size: 14, color: headerColor),
          const SizedBox(width: 4),
          Text(
            message.displayType,
            style: TextStyle(
                color: headerColor, fontSize: 12, fontWeight: FontWeight.bold,),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Виджет для отображения системных сообщений
class SystemMessageWidget extends StatelessWidget {
  const SystemMessageWidget({required this.message, super.key});
  final OrganizerMessage message;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(message.text,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),),
            ],
          ),
        ),
      );
}
