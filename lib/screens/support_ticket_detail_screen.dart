import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';

/// Экран детального просмотра тикета поддержки
class SupportTicketDetailScreen extends ConsumerStatefulWidget {
  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  ConsumerState<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState
    extends ConsumerState<SupportTicketDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали тикета'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Заголовок тикета
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Тикет #${widget.ticketId}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Статус: Открыт',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ),

          // Сообщения
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Сообщение пользователя
                _buildMessageBubble(
                  'Пользователь',
                  'Описание проблемы...',
                  DateTime.now().subtract(const Duration(hours: 2)),
                  isUser: true,
                ),

                // Ответ поддержки
                _buildMessageBubble(
                  'Поддержка',
                  'Спасибо за обращение. Мы рассмотрим вашу проблему.',
                  DateTime.now().subtract(const Duration(minutes: 30)),
                  isUser: false,
                ),
              ],
            ),
          ),

          // Поле ввода сообщения
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String sender, String message, DateTime timestamp,
      {required bool isUser}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                sender[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: isUser
                    ? null
                    : Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sender,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: isUser
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUser
                          ? Colors.white70
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                sender[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Закрыть тикет'),
            onTap: () {
              Navigator.pop(context);
              _closeTicket();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Архивировать'),
            onTap: () {
              Navigator.pop(context);
              _archiveTicket();
            },
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Отправить сообщение через SupportService
      await Future.delayed(const Duration(seconds: 1));

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки сообщения: $e'),
            backgroundColor: Colors.red,
          ),
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

  void _closeTicket() {
    // TODO: Закрыть тикет через SupportService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Тикет закрыт'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _archiveTicket() {
    // TODO: Архивировать тикет через SupportService
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Тикет архивирован'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
