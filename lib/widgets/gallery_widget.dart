import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/gallery_item.dart';
import '../services/gallery_service.dart';
import 'gallery_item_card.dart';
import 'upload_media_dialog.dart';

/// Виджет галереи специалиста
class GalleryWidget extends ConsumerStatefulWidget {
  const GalleryWidget({super.key, required this.specialistId, this.isOwner = false});

  final String specialistId;
  final bool isOwner;

  @override
  ConsumerState<GalleryWidget> createState() => _GalleryWidgetState();
}

class _GalleryWidgetState extends ConsumerState<GalleryWidget> {
  final GalleryService _galleryService = GalleryService();
  List<GalleryItem> _galleryItems = [];
  bool _isLoading = true;
  String? _error;
  bool _showFeaturedOnly = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final items = await _galleryService.getSpecialistGallery(
        widget.specialistId,
        featuredOnly: _showFeaturedOnly,
      );

      setState(() {
        _galleryItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadMedia() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const UploadMediaDialog(),
    );

    if (result ?? false) {
      await _loadGallery();
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Заголовок с фильтрами и кнопкой загрузки
      _buildHeader(),
      const SizedBox(height: 16),

      // Контент галереи
      Expanded(child: _buildGalleryContent()),
    ],
  );

  Widget _buildHeader() => Row(
    children: [
      Expanded(
        child: Text(
          'Галерея',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),

      // Фильтр избранного
      if (_galleryItems.isNotEmpty) ...[
        FilterChip(
          label: const Text('Избранное'),
          selected: _showFeaturedOnly,
          onSelected: (selected) async {
            setState(() {
              _showFeaturedOnly = selected;
            });
            await _loadGallery();
          },
        ),
        const SizedBox(width: 8),
      ],

      // Кнопка загрузки (только для владельца)
      if (widget.isOwner)
        IconButton(
          onPressed: _uploadMedia,
          icon: const Icon(Icons.add_photo_alternate),
          tooltip: 'Добавить медиа',
        ),
    ],
  );

  Widget _buildGalleryContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_galleryItems.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadGallery,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _galleryItems.length,
        itemBuilder: (context, index) {
          final item = _galleryItems[index];
          return GalleryItemCard(
            item: item,
            onTap: () => _showMediaViewer(item),
            onLike: () => _toggleLike(item),
            onDelete: widget.isOwner ? () => _deleteItem(item) : null,
            onEdit: widget.isOwner ? () => _editItem(item) : null,
          );
        },
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text('Ошибка загрузки галереи', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _loadGallery, child: const Text('Повторить')),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          _showFeaturedOnly ? 'Нет избранных работ' : 'Галерея пуста',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          _showFeaturedOnly
              ? 'Добавьте избранные работы в галерею'
              : widget.isOwner
              ? 'Добавьте свои работы в галерею'
              : 'Специалист еще не добавил работы в галерею',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
        if (widget.isOwner && !_showFeaturedOnly) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _uploadMedia,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Добавить работы'),
          ),
        ],
      ],
    ),
  );

  void _showMediaViewer(GalleryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MediaViewerScreen(
          items: _galleryItems,
          initialIndex: _galleryItems.indexOf(item),
          onLike: _toggleLike,
        ),
      ),
    );
  }

  Future<void> _toggleLike(GalleryItem item) async {
    try {
      // Здесь можно добавить логику лайков
      // Пока просто обновляем счетчик
      await _galleryService.incrementLikeCount(item.id);
      await _loadGallery();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _deleteItem(GalleryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить работу'),
        content: const Text('Вы уверены, что хотите удалить эту работу из галереи?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      try {
        await _galleryService.deleteGalleryItem(item.id);
        await _loadGallery();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Работа удалена из галереи'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Ошибка удаления: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _editItem(GalleryItem item) async {
    // Здесь можно открыть диалог редактирования
    // Пока просто показываем информацию
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null) ...[
              const Text('Описание:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(item.description!),
              const SizedBox(height: 8),
            ],
            if (item.tags.isNotEmpty) ...[
              const Text('Теги:', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                children: item.tags
                    .map((tag) => Chip(label: Text(tag), labelStyle: const TextStyle(fontSize: 12)))
                    .toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
        ],
      ),
    );
  }
}

/// Экран просмотра медиа
class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({
    super.key,
    required this.items,
    required this.initialIndex,
    this.onLike,
  });

  final List<GalleryItem> items;
  final int initialIndex;
  final Function(GalleryItem)? onLike;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        '${_currentIndex + 1} / ${widget.items.length}',
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        if (widget.onLike != null)
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () => widget.onLike!(widget.items[_currentIndex]),
          ),
      ],
    ),
    body: PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        return Center(
          child: item.isImage
              ? Image.network(
                  item.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                )
              : const Center(
                  child: Text(
                    'Видео просмотр пока не реализован',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        );
      },
    ),
  );
}
