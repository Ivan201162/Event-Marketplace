import 'package:flutter/material.dart';

/// Виджет поиска в чатах
class ChatSearchWidget extends StatefulWidget {
  const ChatSearchWidget({required this.onSearchChanged, super.key});
  final Function(String) onSearchChanged;

  @override
  State<ChatSearchWidget> createState() => _ChatSearchWidgetState();
}

class _ChatSearchWidgetState extends State<ChatSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Поиск в чатах...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear), onPressed: _clearSearch,)
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
          widget.onSearchChanged(value);
        },
        onSubmitted: (value) {
          // TODO: Выполнить поиск
        },
      );

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearchChanged('');
  }
}
