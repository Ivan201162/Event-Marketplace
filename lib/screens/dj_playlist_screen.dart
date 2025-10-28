import 'package:event_marketplace_app/core/feature_flags.dart';
import 'package:event_marketplace_app/models/dj_playlist.dart';
import 'package:event_marketplace_app/services/dj_playlist_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Экран управления плейлистами диджеев
class DJPlaylistScreen extends ConsumerStatefulWidget {
  const DJPlaylistScreen({required this.djId, super.key});
  final String djId;

  @override
  ConsumerState<DJPlaylistScreen> createState() => _DJPlaylistScreenState();
}

class _DJPlaylistScreenState extends ConsumerState<DJPlaylistScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DJPlaylistService _playlistService = DJPlaylistService();
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistDescriptionController =
      TextEditingController();
  final TextEditingController _vkUrlController = TextEditingController();
  bool _isPublic = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playlistNameController.dispose();
    _playlistDescriptionController.dispose();
    _vkUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.djPlaylistsEnabled) {
      return Scaffold(
        appBar: AppBar(title: const Text('Плейлисты диджея')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Плейлисты диджеев временно недоступны',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Плейлисты диджея'),
        backgroundColor: Colors.purple[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои плейлисты', icon: Icon(Icons.playlist_play)),
            Tab(text: 'Медиафайлы', icon: Icon(Icons.audio_file)),
            Tab(text: 'Импорт VK', icon: Icon(Icons.link)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaylistsTab(),
          _buildMediaFilesTab(),
          _buildVKImportTab(),
        ],
      ),
    );
  }

  Widget _buildPlaylistsTab() => StreamBuilder<List<DJPlaylist>>(
        stream: _playlistService.getDJPlaylists(widget.djId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Ошибка загрузки плейлистов: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Повторить'),),
                ],
              ),
            );
          }

          final playlists = snapshot.data ?? [];
          if (playlists.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('У вас пока нет плейлистов',
                      style: TextStyle(fontSize: 18, color: Colors.grey),),
                  SizedBox(height: 8),
                  Text(
                    'Создайте плейлист или импортируйте из VK',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _buildPlaylistCard(playlist);
            },
          );
        },
      );

  Widget _buildPlaylistCard(DJPlaylist playlist) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: playlist.coverImagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(playlist.coverImagePath!,
                                fit: BoxFit.cover,),
                          )
                        : Icon(Icons.music_note,
                            color: Colors.purple[600], size: 30,),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,),
                        ),
                        if (playlist.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            playlist.description!,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14,),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.music_note,
                                size: 16, color: Colors.grey[600],),
                            const SizedBox(width: 4),
                            Text(
                              '${playlist.trackCount} треков',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12,),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time,
                                size: 16, color: Colors.grey[600],),
                            const SizedBox(width: 4),
                            Text(
                              playlist.formattedDuration,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12,),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handlePlaylistAction(value, playlist),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Редактировать'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_public',
                        child: Row(
                          children: [
                            Icon(playlist.isPublic
                                ? Icons.visibility_off
                                : Icons.visibility,),
                            const SizedBox(width: 8),
                            Text(playlist.isPublic
                                ? 'Сделать приватным'
                                : 'Сделать публичным',),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Удалить',
                                style: TextStyle(color: Colors.red),),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (playlist.isPublic) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4,),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.public,
                              size: 14, color: Colors.green[600],),
                          const SizedBox(width: 4),
                          Text(
                            'Публичный',
                            style: TextStyle(
                              color: Colors.green[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow,
                            size: 14, color: Colors.blue[600],),
                        const SizedBox(width: 4),
                        Text(
                          '${playlist.playCount} прослушиваний',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showPlaylistDetails(playlist),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Подробнее'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildMediaFilesTab() => StreamBuilder<List<MediaFile>>(
        stream: _playlistService.getDJMediaFiles(widget.djId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Ошибка загрузки медиафайлов: ${snapshot.error}'),);
          }

          final mediaFiles = snapshot.data ?? [];
          if (mediaFiles.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.audio_file, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'У вас пока нет медиафайлов',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Загрузите аудиофайлы для создания плейлистов',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _uploadMediaFile,
                        icon: const Icon(Icons.upload),
                        label: const Text('Загрузить файл'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: mediaFiles.length,
                  itemBuilder: (context, index) {
                    final mediaFile = mediaFiles[index];
                    return _buildMediaFileCard(mediaFile);
                  },
                ),
              ),
            ],
          );
        },
      );

  Widget _buildMediaFileCard(MediaFile mediaFile) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getMediaTypeColor(mediaFile.type),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_getMediaTypeIcon(mediaFile.type),
                color: Colors.white, size: 24,),
          ),
          title: Text(mediaFile.originalName,
              style: const TextStyle(fontWeight: FontWeight.w500),),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  '${mediaFile.formattedFileSize} • ${mediaFile.formattedDuration}',),
              if (mediaFile.metadata['artist'] != null)
                Text(
                  'Исполнитель: ${mediaFile.metadata['artist']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) => _handleMediaFileAction(value, mediaFile),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'download',
                child: Row(children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Скачать'),
                ],),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Удалить', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildVKImportTab() => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVKImportHeader(),
            const SizedBox(height: 24),
            _buildVKUrlInput(),
            const SizedBox(height: 24),
            _buildPlaylistSettings(),
            const SizedBox(height: 24),
            _buildImportButton(),
            const SizedBox(height: 24),
            _buildVKImportHelp(),
          ],
        ),
      );

  Widget _buildVKImportHeader() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.link, color: Colors.blue[600], size: 32),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Импорт из VK',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Импортируйте плейлисты из VK, чтобы использовать их в своих мероприятиях. Поддерживается импорт треков и создание плейлистов.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );

  Widget _buildVKUrlInput() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ссылка на VK плейлист',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _vkUrlController,
                decoration: const InputDecoration(
                  hintText: 'https://vk.com/audio?section=playlists&id=123456',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildPlaylistSettings() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Настройки плейлиста',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playlistNameController,
                decoration: const InputDecoration(
                  labelText: 'Название плейлиста',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _playlistDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Публичный плейлист'),
                subtitle: const Text(
                    'Другие пользователи смогут видеть этот плейлист',),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
                secondary: Icon(
                  _isPublic ? Icons.public : Icons.lock,
                  color: _isPublic ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildImportButton() => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _importVKPlaylist,
          icon: const Icon(Icons.download),
          label: const Text('Импортировать плейлист'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );

  Widget _buildVKImportHelp() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Помощь',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
              const SizedBox(height: 12),
              _buildHelpItem(
                Icons.info,
                'Как получить ссылку на плейлист?',
                'Откройте VK, перейдите в раздел "Музыка" → "Плейлисты", выберите нужный плейлист и скопируйте ссылку из адресной строки.',
              ),
              _buildHelpItem(
                Icons.security,
                'Безопасность',
                'Мы импортируем только публично доступные треки. Приватные плейлисты импортировать нельзя.',
              ),
              _buildHelpItem(
                Icons.lock,
                'Ограничения',
                'Максимальное количество треков в одном плейлисте: 100. Поддерживаются только аудиофайлы.',
              ),
            ],
          ),
        ),
      );

  Widget _buildHelpItem(IconData icon, String title, String description) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.blue[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500),),
                  const SizedBox(height: 4),
                  Text(description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),),
                ],
              ),
            ),
          ],
        ),
      );

  Color _getMediaTypeColor(MediaType type) {
    switch (type) {
      case MediaType.audio:
        return Colors.purple;
      case MediaType.video:
        return Colors.red;
      case MediaType.image:
        return Colors.blue;
      case MediaType.playlist:
        return Colors.green;
    }
  }

  IconData _getMediaTypeIcon(MediaType type) {
    switch (type) {
      case MediaType.audio:
        return Icons.audio_file;
      case MediaType.video:
        return Icons.video_file;
      case MediaType.image:
        return Icons.image;
      case MediaType.playlist:
        return Icons.playlist_play;
    }
  }

  Future<void> _uploadMediaFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.audio);

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first.path!;
        final fileName = result.files.first.name;

        // Показываем диалог загрузки
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Загрузка файла...'),
              ],
            ),
          ),
        );

        try {
          await _playlistService.uploadMediaFile(
            djId: widget.djId,
            file: file,
            originalName: fileName,
            type: MediaType.audio,
          );

          Navigator.of(context).pop(); // Закрываем диалог загрузки

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Файл успешно загружен!'),
                backgroundColor: Colors.green,),
          );
        } catch (e) {
          Navigator.of(context).pop(); // Закрываем диалог загрузки
          rethrow;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка загрузки: $e'), backgroundColor: Colors.red,),);
    }
  }

  Future<void> _importVKPlaylist() async {
    final vkUrl = _vkUrlController.text.trim();
    final playlistName = _playlistNameController.text.trim();

    if (vkUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите ссылку на VK плейлист'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (playlistName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Введите название плейлиста'),
            backgroundColor: Colors.orange,),
      );
      return;
    }

    try {
      // Показываем диалог импорта
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Импорт плейлиста...'),
            ],
          ),
        ),
      );

      await _playlistService.importVKPlaylist(
        djId: widget.djId,
        vkPlaylistUrl: vkUrl,
        playlistName: playlistName,
        description: _playlistDescriptionController.text.trim().isEmpty
            ? null
            : _playlistDescriptionController.text.trim(),
      );

      Navigator.of(context).pop(); // Закрываем диалог импорта

      // Очищаем поля
      _vkUrlController.clear();
      _playlistNameController.clear();
      _playlistDescriptionController.clear();
      setState(() {
        _isPublic = false;
      });

      // Переключаемся на вкладку плейлистов
      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Плейлист успешно импортирован!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Закрываем диалог импорта
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка импорта: $e'), backgroundColor: Colors.red,),);
    }
  }

  void _handlePlaylistAction(String action, DJPlaylist playlist) {
    switch (action) {
      case 'edit':
        _editPlaylist(playlist);
      case 'toggle_public':
        _togglePlaylistVisibility(playlist);
      case 'delete':
        _deletePlaylist(playlist);
    }
  }

  void _handleMediaFileAction(String action, MediaFile mediaFile) {
    switch (action) {
      case 'download':
        _downloadMediaFile(mediaFile);
      case 'delete':
        _deleteMediaFile(mediaFile);
    }
  }

  void _editPlaylist(DJPlaylist playlist) {
    // TODO(developer): Реализовать редактирование плейлиста
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция редактирования будет добавлена'),),);
  }

  Future<void> _togglePlaylistVisibility(DJPlaylist playlist) async {
    try {
      await _playlistService
          .updatePlaylist(playlist.id, {'isPublic': !playlist.isPublic});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            playlist.isPublic
                ? 'Плейлист сделан приватным'
                : 'Плейлист сделан публичным',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(
          content: Text('Ошибка обновления: $e'), backgroundColor: Colors.red,),);
    }
  }

  void _deletePlaylist(DJPlaylist playlist) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить плейлист'),
        content: const Text('Вы уверены, что хотите удалить этот плейлист?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _playlistService.deletePlaylist(playlist.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Плейлист удален'),
                      backgroundColor: Colors.green,),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Ошибка удаления: $e'),
                      backgroundColor: Colors.red,),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _downloadMediaFile(MediaFile mediaFile) {
    // TODO(developer): Реализовать скачивание медиафайла
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
        const SnackBar(content: Text('Функция скачивания будет добавлена')),);
  }

  void _deleteMediaFile(MediaFile mediaFile) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить файл'),
        content: const Text('Вы уверены, что хотите удалить этот файл?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await _playlistService.deleteMediaFile(mediaFile.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Файл удален'),
                      backgroundColor: Colors.green,),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Ошибка удаления: $e'),
                      backgroundColor: Colors.red,),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showPlaylistDetails(DJPlaylist playlist) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                playlist.name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: playlist.mediaFiles.length,
                  itemBuilder: (context, index) {
                    final mediaFile = playlist.mediaFiles[index];
                    return ListTile(
                      leading: Icon(_getMediaTypeIcon(mediaFile.type)),
                      title: Text(mediaFile.originalName),
                      subtitle: Text(mediaFile.formattedDuration),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
