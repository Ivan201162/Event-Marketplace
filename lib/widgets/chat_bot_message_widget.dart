import 'package:event_marketplace_app/models/chat_bot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет для отображения сообщений бота
class ChatBotMessageWidget extends ConsumerWidget {
  const ChatBotMessageWidget({
    required this.message, super.key,
    this.onQuickReplyTap,
    this.onButtonTap,
  });
  final ChatBotMessage message;
  final void Function(String)? onQuickReplyTap;
  final void Function(BotButton)? onButtonTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватар бота
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            // Контент сообщения
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Имя бота
                  Text(
                    'Бот-помощник',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Основное сообщение
                  _buildMessageContent(context),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case BotMessageType.text:
        return _buildTextMessage(context);
      case BotMessageType.quickReply:
        return _buildQuickReplyMessage(context);
      case BotMessageType.card:
        return _buildCardMessage(context);
      case BotMessageType.list:
        return _buildListMessage(context);
      case BotMessageType.image:
        return _buildImageMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(12),),
        child: Text(message.message, style: const TextStyle(fontSize: 14)),
      );

  Widget _buildQuickReplyMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое сообщение
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),),
            child: Text(message.message, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 8),
          // Быстрые ответы
          if (message.quickReplies != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: message.quickReplies!
                  .map(
                    (reply) => GestureDetector(
                      onTap: () => onQuickReplyTap?.call(reply.payload),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8,),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Text(
                          reply.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      );

  Widget _buildCardMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое сообщение
          if (message.message.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Text(message.message, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
          ],
          // Карточки
          if (message.cards != null)
            ...message.cards!.map((card) => _buildCard(context, card)),
        ],
      );

  Widget _buildListMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое сообщение
          if (message.message.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Text(message.message, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
          ],
          // Список элементов
          if (message.listItems != null)
            ...message.listItems!.map((item) => _buildListItem(context, item)),
        ],
      );

  Widget _buildImageMessage(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Текстовое сообщение
          if (message.message.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Text(message.message, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
          ],
          // Изображение
          if (message.imageUrl != null)
            Container(
              constraints: const BoxConstraints(maxWidth: 200),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            ),
        ],
      );

  Widget _buildCard(BuildContext context, BotCard card) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        width: 250,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение карточки
            if (card.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  card.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            // Контент карточки
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold,),),
                  if (card.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(card.subtitle!,
                        style:
                            TextStyle(fontSize: 14, color: Colors.grey[600]),),
                  ],
                  // Кнопки карточки
                  if (card.buttons != null && card.buttons!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ...card.buttons!
                        .map((button) => _buildButton(context, button)),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildListItem(BuildContext context, BotListItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Иконка элемента
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),),
              child:
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
            ),
            const SizedBox(width: 12),
            // Контент элемента
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold,),),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(item.subtitle!,
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600]),),
                  ],
                ],
              ),
            ),
            // Кнопка элемента
            if (item.button != null) _buildButton(context, item.button!),
          ],
        ),
      );

  Widget _buildButton(BuildContext context, BotButton button) => Container(
        margin: const EdgeInsets.only(top: 8),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => onButtonTap?.call(button),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.blue[200]!),
            ),
          ),
          child: Text(button.title, style: const TextStyle(fontSize: 12)),
        ),
      );
}
