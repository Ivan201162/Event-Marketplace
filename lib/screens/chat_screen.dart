import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat.dart';
import '../models/message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/chat_header.dart';
import '../widgets/file_preview.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String currentUserId;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.currentUserId,
    this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more messages when near bottom
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    try {
      final messageService = ref.read(messageServiceProvider);
      await messageService.sendTextMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        text: text,
      );
      
      // Mark chat as read
      final chatService = ref.read(chatServiceProvider);
      await chatService.markChatAsRead(widget.chatId, widget.currentUserId);
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки сообщения: $e')),
        );
      }
    }
  }

  Future<void> _sendImage() async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      
      final imageUrl = await fileUploadService.uploadImage(
        chatId: widget.chatId,
        userId: widget.currentUserId,
        source: ImageSource.gallery,
        onProgress: (progress) {
          // Update upload progress
        },
      );
      
      await messageService.sendFileMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        fileUrl: imageUrl,
        fileName: 'image.jpg',
        fileType: 'image/jpeg',
        fileSize: 0, // Will be updated by service
        type: MessageType.image,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки изображения: $e')),
        );
      }
    }
  }

  Future<void> _sendVideo() async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      
      final videoUrl = await fileUploadService.uploadVideo(
        chatId: widget.chatId,
        userId: widget.currentUserId,
        source: ImageSource.gallery,
        onProgress: (progress) {
          // Update upload progress
        },
      );
      
      await messageService.sendFileMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        fileUrl: videoUrl,
        fileName: 'video.mp4',
        fileType: 'video/mp4',
        fileSize: 0, // Will be updated by service
        type: MessageType.video,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки видео: $e')),
        );
      }
    }
  }

  Future<void> _sendDocument() async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      
      final fileUrl = await fileUploadService.uploadDocument(
        chatId: widget.chatId,
        userId: widget.currentUserId,
        onProgress: (progress) {
          // Update upload progress
        },
      );
      
      await messageService.sendFileMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        fileUrl: fileUrl,
        fileName: 'document.pdf',
        fileType: 'application/pdf',
        fileSize: 0, // Will be updated by service
        type: MessageType.file,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки документа: $e')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Фото'),
              onTap: () {
                Navigator.pop(context);
                _sendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Видео'),
              onTap: () {
                Navigator.pop(context);
                _sendVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Документ'),
              onTap: () {
                Navigator.pop(context);
                _sendDocument();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Камера'),
              onTap: () {
                Navigator.pop(context);
                _sendImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendImageFromCamera() async {
    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final messageService = ref.read(messageServiceProvider);
      
      final imageUrl = await fileUploadService.uploadImage(
        chatId: widget.chatId,
        userId: widget.currentUserId,
        source: ImageSource.camera,
        onProgress: (progress) {
          // Update upload progress
        },
      );
      
      await messageService.sendFileMessage(
        chatId: widget.chatId,
        senderId: widget.currentUserId,
        fileUrl: imageUrl,
        fileName: 'camera_image.jpg',
        fileType: 'image/jpeg',
        fileSize: 0,
        type: MessageType.image,
      );
      
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отправки фото: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: chatAsync.when(
          data: (chat) => ChatHeader(
            chat: chat,
            currentUserId: widget.currentUserId,
          ),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Ошибка'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showChatOptions();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Начните общение!',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      isMe: message.senderId == widget.currentUserId,
                      onTap: () => _onMessageTap(message),
                      onLongPress: () => _onMessageLongPress(message),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Ошибка загрузки сообщений: $error'),
              ),
            ),
          ),
          ChatInput(
            controller: _messageController,
            focusNode: _messageFocusNode,
            onSend: _sendMessage,
            onAttachment: _showAttachmentOptions,
          ),
        ],
      ),
    );
  }

  void _onMessageTap(Message message) {
    if (message.hasFile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreview(
            message: message,
          ),
        ),
      );
    }
  }

  void _onMessageLongPress(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (message.senderId == widget.currentUserId) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Редактировать'),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Удалить'),
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
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Переслать'),
              onTap: () {
                Navigator.pop(context);
                _forwardMessage(message);
              },
            ),
            if (message.hasFile)
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Скачать'),
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(message);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _editMessage(Message message) {
    // Implement message editing
  }

  void _deleteMessage(Message message) {
    // Implement message deletion
  }

  void _copyMessage(Message message) {
    // Implement message copying
  }

  void _forwardMessage(Message message) {
    // Implement message forwarding
  }

  void _downloadFile(Message message) {
    // Implement file download
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Поиск в чате'),
              onTap: () {
                Navigator.pop(context);
                _searchInChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.media),
              title: const Text('Медиафайлы'),
              onTap: () {
                Navigator.pop(context);
                _showMediaFiles();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Документы'),
              onTap: () {
                Navigator.pop(context);
                _showDocuments();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Отключить уведомления'),
              onTap: () {
                Navigator.pop(context);
                _toggleNotifications();
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Архивировать чат'),
              onTap: () {
                Navigator.pop(context);
                _archiveChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Удалить чат'),
              onTap: () {
                Navigator.pop(context);
                _deleteChat();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _searchInChat() {
    // Implement chat search
  }

  void _showMediaFiles() {
    // Implement media files view
  }

  void _showDocuments() {
    // Implement documents view
  }

  void _toggleNotifications() {
    // Implement notifications toggle
  }

  void _archiveChat() {
    // Implement chat archiving
  }

  void _deleteChat() {
    // Implement chat deletion
  }
}