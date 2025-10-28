import 'package:event_marketplace_app/models/chat.dart';
import 'package:event_marketplace_app/services/chat_service.dart';
import 'package:event_marketplace_app/services/media_upload_service.dart';
import 'package:event_marketplace_app/widgets/media_attachment_widget.dart';
import 'package:event_marketplace_app/widgets/media_message_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestMediaChatScreen extends ConsumerStatefulWidget {
  const TestMediaChatScreen({super.key});

  @override
  ConsumerState<TestMediaChatScreen> createState() =>
      _TestMediaChatScreenState();
}

class _TestMediaChatScreenState extends ConsumerState<TestMediaChatScreen> {
  final ChatService _chatService = ChatService();
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _createTestMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _createTestMessages() {
    final testMessages = [
      ChatMessage(
        id: '1',
        chatId: 'test_chat',
        senderId: 'user1',
        senderName: 'Анна',
        senderAvatar:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        type: MessageType.text,
        content: 'Привет! Как дела?',
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: '2',
        chatId: 'test_chat',
        senderId: 'user2',
        senderName: 'Максим',
        senderAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        type: MessageType.text,
        content: 'Привет! Всё отлично, спасибо! А у тебя?',
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
        id: '3',
        chatId: 'test_chat',
        senderId: 'user1',
        senderName: 'Анна',
        senderAvatar:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        type: MessageType.image,
        content: 'Посмотри на это фото!',
        fileUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        fileName: 'mountain_landscape.jpg',
        fileType: 'jpg',
        fileSize: 1024000,
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: '4',
        chatId: 'test_chat',
        senderId: 'user2',
        senderName: 'Максим',
        senderAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        type: MessageType.video,
        content: 'А вот видео с концерта',
        fileUrl:
            'https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4',
        fileName: 'concert_video.mp4',
        fileType: 'mp4',
        fileSize: 1048576,
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        id: '5',
        chatId: 'test_chat',
        senderId: 'user1',
        senderName: 'Анна',
        senderAvatar:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        type: MessageType.file,
        content: 'Документ для работы',
        fileUrl:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        fileName: 'project_document.pdf',
        fileType: 'pdf',
        fileSize: 512000,
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
        id: '6',
        chatId: 'test_chat',
        senderId: 'user2',
        senderName: 'Максим',
        senderAvatar:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100',
        type: MessageType.audio,
        content: 'Голосовое сообщение',
        fileUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        fileName: 'voice_message.wav',
        fileType: 'wav',
        fileSize: 256000,
        status: MessageStatus.read,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];

    setState(() {
      _messages.addAll(testMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Тест медиа-чата'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearMessages,
            tooltip: 'Очистить сообщения',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _createTestMessages,
            tooltip: 'Создать тестовые сообщения',
          ),
        ],
      ),
      body: Column(
        children: [
          // Информационная панель
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Text(
                  'Тестирование медиафункций чата',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Сообщений: ${_messages.length} | Загрузка: ${_isUploading ? "В процессе" : "Готово"}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // Список сообщений
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400],),
                        const SizedBox(height: 16),
                        Text(
                          'Нет сообщений',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Нажмите "Создать тестовые сообщения" или отправьте новое',
                          style:
                              TextStyle(fontSize: 14, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isOwnMessage = message.senderId ==
                          'user1'; // Симулируем текущего пользователя

                      return MediaMessageWidget(
                        message: message,
                        isOwnMessage: isOwnMessage,
                        onTap: () => _handleMediaTap(message),
                      );
                    },
                  ),
          ),

          // Поле ввода сообщения
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),),),
      ),
      child: Row(
        children: [
          // Кнопка прикрепления медиа
          IconButton(
            icon: _isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            onPressed: _isUploading ? null : _showMediaAttachmentOptions,
            tooltip: 'Прикрепить файл',
          ),

          // Поле ввода текста
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendTextMessage(),
            ),
          ),

          const SizedBox(width: 8),

          // Кнопка отправки
          FloatingActionButton.small(
              onPressed: _sendTextMessage, child: const Icon(Icons.send),),
        ],
      ),
    );
  }

  void _sendTextMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: 'test_chat',
      senderId: 'user1',
      senderName: 'Анна',
      senderAvatar:
          'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
      type: MessageType.text,
      content: content,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _showMediaAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MediaAttachmentWidget(
          onMediaSelected: _handleMediaSelected, onError: _showErrorSnackBar,),
    );
  }

  Future<void> _handleMediaSelected(MediaUploadResult mediaResult) async {
    try {
      setState(() => _isUploading = true);

      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: 'test_chat',
        senderId: 'user1',
        senderName: 'Анна',
        senderAvatar:
            'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=100',
        type: _getMessageTypeFromMediaType(mediaResult.mediaType),
        content: '${mediaResult.typeIcon} ${mediaResult.fileName}',
        fileUrl: mediaResult.fileUrl,
        fileName: mediaResult.fileName,
        fileType: mediaResult.fileType,
        fileSize: mediaResult.fileSize,
        thumbnailUrl: mediaResult.thumbnailUrl,
        metadata: {
          'storagePath': mediaResult.storagePath,
          'mediaType': mediaResult.mediaType.name,
        },
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(newMessage);
      });

      _showSuccessSnackBar('Файл загружен успешно');
      _scrollToBottom();
    } catch (e) {
      _showErrorSnackBar('Ошибка отправки файла: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  MessageType _getMessageTypeFromMediaType(MediaType mediaType) {
    switch (mediaType) {
      case MediaType.image:
        return MessageType.image;
      case MediaType.video:
        return MessageType.video;
      case MediaType.audio:
        return MessageType.audio;
      case MediaType.document:
        return MessageType.file;
      case MediaType.file:
        return MessageType.attachment;
    }
  }

  void _handleMediaTap(ChatMessage message) {
    if (message.fileUrl == null) return;

    switch (message.type) {
      case MessageType.image:
        _showImagePreview(message.fileUrl!);
      case MessageType.video:
        _showVideoPreview(message.fileUrl!);
      case MessageType.audio:
        _showAudioPreview(message.fileUrl!);
      case MessageType.file:
      case MessageType.attachment:
        _showFilePreview(message);
      default:
        break;
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Просмотр изображения'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Expanded(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, size: 64)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVideoPreview(String videoUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Видео'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library, size: 64),
            const SizedBox(height: 16),
            Text('URL: $videoUrl'),
            const SizedBox(height: 16),
            const Text('В реальном приложении здесь будет видеоплеер'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _showAudioPreview(String audioUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Аудио'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audiotrack, size: 64),
            const SizedBox(height: 16),
            Text('URL: $audioUrl'),
            const SizedBox(height: 16),
            const Text('В реальном приложении здесь будет аудиоплеер'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _showFilePreview(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Файл: ${message.fileName ?? "Неизвестный"}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Тип: ${message.fileType ?? "Неизвестный"}'),
            Text('Размер: ${message.formattedFileSize}'),
            const SizedBox(height: 16),
            Text('URL: ${message.fileUrl}'),
            const SizedBox(height: 16),
            const Text(
                'В реальном приложении здесь будет возможность скачать файл',),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Закрыть'),),
        ],
      ),
    );
  }

  void _clearMessages() {
    setState(_messages.clear);
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),);
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),);
  }
}
