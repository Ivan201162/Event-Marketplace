import 'package:event_marketplace_app/models/message.dart';
import 'package:flutter/material.dart';

/// Виджет пузырька сообщения
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    required this.message, required this.isFromCurrentUser, super.key,
    this.showAvatar = false,
    this.showTime = true,
  });

  final Message message;
  final bool isFromCurrentUser;
  final bool showAvatar;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Icon(Icons.person, size: 16, color: theme.primaryColor)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser
                        ? theme.primaryColor
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isFromCurrentUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4),
                      bottomRight: isFromCurrentUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isFromCurrentUser && message.senderName != null) ...[
                        Text(
                          message.senderName!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: isFromCurrentUser
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (showTime) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.timeString,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        _buildReadStatus(theme),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (isFromCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Icon(Icons.person, size: 16, color: theme.primaryColor)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  /// Виджет статуса прочтения
  Widget _buildReadStatus(ThemeData theme) {
    if (message.read) {
      return Icon(
        Icons.done_all,
        size: 16,
        color: theme.primaryColor,
      );
    } else {
      return Icon(
        Icons.done,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      );
    }
  }
}

/// Виджет для системных сообщений
class SystemMessageBubble extends StatelessWidget {
  const SystemMessageBubble({
    required this.message, super.key,
  });

  final Message message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет для отображения времени сообщения
class MessageTimeWidget extends StatelessWidget {
  const MessageTimeWidget({
    required this.timestamp, super.key,
    this.showRelative = false,
  });

  final DateTime timestamp;
  final bool showRelative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      showRelative ? _getRelativeTime(timestamp) : _getTimeString(timestamp),
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
    );
  }

  String _getRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  String _getTimeString(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Виджет для отображения статуса печати
class TypingIndicator extends StatelessWidget {
  const TypingIndicator({
    required this.isTyping, super.key,
    this.userName,
  });

  final bool isTyping;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    if (!isTyping) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        children: [
          const SizedBox(width: 48), // Отступ для выравнивания с сообщениями
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userName != null ? '$userName печатает...' : 'Печатает...',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTypingDots(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots(ThemeData theme) {
    return SizedBox(
      width: 20,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return _TypingDot(
            delay: Duration(milliseconds: index * 200),
            color: theme.primaryColor,
          );
        }),
      ),
    );
  }
}

/// Анимированная точка для индикатора печати
class _TypingDot extends StatefulWidget {
  const _TypingDot({
    required this.delay,
    required this.color,
  });

  final Duration delay;
  final Color color;

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
