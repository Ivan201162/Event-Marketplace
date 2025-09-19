import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_message_extended.dart';
import '../widgets/message_reactions_widget.dart';
import '../widgets/voice_player_widget.dart';
// import '../models/user.dart';
import '../widgets/voice_recorder_widget.dart';

/// Расширенный экран чата с голосовыми сообщениями и реакциями
class ChatExtendedScreen extends ConsumerStatefulWidget {
  const ChatExtendedScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
    required this.otherUserName,
    this.otherUserAvatar,
  });
  final String chatId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;
  final String otherUserName;
  final String? otherUserAvatar;

  @override
  ConsumerState<ChatExtendedScreen> createState() => _ChatExtendedScreenState();
}

class _ChatExtendedScreenState extends ConsumerState<ChatExtendedScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageExtended> _messages = [];

  bool _showVoiceRecorder = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherUserAvatar != null
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUserName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isTyping)
                      const Text(
                        'печатает...',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.videocam),
              onPressed: _startVideoCall,
            ),
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: _startVoiceCall,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline),
                      SizedBox(width: 8),
                      Text('Информация о чате'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'media',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library),
                      SizedBox(width: 8),
                      Text('Медиафайлы'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'search',
                  child: Row(
                    children: [
                      Icon(Icons.search),
                      SizedBox(width: 8),
                      Text('Поиск'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Список сообщений
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isOwnMessage = message.senderId == widget.currentUserId;

                  return _buildMessageBubble(message, isOwnMessage);
                },
              ),
            ),

            // Голосовой рекордер
            if (_showVoiceRecorder)
              VoiceRecorderWidget(
                chatId: widget.chatId,
                senderId: widget.currentUserId,
                senderName: widget.currentUserName,
                senderAvatar: widget.currentUserAvatar,
                onVoiceMessageSent: _onVoiceMessageSent,
              ),

            // Поле ввода сообщения
            _buildMessageInput(),
          ],
        ),
      );

  Widget _buildMessageBubble(ChatMessageExtended message, bool isOwnMessage) =>
      Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment:
              isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwnMessage) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.otherUserAvatar != null
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isOwnMessage
                      ? Theme.of(context).primaryColor
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16).copyWith(
                    bottomLeft: isOwnMessage
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                    bottomRight: isOwnMessage
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Содержимое сообщения
                    if (message.type == MessageType.voice)
                      VoicePlayerWidget(
                        message: message,
                        isOwnMessage: isOwnMessage,
                      )
                    else
                      Text(
                        message.content,
                        style: TextStyle(
                          color: isOwnMessage ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Время и статус
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isOwnMessage
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (isOwnMessage) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.done,
                            size: 16,
                            color: message.isRead
                                ? Colors.blue[300]
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ],
                    ),

                    // Реакции
                    if (message.reactions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      MessageReactionsWidget(
                        message: message,
                        currentUserId: widget.currentUserId,
                        currentUserName: widget.currentUserName,
                        isOwnMessage: isOwnMessage,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isOwnMessage) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundImage: widget.currentUserAvatar != null
                    ? NetworkImage(widget.currentUserAvatar!)
                    : null,
                child: widget.currentUserAvatar == null
                    ? Text(
                        widget.currentUserName.isNotEmpty
                            ? widget.currentUserName[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
            ],
          ],
        ),
      );

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          children: [
            // Кнопка голосового сообщения
            IconButton(
              icon: Icon(
                _showVoiceRecorder ? Icons.keyboard : Icons.mic,
                color: _showVoiceRecorder
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _showVoiceRecorder = !_showVoiceRecorder;
                });
              },
            ),

            // Поле ввода текста
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Напишите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onChanged: _onTextChanged,
                onSubmitted: (value) => _sendTextMessage(),
              ),
            ),

            const SizedBox(width: 8),

            // Кнопка отправки
            GestureDetector(
              onTap: _sendTextMessage,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      );

  void _loadMessages() {
    // TODO: Загрузить сообщения из Firestore
    // Пока добавляем тестовые сообщения
    setState(() {
      _messages.addAll([
        ChatMessageExtended(
          id: '1',
          chatId: widget.chatId,
          senderId: widget.otherUserName,
          senderName: widget.otherUserName,
          content: 'Привет! Как дела?',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        ChatMessageExtended(
          id: '2',
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          senderName: widget.currentUserName,
          content: 'Привет! Всё отлично, спасибо!',
          timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ]);
    });
  }

  void _sendTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessageExtended(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      content: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(message);
    });

    _messageController.clear();
    _scrollToBottom();

    // TODO: Отправить сообщение в Firestore
  }

  void _onVoiceMessageSent(ChatMessageExtended message) {
    setState(() {
      _messages.add(message);
      _showVoiceRecorder = false;
    });

    _scrollToBottom();
  }

  void _onTextChanged(String text) {
    // TODO: Отправить статус "печатает"
    setState(() {
      _isTyping = text.isNotEmpty;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVideoCall() {
    // TODO: Начать видеозвонок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Видеозвонок (в разработке)')),
    );
  }

  void _startVoiceCall() {
    // TODO: Начать голосовой звонок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Голосовой звонок (в разработке)')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showChatInfo();
        break;
      case 'media':
        _showMediaFiles();
        break;
      case 'search':
        _showSearchDialog();
        break;
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о чате'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: widget.otherUserAvatar != null
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? Text(
                        widget.otherUserName.isNotEmpty
                            ? widget.otherUserName[0].toUpperCase()
                            : '?',
                      )
                    : null,
              ),
              title: Text(widget.otherUserName),
              subtitle: const Text('Активен'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Медиафайлы'),
              trailing: const Text('0'),
              onTap: () {
                Navigator.pop(context);
                _showMediaFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Поиск'),
              onTap: () {
                Navigator.pop(context);
                _showSearchDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showMediaFiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Медиафайлы (в разработке)')),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск сообщений'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите текст для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            // TODO: Выполнить поиск
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Поиск: $query (в разработке)')),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Вчера ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}.${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
