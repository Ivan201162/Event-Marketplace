import 'package:flutter/material.dart';

/// Виджет поиска идей
class IdeaSearchBar extends StatefulWidget {
  const IdeaSearchBar({
    super.key,
    required this.onSearch,
    this.initialValue = '',
    this.hintText = 'Поиск идей...',
  });

  final void Function(String) onSearch;
  final String initialValue;
  final String hintText;

  @override
  State<IdeaSearchBar> createState() => _IdeaSearchBarState();
}

class _IdeaSearchBarState extends State<IdeaSearchBar> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
    });

    // Добавляем задержку для оптимизации поиска
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_controller.text == value) {
        widget.onSearch(value);
      }
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _isSearching = false;
    });
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: TextField(
        controller: _controller,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _isSearching
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }
}
