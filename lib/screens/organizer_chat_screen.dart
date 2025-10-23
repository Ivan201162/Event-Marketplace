import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/organizer_chat.dart';
import '../services/organizer_chat_service.dart';
import '../widgets/organizer_message_bubble.dart';
import '../widgets/specialist_proposal_widget.dart';

class OrganizerChatScreen extends ConsumerStatefulWidget {
  const OrganizerChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<OrganizerChatScreen> createState() =>
      _OrganizerChatScreenState();
}

class _OrganizerChatScreenState extends ConsumerState<OrganizerChatScreen> {
  final OrganizerChatService _chatService = OrganizerChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  OrganizerChat? _chat;
  List<OrganizerMessage> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserType;

  @override
  void initState() {
    super.initState();
    _loadChat();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      final chat = await _chatService.getChatById(widget.chatId);
      if (chat != null) {
        setState(() {
          _chat = chat;
          _isLoading = false;
        });

        // TODO(developer): Получить текущего пользователя из провайдера
        _currentUserId = chat.customerId; // Временно
        _currentUserType = 'customer'; // Временно

        // Отметить сообщения как прочитанные
        if (_currentUserId != null) {
          await _chatService.markMessagesAsRead(widget.chatId, _currentUserId!);
        }
      }
    } on Exception catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка загрузки чата: $e')));
      }
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getChatMessages(widget.chatId);
      setState(() {
        _messages = messages;
      });
      _scrollToBottom();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка загрузки сообщений: $e')));
      }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_chat == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Чат не найден')),
        body: const Center(child: Text('Чат не найден или был удален')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentUserType == 'customer'
                ? _chat!.organizerName
                : _chat!.customerName),
            Text(
              _chat!.eventTitle,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info),
                    SizedBox(width: 8),
                    Text('Информация о чате')
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'close',
                child: Row(children: [
                  Icon(Icons.close),
                  SizedBox(width: 8),
                  Text('Закрыть чат')
                ]),
              ),
            ],
            onSelected: (value) {
              if (value == 'info') {
                _showChatInfo();
              } else if (value == 'close') {
                _closeChat();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о мероприятии
          _buildEventInfo(),

          // Список сообщений
          Expanded(child: _buildMessagesList()),

          // Поле ввода сообщения
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEventInfo() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_chat!.eventTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (_chat!.eventDescription != null)
                    Text(
                      _chat!.eventDescription!,
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    'Дата: ${_formatDate(_chat!.eventDate)}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Пока нет сообщений'),
            Text('Начните общение с организатором'),
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
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildMessageBubble(message),
        );
      },
    );
  }

  Widget _buildMessageBubble(OrganizerMessage message) {
    final isFromCurrentUser = message.senderId == _currentUserId;

    switch (message.type) {
      case OrganizerMessageType.specialistProposal:
        return SpecialistProposalWidget(
          message: message,
          isFromCurrentUser: isFromCurrentUser,
          onAccept: () => _acceptSpecialist(message),
          onReject: () => _rejectSpecialist(message),
        );
      default:
        return OrganizerMessageBubble(
            message: message, isFromCurrentUser: isFromCurrentUser);
    }
  }

  Widget _buildMessageInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border:
              Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Введите сообщение...',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      );

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentUserId == null) return;

    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: _currentUserId!,
        senderName: _currentUserType == 'customer'
            ? _chat!.customerName
            : _chat!.organizerName,
        senderType: _currentUserType!,
        type: OrganizerMessageType.text,
        text: text,
      );

      _loadMessages();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка отправки сообщения: $e')));
      }
    }
  }

  Future<void> _acceptSpecialist(OrganizerMessage message) async {
    if (message.metadata == null) return;

    final specialistId = message.metadata!['specialistId'] as String?;
    if (specialistId == null) return;

    try {
      await _chatService.acceptSpecialist(
        chatId: widget.chatId,
        customerId: _currentUserId!,
        customerName: _chat!.customerName,
        specialistId: specialistId,
        message: 'Отлично! Хочу забронировать этого специалиста',
      );

      _loadMessages();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка принятия специалиста: $e')));
      }
    }
  }

  Future<void> _rejectSpecialist(OrganizerMessage message) async {
    if (message.metadata == null) return;

    final specialistId = message.metadata!['specialistId'] as String?;
    if (specialistId == null) return;

    final reason = await _showRejectionDialog();
    if (reason == null) return;

    try {
      await _chatService.rejectSpecialist(
        chatId: widget.chatId,
        customerId: _currentUserId!,
        customerName: _chat!.customerName,
        specialistId: specialistId,
        reason: reason,
      );

      _loadMessages();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(content: Text('Ошибка отклонения специалиста: $e')));
      }
    }
  }

  Future<String?> _showRejectionDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отклонить специалиста'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Укажите причину отклонения (необязательно)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Отклонить'),
          ),
        ],
      ),
    );
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
            _buildInfoRow('Мероприятие', _chat!.eventTitle),
            if (_chat!.eventDescription != null)
              _buildInfoRow('Описание', _chat!.eventDescription!),
            _buildInfoRow('Дата', _formatDate(_chat!.eventDate)),
            _buildInfoRow('Заказчик', _chat!.customerName),
            _buildInfoRow('Организатор', _chat!.organizerName),
            _buildInfoRow('Статус', _getStatusText(_chat!.status)),
            _buildInfoRow('Создан', _formatDateTime(_chat!.createdAt)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 100,
              child: Text('$label:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(child: Text(value)),
          ],
        ),
      );

  Future<void> _closeChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Закрыть чат'),
        content: const Text('Вы уверены, что хотите закрыть этот чат?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _chatService.updateChatStatus(
            widget.chatId, OrganizerChatStatus.closed);
        if (mounted) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Ошибка закрытия чата: $e')));
        }
      }
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  String _getStatusText(OrganizerChatStatus status) {
    switch (status) {
      case OrganizerChatStatus.active:
        return 'Активный';
      case OrganizerChatStatus.closed:
        return 'Закрыт';
      case OrganizerChatStatus.archived:
        return 'Архивирован';
      case OrganizerChatStatus.pending:
        return 'Ожидает ответа';
    }
  }
}
