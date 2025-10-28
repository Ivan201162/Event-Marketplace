import 'package:flutter/material.dart';

///
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({
    required this.hintText, super.key,
    this.onChanged,
    this.onFilterTap,
    this.initialValue,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final String? initialValue;

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            //
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(Icons.search, color: Colors.grey[600], size: 20),
            ),
            //
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (value) {
                  setState(() => _isSearching = value.isNotEmpty);
                  widget.onChanged?.call(value);
                },
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
            ),
            //
            if (_isSearching)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  _controller.clear();
                  setState(() => _isSearching = false);
                  widget.onChanged?.call('');
                },
              ),
            //
            if (widget.onFilterTap != null)
              IconButton(
                icon: Icon(Icons.tune, color: Colors.grey[600]),
                onPressed: widget.onFilterTap,
              ),
          ],
        ),
      );
}
