import 'package:flutter/material.dart';

/// Виджет ввода сообщения в чате
class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoidCallback? onAttach;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _isComposing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isComposing = widget.controller.text.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Кнопка прикрепления
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: widget.onAttach,
          ),
          
          // Поле ввода
          Expanded(
            child: TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: _handleSubmit,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Кнопка отправки
          if (_isComposing)
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSend,
              color: Theme.of(context).primaryColor,
            )
          else
            IconButton(
              icon: const Icon(Icons.mic),
              onPressed: _handleVoiceMessage,
            ),
        ],
      ),
    );
  }

  void _handleSubmit(String text) {
    if (text.trim().isNotEmpty) {
      widget.onSend(text.trim());
    }
  }

  void _handleSend() {
    if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend(widget.controller.text.trim());
    }
  }

  void _handleVoiceMessage() {
    // TODO: Реализовать голосовые сообщения
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Голосовые сообщения')),
    );
  }
}
