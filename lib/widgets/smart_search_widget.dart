import 'package:event_marketplace_app/services/smart_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Виджет умного поиска с подсказками
class SmartSearchWidget extends ConsumerStatefulWidget {
  const SmartSearchWidget({
    required this.onSearch, required this.onSuggestionTap, super.key,
    this.hintText = 'Поиск специалистов...',
  });

  final void Function(String) onSearch;
  final void Function(SearchSuggestion) onSuggestionTap;
  final String hintText;

  @override
  ConsumerState<SmartSearchWidget> createState() => _SmartSearchWidgetState();
}

class _SmartSearchWidgetState extends ConsumerState<SmartSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final SmartSearchService _searchService = SmartSearchService();

  List<SearchSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    _loadPopularSuggestions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {
      _showSuggestions = _focusNode.hasFocus && _suggestions.isNotEmpty;
    });
  }

  Future<void> _loadPopularSuggestions() async {
    setState(() => _isLoading = true);
    try {
      final suggestions = await _searchService.getSearchSuggestions('');
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;
      });
    } on Exception catch (e) {
      debugPrint('Ошибка загрузки популярных подсказок: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onTextChanged(String text) async {
    if (text.isEmpty) {
      await _loadPopularSuggestions();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final suggestions = await _searchService.getSearchSuggestions(text);
      setState(() {
        _suggestions = suggestions;
        _showSuggestions = _focusNode.hasFocus && suggestions.isNotEmpty;
      });
    } on Exception catch (e) {
      debugPrint('Ошибка получения подсказок: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSuggestionSelected(SearchSuggestion suggestion) {
    _controller.text = suggestion.text;
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onSuggestionTap(suggestion);
  }

  void _onSearchSubmitted(String text) {
    _focusNode.unfocus();
    setState(() {
      _showSuggestions = false;
    });
    widget.onSearch(text);
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          // Поле поиска
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _loadPopularSuggestions();
                          },
                        )
                      : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            onChanged: _onTextChanged,
            onSubmitted: _onSearchSubmitted,
          ),

          // Подсказки
          if (_showSuggestions && _suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return _buildSuggestionItem(suggestion);
                },
              ),
            ),
        ],
      );

  Widget _buildSuggestionItem(SearchSuggestion suggestion) => ListTile(
        leading: Icon(suggestion.icon,
            color: _getSuggestionColor(suggestion.type), size: 20,),
        title: Text(suggestion.text,
            style: const TextStyle(fontWeight: FontWeight.w500),),
        subtitle: Text(suggestion.subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),),
        trailing: _getSuggestionTrailing(suggestion.type),
        onTap: () => _onSuggestionSelected(suggestion),
      );

  Color _getSuggestionColor(SuggestionType type) {
    switch (type) {
      case SuggestionType.specialist:
        return Colors.blue;
      case SuggestionType.category:
        return Colors.green;
      case SuggestionType.location:
        return Colors.orange;
      case SuggestionType.service:
        return Colors.purple;
    }
  }

  Widget? _getSuggestionTrailing(SuggestionType type) {
    switch (type) {
      case SuggestionType.specialist:
        return const Icon(Icons.person, size: 16);
      case SuggestionType.category:
        return const Icon(Icons.category, size: 16);
      case SuggestionType.location:
        return const Icon(Icons.location_on, size: 16);
      case SuggestionType.service:
        return const Icon(Icons.event, size: 16);
    }
  }
}
