import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

import '../models/chat.dart';
import '../models/chat_message.dart' as chat_message;
import '../models/chat_attachment.dart';
import '../models/chat_bot.dart';
import '../providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../services/attachment_service.dart';
import '../services/chat_bot_service.dart';
import '../widgets/chat_attachment_widget.dart';
import '../widgets/chat_bot_message_widget.dart';

/// Экран чата
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
  });
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isUploadingFile = false;
  final AttachmentService _attachmentService = AttachmentService();
  final ChatBotService _chatBotService = ChatBotService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatProvider(widget.chatId));
    final messagesAsync = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: chatAsync.when(
          data: (chat) => Text(chat?.title ?? 'Чат'),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Ошибка'),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: _isUploadingFile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
            onPressed: _isUploadingFile ? null : _attachFile,
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            onPressed: _showBotHelp,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showChatInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(chatMessagesProvider(widget.chatId)),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Поле ввода сообщения
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => const Center(
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

  Widget _buildMessageBubble(chat_message.ChatMessage message) {
    // Получаем ID текущего пользователя из провайдера
    final currentUserId = ref.read(currentUserProvider).value?.id ?? '';
    final isMe = message.senderId == currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: 100,
        ),
        decoration: BoxDecoration(
          color:
              isMe ? Theme.of(context).colorScheme.primary : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
              Text(
                message.senderName ?? 'Неизвестный',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _sendMessage,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      );

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}.${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Отправка сообщения через провайдер
    try {
      ref.read(chatStateProvider.notifier).sendMessage(
            widget.chatId,
            content,
          );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      // Показываем ошибку пользователю
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки сообщения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Future<void> _attachFile() async {
    if (_isUploadingFile) return;

    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileData = file.bytes;
        final fileName = file.name;

        if (fileData == null) {
          _showErrorSnackBar('Не удалось загрузить файл');
          return;
        }

        // Проверяем поддержку типа файла
        if (!_attachmentService.isFileTypeSupported(fileName)) {
          _showErrorSnackBar('Неподдерживаемый тип файла');
          return;
        }

        // Загружаем файл
        final currentUserId = ref.read(currentUserProvider).value?.id ?? '';
        final attachment = await _attachmentService.uploadFile(
          messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          userId: currentUserId,
          filePath: file.path ?? '',
          originalFileName: fileName,
          fileData: fileData,
        );

        if (attachment != null) {
          // Отправляем сообщение с вложением
          ref.read(chatStateProvider.notifier).sendMessage(
                widget.chatId,
                '📎 ${attachment.originalFileName}',
                attachment: attachment,
              );

          _showSuccessSnackBar('Файл загружен успешно');
        } else {
          _showErrorSnackBar('Ошибка загрузки файла');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Ошибка прикрепления файла');
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  void _showBotHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.blue),
            SizedBox(width: 8),
            Text('Бот-помощник'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Я могу помочь вам с:'),
            SizedBox(height: 8),
            Text('• Часто задаваемыми вопросами'),
            Text('• Техническими проблемами'),
            Text('• Бронированием услуг'),
            Text('• Оплатой'),
            Text('• Связью с оператором'),
            SizedBox(height: 16),
            Text('Просто напишите мне сообщение!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _messageController.text = 'Помощь';
              _sendMessage();
            },
            child: const Text('Написать боту'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о чате'),
        content: const Text('Здесь будет информация о чате и участниках'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
