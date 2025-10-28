import 'package:event_marketplace_app/providers/chat_providers.dart';
import 'package:event_marketplace_app/widgets/chat_input.dart';
import 'package:event_marketplace_app/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран чата
class ChatScreen extends ConsumerStatefulWidget {

  const ChatScreen({
    required this.chatId, super.key,
  });
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Отметить сообщения как прочитанные
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatMessagesProvider(widget.chatId).notifier).markAsRead();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesState = ref.watch(chatMessagesProvider(widget.chatId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
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
            child: messagesState.when(
              data: (messages) => ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return MessageBubble(
                    message: message,
                    onEdit: () => _editMessage(message.id),
                    onDelete: () => _deleteMessage(message.id),
                    onReact: () => _reactToMessage(message.id),
                  );
                },
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red,),
                    const SizedBox(height: 16),
                    Text('Ошибка загрузки сообщений: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(chatMessagesProvider(widget.chatId).notifier)
                          .refreshMessages(),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Поле ввода сообщения
          ChatInput(
            controller: _messageController,
            onSend: _sendMessage,
            onAttach: _attachFile,
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    ref.read(chatMessagesProvider(widget.chatId).notifier).sendMessage(text);
    _messageController.clear();

    // Прокрутить вниз
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _attachFile() {
    // TODO: Реализовать прикрепление файлов
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Прикрепление файлов')),
    );
  }

  void _editMessage(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Введите новый текст...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (newText) {
            if (newText.trim().isNotEmpty) {
              ref
                  .read(chatMessagesProvider(widget.chatId).notifier)
                  .editMessage(messageId, newText);
              Navigator.pop(context);
            }
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

  void _deleteMessage(String messageId) {
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
          ElevatedButton(
            onPressed: () {
              ref
                  .read(chatMessagesProvider(widget.chatId).notifier)
                  .deleteMessage(messageId);
              Navigator.pop(context);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _reactToMessage(String messageId) {
    // TODO: Реализовать реакции на сообщения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Реакции на сообщения')),
    );
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Информация о чате'),
        content: const Text('Детали чата будут здесь'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
