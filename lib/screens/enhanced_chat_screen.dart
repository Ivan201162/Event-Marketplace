import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/enhanced_chat.dart';
import '../models/enhanced_message.dart';
import '../services/enhanced_chats_service.dart';
import '../widgets/message_bubble_widget.dart';
import '../widgets/message_input_widget.dart';

/// Расширенный экран чата
class EnhancedChatScreen extends ConsumerStatefulWidget {
  const EnhancedChatScreen({
    super.key,
    required this.chatId,
  });

  final String chatId;

  @override
  ConsumerState<EnhancedChatScreen> createState() => _EnhancedChatScreenState();
}

class _EnhancedChatScreenState extends ConsumerState<EnhancedChatScreen> {
  final EnhancedChatsService _chatsService = EnhancedChatsService();
  final ScrollController _scrollController = ScrollController();

  EnhancedChat? _chat;
  List<EnhancedMessage> _messages = [];
  bool _isLoading = true;
  String? _error;
  MessageReply? _replyTo;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _loadMessages();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      // TODO: Реализовать получение чата по ID
      // Пока что создаём заглушку
      setState(() {
        _chat = _createMockChat();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);

    try {
      // TODO: Реализовать получение сообщений
      // Пока что создаём заглушку
      setState(() {
        _messages = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  EnhancedChat _createMockChat() => EnhancedChat(
        id: widget.chatId,
        type: ChatType.direct,
        members: [
          ChatMember(
            userId: 'user_1',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            isOnline: true,
          ),
          ChatMember(
            userId: 'user_2',
            role: ChatMemberRole.member,
            joinedAt: DateTime.now().subtract(const Duration(days: 1)),
            lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        name: 'Тестовый чат',
        lastMessage: ChatLastMessage(
          id: '1',
          senderId: 'user_1',
          text: 'Привет! Как дела?',
          type: MessageType.text,
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _loadChat();
                  _loadMessages();
                },
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат не найден')),
        body: const Center(child: Text('Чат не найден')),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _buildMessagesList(),
          ),

          // Индикатор печати
          if (_isTyping) _buildTypingIndicator(),

          // Поле ввода сообщений
          MessageInputWidget(
            onSendMessage: _sendTextMessage,
            onSendMedia: _sendMediaMessage,
            onSendVoice: _sendVoiceMessage,
            onSendDocument: _sendDocumentMessage,
            replyTo: _replyTo,
            onCancelReply: _cancelReply,
            isTyping: _isTyping,
            onTypingChanged: _onTypingChanged,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chat!.name ?? 'Чат',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_chat!.type == ChatType.direct) ...[
                    Text(
                      _getOnlineStatus(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
            tooltip: 'Видеозвонок',
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: _startVoiceCall,
            tooltip: 'Голосовой звонок',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: ListTile(
                  leading: Icon(Icons.search),
                  title: Text('Поиск'),
                ),
              ),
              const PopupMenuItem(
                value: 'media',
                child: ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Медиафайлы'),
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Настройки'),
                ),
              ),
              const PopupMenuItem(
                value: 'pin',
                child: ListTile(
                  leading: Icon(Icons.push_pin),
                  title: Text('Закрепить'),
                ),
              ),
              const PopupMenuItem(
                value: 'mute',
                child: ListTile(
                  leading: Icon(Icons.volume_off),
                  title: Text('Заглушить'),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Начните общение',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Отправьте первое сообщение',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser =
            message.senderId == 'current_user'; // TODO: Получить из провайдера
        final showAvatar = index == _messages.length - 1 ||
            _messages[index + 1].senderId != message.senderId;

        return MessageBubbleWidget(
          message: message,
          isCurrentUser: isCurrentUser,
          showAvatar: showAvatar,
          onTap: () => _onMessageTap(message),
          onLongPress: () => _onMessageLongPress(message),
          onReply: () => _replyToMessage(message),
          onForward: () => _forwardMessage(message),
          onEdit: () => _editMessage(message),
          onDelete: () => _deleteMessage(message),
          onReact: (emoji) => _reactToMessage(message, emoji),
        );
      },
    );
  }

  Widget _buildTypingIndicator() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 40), // Отступ для выравнивания с сообщениями
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Печатает',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  String _getOnlineStatus() {
    final otherMember = _chat!.members.firstWhere(
      (member) =>
          member.userId != 'current_user', // TODO: Получить из провайдера
      orElse: () => _chat!.members.first,
    );

    if (otherMember.isOnline) {
      return 'В сети';
    } else if (otherMember.lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(otherMember.lastSeen!);

      if (difference.inMinutes < 60) {
        return 'Был(а) в сети ${difference.inMinutes} мин назад';
      } else if (difference.inHours < 24) {
        return 'Был(а) в сети ${difference.inHours} ч назад';
      } else {
        return 'Был(а) в сети ${difference.inDays} дн назад';
      }
    } else {
      return 'Не в сети';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'search':
        _searchMessages();
        break;
      case 'media':
        _showMediaFiles();
        break;
      case 'settings':
        _showChatSettings();
        break;
      case 'pin':
        _pinChat();
        break;
      case 'mute':
        _muteChat();
        break;
    }
  }

  void _onMessageTap(EnhancedMessage message) {
    // TODO: Реализовать обработку нажатия на сообщение
  }

  void _onMessageLongPress(EnhancedMessage message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildMessageActionsSheet(message),
    );
  }

  Widget _buildMessageActionsSheet(EnhancedMessage message) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Ответить'),
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
            if (message.senderId == 'current_user') ...[
              // TODO: Получить из провайдера
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Копировать'),
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
          ],
        ),
      );

  void _sendTextMessage(String text) {
    // TODO: Реализовать отправку текстового сообщения
    debugPrint('Отправка текстового сообщения: $text');
  }

  void _sendMediaMessage(
    List<MessageAttachment> attachments, {
    String? caption,
  }) {
    // TODO: Реализовать отправку медиа сообщения
    debugPrint('Отправка медиа сообщения: ${attachments.length} файлов');
  }

  void _sendVoiceMessage(MessageAttachment voiceAttachment) {
    // TODO: Реализовать отправку голосового сообщения
    debugPrint('Отправка голосового сообщения');
  }

  void _sendDocumentMessage(List<MessageAttachment> documents) {
    // TODO: Реализовать отправку документов
    debugPrint('Отправка документов: ${documents.length} файлов');
  }

  void _replyToMessage(EnhancedMessage message) {
    setState(() {
      _replyTo = MessageReply(
        messageId: message.id,
        senderId: message.senderId,
        text: message.text,
        type: message.type,
      );
    });
  }

  void _cancelReply() {
    setState(() {
      _replyTo = null;
    });
  }

  void _forwardMessage(EnhancedMessage message) {
    // TODO: Реализовать пересылку сообщения
    debugPrint('Пересылка сообщения: ${message.id}');
  }

  void _editMessage(EnhancedMessage message) {
    // TODO: Реализовать редактирование сообщения
    debugPrint('Редактирование сообщения: ${message.id}');
  }

  void _deleteMessage(EnhancedMessage message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сообщение'),
        content: const Text('Вы уверены, что хотите удалить это сообщение?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Реализовать удаление сообщения
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _reactToMessage(EnhancedMessage message, String emoji) {
    // TODO: Реализовать реакцию на сообщение
    debugPrint('Реакция на сообщение: $emoji');
  }

  void _copyMessage(EnhancedMessage message) {
    // TODO: Реализовать копирование сообщения
    debugPrint('Копирование сообщения');
  }

  void _onTypingChanged(bool isTyping) {
    setState(() {
      _isTyping = isTyping;
    });
  }

  void _startVideoCall() {
    // TODO: Реализовать видеозвонок
    debugPrint('Начало видеозвонка');
  }

  void _startVoiceCall() {
    // TODO: Реализовать голосовой звонок
    debugPrint('Начало голосового звонка');
  }

  void _searchMessages() {
    // TODO: Реализовать поиск по сообщениям
    debugPrint('Поиск по сообщениям');
  }

  void _showMediaFiles() {
    // TODO: Реализовать показ медиафайлов
    debugPrint('Показ медиафайлов');
  }

  void _showChatSettings() {
    // TODO: Реализовать настройки чата
    debugPrint('Настройки чата');
  }

  void _pinChat() {
    // TODO: Реализовать закрепление чата
    debugPrint('Закрепление чата');
  }

  void _muteChat() {
    // TODO: Реализовать заглушение чата
    debugPrint('Заглушение чата');
  }
}
