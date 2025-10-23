import 'package:flutter/material.dart';

/// Анимированная строка поиска с эффектами
class AnimatedSearchBar extends StatefulWidget {
  const AnimatedSearchBar({super.key, required this.onSearch});

  final ValueChanged<String> onSearch;

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
              scale: _scaleAnimation, child: _buildSearchField()),
        );
      },
    );
  }

  Widget _buildSearchField() => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Найти специалиста',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Focus(
              onFocusChange: (hasFocus) {
                setState(() {
                  _isFocused = hasFocus;
                });
                if (hasFocus) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }
              },
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Найти специалиста…',
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isFocused
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : IconButton(
                          onPressed: () {
                            if (_searchController.text.isNotEmpty) {
                              widget.onSearch(_searchController.text);
                            }
                          },
                          icon: const Icon(Icons.search),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _isFocused
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                      width: _isFocused ? 2 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: _isFocused
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.05)
                      : Theme.of(context).cardColor,
                ),
                onChanged: (value) {
                  setState(() {});
                },
                onSubmitted: (query) {
                  if (query.isNotEmpty) {
                    widget.onSearch(query);
                  }
                },
              ),
            ),
          ],
        ),
      );
}
