import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/message_reaction_service.dart';
import '../models/chat_message_extended.dart';

/// Виджет для отображения и управления реакциями на сообщения
class MessageReactionsWidget extends ConsumerStatefulWidget {
  final ChatMessageExtended message;
  final String currentUserId;
  final String currentUserName;
  final bool isOwnMessage;

  const MessageReactionsWidget({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.currentUserName,
    this.isOwnMessage = false,
  });

  @override
  ConsumerState<MessageReactionsWidget> createState() => _MessageReactionsWidgetState();
}

class _MessageReactionsWidgetState extends ConsumerState<MessageReactionsWidget> {
  final MessageReactionService _reactionService = MessageReactionService();
  bool _showEmojiPicker = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Существующие реакции
        if (widget.message.reactions.isNotEmpty) ...[
          _buildReactionsList(),
          const SizedBox(height: 8),
        ],
        
        // Кнопка добавления реакции
        _buildAddReactionButton(),
        
        // Эмодзи пикер
        if (_showEmojiPicker) ...[
          const SizedBox(height: 8),
          _buildEmojiPicker(),
        ],
      ],
    );
  }

  Widget _buildReactionsList() {
    // Группируем реакции по эмодзи
    final reactionsByEmoji = <String, List<MessageReaction>>{};
    for (final reaction in widget.message.reactions) {
      reactionsByEmoji.putIfAbsent(reaction.emoji, () => []).add(reaction);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: reactionsByEmoji.entries.map((entry) {
        final emoji = entry.key;
        final reactions = entry.value;
        final count = reactions.length;
        final hasCurrentUserReaction = reactions.any((r) => r.userId == widget.currentUserId);

        return GestureDetector(
          onTap: () => _toggleReaction(emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasCurrentUserReaction 
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasCurrentUserReaction 
                    ? Theme.of(context).primaryColor.withOpacity(0.3)
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                if (count > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: hasCurrentUserReaction 
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAddReactionButton() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showEmojiPicker = !_showEmojiPicker;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showEmojiPicker ? Icons.close : Icons.add_reaction,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              _showEmojiPicker ? 'Закрыть' : 'Реакция',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    final emojisByCategory = _reactionService.getEmojisByCategory();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Популярные эмодзи
          _buildEmojiCategory(
            'Популярные',
            _reactionService.getPopularEmojis().take(12).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Категории эмодзи
          ...emojisByCategory.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEmojiCategory(entry.key, entry.value),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmojiCategory(String title, List<String> emojis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () => _addReaction(emoji),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _addReaction(String emoji) async {
    final success = await _reactionService.addReaction(
      messageId: widget.message.id,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      emoji: emoji,
    );

    if (success) {
      setState(() {
        _showEmojiPicker = false;
      });
    } else {
      _showErrorSnackBar('Не удалось добавить реакцию');
    }
  }

  void _toggleReaction(String emoji) async {
    final success = await _reactionService.toggleReaction(
      messageId: widget.message.id,
      userId: widget.currentUserId,
      userName: widget.currentUserName,
      emoji: emoji,
    );

    if (!success) {
      _showErrorSnackBar('Не удалось изменить реакцию');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// Виджет для отображения детальной информации о реакциях
class ReactionDetailsWidget extends StatelessWidget {
  final List<MessageReaction> reactions;
  final String emoji;

  const ReactionDetailsWidget({
    super.key,
    required this.reactions,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final emojiReactions = reactions.where((r) => r.emoji == emoji).toList();
    
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text('${emojiReactions.length}'),
                ],
              ),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: emojiReactions.length,
                itemBuilder: (context, index) {
                  final reaction = emojiReactions[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        reaction.userName.isNotEmpty 
                            ? reaction.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(reaction.userName),
                    subtitle: Text(
                      _formatDate(reaction.timestamp),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Сегодня в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера в ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
