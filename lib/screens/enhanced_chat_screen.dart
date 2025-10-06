import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../services/media_upload_service.dart';
import '../services/typing_service.dart';
import '../widgets/chat_attachment_picker.dart';
import '../widgets/media_message_widget.dart';
import '../widgets/typing_indicator_widget.dart';

/// Улучшенный экран чата с полной функциональностью
class EnhancedChatScreen extends ConsumerStatefulWidget {
  const EnhancedChatScreen({
    super.key,
    required this.chatId,
    this.chatTitle,
  });

  final String chatId;
  final String? chatTitle;

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final TypingService _typingService = TypingService();

  bool _isTyping = false;
  bool _isUploading = false;
  String? _currentUserId;
  String? _currentUserName;
  List<TypingUser> _typingUsers = [];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    _loadCurrentUser();
    _setupTypingListener();
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _scrollController.removeListener(_onScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _stopTyping();
    super.dispose();
  }

  void _loadCurrentUser() {
    // TODO(developer): Получить текущего пользователя из провайдера
    _currentUserId = 'current_user_id';
    _currentUserName = 'Текущий пользователь';
  }

  void _setupTypingListener() {
    _typingService.getTypingUsers(widget.chatId).listen((users) {
      setState(() {
        _typingUsers = users;
      });
    });
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _startTyping();
    } else if (_messageController.text.isEmpty && _isTyping) {
      _stopTyping();
    }
  }

  void _onScroll() {
    // Автоматически останавливаем печатание при скролле
    if (_isTyping) {
      _stopTyping();
    }
  }

  void _startTyping() {
    if (_currentUserId != null && _currentUserName != null) {
      setState(() {
        _isTyping = true;
      });
      _typingService.startTyping(
        chatId: widget.chatId,
        userId: _currentUserId!,
        userName: _currentUserName!,
      );
    }
  }

  void _stopTyping() {
    if (_currentUserId != null) {
      setState(() {
        _isTyping = false;
      });
      _typingService.stopTyping(
        chatId: widget.chatId,
        userId: _currentUserId!,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.chatTitle ?? 'Чат'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachmentPicker,
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Очистить чат'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'chat_info',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('Информация о чате'),
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
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.getChatMessages(widget.chatId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Ошибка: ${snapshot.error}'),
                    );
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('Пока нет сообщений'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        messages.length + (_typingUsers.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _typingUsers.isNotEmpty) {
                        return AnimatedTypingIndicator(
                          typingUsers: _typingUsers,
                          currentUserId: _currentUserId,
                        );
                      }

                      final messageIndex =
                          _typingUsers.isNotEmpty ? index - 1 : index;
                      final message = messages[messageIndex];
                      final isOwnMessage = message.senderId == _currentUserId;

                      return _buildMessageBubble(message, isOwnMessage);
                    },
                  );
                },
              ),
            ),

            // Индикатор загрузки файлов
            if (_isUploading) const LinearProgressIndicator(),

            // Поле ввода сообщения
            _buildMessageInput(),
          ],
        ),
      );

  Widget _buildMessageBubble(ChatMessage message, bool isOwnMessage) {
    if (message.isAttachment) {
      return MediaMessageWidget(
        message: message,
        isOwnMessage: isOwnMessage,
        onTap: () => _handleMediaTap(message),
        onDelete: () => _deleteMessage(message.id),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Text(message.senderName[0].toUpperCase())
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isOwnMessage)
                    Text(
                      message.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isOwnMessage ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color:
                              isOwnMessage ? Colors.white70 : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isOwnMessage) ...[
                        const SizedBox(width: 4),
                        Icon(
                          _getStatusIcon(message.status),
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Text(message.senderName[0].toUpperCase())
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachmentPicker,
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed:
                  _messageController.text.isNotEmpty ? _sendMessage : null,
            ),
          ],
        ),
      );

  void _sendMessage([String? text]) {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty ||
        _currentUserId == null ||
        _currentUserName == null) {
      return;
    }

    _stopTyping();
    _messageController.clear();

    final message = ChatMessage(
      id: '', // Будет установлен Firestore
      chatId: widget.chatId,
      senderId: _currentUserId!,
      senderName: _currentUserName!,
      type: MessageType.text,
      content: messageText,
      status: MessageStatus.sending,
      timestamp: DateTime.now(),
    );

    _chatService.sendMessage(widget.chatId, message);
  }

  void _showAttachmentPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ChatAttachmentPicker(
        onFileSelected: _sendFileMessage,
        onImageSelected: _sendFileMessage,
        onVideoSelected: _sendFileMessage,
        onDocumentSelected: _sendFileMessage,
        onAudioSelected: _sendFileMessage,
      ),
    );
  }

  void _sendFileMessage(MediaUploadResult result) {
    if (_currentUserId == null || _currentUserName == null) return;

    setState(() {
      _isUploading = true;
    });

    _chatService
        .sendMessageWithMedia(
      chatId: widget.chatId,
      senderId: _currentUserId!,
      senderName: _currentUserName!,
      content: result.fileName,
      mediaResult: result,
    )
        .then((_) {
      setState(() {
        _isUploading = false;
      });
    }).catchError((error) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки файла: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _handleMediaTap(ChatMessage message) {
    // TODO(developer): Реализовать просмотр медиафайлов
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр ${message.typeName}'),
      ),
    );
  }

  void _deleteMessage(String messageId) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сообщение?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatService.deleteMessage(messageId);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_chat':
        _clearChat();
        break;
      case 'chat_info':
        _showChatInfo();
        break;
    }
  }

  void _clearChat() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить чат?'),
        content: const Text(
          'Все сообщения будут удалены. Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _chatService.clearChat(widget.chatId);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  void _showChatInfo() {
    // TODO(developer): Показать информацию о чате
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Информация о чате'),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}.${dateTime.month}.${dateTime.year}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return dateTime.minute.toString().padLeft(2, '0');
    }
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
}
