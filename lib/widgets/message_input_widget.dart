import 'package:flutter/material.dart';
import '../models/enhanced_message.dart';

/// Виджет ввода сообщений
class MessageInputWidget extends StatefulWidget {
  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendMedia,
    this.onSendVoice,
    this.onSendDocument,
    this.replyTo,
    this.onCancelReply,
    this.isTyping = false,
    this.onTypingChanged,
  });

  final Function(String text) onSendMessage;
  final Function(List<MessageAttachment> attachments, {String? caption})? onSendMedia;
  final Function(MessageAttachment voiceAttachment)? onSendVoice;
  final Function(List<MessageAttachment> documents)? onSendDocument;
  final MessageReply? replyTo;
  final VoidCallback? onCancelReply;
  final bool isTyping;
  final Function(bool isTyping)? onTypingChanged;

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isRecording = false;
  bool _isExpanded = false;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Ответ на сообщение
          if (widget.replyTo != null) _buildReplyPreview(),
          
          // Основная область ввода
          Row(
            children: [
              // Кнопка прикрепления
              IconButton(
                onPressed: _showAttachmentOptions,
                icon: const Icon(Icons.attach_file),
                tooltip: 'Прикрепить файл',
              ),
              
              // Поле ввода текста
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: _onTextChanged,
                    onSubmitted: _onSendText,
                  ),
                ),
              ),
              
              // Кнопка отправки или записи голоса
              if (_textController.text.trim().isNotEmpty)
                IconButton(
                  onPressed: _sendTextMessage,
                  icon: const Icon(Icons.send),
                  tooltip: 'Отправить',
                )
              else
                GestureDetector(
                  onTapDown: (_) => _startVoiceRecording(),
                  onTapUp: (_) => _stopVoiceRecording(),
                  onTapCancel: _cancelVoiceRecording,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          // Дополнительные опции (при развернутом состоянии)
          if (_isExpanded) _buildExpandedOptions(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: Colors.blue, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ответ на сообщение',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.replyTo!.text,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onCancelReply,
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Отменить ответ',
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOptions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildOptionButton(
            icon: Icons.photo_camera,
            label: 'Камера',
            onTap: _openCamera,
          ),
          _buildOptionButton(
            icon: Icons.photo_library,
            label: 'Галерея',
            onTap: _openGallery,
          ),
          _buildOptionButton(
            icon: Icons.videocam,
            label: 'Видео',
            onTap: _openVideoCamera,
          ),
          _buildOptionButton(
            icon: Icons.insert_drive_file,
            label: 'Документ',
            onTap: _openDocumentPicker,
          ),
          _buildOptionButton(
            icon: Icons.location_on,
            label: 'Местоположение',
            onTap: _sendLocation,
          ),
          _buildOptionButton(
            icon: Icons.contact_phone,
            label: 'Контакт',
            onTap: _sendContact,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _onTextChanged(String text) {
    widget.onTypingChanged?.call(text.trim().isNotEmpty);
  }

  void _onSendText(String text) {
    if (text.trim().isNotEmpty) {
      _sendTextMessage();
    }
  }

  void _sendTextMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      widget.onSendMessage(text);
      _textController.clear();
      widget.onTypingChanged?.call(false);
    }
  }

  void _showAttachmentOptions() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _startVoiceRecording() {
    setState(() {
      _isRecording = true;
    });
    // TODO: Начать запись голоса
  }

  void _stopVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Остановить запись и отправить голосовое сообщение
  }

  void _cancelVoiceRecording() {
    setState(() {
      _isRecording = false;
    });
    // TODO: Отменить запись
  }

  void _openCamera() {
    // TODO: Открыть камеру для фото
    _showNotImplementedDialog('Камера');
  }

  void _openGallery() {
    // TODO: Открыть галерею для выбора фото
    _showNotImplementedDialog('Галерея');
  }

  void _openVideoCamera() {
    // TODO: Открыть камеру для видео
    _showNotImplementedDialog('Видеокамера');
  }

  void _openDocumentPicker() {
    // TODO: Открыть выбор документов
    _showNotImplementedDialog('Документы');
  }

  void _sendLocation() {
    // TODO: Отправить местоположение
    _showNotImplementedDialog('Местоположение');
  }

  void _sendContact() {
    // TODO: Отправить контакт
    _showNotImplementedDialog('Контакт');
  }

  void _showNotImplementedDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Функция в разработке'),
        content: Text('Функция "$feature" будет реализована в следующих версиях'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

