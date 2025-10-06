import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import 'dart:io';
import '../models/customer_profile_extended.dart';
import '../providers/customer_profile_extended_providers.dart';
import '../services/customer_profile_extended_service.dart';
import '../widgets/photo_filter_widget.dart';
import '../widgets/photo_grid_widget.dart';
import '../widgets/photo_upload_widget.dart';

/// Экран управления фотоальбомом вдохновения
class InspirationPhotosScreen extends ConsumerStatefulWidget {
  const InspirationPhotosScreen({
    super.key,
    required this.userId,
  });
  final String userId;

  @override
  ConsumerState<InspirationPhotosScreen> createState() =>
      _InspirationPhotosScreenState();
}

class _InspirationPhotosScreenState
    extends ConsumerState<InspirationPhotosScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  // final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(inspirationPhotosProvider(widget.userId));
    final statsAsync = ref.watch(customerProfileStatsProvider(widget.userId));
    // final photoFilters = ref.watch(photoFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фотоальбом вдохновения'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все фото', icon: Icon(Icons.photo_library)),
            Tab(text: 'Публичные', icon: Icon(Icons.public)),
            Tab(text: 'По тегам', icon: Icon(Icons.tag)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Статистика
          statsAsync.when(
            data: _buildStatsCard,
            loading: () => const LinearProgressIndicator(),
            error: (error, stack) => const SizedBox.shrink(),
          ),

          // Контент по вкладкам
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllPhotosTab(photosAsync),
                _buildPublicPhotosTab(),
                _buildTagsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPhotoDialog,
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _buildStatsCard(CustomerProfileStats stats) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Всего фото',
                stats.totalPhotos,
                Icons.photo_library,
              ),
              _buildStatItem('Публичных', stats.publicPhotos, Icons.public),
              _buildStatItem('Тегов', stats.totalTags, Icons.tag),
            ],
          ),
        ),
      );

  Widget _buildStatItem(String label, int value, IconData icon) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      );

  Widget _buildAllPhotosTab(AsyncValue<List<InspirationPhoto>> photosAsync) =>
      photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return _buildEmptyState(
              'Нет фото для вдохновения',
              'Добавьте фото, которые вдохновляют вас на создание мероприятий',
              Icons.photo_library_outlined,
            );
          }

          return PhotoGridWidget(
            photos: photos,
            onPhotoTap: _showPhotoDetails,
            onPhotoEdit: _showEditPhotoDialog,
            onPhotoDelete: _deletePhoto,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
      );

  Widget _buildPublicPhotosTab() {
    final publicPhotosAsync = ref.watch(publicPhotosProvider(widget.userId));

    return publicPhotosAsync.when(
      data: (photos) {
        if (photos.isEmpty) {
          return _buildEmptyState(
            'Нет публичных фото',
            'Сделайте фото публичными, чтобы другие могли их видеть',
            Icons.public_outlined,
          );
        }

        return PhotoGridWidget(
          photos: photos,
          onPhotoTap: _showPhotoDetails,
          onPhotoEdit: _showEditPhotoDialog,
          onPhotoDelete: _deletePhoto,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTagsTab() {
    final tagsAsync = ref.watch(userTagsProvider(widget.userId));

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) {
          return _buildEmptyState(
            'Нет тегов',
            'Добавьте теги к фото, чтобы лучше их организовывать',
            Icons.tag_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return _buildTagCard(tag);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildTagCard(String tag) {
    final photosByTagAsync =
        ref.watch(photosByTagProvider((widget.userId, tag)));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.tag),
        title: Text(tag),
        subtitle: photosByTagAsync.when(
          data: (photos) => Text('${photos.length} фото'),
          loading: () => const Text('Загрузка...'),
          error: (_, __) => const Text('Ошибка'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => _showPhotosByTag(tag),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildErrorState(String error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(inspirationPhotosProvider(widget.userId)),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _showAddPhotoDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => PhotoUploadWidget(
        userId: widget.userId,
        onPhotoAdded: () {
          ref.refresh(inspirationPhotosProvider(widget.userId));
          ref.refresh(customerProfileStatsProvider(widget.userId));
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск фото'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Введите запрос для поиска...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final query = _searchController.text.trim();
              if (query.isNotEmpty) {
                Navigator.pop(context);
                _showSearchResults(query);
              }
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => PhotoFilterWidget(
        currentFilters: ref.read(photoFiltersProvider),
        onFiltersChanged: (filters) {
          ref.read(photoFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }

  void _showPhotoDetails(InspirationPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.caption != null) ...[
                    Text(
                      photo.caption!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (photo.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 4,
                      children: photo.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Icon(
                        photo.isPublic ? Icons.public : Icons.lock,
                        size: 16,
                        color: photo.isPublic ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        photo.isPublic ? 'Публичное' : 'Приватное',
                        style: TextStyle(
                          color: photo.isPublic ? Colors.green : Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(photo.uploadedAt),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPhotoDialog(InspirationPhoto photo) {
    // TODO(developer): Реализовать редактирование фото
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Редактирование фото будет добавлено в следующей версии'),
      ),
    );
  }

  void _deletePhoto(InspirationPhoto photo) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить фото?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service = ref.read(customerProfileExtendedServiceProvider);
              await service.removeInspirationPhoto(widget.userId, photo.id);
              ref.refresh(inspirationPhotosProvider(widget.userId));
              ref.refresh(customerProfileStatsProvider(widget.userId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showPhotosByTag(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PhotosByTagScreen(
          userId: widget.userId,
          tag: tag,
        ),
      ),
    );
  }

  void _showSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PhotoSearchResultsScreen(
          userId: widget.userId,
          query: query,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Экран фото по тегу
class PhotosByTagScreen extends ConsumerWidget {
  const PhotosByTagScreen({
    super.key,
    required this.userId,
    required this.tag,
  });
  final String userId;
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosByTagProvider((userId, tag)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Фото: $tag'),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text('Нет фото с этим тегом'),
            );
          }

          return PhotoGridWidget(
            photos: photos,
            onPhotoTap: (photo) => _showPhotoDetails(context, photo),
            onPhotoEdit: (photo) => _showEditPhotoDialog(context, photo),
            onPhotoDelete: (photo) => _deletePhoto(context, ref, photo),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  void _showPhotoDetails(BuildContext context, InspirationPhoto photo) {
    // TODO(developer): Показать детали фото
  }

  void _showEditPhotoDialog(BuildContext context, InspirationPhoto photo) {
    // TODO(developer): Редактировать фото
  }

  void _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    InspirationPhoto photo,
  ) {
    // TODO(developer): Удалить фото
  }
}

/// Экран результатов поиска фото
class PhotoSearchResultsScreen extends ConsumerWidget {
  const PhotoSearchResultsScreen({
    super.key,
    required this.userId,
    required this.query,
  });
  final String userId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(searchPhotosProvider((userId, query)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Результаты поиска: $query'),
      ),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text('Ничего не найдено'),
            );
          }

          return PhotoGridWidget(
            photos: photos,
            onPhotoTap: (photo) => _showPhotoDetails(context, photo),
            onPhotoEdit: (photo) => _showEditPhotoDialog(context, photo),
            onPhotoDelete: (photo) => _deletePhoto(context, ref, photo),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  void _showPhotoDetails(BuildContext context, InspirationPhoto photo) {
    // TODO(developer): Показать детали фото
  }

  void _showEditPhotoDialog(BuildContext context, InspirationPhoto photo) {
    // TODO(developer): Редактировать фото
  }

  void _deletePhoto(
    BuildContext context,
    WidgetRef ref,
    InspirationPhoto photo,
  ) {
    // TODO(developer): Удалить фото
  }
}
