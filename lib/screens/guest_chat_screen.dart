import 'package:event_marketplace_app/core/logger.dart';
import 'package:event_marketplace_app/models/chat_attachment.dart';
import 'package:event_marketplace_app/models/guest_access.dart';
import 'package:event_marketplace_app/services/attachment_service.dart';
import 'package:event_marketplace_app/services/chat_bot_service.dart';
import 'package:event_marketplace_app/services/guest_access_service.dart';
import 'package:event_marketplace_app/widgets/chat_attachment_widget.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран чата для гостей
class GuestChatScreen extends ConsumerStatefulWidget {
  const GuestChatScreen({required this.accessCode, super.key});
  final String accessCode;

  @override
  ConsumerState<GuestChatScreen> createState() => _GuestChatScreenState();
}

class _GuestChatScreenState extends ConsumerState<GuestChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GuestAccess? _guestAccess;
  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isUploadingFile = false;

  final List<Map<String, dynamic>> _messages = [];
  final GuestAccessService _guestAccessService = GuestAccessService();
  final AttachmentService _attachmentService = AttachmentService();
  final ChatBotService _chatBotService = ChatBotService();

  @override
  void initState() {
    super.initState();
    _loadGuestAccess();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGuestAccess() async {
    try {
      setState(() => _isLoading = true);

      final guestAccess =
          await _guestAccessService.getGuestAccessByCode(widget.accessCode);

      if (guestAccess == null) {
        if (mounted) {
          _showErrorDialog('Неверный или истекший код доступа');
        }
        return;
      }

      setState(() {
        _guestAccess = guestAccess;
        _isLoading = false;
      });

      // Добавляем приветственное сообщение от бота
      _addBotWelcomeMessage();

      // Отмечаем использование доступа
      await _guestAccessService.useGuestAccess(
        widget.accessCode,
        guestName: _guestAccess?.guestName,
        guestEmail: _guestAccess?.guestEmail,
      );
    } on Exception catch (e, stackTrace) {
      AppLogger.logE('Ошибка загрузки гостевого доступа', 'guest_chat_screen',
          e, stackTrace,);
      if (mounted) {
        _showErrorDialog('Ошибка загрузки чата');
      }
    }
  }

  void _addBotWelcomeMessage() {
    setState(() {
      _messages.add({
        'id': 'welcome_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'bot',
        'message': 'Добро пожаловать! Я бот-помощник. Чем могу помочь?',
        'timestamp': DateTime.now(),
        'quickReplies': [
          {'title': 'Задать вопрос', 'payload': 'question'},
          {'title': 'Связаться с организатором', 'payload': 'organizer'},
        ],
      });
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);

    try {
      // Добавляем сообщение пользователя
      final userMessage = {
        'id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'user',
        'message': messageText,
        'timestamp': DateTime.now(),
        'senderName': _guestAccess?.guestName ?? 'Гость',
      };

      setState(() {
        _messages.add(userMessage);
        _messageController.clear();
      });

      _scrollToBottom();

      // Обрабатываем сообщение ботом
      final botResponse = await _chatBotService.processUserMessage(
        chatId: 'guest_${widget.accessCode}',
        userId: 'guest_${widget.accessCode}',
        message: messageText,
      );

      if (botResponse != null) {
        setState(() {
          _messages.add({
            'id': botResponse.id,
            'type': 'bot',
            'message': botResponse.message,
            'timestamp': botResponse.createdAt,
            'quickReplies': botResponse.quickReplies
                ?.map(
                    (reply) => {'title': reply.title, 'payload': reply.payload},)
                .toList(),
            'cards': botResponse.cards
                ?.map(
                  (card) => {
                    'title': card.title,
                    'subtitle': card.subtitle,
                    'imageUrl': card.imageUrl,
                  },
                )
                .toList(),
          });
        });

        _scrollToBottom();
      }
    } on Exception catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка отправки сообщения', 'guest_chat_screen', e, stackTrace,);
      _showErrorSnackBar('Ошибка отправки сообщения');
    } finally {
      setState(() => _isSendingMessage = false);
    }
  }

  Future<void> _attachFile() async {
    if (_isUploadingFile) return;

    try {
      setState(() => _isUploadingFile = true);

      final result = await FilePicker.platform.pickFiles();

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
        final attachment = await _attachmentService.uploadFile(
          messageId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
          userId: 'guest_${widget.accessCode}',
          filePath: file.path ?? '',
          originalFileName: fileName,
          fileData: fileData,
        );

        if (attachment != null) {
          setState(() {
            _messages.add({
              'id': 'attachment_${DateTime.now().millisecondsSinceEpoch}',
              'type': 'attachment',
              'attachment': attachment,
              'timestamp': DateTime.now(),
              'senderName': _guestAccess?.guestName ?? 'Гость',
            });
          });

          _scrollToBottom();
          _showSuccessSnackBar('Файл загружен успешно');
        } else {
          _showErrorSnackBar('Ошибка загрузки файла');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.logE(
          'Ошибка прикрепления файла', 'guest_chat_screen', e, stackTrace,);
      _showErrorSnackBar('Ошибка прикрепления файла');
    } finally {
      setState(() => _isUploadingFile = false);
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

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_guestAccess == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Неверный код доступа',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Проверьте ссылку и попробуйте снова'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Назад'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чат с организатором'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _attachFile,
            icon: _isUploadingFile
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.attach_file),
          ),
        ],
      ),
      body: Column(
        children: [
          // Информация о гостевом доступе
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Гостевой доступ: ${_guestAccess!.accessCode}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (_guestAccess!.guestName != null)
                  Text(
                    _guestAccess!.guestName!,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold,),
                  ),
              ],
            ),
          ),
          // Список сообщений
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageWidget(message);
              },
            ),
          ),
          // Поле ввода сообщения
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
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
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isSendingMessage ? null : _sendMessage,
                  icon: _isSendingMessage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'user':
        return _buildUserMessage(message);
      case 'bot':
        return _buildBotMessage(message);
      case 'attachment':
        return _buildAttachmentMessage(message);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUserMessage(Map<String, dynamic> message) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(message['message'] as String,
                    style: const TextStyle(color: Colors.white),),
              ),
            ),
          ],
        ),
      );

  Widget _buildBotMessage(Map<String, dynamic> message) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy,
                            size: 16, color: Colors.grey[600],),
                        const SizedBox(width: 8),
                        Text(
                          'Бот-помощник',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(message['message'] as String,
                        style: const TextStyle(color: Colors.black87),),
                  ],
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildAttachmentMessage(Map<String, dynamic> message) {
    final attachment = message['attachment'] as ChatAttachment;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
              child: ChatAttachmentWidget(
                  attachment: attachment, isFromCurrentUser: true,),),
        ],
      ),
    );
  }
}
