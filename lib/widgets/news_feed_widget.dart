import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/news_feed_service.dart';

/// Виджет для отображения ленты новостей
class NewsFeedWidget extends StatefulWidget {
  const NewsFeedWidget({
    super.key,
    this.userId,
    this.specialistId,
    this.onNewsItemTap,
    this.onAuthorTap,
  });

  final String? userId;
  final String? specialistId;
  final void Function(NewsItem)? onNewsItemTap;
  final void Function(String)? onAuthorTap;

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  final NewsFeedService _newsService = NewsFeedService();
  final ScrollController _scrollController = ScrollController();

  List<NewsItem> _newsItems = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent()),
        ],
      );

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.newspaper, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Лента новостей',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                onPressed: _refreshNews, icon: const Icon(Icons.refresh), tooltip: 'Обновить'),
          ],
        ),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildError();
    }

    if (_newsItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshNews,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _newsItems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _newsItems.length) {
            return const Center(
              child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
            );
          }

          final newsItem = _newsItems[index];
          return _buildNewsItem(newsItem);
        },
      ),
    );
  }

  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Ошибка загрузки новостей',
              style: TextStyle(fontSize: 18, color: Colors.red.shade700),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadNews, child: const Text('Повторить')),
          ],
        ),
      );

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.newspaper_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Новостей пока нет', style: TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 8),
            const Text(
              'Следите за обновлениями от специалистов',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildNewsItem(NewsItem newsItem) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: () => _onNewsItemTap(newsItem),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNewsHeader(newsItem),
                const SizedBox(height: 12),
                _buildNewsContent(newsItem),
                if (newsItem.imageUrl != null) ...[
                  const SizedBox(height: 12),
                  _buildNewsImage(newsItem.imageUrl!),
                ],
                const SizedBox(height: 12),
                _buildNewsActions(newsItem),
              ],
            ),
          ),
        ),
      );

  Widget _buildNewsHeader(NewsItem newsItem) => Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              newsItem.authorName.isNotEmpty ? newsItem.authorName[0].toUpperCase() : '?',
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _onAuthorTap(newsItem.authorId),
                  child: Text(
                    newsItem.authorName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Row(
                  children: [
                    _buildTypeChip(newsItem.type),
                    const SizedBox(width: 8),
                    Text(
                      newsItem.formattedDate,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildTypeChip(NewsType type) {
    Color color;
    IconData icon;

    switch (type) {
      case NewsType.idea:
        color = Colors.green;
        icon = Icons.lightbulb;
        break;
      case NewsType.story:
        color = Colors.blue;
        icon = Icons.book;
        break;
      case NewsType.promotion:
        color = Colors.orange;
        icon = Icons.local_offer;
        break;
      case NewsType.announcement:
        color = Colors.purple;
        icon = Icons.announcement;
        break;
      case NewsType.tip:
        color = Colors.teal;
        icon = Icons.tips_and_updates;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            type.name.toUpperCase(),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsContent(NewsItem newsItem) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(newsItem.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            newsItem.content,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );

  Widget _buildNewsImage(String imageUrl) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey.shade200,
            child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
          ),
        ),
      );

  Widget _buildNewsActions(NewsItem newsItem) => Row(
        children: [
          _buildActionButton(
            icon: Icons.favorite_border,
            label: newsItem.likes.toString(),
            onTap: () => _onLikeTap(newsItem),
          ),
          const SizedBox(width: 16),
          _buildActionButton(
            icon: Icons.share,
            label: newsItem.shares.toString(),
            onTap: () => _onShareTap(newsItem),
          ),
          const SizedBox(width: 16),
          _buildActionButton(icon: Icons.visibility, label: newsItem.views.toString()),
          const Spacer(),
          if (newsItem.linkUrl != null)
            TextButton.icon(
              onPressed: () => _onLinkTap(newsItem.linkUrl!),
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Подробнее'),
            ),
        ],
      );

  Widget _buildActionButton({required IconData icon, required String label, VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
      );

  // ========== МЕТОДЫ ==========

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final newsItems = widget.specialistId != null
          ? await _newsService.getSpecialistNews(specialistId: widget.specialistId!)
          : await _newsService.getNewsFeed(userId: widget.userId);

      setState(() {
        _newsItems = newsItems;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Ошибка загрузки новостей: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshNews() async {
    _lastDocument = null;
    await _loadNews();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreNews();
    }
  }

  Future<void> _loadMoreNews() async {
    if (_isLoadingMore) {
      return;
    }

    setState(() => _isLoadingMore = true);

    try {
      final newsItems = widget.specialistId != null
          ? await _newsService.getSpecialistNews(
              specialistId: widget.specialistId!,
              lastDocument: _lastDocument,
            )
          : await _newsService.getNewsFeed(userId: widget.userId, lastDocument: _lastDocument);

      setState(() {
        _newsItems.addAll(newsItems);
        _isLoadingMore = false;
      });
    } on Exception {
      setState(() => _isLoadingMore = false);
    }
  }

  void _onNewsItemTap(NewsItem newsItem) {
    if (widget.onNewsItemTap != null) {
      widget.onNewsItemTap!(newsItem);
    }
  }

  void _onAuthorTap(String authorId) {
    if (widget.onAuthorTap != null) {
      widget.onAuthorTap!(authorId);
    }
  }

  void _onLikeTap(NewsItem newsItem) {
    // TODO(developer): Implement like functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Лайк добавлен'), duration: Duration(seconds: 1)));
  }

  void _onShareTap(NewsItem newsItem) {
    // TODO(developer): Implement share functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Поделиться'), duration: Duration(seconds: 1)));
  }

  void _onLinkTap(String linkUrl) {
    // TODO(developer): Implement link opening
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Открыть ссылку: $linkUrl'), duration: const Duration(seconds: 1)),
    );
  }
}
