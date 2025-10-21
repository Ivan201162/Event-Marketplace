import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../models/user_profile.dart';
import '../providers/user_profile_provider.dart';

/// Виджет для отображения галереи фотографий
class PhotoGallery extends ConsumerWidget {
  const PhotoGallery({super.key, required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(userPostsProvider(userId));

    return postsAsync.when(
      data: (posts) => _buildPhotoGrid(context, posts),
      loading: _buildLoadingGrid,
      error: (error, stack) => _buildErrorWidget(context, error.toString()),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<UserPost> posts) {
    // Фильтруем только фото
    final photos = posts.where((post) => !post.isVideo && post.imageUrl != null).toList();

    if (photos.isEmpty) {
      return _buildEmptyState(context);
    }

    return RefreshIndicator(
      onRefresh: () async {
        // TODO(developer): Обновить фото
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return _buildPhotoItem(context, photo);
        },
      ),
    );
  }

  Widget _buildPhotoItem(BuildContext context, UserPost photo) => GestureDetector(
    onTap: () => _openPhotoViewer(context, photo),
    child: Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: photo.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Container(color: Colors.grey[300], child: const Icon(Icons.image)),
          errorWidget: (context, url, error) =>
              Container(color: Colors.grey[300], child: const Icon(Icons.image)),
        ),
      ),
    ),
  );

  Widget _buildLoadingGrid() => GridView.builder(
    padding: const EdgeInsets.all(8),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      crossAxisSpacing: 2,
      mainAxisSpacing: 2,
    ),
    itemCount: 9,
    itemBuilder: (context, index) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );

  Widget _buildEmptyState(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_library, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Пока нет фотографий',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          'Когда пользователь опубликует фото,\nоно появится здесь',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _buildErrorWidget(BuildContext context, String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Ошибка загрузки фотографий',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  void _openPhotoViewer(BuildContext context, UserPost photo) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (context) => PhotoViewerScreen(photo: photo)));
  }
}

/// Экран просмотра фотографии в полноэкранном режиме
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.photo});
  final UserPost photo;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _sharePhoto(context),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () => _showPhotoMenu(context),
        ),
      ],
    ),
    body: Center(
      child: InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: photo.imageUrl!,
          fit: BoxFit.contain,
          placeholder: (context, url) => Container(
            color: Colors.grey[800],
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[800],
            child: const Center(child: Icon(Icons.error, color: Colors.white, size: 64)),
          ),
        ),
      ),
    ),
  );

  void _sharePhoto(BuildContext context) {
    // TODO(developer): Реализовать шаринг фотографии
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Поделиться фотографией')));
  }

  void _showPhotoMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Скачать'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Скачать фотографию
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Поделиться'),
              onTap: () {
                Navigator.pop(context);
                _sharePhoto(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Копировать ссылку'),
              onTap: () {
                Navigator.pop(context);
                // TODO(developer): Копировать ссылку
              },
            ),
          ],
        ),
      ),
    );
  }
}
