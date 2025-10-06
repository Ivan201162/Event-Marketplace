import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_bot_service.dart';

/// Виджет бота-помощника в чате поддержки
class ChatBotWidget extends ConsumerStatefulWidget {
  const ChatBotWidget({
    super.key,
    required this.chatId,
    required this.userId,
    this.onTicketCreated,
  });
  final String chatId;
  final String userId;
  final Function(String ticketId)? onTicketCreated;

  @override
  ConsumerState<ChatBotWidget> createState() => _ChatBotWidgetState();
}

class _ChatBotWidgetState extends ConsumerState<ChatBotWidget> {
  final ChatBotService _botService = ChatBotService();
  final TextEditingController _messageController = TextEditingController();
  final List<BotMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeResponse = _botService.getWelcomeMessage('default_chat');
    _messages.add(
      BotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isBot: true,
        content: welcomeResponse.content,
        suggestions: welcomeResponse.suggestions,
        type: BotMessageType.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Заголовок
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.blue[200]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Бот-помощник',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Готов помочь с вашими вопросами',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Сообщения
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessage(message);
              },
            ),
          ),

          // Поле ввода
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      hintText: 'Напишите ваш вопрос...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    onSubmitted: _isLoading ? null : _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildMessage(BotMessage message) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isBot) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: Colors.blue[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: message.isBot
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          message.isBot ? Colors.grey[100] : Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            color:
                                message.isBot ? Colors.black87 : Colors.white,
                          ),
                        ),
                        if (message.suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: message.suggestions
                                .map(
                                  (suggestion) => InkWell(
                                    onTap: () => _selectSuggestion(suggestion),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: message.isBot
                                            ? Colors.blue[50]
                                            : Colors.white
                                                .withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: message.isBot
                                              ? Colors.blue[200]!
                                              : Colors.white
                                                  .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      child: Text(
                                        suggestion,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: message.isBot
                                              ? Colors.blue[700]
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!message.isBot) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    // Добавляем сообщение пользователя
    _messages.add(
      BotMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        isBot: false,
        content: message,
        suggestions: [],
        type: BotMessageType.text,
      ),
    );

    _messageController.clear();
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем ответ от бота
      final response = await _botService.processUserMessage(
        userId: widget.userId,
        message: message,
        chatId: widget.chatId,
      );

      // Добавляем ответ бота
      _messages.add(
        BotMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isBot: true,
          content: response.content,
          suggestions: response.suggestions,
          type: _mapResponseType(response.type),
        ),
      );

      // Если создан тикет, уведомляем
      if (response.ticketId != null) {
        widget.onTicketCreated?.call(response.ticketId!);
      }
    } catch (e) {
      _messages.add(
        BotMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          isBot: true,
          content: 'Извините, произошла ошибка. Попробуйте еще раз.',
          suggestions: ['Повторить вопрос', 'Обратиться к специалисту'],
          type: BotMessageType.text,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _messageController.text = suggestion;
    _sendMessage();
  }

  BotMessageType _mapResponseType(BotResponseType responseType) {
    switch (responseType) {
      case BotResponseType.text:
        return BotMessageType.text;
      case BotResponseType.faqSuggestions:
        return BotMessageType.faqSuggestions;
      case BotResponseType.escalateToHuman:
        return BotMessageType.escalateToHuman;
      case BotResponseType.ticketCreated:
        return BotMessageType.ticketCreated;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ч назад';
    } else {
      return '${timestamp.day}.${timestamp.month}.${timestamp.year}';
    }
  }
}

/// Модель сообщения бота
class BotMessage {
  const BotMessage({
    required this.id,
    required this.isBot,
    required this.content,
    required this.suggestions,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  final String id;
  final bool isBot;
  final String content;
  final List<String> suggestions;
  final BotMessageType type;
  final DateTime timestamp;
}

/// Типы сообщений бота
enum BotMessageType {
  text,
  faqSuggestions,
  escalateToHuman,
  ticketCreated,
}
