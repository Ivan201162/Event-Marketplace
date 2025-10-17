import 'package:flutter/material.dart';

import '../services/support_service.dart';

/// Виджет чата поддержки
class SupportChatWidget extends StatefulWidget {
  const SupportChatWidget({
    super.key,
    required this.userId,
    this.onTransferToOperator,
  });

  final String userId;
  final void Function(String reason)? onTransferToOperator;

  @override
  State<SupportChatWidget> createState() => _SupportChatWidgetState();
}

class _SupportChatWidgetState extends State<SupportChatWidget> {
  final SupportService _supportService = SupportService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String? _error;
  TransferStatus _transferStatus = TransferStatus.notRequested;

  @override
  void initState() {
    super.initState();
    _loadTransferStatus();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTransferStatus() async {
    try {
      final status = await _supportService.getTransferStatus(widget.userId);
      setState(() {
        _transferStatus = status;
      });
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки статуса передачи: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _supportService.sendMessage(
        userId: widget.userId,
        message: _messageController.text.trim(),
        type: MessageType.text,
      );

      _messageController.clear();
      _scrollToBottom();
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $_error')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _transferToOperator() async {
    final reason = await _showTransferDialog();
    if (reason != null) {
      try {
        await _supportService.transferToLiveOperator(widget.userId, reason);
        setState(() {
          _transferStatus = TransferStatus.pending;
        });
        widget.onTransferToOperator?.call(reason);
        _showSuccessSnackBar('Запрос на передачу оператору отправлен');
      } on Exception catch (e) {
        _showErrorSnackBar('Ошибка передачи оператору: $e');
      }
    }
  }

  Future<String?> _showTransferDialog() async => showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Передать оператору'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Выберите причину передачи:'),
              const SizedBox(height: 16),
              ...TransferReasons.values.map(
                (reason) => ListTile(
                  title: Text(reason.title),
                  subtitle: Text(reason.description),
                  onTap: () => Navigator.of(context).pop(reason.value),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        ),
      );

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
  Widget build(BuildContext context) => Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildMessagesList(),
          ),
          _buildInputArea(),
        ],
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.support_agent,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Поддержка',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_transferStatus == TransferStatus.notRequested)
              IconButton(
                onPressed: _transferToOperator,
                icon: const Icon(Icons.person, color: Colors.white),
                tooltip: 'Передать оператору',
              ),
            if (_transferStatus == TransferStatus.pending)
              const Icon(
                Icons.hourglass_empty,
                color: Colors.orange,
                size: 24,
              ),
            if (_transferStatus == TransferStatus.accepted)
              const Icon(
                Icons.person,
                color: Colors.green,
                size: 24,
              ),
          ],
        ),
      );

  Widget _buildMessagesList() => StreamBuilder<List<SupportMessage>>(
        stream: _supportService.getSupportMessages(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorWidget(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {}),
            );
          }

          final messages = snapshot.data ?? [];

          if (messages.isEmpty) {
            return const _EmptyWidget();
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _MessageBubble(message: message);
            },
          );
        },
      );

  Widget _buildInputArea() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
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
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

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
}

/// Виджет ошибки
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ошибка загрузки чата',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
}

/// Виджет пустого состояния
class _EmptyWidget extends StatelessWidget {
  const _EmptyWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Начните диалог с поддержкой',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Задайте вопрос или опишите проблему',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}

/// Пузырек сообщения
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: message.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!message.isFromUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(
                  message.type == MessageType.system ? Icons.settings : Icons.support_agent,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isFromUser ? Colors.blue : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(
                        color: message.isFromUser ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: message.isFromUser ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (message.isFromUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: const Icon(
                  Icons.person,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ],
        ),
      );
}

/// Причины передачи оператору
enum TransferReasons {
  payment('Проблемы с оплатой', 'Вопросы по оплате, возврату средств'),
  technical(
    'Технические проблемы',
    'Ошибки в приложении, проблемы с функционалом',
  ),
  booking('Проблемы с заказами', 'Вопросы по бронированию, отмене заказов'),
  specialist('Проблемы со специалистами', 'Конфликты, некачественные услуги'),
  other('Другое', 'Прочие вопросы, требующие помощи оператора');

  const TransferReasons(this.title, this.description);

  final String title;
  final String description;
  String get value => name;
}

/// Форматирование времени
String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
