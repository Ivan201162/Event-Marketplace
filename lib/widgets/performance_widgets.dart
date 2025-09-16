import 'package:flutter/material.dart';
import 'dart:async';

/// Виджет с ленивой загрузкой
class LazyLoadWidget extends StatefulWidget {
  final Widget child;
  final double? height;
  final VoidCallback? onVisible;

  const LazyLoadWidget({
    super.key,
    required this.child,
    this.height,
    this.onVisible,
  });

  @override
  State<LazyLoadWidget> createState() => _LazyLoadWidgetState();
}

class _LazyLoadWidgetState extends State<LazyLoadWidget> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: VisibilityDetector(
        onVisibilityChanged: (visibilityInfo) {
          if (visibilityInfo.visibleFraction > 0.1 && !_isVisible) {
            setState(() {
              _isVisible = true;
            });
            widget.onVisible?.call();
          }
        },
        child: _isVisible ? widget.child : const SizedBox.shrink(),
      ),
    );
  }
}

/// Простой детектор видимости
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: Container(
        key: _key,
        child: widget.child,
      ),
    );
  }

  void _checkVisibility() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenSize = MediaQuery.of(context).size;

      final visibleTop = position.dy < screenSize.height;
      final visibleBottom = position.dy + size.height > 0;

      if (visibleTop && visibleBottom) {
        final visibleHeight =
            (position.dy + size.height).clamp(0.0, screenSize.height) -
                position.dy.clamp(0.0, screenSize.height);
        final visibleFraction = visibleHeight / size.height;

        widget.onVisibilityChanged(
            VisibilityInfo(visibleFraction: visibleFraction));
      }
    }
  }
}

/// Информация о видимости
class VisibilityInfo {
  final double visibleFraction;

  const VisibilityInfo({required this.visibleFraction});
}

/// Виджет с кэшированием изображений
class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      child: Image.network(
        imageUrl,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ??
              const Center(
                child: CircularProgressIndicator(),
              );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ??
              Container(
                color: Colors.grey[300],
                child: const Icon(Icons.error),
              );
        },
      ),
    );
  }
}

/// Виджет с виртуализацией списка
class VirtualizedList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double? itemHeight;
  final EdgeInsets? padding;

  const VirtualizedList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (itemHeight != null) {
      return ListView.builder(
        padding: padding,
        itemCount: itemCount,
        itemExtent: itemHeight,
        itemBuilder: itemBuilder,
      );
    } else {
      return ListView.builder(
        padding: padding,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
      );
    }
  }
}

/// Виджет с пагинацией
class PaginatedList extends StatefulWidget {
  final Future<List<dynamic>> Function(int page, int limit) loadData;
  final Widget Function(BuildContext context, dynamic item) itemBuilder;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;

  const PaginatedList({
    super.key,
    required this.loadData,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  final List<dynamic> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newItems = await widget.loadData(_currentPage, widget.itemsPerPage);

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length == widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Ошибка: $_error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _currentPage = 0;
                      _items.clear();
                      _hasMore = true;
                    });
                    _loadMore();
                  },
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
    }

    if (_items.isEmpty && _isLoading) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('Нет данных'),
          );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification &&
            notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 200) {
          _loadMore();
        }
        return false;
      },
      child: ListView.builder(
        itemCount: _items.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return _isLoading
                ? const Center(child: CircularProgressIndicator())
                : const SizedBox.shrink();
          }
          return widget.itemBuilder(context, _items[index]);
        },
      ),
    );
  }
}

/// Виджет с дебаунсом
class DebouncedWidget extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final VoidCallback? onDebounce;

  const DebouncedWidget({
    super.key,
    required this.child,
    this.delay = const Duration(milliseconds: 300),
    this.onDebounce,
  });

  @override
  State<DebouncedWidget> createState() => _DebouncedWidgetState();
}

class _DebouncedWidgetState extends State<DebouncedWidget> {
  Timer? _timer;

  void _debounce() {
    _timer?.cancel();
    _timer = Timer(widget.delay, () {
      widget.onDebounce?.call();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _debounce,
      child: widget.child,
    );
  }
}

/// Виджет с троттлингом
class ThrottledWidget extends StatefulWidget {
  final Widget child;
  final Duration interval;
  final VoidCallback? onThrottle;

  const ThrottledWidget({
    super.key,
    required this.child,
    this.interval = const Duration(milliseconds: 1000),
    this.onThrottle,
  });

  @override
  State<ThrottledWidget> createState() => _ThrottledWidgetState();
}

class _ThrottledWidgetState extends State<ThrottledWidget> {
  DateTime? _lastCall;

  void _throttle() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= widget.interval) {
      _lastCall = now;
      widget.onThrottle?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _throttle,
      child: widget.child,
    );
  }
}

/// Виджет с предзагрузкой
class PreloadWidget extends StatefulWidget {
  final Widget child;
  final Future<void> Function() preloadFunction;
  final Widget? loadingWidget;

  const PreloadWidget({
    super.key,
    required this.child,
    required this.preloadFunction,
    this.loadingWidget,
  });

  @override
  State<PreloadWidget> createState() => _PreloadWidgetState();
}

class _PreloadWidgetState extends State<PreloadWidget> {
  bool _isPreloading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _preload();
  }

  Future<void> _preload() async {
    try {
      await widget.preloadFunction();
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isPreloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPreloading) {
      return widget.loadingWidget ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка предзагрузки: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _isPreloading = true;
                });
                _preload();
              },
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }
}
