import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/chat_message.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import '../services/upload_service.dart';
import '../providers/auth_providers.dart';
import '../core/feature_flags.dart';
import '../core/safe_log.dart';

/// Экран чата
class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String? chatAvatar;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    this.chatAvatar,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UploadService _uploadService = UploadService();

  bool _isLoading = false;
  bool _isSending = false;
  String? _replyToMessageId;
  ChatMessage? _replyToMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Автоматическая прокрутка вниз при приближении к концу
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.chatAvatar != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(widget.chatAvatar!),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (FeatureFlags.chatAttachmentsEnabled)
                    const Text(
                      'Онлайн',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: _buildMessagesList(currentUser),
          ),

          // Ответ на сообщение
          if (_replyToMessage != null) _buildReplyPreview(),

          // Поле ввода сообщения
          _buildMessageInput(currentUser),
        ],
      ),
    );
  }

  Widget _buildMessagesList(AppUser? currentUser) {
    if (currentUser == null) {
      return const Center(
        child: Text('Необходимо войти в систему'),
      );
    }

    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getChatMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка загрузки сообщений: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
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
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isOwnMessage = message.senderId == currentUser.id;

            return _buildMessageBubble(message, isOwnMessage, currentUser);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
      ChatMessage message, bool isOwnMessage, AppUser currentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isOwnMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isOwnMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: message.senderAvatar != null
                  ? NetworkImage(message.senderAvatar!)
                  : null,
              child: message.senderAvatar == null
                  ? Text(message.senderName.isNotEmpty
                      ? message.senderName[0].toUpperCase()
                      : '?')
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOwnMessage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isOwnMessage
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isOwnMessage
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ответ на сообщение
                  if (message.isReply) _buildReplyIndicator(message),

                  // Содержимое сообщения
                  _buildMessageContent(message, isOwnMessage),

                  // Метаданные сообщения
                  _buildMessageMetadata(message, isOwnMessage),
                ],
              ),
            ),
          ),
          if (isOwnMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: currentUser.photoUrl != null
                  ? NetworkImage(currentUser.photoUrl!)
                  : null,
              child: currentUser.photoUrl == null
                  ? Text(currentUser.name.isNotEmpty
                      ? currentUser.name[0].toUpperCase()
                      : '?')
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyIndicator(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Ответ на сообщение',
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message, bool isOwnMessage) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: isOwnMessage
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        );

      case MessageType.image:
        return _buildImageMessage(message);

      case MessageType.video:
        return _buildVideoMessage(message);

      case MessageType.audio:
        return _buildAudioMessage(message);

      case MessageType.file:
        return _buildFileMessage(message);

      case MessageType.location:
        return _buildLocationMessage(message);

      case MessageType.system:
        return _buildSystemMessage(message);
    }
  }

  Widget _buildImageMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty) ...[
          Text(
            message.content,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            message.fileUrl!,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[300],
                child: const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoMessage(ChatMessage message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty) ...[
          Text(
            message.content,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: 200,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (message.thumbnailUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.thumbnailUrl!,
                    width: 200,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const Icon(
                Icons.play_circle_filled,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message.fileName ?? 'Видео',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAudioMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            message.fileName ?? 'Аудио',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFileMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, color: Colors.blue),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.fileName ?? 'Файл',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              if (message.fileSize != null)
                Text(
                  message.formattedFileSize,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Местоположение'),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.content,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMessageMetadata(ChatMessage message, bool isOwnMessage) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 11,
            color: isOwnMessage
                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
        if (isOwnMessage) ...[
          const SizedBox(width: 4),
          Icon(
            _getStatusIcon(message.status),
            size: 12,
            color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
          ),
        ],
        if (message.isEdited) ...[
          const SizedBox(width: 4),
          Text(
            'изменено',
            style: TextStyle(
              fontSize: 10,
              color: isOwnMessage
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
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

  Widget _buildReplyPreview() {
    if (_replyToMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ на сообщение от ${_replyToMessage!.senderName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyToMessage!.content,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              setState(() {
                _replyToMessage = null;
                _replyToMessageId = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AppUser? currentUser) {
    if (currentUser == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          // Кнопка вложений
          if (FeatureFlags.chatAttachmentsEnabled)
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: _showAttachmentOptions,
            ),

          // Поле ввода
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Введите сообщение...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (text) => _sendMessage(currentUser),
            ),
          ),

          const SizedBox(width: 8),

          // Кнопка отправки
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isSending ? null : () => _sendMessage(currentUser),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(AppUser currentUser) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _chatService.sendTextMessage(
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderAvatar: currentUser.photoUrl,
        content: text,
        replyToMessageId: _replyToMessageId,
      );

      _messageController.clear();
      setState(() {
        _replyToMessage = null;
        _replyToMessageId = null;
      });

      // Прокрутка вниз
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e, stackTrace) {
      SafeLog.error('ChatScreen: Error sending message', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки сообщения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Прикрепить файл',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Фото',
                  onTap: () => _pickAndSendImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Камера',
                  onTap: () => _pickAndSendImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.videocam,
                  label: 'Видео',
                  onTap: () => _pickAndSendVideo(),
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'Файл',
                  onTap: () => _pickAndSendFile(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final result = await _uploadService.pickAndUploadImage(source: source);
      if (result == null) return;

      await _chatService.sendAttachmentMessage(
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        file: File(result.filePath),
        messageType: MessageType.image,
        senderAvatar: currentUser.photoUrl,
        replyToMessageId: _replyToMessageId,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatScreen: Error sending image', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndSendVideo() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final result = await _uploadService.pickAndUploadVideo();
      if (result == null) return;

      await _chatService.sendAttachmentMessage(
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        file: File(result.filePath),
        messageType: MessageType.video,
        senderAvatar: currentUser.photoUrl,
        replyToMessageId: _replyToMessageId,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatScreen: Error sending video', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки видео: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndSendFile() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      final result = await _uploadService.pickAndUploadFile();
      if (result == null) return;

      await _chatService.sendAttachmentMessage(
        chatId: widget.chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        file: File(result.filePath),
        messageType: MessageType.file,
        senderAvatar: currentUser.photoUrl,
        replyToMessageId: _replyToMessageId,
      );
    } catch (e, stackTrace) {
      SafeLog.error('ChatScreen: Error sending file', e, stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Поиск в чате'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Реализовать поиск
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Информация о чате'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Показать информацию о чате
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Уведомления'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Настройки уведомлений
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('Очистить чат'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Очистка чата
              },
            ),
          ],
        ),
      ),
    );
  }
}
