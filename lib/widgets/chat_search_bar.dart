import 'package:flutter/material.dart';

/// Виджет поиска чатов
class ChatSearchBar extends StatefulWidget {

  const ChatSearchBar({
    required this.onSearchChanged, super.key,
  });
  final ValueChanged<String> onSearchChanged;

  @override
  State<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends State<ChatSearchBar> {
  final TextEditingController _controller = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Поиск в чатах...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onChanged: (value) {
                setState(() {});
                widget.onSearchChanged(value);
              },
              onSubmitted: (value) {
                widget.onSearchChanged(value);
              },
            ),
          ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelSearch,
            ),
        ],
      ),
    );
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {});
    widget.onSearchChanged('');
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
    });
    _clearSearch();
  }
}
