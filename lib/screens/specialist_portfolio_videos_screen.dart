import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/specialist_profile_extended.dart';
import '../providers/specialist_profile_extended_providers.dart';
import '../services/specialist_profile_extended_service.dart';
import '../widgets/video_card_widget.dart';
import '../widgets/video_editor_widget.dart';
import '../widgets/video_filter_widget.dart';

/// Экран управления портфолио видео специалиста
class SpecialistPortfolioVideosScreen extends ConsumerStatefulWidget {
  const SpecialistPortfolioVideosScreen({
    super.key,
    required this.specialistId,
  });
  final String specialistId;

  @override
  ConsumerState<SpecialistPortfolioVideosScreen> createState() =>
      _SpecialistPortfolioVideosScreenState();
}

class _SpecialistPortfolioVideosScreenState
    extends ConsumerState<SpecialistPortfolioVideosScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
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
    final videosAsync =
        ref.watch(specialistPortfolioVideosProvider(widget.specialistId));
    final statsAsync =
        ref.watch(specialistProfileStatsProvider(widget.specialistId));
    final videoFilters = ref.watch(videoFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Портфолио видео'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все видео', icon: Icon(Icons.video_library)),
            Tab(text: 'Публичные', icon: Icon(Icons.public)),
            Tab(text: 'По платформам', icon: Icon(Icons.devices)),
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
                _buildAllVideosTab(videosAsync),
                _buildPublicVideosTab(),
                _buildPlatformsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddVideoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(SpecialistProfileStats stats) => Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Всего видео',
                stats.totalVideos,
                Icons.video_library,
              ),
              _buildStatItem('Публичных', stats.publicVideos, Icons.public),
              _buildStatItem('Платформ', _getPlatformsCount(), Icons.devices),
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

  Widget _buildAllVideosTab(AsyncValue<List<PortfolioVideo>> videosAsync) =>
      videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return _buildEmptyState(
              'Нет видео',
              'Добавьте видео в портфолио, чтобы показать свои работы',
              Icons.video_library_outlined,
            );
          }

          // Сортируем по дате загрузки
          final sortedVideos = List<PortfolioVideo>.from(videos);
          sortedVideos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: sortedVideos.length,
            itemBuilder: (context, index) {
              final video = sortedVideos[index];
              return VideoCardWidget(
                video: video,
                onTap: () => _showVideoDetails(video),
                onEdit: () => _showEditVideoDialog(video),
                onDelete: () => _deleteVideo(video),
                onTogglePublish: () => _togglePublish(video),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
      );

  Widget _buildPublicVideosTab() {
    final publicVideosAsync =
        ref.watch(specialistPublicVideosProvider(widget.specialistId));

    return publicVideosAsync.when(
      data: (videos) {
        if (videos.isEmpty) {
          return _buildEmptyState(
            'Нет публичных видео',
            'Сделайте видео публичными, чтобы клиенты могли их видеть',
            Icons.public_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return VideoCardWidget(
              video: video,
              onTap: () => _showVideoDetails(video),
              onEdit: () => _showEditVideoDialog(video),
              onDelete: () => _deleteVideo(video),
              onTogglePublish: () => _togglePublish(video),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildPlatformsTab() {
    final videosAsync =
        ref.watch(specialistPortfolioVideosProvider(widget.specialistId));

    return videosAsync.when(
      data: (videos) {
        final platforms =
            videos.map((video) => video.platform).toSet().toList();
        platforms.sort();

        if (platforms.isEmpty) {
          return _buildEmptyState(
            'Нет видео',
            'Добавьте видео с разных платформ',
            Icons.devices_outlined,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: platforms.length,
          itemBuilder: (context, index) {
            final platform = platforms[index];
            return _buildPlatformCard(platform);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(error.toString()),
    );
  }

  Widget _buildPlatformCard(String platform) {
    final videosAsync =
        ref.watch(specialistPortfolioVideosProvider(widget.specialistId));

    return videosAsync.when(
      data: (videos) {
        final platformVideos =
            videos.where((video) => video.platform == platform).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: Icon(_getPlatformIcon(platform)),
            title: Text(_getPlatformDisplayName(platform)),
            subtitle: Text('${platformVideos.length} видео'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => _showVideosByPlatform(platform),
          ),
        );
      },
      loading: () => const Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text('Загрузка...'),
        ),
      ),
      error: (_, __) => const Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text('Ошибка'),
        ),
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
              onPressed: () => ref.refresh(
                specialistPortfolioVideosProvider(widget.specialistId),
              ),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );

  void _showAddVideoDialog() {
    showDialog(
      context: context,
      builder: (context) => VideoEditorWidget(
        specialistId: widget.specialistId,
        onVideoSaved: () {
          ref.refresh(specialistPortfolioVideosProvider(widget.specialistId));
          ref.refresh(specialistProfileStatsProvider(widget.specialistId));
        },
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Поиск видео'),
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
    showDialog(
      context: context,
      builder: (context) => VideoFilterWidget(
        currentFilters: ref.read(videoFiltersProvider),
        onFiltersChanged: (filters) {
          ref.read(videoFiltersProvider.notifier).state = filters;
        },
      ),
    );
  }

  void _showVideoDetails(PortfolioVideo video) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
          child: Column(
            children: [
              AppBar(
                title: Text(video.title),
                actions: [
                  IconButton(
                    icon: Icon(video.isPublic ? Icons.public : Icons.lock),
                    onPressed: () {
                      Navigator.pop(context);
                      _togglePublish(video);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditVideoDialog(video);
                    },
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Превью видео
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.video_library,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        video.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Chip(
                            label:
                                Text(_getPlatformDisplayName(video.platform)),
                            backgroundColor: _getPlatformColor(video.platform),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Длительность: ${video.duration}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (video.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 4,
                          children: video.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  labelStyle: const TextStyle(fontSize: 12),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Text(
                            'Загружено: ${_formatDate(video.uploadedAt)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Просмотров: ${video.viewCount}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditVideoDialog(PortfolioVideo video) {
    showDialog(
      context: context,
      builder: (context) => VideoEditorWidget(
        specialistId: widget.specialistId,
        existingVideo: video,
        onVideoSaved: () {
          ref.refresh(specialistPortfolioVideosProvider(widget.specialistId));
          ref.refresh(specialistProfileStatsProvider(widget.specialistId));
        },
      ),
    );
  }

  void _deleteVideo(PortfolioVideo video) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить видео?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final service =
                  ref.read(specialistProfileExtendedServiceProvider);
              await service.removePortfolioVideo(widget.specialistId, video.id);
              ref.refresh(
                specialistPortfolioVideosProvider(widget.specialistId),
              );
              ref.refresh(specialistProfileStatsProvider(widget.specialistId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePublish(PortfolioVideo video) async {
    final service = ref.read(specialistProfileExtendedServiceProvider);
    final updatedVideo = video.copyWith(isPublic: !video.isPublic);
    await service.updatePortfolioVideo(widget.specialistId, updatedVideo);
    ref.refresh(specialistPortfolioVideosProvider(widget.specialistId));
    ref.refresh(specialistProfileStatsProvider(widget.specialistId));
  }

  void _showVideosByPlatform(String platform) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideosByPlatformScreen(
          specialistId: widget.specialistId,
          platform: platform,
        ),
      ),
    );
  }

  void _showSearchResults(String query) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoSearchResultsScreen(
          specialistId: widget.specialistId,
          query: query,
        ),
      ),
    );
  }

  int _getPlatformsCount() {
    final videosAsync =
        ref.read(specialistPortfolioVideosProvider(widget.specialistId));
    return videosAsync.when(
      data: (videos) => videos.map((video) => video.platform).toSet().length,
      loading: () => 0,
      error: (_, __) => 0,
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'youtube':
        return Icons.play_circle_filled;
      case 'vimeo':
        return Icons.video_library;
      case 'direct':
        return Icons.video_file;
      default:
        return Icons.video_library;
    }
  }

  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'vimeo':
        return 'Vimeo';
      case 'direct':
        return 'Прямая загрузка';
      default:
        return platform;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'youtube':
        return Colors.red[100]!;
      case 'vimeo':
        return Colors.blue[100]!;
      case 'direct':
        return Colors.green[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';
}

/// Экран видео по платформе
class VideosByPlatformScreen extends ConsumerWidget {
  const VideosByPlatformScreen({
    super.key,
    required this.specialistId,
    required this.platform,
  });
  final String specialistId;
  final String platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync =
        ref.watch(specialistPortfolioVideosProvider(specialistId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Видео: ${_getPlatformDisplayName(platform)}'),
      ),
      body: videosAsync.when(
        data: (videos) {
          final platformVideos =
              videos.where((video) => video.platform == platform).toList();

          if (platformVideos.isEmpty) {
            return const Center(
              child: Text('Нет видео на этой платформе'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: platformVideos.length,
            itemBuilder: (context, index) {
              final video = platformVideos[index];
              return VideoCardWidget(
                video: video,
                onTap: () => _showVideoDetails(context, video),
                onEdit: () => _showEditVideoDialog(context, ref, video),
                onDelete: () => _deleteVideo(context, ref, video),
                onTogglePublish: () => _togglePublish(context, ref, video),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  String _getPlatformDisplayName(String platform) {
    switch (platform) {
      case 'youtube':
        return 'YouTube';
      case 'vimeo':
        return 'Vimeo';
      case 'direct':
        return 'Прямая загрузка';
      default:
        return platform;
    }
  }

  void _showVideoDetails(BuildContext context, PortfolioVideo video) {
    // TODO: Показать детали видео
  }

  void _showEditVideoDialog(
    BuildContext context,
    WidgetRef ref,
    PortfolioVideo video,
  ) {
    // TODO: Редактировать видео
  }

  void _deleteVideo(BuildContext context, WidgetRef ref, PortfolioVideo video) {
    // TODO: Удалить видео
  }

  void _togglePublish(
    BuildContext context,
    WidgetRef ref,
    PortfolioVideo video,
  ) {
    // TODO: Переключить публикацию
  }
}

/// Экран результатов поиска видео
class VideoSearchResultsScreen extends ConsumerWidget {
  const VideoSearchResultsScreen({
    super.key,
    required this.specialistId,
    required this.query,
  });
  final String specialistId;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync =
        ref.watch(specialistVideoSearchProvider((specialistId, query)));

    return Scaffold(
      appBar: AppBar(
        title: Text('Результаты поиска: $query'),
      ),
      body: videosAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text('Ничего не найдено'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return VideoCardWidget(
                video: video,
                onTap: () => _showVideoDetails(context, video),
                onEdit: () => _showEditVideoDialog(context, ref, video),
                onDelete: () => _deleteVideo(context, ref, video),
                onTogglePublish: () => _togglePublish(context, ref, video),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Ошибка: $error'),
        ),
      ),
    );
  }

  void _showVideoDetails(BuildContext context, PortfolioVideo video) {
    // TODO: Показать детали видео
  }

  void _showEditVideoDialog(
    BuildContext context,
    WidgetRef ref,
    PortfolioVideo video,
  ) {
    // TODO: Редактировать видео
  }

  void _deleteVideo(BuildContext context, WidgetRef ref, PortfolioVideo video) {
    // TODO: Удалить видео
  }

  void _togglePublish(
    BuildContext context,
    WidgetRef ref,
    PortfolioVideo video,
  ) {
    // TODO: Переключить публикацию
  }
}
