import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/responsive_utils.dart';
import '../ui/responsive/responsive_widgets.dart' hide ResponsiveText;

/// Виджет для отображения фотоальбомов
class PhotoAlbumsWidget extends ConsumerWidget {
  const PhotoAlbumsWidget({super.key, required this.specialistId, this.showCreateAlbum = false});
  final String specialistId;
  final bool showCreateAlbum;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(developer): Заменить на реальные данные из провайдера
    final albums = _getMockAlbums();

    return GridView.count(
      crossAxisCount: _getCrossAxisCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (showCreateAlbum) _buildCreateAlbumCard(context),
        ...albums.map((album) => _buildAlbumCard(context, album)),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    if (context.isMobile) {
      return 2;
    }
    if (context.isTablet) {
      return 3;
    }
    if (context.isDesktop) {
      return 4;
    }
    return 5;
  }

  Widget _buildCreateAlbumCard(BuildContext context) => ResponsiveCard(
        child: InkWell(
          onTap: () => _createNewAlbum(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text('Создать альбом',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        ),
      );

  Widget _buildAlbumCard(BuildContext context, PhotoAlbum album) => ResponsiveCard(
        child: InkWell(
          onTap: () => _openAlbum(context, album),
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Обложка альбома
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    image: DecorationImage(
                        image: NetworkImage(album.coverImageUrl), fit: BoxFit.cover),
                  ),
                  child: Stack(
                    children: [
                      // Счетчик фото
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.photo, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${album.photoCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Индикатор видео
                      if (album.hasVideos)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.videocam, color: Colors.white, size: 16),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Информация об альбоме
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(album.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(album.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const Spacer(),
                          if (album.isPublic)
                            Icon(Icons.public, size: 14, color: Colors.green[600])
                          else
                            Icon(Icons.lock, size: 14, color: Colors.orange[600]),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  List<PhotoAlbum> _getMockAlbums() => [
        PhotoAlbum(
          id: '1',
          title: 'Свадебные фото',
          description: 'Красивые моменты свадебных церемоний',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Свадьба',
          photoCount: 24,
          hasVideos: true,
          isPublic: true,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        PhotoAlbum(
          id: '2',
          title: 'Портреты',
          description: 'Профессиональные портретные съемки',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Портреты',
          photoCount: 18,
          hasVideos: false,
          isPublic: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        PhotoAlbum(
          id: '3',
          title: 'Семейные фото',
          description: 'Теплые семейные моменты',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Семья',
          photoCount: 32,
          hasVideos: true,
          isPublic: false,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        PhotoAlbum(
          id: '4',
          title: 'Корпоративы',
          description: 'Корпоративные мероприятия и события',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Корпоратив',
          photoCount: 15,
          hasVideos: false,
          isPublic: true,
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        PhotoAlbum(
          id: '5',
          title: 'Детские фото',
          description: 'Милые детские портреты',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Дети',
          photoCount: 28,
          hasVideos: true,
          isPublic: true,
          createdAt: DateTime.now().subtract(const Duration(days: 12)),
        ),
        PhotoAlbum(
          id: '6',
          title: 'Природа',
          description: 'Пейзажи и природные красоты',
          coverImageUrl: 'https://via.placeholder.com/300x200?text=Природа',
          photoCount: 42,
          hasVideos: false,
          isPublic: true,
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ];

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _createNewAlbum(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => const CreateAlbumScreen()));
  }

  void _openAlbum(BuildContext context, PhotoAlbum album) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => AlbumDetailScreen(album: album)));
  }
}

/// Модель фотоальбома
class PhotoAlbum {
  const PhotoAlbum({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.photoCount,
    required this.hasVideos,
    required this.isPublic,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final int photoCount;
  final bool hasVideos;
  final bool isPublic;
  final DateTime createdAt;
}

/// Экран создания нового альбома
class CreateAlbumScreen extends StatefulWidget {
  const CreateAlbumScreen({super.key});

  @override
  State<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends State<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isPublic = true;
  List<String> _selectedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Создать альбом'),
          actions: [
            TextButton(onPressed: _canCreate() ? _createAlbum : null, child: const Text('Создать')),
          ],
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Название альбома
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Название альбома',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите название альбома';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Описание
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // Настройки приватности
                SwitchListTile(
                  title: const Text('Публичный альбом'),
                  subtitle: const Text('Альбом будет виден всем пользователям'),
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                // Выбор фотографий
                const ResponsiveText('Фотографии', isTitle: true),
                const SizedBox(height: 16),
                _buildImageSelector(),
                const SizedBox(height: 16),
                // Предварительный просмотр
                if (_selectedImages.isNotEmpty) ...[
                  const ResponsiveText('Предварительный просмотр'),
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                ],
              ],
            ),
          ),
        ),
      );

  Widget _buildImageSelector() => Container(
        height: 120,
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          onTap: _selectImages,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                'Добавить фотографии',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImagePreview() => SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  Image.network(_selectedImages[index], width: 150, height: 200, fit: BoxFit.cover),
            ),
          ),
        ),
      );

  bool _canCreate() => _titleController.text.isNotEmpty && _selectedImages.isNotEmpty;

  void _selectImages() {
    // TODO(developer): Реализовать выбор изображений
    setState(() {
      _selectedImages = [
        'https://via.placeholder.com/300x400?text=Фото+1',
        'https://via.placeholder.com/300x400?text=Фото+2',
        'https://via.placeholder.com/300x400?text=Фото+3',
      ];
    });
  }

  void _createAlbum() {
    if (_formKey.currentState!.validate()) {
      // TODO(developer): Реализовать создание альбома
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Альбом создан')));
      Navigator.pop(context);
    }
  }
}

/// Экран детального просмотра альбома
class AlbumDetailScreen extends StatefulWidget {
  const AlbumDetailScreen({super.key, required this.album});
  final PhotoAlbum album;

  @override
  State<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.album.title),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: _shareAlbum),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: _showAlbumOptions),
          ],
        ),
        body: Column(
          children: [
            // Информация об альбоме
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.album.title),
                  const SizedBox(height: 8),
                  Text(widget.album.description),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.photo, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.album.photoCount} фотографий',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(widget.album.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Сетка фотографий
            Expanded(child: _buildPhotoGrid()),
          ],
        ),
      );

  Widget _buildPhotoGrid() {
    // TODO(developer): Заменить на реальные данные
    final photos = List.generate(
      widget.album.photoCount,
      (index) => 'https://via.placeholder.com/300x400?text=Фото+${index + 1}',
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => _openPhotoViewer(photos, index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(photos[index], fit: BoxFit.cover),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} дн. назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ч. назад';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} мин. назад';
    } else {
      return 'Только что';
    }
  }

  void _shareAlbum() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Альбом скопирован в буфер обмена')));
  }

  void _showAlbumOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Редактировать'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Скачать'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openPhotoViewer(List<String> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PhotoViewerScreen(photos: photos, initialIndex: initialIndex),
      ),
    );
  }
}

/// Экран просмотра фотографий
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, required this.photos, this.initialIndex = 0});
  final List<String> photos;
  final int initialIndex;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
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
          title: Text('${_currentIndex + 1} из ${widget.photos.length}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: _sharePhoto,
            ),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white),
              onPressed: _downloadPhoto,
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
          itemCount: widget.photos.length,
          itemBuilder: (context, index) =>
              Center(child: Image.network(widget.photos[index], fit: BoxFit.contain)),
        ),
      );

  void _sharePhoto() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Фото скопировано в буфер обмена')));
  }

  void _downloadPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Фото скачано')));
  }
}
