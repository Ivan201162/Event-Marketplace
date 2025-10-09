import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../core/navigation/app_navigator.dart';
import '../models/chat.dart';
import '../services/chat_media_service.dart';
import '../services/chat_service.dart';
import '../widgets/attachment_picker.dart';
import '../widgets/auth_gate.dart';
import '../widgets/message_bubble.dart';

/// Экран конкретного чата
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherParticipantId,
    required this.otherParticipantName,
    this.otherParticipantAvatar,
  });
  final String chatId;
  final String otherParticipantId;
  final String otherParticipantName;
  final String? otherParticipantAvatar;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ChatService _chatService = ChatService();
  final ChatMediaService _mediaService = ChatMediaService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadCachedMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCachedMessages() async {
    final cachedMessages = await _chatService.getCachedMessages(widget.chatId);
    if (mounted) {
      setState(() {
        _messages = cachedMessages;
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    if (currentUser != null) {
      await _chatService.markMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Ошибка загрузки пользователя: $e')),
      ),
      data: (currentUser) {
        if (currentUser == null) {
          return const Scaffold(
            body: Center(
              child: Text('Необходимо войти в систему'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: AppNavigator.buildBackButton(context),
            title: Row(
              children: [
                Hero(
                  tag: 'chat_avatar_${widget.otherParticipantId}',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.otherParticipantAvatar != null
                        ? NetworkImage(widget.otherParticipantAvatar!)
                        : null,
                    child: widget.otherParticipantAvatar == null
                        ? Text(
                            widget.otherParticipantName.isNotEmpty
                                ? widget.otherParticipantName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.otherParticipantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'в сети',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
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
                        Icon(Icons.info),
                        SizedBox(width: 8),
                        Text('Информация о чате'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('Поиск в чате'),
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
                    value: 'block',
                    child: Row(
                      children: [
                        Icon(Icons.block),
                        SizedBox(width: 8),
                        Text('Заблокировать'),
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
                    if (snapshot.hasData) {
                      _messages = snapshot.data!;
                    }

                    if (_messages.isEmpty && !snapshot.hasData) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Начните общение',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Отправьте первое сообщение',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isFromCurrentUser =
                            message.senderId == currentUser.uid;

                        return MessageBubble(
                          message: message,
                          isFromCurrentUser: isFromCurrentUser,
                          onTap: () => _showMessageOptions(context, message),
                          onLongPress: () =>
                              _showMessageContextMenu(context, message),
                        );
                      },
                    );
                  },
                ),
              ),
              // Поле ввода сообщения
              _buildMessageInput(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Кнопка прикрепления
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachmentOptions,
              color: Theme.of(context).primaryColor,
            ),
            // Поле ввода
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendTextMessage,
              ),
            ),
            const SizedBox(width: 8),
            // Кнопка отправки
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: _isLoading
                    ? null
                    : () => _sendTextMessage(_messageController.text),
              ),
            ),
          ],
        ),
      );

  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final currentUserAsync = ref.read(currentUserProvider);
    final currentUser = currentUserAsync.value;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    _messageController.clear();

    try {
      await _chatService.sendTextMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        text: text.trim(),
        senderName: currentUser.name,
      );

      // Прокручиваем вниз
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки сообщения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => AttachmentPicker(
        onImageSelected: _sendImageMessage,
        onVideoSelected: _sendVideoMessage,
        onFileSelected: _sendFileMessage,
        onAudioSelected: _sendAudioMessage,
      ),
    );
  }

  Future<void> _sendImageMessage() async {
    try {
      final imageFile = await _mediaService.pickImage();
      if (imageFile == null) return;

      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      final success = await _mediaService.sendImageMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
        imageFile: imageFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение отправлено')),
        );
        _loadCachedMessages(); // Обновляем список сообщений
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отправки изображения')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки изображения: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendVideoMessage() async {
    try {
      final videoFile = await _mediaService.pickVideo();
      if (videoFile == null) return;

      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      final success = await _mediaService.sendVideoMessage(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
        videoFile: videoFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Видео отправлено')),
        );
        _loadCachedMessages(); // Обновляем список сообщений
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка отправки видео')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки видео: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendFileMessage() async {
    try {
      final currentUserAsync = ref.read(currentUserProvider);
      final currentUser = currentUserAsync.value;
      if (currentUser == null) return;

      setState(() {
        _isLoading = true;
      });

      await _chatService.pickAndSendFile(
        chatId: widget.chatId,
        senderId: currentUser.uid,
        senderName: currentUser.name,
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки файла: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendAudioMessage() async {
    // TODO(developer): Реализовать запись и отправку аудио
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Функция записи аудио будет добавлена в следующих версиях'),
      ),
    );
  }

  void _showMessageOptions(BuildContext context, ChatMessage message) {
    if (message.type == MessageType.image ||
        message.type == MessageType.video) {
      _showMediaViewer(context, message);
    }
  }

  void _showMessageContextMenu(BuildContext context, ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать'),
                onTap: () {
                  context.pop();
                  // TODO(developer): Реализовать копирование
                },
              ),
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Ответить'),
                onTap: () {
                  context.pop();
                  // TODO(developer): Реализовать ответ на сообщение
                },
              ),
              ListTile(
                leading: const Icon(Icons.forward),
                title: const Text('Переслать'),
                onTap: () {
                  context.pop();
                  // TODO(developer): Реализовать пересылку
                },
              ),
              if (message.senderId == ref.read(currentUserProvider).value?.uid) ...[
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Редактировать'),
                  onTap: () {
                    context.pop();
                    _editMessage(message);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Удалить',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    context.pop();
                    _deleteMessage(message);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaViewer(BuildContext context, ChatMessage message) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MediaViewerScreen(
          message: message,
        ),
      ),
    );
  }

  void _editMessage(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          controller: TextEditingController(text: message.content),
          decoration: const InputDecoration(
            hintText: 'Введите новый текст...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              // TODO(developer): Реализовать редактирование сообщения
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _deleteMessage(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить сообщение'),
        content: const Text('Вы уверены, что хотите удалить это сообщение?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              _chatService.deleteMessage(message.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _startVideoCall() {
    // TODO(developer): Реализовать видеозвонок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Функция видеозвонка будет добавлена в следующих версиях'),
      ),
    );
  }

  void _startVoiceCall() {
    // TODO(developer): Реализовать голосовой звонок
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Функция голосового звонка будет добавлена в следующих версиях',
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'info':
        _showChatInfo();
        break;
      case 'search':
        _searchInChat();
        break;
      case 'media':
        _showMediaFiles();
        break;
      case 'block':
        _blockUser();
        break;
    }
  }

  void _showChatInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о чате'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Участник: ${widget.otherParticipantName}'),
            Text('ID чата: ${widget.chatId}'),
            Text('Сообщений: ${_messages.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _searchInChat() {
    // TODO(developer): Реализовать поиск в чате
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Функция поиска в чате будет добавлена в следующих версиях',
        ),
      ),
    );
  }

  void _showMediaFiles() {
    // TODO(developer): Реализовать показ медиафайлов
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Функция просмотра медиафайлов будет добавлена в следующих версиях',
        ),
      ),
    );
  }

  void _blockUser() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Заблокировать пользователя'),
        content: Text(
          'Вы уверены, что хотите заблокировать ${widget.otherParticipantName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              context.pop();
              // TODO(developer): Реализовать блокировку пользователя
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пользователь заблокирован')),
              );
            },
            child: const Text('Заблокировать'),
          ),
        ],
      ),
    );
  }
}

/// Экран просмотра медиафайлов
class MediaViewerScreen extends StatelessWidget {
  const MediaViewerScreen({
    super.key,
    required this.message,
  });
  final ChatMessage message;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(message.typeName),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.black,
        body: Center(
          child: message.fileUrl != null
              ? InteractiveViewer(
                  child: message.type == MessageType.image
                      ? CachedNetworkImage(
                          imageUrl: message.fileUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.error,
                            color: Colors.white,
                            size: 64,
                          ),
                        )
                      : message.type == MessageType.video
                          ? const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 64,
                            )
                          : const Icon(
                              Icons.file_present,
                              color: Colors.white,
                              size: 64,
                            ),
                )
              : const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 64,
                ),
        ),
      );
}
