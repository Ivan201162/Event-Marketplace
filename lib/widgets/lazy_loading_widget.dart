import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Виджет для ленивой загрузки с пагинацией
class LazyLoadingWidget<T> extends StatefulWidget {
  const LazyLoadingWidget({
    super.key,
    required this.itemBuilder,
    required this.loadData,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.separatorBuilder,
    this.scrollController,
    this.enablePullToRefresh = true,
    this.enableLoadMore = true,
    this.loadMoreThreshold = 200,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int limit) loadData;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final ScrollController? scrollController;
  final bool enablePullToRefresh;
  final bool enableLoadMore;
  final double loadMoreThreshold;

  @override
  State<LazyLoadingWidget<T>> createState() => _LazyLoadingWidgetState<T>();
}

class _LazyLoadingWidgetState<T> extends State<LazyLoadingWidget<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String? _errorMessage;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _scrollController;

  @override
  void initState() {
    super.initState();
    _effectiveScrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _effectiveScrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enableLoadMore || _isLoadingMore || !_hasMoreData) return;

    final threshold = widget.loadMoreThreshold;
    final position = _effectiveScrollController.position;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final items = await widget.loadData(0, widget.itemsPerPage);
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _currentPage = 0;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await widget.loadData(nextPage, widget.itemsPerPage);

      setState(() {
        _items.addAll(items);
        _currentPage = nextPage;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  Widget _buildShimmerLoading() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: List.generate(
            5,
            (index) => Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              height: 100,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      );

  Widget _buildLoadingWidget() =>
      widget.loadingWidget ?? _buildShimmerLoading();

  Widget _buildErrorWidget() =>
      widget.errorWidget ??
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Ошибка загрузки данных',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadInitialData, child: const Text('Повторить')),
          ],
        ),
      );

  Widget _buildEmptyWidget() =>
      widget.emptyWidget ??
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет данных',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Попробуйте обновить страницу',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );

  Widget _buildLoadMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_items.isEmpty) {
      return _buildEmptyWidget();
    }

    Widget listView = ListView.separated(
      controller: _effectiveScrollController,
      itemCount: _items.length + (_hasMoreData ? 1 : 0),
      separatorBuilder: widget.separatorBuilder ??
          (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return _buildLoadMoreIndicator();
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );

    if (widget.enablePullToRefresh) {
      listView = RefreshIndicator(onRefresh: _onRefresh, child: listView);
    }

    return listView;
  }
}

/// Виджет для ленивой загрузки в виде сетки
class LazyLoadingGrid<T> extends StatefulWidget {
  const LazyLoadingGrid({
    super.key,
    required this.itemBuilder,
    required this.loadData,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8,
    this.mainAxisSpacing = 8,
    this.childAspectRatio = 1,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.scrollController,
    this.enablePullToRefresh = true,
    this.enableLoadMore = true,
    this.loadMoreThreshold = 200,
  });

  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Future<List<T>> Function(int page, int limit) loadData;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final ScrollController? scrollController;
  final bool enablePullToRefresh;
  final bool enableLoadMore;
  final double loadMoreThreshold;

  @override
  State<LazyLoadingGrid<T>> createState() => _LazyLoadingGridState<T>();
}

class _LazyLoadingGridState<T> extends State<LazyLoadingGrid<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String? _errorMessage;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _scrollController;

  @override
  void initState() {
    super.initState();
    _effectiveScrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _effectiveScrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enableLoadMore || _isLoadingMore || !_hasMoreData) return;

    final threshold = widget.loadMoreThreshold;
    final position = _effectiveScrollController.position;

    if (position.pixels >= position.maxScrollExtent - threshold) {
      _loadMoreData();
    }
  }

  Future<void> _loadInitialData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final items = await widget.loadData(0, widget.itemsPerPage);
      setState(() {
        _items
          ..clear()
          ..addAll(items);
        _currentPage = 0;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final items = await widget.loadData(nextPage, widget.itemsPerPage);

      setState(() {
        _items.addAll(items);
        _currentPage = nextPage;
        _hasMoreData = items.length >= widget.itemsPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitialData();
  }

  Widget _buildShimmerLoading() => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
          ),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );

  Widget _buildLoadingWidget() =>
      widget.loadingWidget ?? _buildShimmerLoading();

  Widget _buildErrorWidget() =>
      widget.errorWidget ??
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Ошибка загрузки данных',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadInitialData, child: const Text('Повторить')),
          ],
        ),
      );

  Widget _buildEmptyWidget() =>
      widget.emptyWidget ??
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет данных',
                style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(
              'Попробуйте обновить страницу',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );

  Widget _buildLoadMoreIndicator() {
    if (!_isLoadingMore) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError) {
      return _buildErrorWidget();
    }

    if (_items.isEmpty) {
      return _buildEmptyWidget();
    }

    Widget gridView = GridView.builder(
      controller: _effectiveScrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: _items.length + (_hasMoreData ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return _buildLoadMoreIndicator();
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );

    if (widget.enablePullToRefresh) {
      gridView = RefreshIndicator(onRefresh: _onRefresh, child: gridView);
    }

    return gridView;
  }
}
