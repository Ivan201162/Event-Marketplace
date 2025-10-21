import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organizer_chat.dart';
import '../services/organizer_chat_service.dart';

class OrganizerChatsListScreen extends ConsumerStatefulWidget {
  // 'customer' или 'organizer'

  const OrganizerChatsListScreen({super.key, required this.userId, required this.userType});
  final String userId;
  final String userType;

  @override
  ConsumerState<OrganizerChatsListScreen> createState() => _OrganizerChatsListScreenState();
}

class _OrganizerChatsListScreenState extends ConsumerState<OrganizerChatsListScreen> {
  final OrganizerChatService _chatService = OrganizerChatService();
  List<OrganizerChat> _chats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<OrganizerChat> chats;
      if (widget.userType == 'customer') {
        chats = await _chatService.getCustomerChats(widget.userId);
      } else {
        chats = await _chatService.getOrganizerChats(widget.userId);
      }

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки чатов: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.userType == 'customer' ? 'Чаты с организаторами' : 'Чаты с заказчиками'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadChats, tooltip: 'Обновить'),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _chats.isEmpty
        ? _buildEmptyState()
        : _buildChatsList(),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Text('Нет чатов', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          widget.userType == 'customer'
              ? 'Начните общение с организатором'
              : 'Заказчики пока не обращались к вам',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (widget.userType == 'customer')
          ElevatedButton.icon(
            onPressed: _createNewChat,
            icon: const Icon(Icons.add),
            label: const Text('Найти организатора'),
          ),
      ],
    ),
  );

  Widget _buildChatsList() => ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: _chats.length,
    itemBuilder: (context, index) {
      final chat = _chats[index];
      return _buildChatCard(chat);
    },
  );

  Widget _buildChatCard(OrganizerChat chat) {
    final isUnread = chat.hasUnreadMessages;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 4 : 2,
      child: InkWell(
        onTap: () => _openChat(chat),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Аватар
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  (widget.userType == 'customer' ? chat.organizerName : chat.customerName)
                          .isNotEmpty
                      ? (widget.userType == 'customer' ? chat.organizerName : chat.customerName)[0]
                            .toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(width: 12),

              // Информация о чате
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Имя собеседника и время
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.userType == 'customer' ? chat.organizerName : chat.customerName,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (chat.lastMessageAt != null)
                          Text(
                            _formatTime(chat.lastMessageAt!),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Название мероприятия
                    Text(
                      chat.eventTitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Последнее сообщение
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessageText ?? 'Нет сообщений',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            child: Text(
                              '${chat.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Статус чата
              Column(
                children: [
                  _buildStatusChip(chat.status),
                  const SizedBox(height: 4),
                  if (chat.eventDate.isAfter(DateTime.now()))
                    Text(
                      _formatDate(chat.eventDate),
                      style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrganizerChatStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrganizerChatStatus.active:
        color = Colors.green;
        text = 'Активный';
        break;
      case OrganizerChatStatus.closed:
        color = Colors.red;
        text = 'Закрыт';
        break;
      case OrganizerChatStatus.archived:
        color = Colors.grey;
        text = 'Архив';
        break;
      case OrganizerChatStatus.pending:
        color = Colors.orange;
        text = 'Ожидает';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openChat(OrganizerChat chat) {
    Navigator.pushNamed(context, '/organizer-chat', arguments: chat.id);
  }

  void _createNewChat() {
    // TODO(developer): Реализовать создание нового чата
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Функция создания чата будет реализована')));
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Вчера';
    } else {
      return '${dateTime.day}.${dateTime.month}';
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}
