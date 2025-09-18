import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/content_management.dart';
import '../services/content_management_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления контентом и медиа
class ContentManagementScreen extends ConsumerStatefulWidget {
  const ContentManagementScreen({super.key});

  @override
  ConsumerState<ContentManagementScreen> createState() =>
      _ContentManagementScreenState();
}

class _ContentManagementScreenState
    extends ConsumerState<ContentManagementScreen> {
  final ContentManagementService _contentService = ContentManagementService();
  List<MediaContent> _mediaContent = [];
  List<ContentGallery> _galleries = [];
  bool _isLoading = true;
  String _selectedTab = 'media';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      title: 'Управление контентом',
      body: Column(
        children: [
          // Вкладки
          _buildTabs(),

          // Контент
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 'media'
                    ? _buildMediaTab()
                    : _selectedTab == 'galleries'
                        ? _buildGalleriesTab()
                        : _buildUploadTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return ResponsiveCard(
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('media', 'Медиа', Icons.photo_library),
          ),
          Expanded(
            child: _buildTabButton('galleries', 'Галереи', Icons.collections),
          ),
          Expanded(
            child: _buildTabButton('upload', 'Загрузка', Icons.cloud_upload),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tab, String title, IconData icon) {
    final isSelected = _selectedTab == tab;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = tab;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaTab() {
    return Column(
      children: [
        // Заголовок с фильтрами
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Медиа контент',
                isTitle: true,
              ),
              const Spacer(),
              DropdownButton<MediaType?>(
                value: null,
                hint: const Text('Все типы'),
                items: [
                  const DropdownMenuItem<MediaType?>(
                    value: null,
                    child: Text('Все типы'),
                  ),
                  ...MediaType.values.map((type) {
                    return DropdownMenuItem<MediaType?>(
                      value: type,
                      child: Row(
                        children: [
                          Text(type.icon),
                          const SizedBox(width: 8),
                          Text(type.displayName),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  // TODO: Реализовать фильтрацию
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список медиа
        Expanded(
          child: _mediaContent.isEmpty
              ? const Center(child: Text('Медиа контент не найден'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: _mediaContent.length,
                  itemBuilder: (context, index) {
                    final media = _mediaContent[index];
                    return _buildMediaCard(media);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaContent media) {
    final statusColor = _getStatusColor(media.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Превью медиа
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: media.type == MediaType.image
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        media.thumbnailUrl ?? media.url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  media.type.icon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  media.type.displayName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            media.type.icon,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            media.type.displayName,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 8),

          // Информация о медиа
          Text(
            media.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 4),

          // Статус и размер
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  media.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                media.formattedFileSize,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Действия
          Row(
            children: [
              Expanded(
                child: IconButton(
                  onPressed: () => _showMediaDetails(media),
                  icon: const Icon(Icons.info, size: 16),
                  tooltip: 'Подробности',
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => _addToGallery(media),
                  icon: const Icon(Icons.add_to_photos, size: 16),
                  tooltip: 'В галерею',
                ),
              ),
              Expanded(
                child: IconButton(
                  onPressed: () => _deleteMedia(media),
                  icon: const Icon(Icons.delete, size: 16),
                  tooltip: 'Удалить',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGalleriesTab() {
    return Column(
      children: [
        // Заголовок
        ResponsiveCard(
          child: Row(
            children: [
              ResponsiveText(
                'Галереи контента',
                isTitle: true,
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCreateGalleryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Создать галерею'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Обновить'),
              ),
            ],
          ),
        ),

        // Список галерей
        Expanded(
          child: _galleries.isEmpty
              ? const Center(child: Text('Галереи не найдены'))
              : ListView.builder(
                  itemCount: _galleries.length,
                  itemBuilder: (context, index) {
                    final gallery = _galleries[index];
                    return _buildGalleryCard(gallery);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGalleryCard(ContentGallery gallery) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                gallery.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gallery.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (gallery.description != null)
                      Text(
                        gallery.description!,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleGalleryAction(value, gallery),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'manage',
                    child: ListTile(
                      leading: Icon(Icons.manage_accounts),
                      title: Text('Управление медиа'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete),
                      title: Text('Удалить'),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Тип', gallery.type.displayName, Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Медиа', '${gallery.mediaCount}', Colors.green),
              const SizedBox(width: 8),
              _buildInfoChip(
                  'Статус',
                  gallery.isPublic ? 'Публичная' : 'Приватная',
                  gallery.isPublic ? Colors.green : Colors.orange),
            ],
          ),

          const SizedBox(height: 8),

          // Время создания
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создана: ${_formatDateTime(gallery.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadTab() {
    return SingleChildScrollView(
      child: ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Загрузка медиа',
              isTitle: true,
            ),

            const SizedBox(height: 16),

            // Форма загрузки
            _buildUploadForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadForm() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController();
    MediaType selectedType = MediaType.image;
    String? selectedFile;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            // Выбор файла
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.any,
                    allowMultiple: false,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    setState(() {
                      selectedFile = file.path;
                      // Автоматически определяем тип по расширению
                      final extension = file.extension?.toLowerCase();
                      if (extension != null) {
                        if (['jpg', 'jpeg', 'png', 'gif', 'webp']
                            .contains(extension)) {
                          selectedType = MediaType.image;
                        } else if (['mp4', 'avi', 'mov', 'webm']
                            .contains(extension)) {
                          selectedType = MediaType.video;
                        } else if (['mp3', 'wav', 'ogg', 'm4a']
                            .contains(extension)) {
                          selectedType = MediaType.audio;
                        } else if (['pdf', 'txt', 'doc', 'docx']
                            .contains(extension)) {
                          selectedType = MediaType.document;
                        } else {
                          selectedType = MediaType.other;
                        }
                      }
                    });
                  }
                },
                child: selectedFile == null
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Нажмите для выбора файла'),
                          ],
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              selectedType.icon,
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFile!.split('/').last,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Название
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Описание
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Теги
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Теги (через запятую)',
                border: OutlineInputBorder(),
                hintText: 'фото, свадьба, портрет',
              ),
            ),

            const SizedBox(height: 16),

            // Тип медиа
            DropdownButtonFormField<MediaType>(
              value: selectedType,
              decoration: const InputDecoration(
                labelText: 'Тип медиа',
                border: OutlineInputBorder(),
              ),
              items: MediaType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedType = value!;
                });
              },
            ),

            const SizedBox(height: 24),

            // Кнопка загрузки
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedFile == null || titleController.text.isEmpty
                    ? null
                    : () => _uploadMedia(
                          selectedFile!,
                          titleController.text,
                          descriptionController.text,
                          tagsController.text,
                          selectedType,
                        ),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Загрузить медиа'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(ContentStatus status) {
    switch (status) {
      case ContentStatus.uploaded:
        return Colors.blue;
      case ContentStatus.processing:
        return Colors.orange;
      case ContentStatus.processed:
        return Colors.green;
      case ContentStatus.published:
        return Colors.purple;
      case ContentStatus.archived:
        return Colors.grey;
      case ContentStatus.error:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _contentService.initialize();
      // TODO: Загрузить медиа и галереи для текущего пользователя
      setState(() {
        _mediaContent = [];
        _galleries = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки данных: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMediaDetails(MediaContent media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(media.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (media.description != null) ...[
              Text('Описание: ${media.description}'),
              const SizedBox(height: 8),
            ],
            Text('Тип: ${media.type.displayName}'),
            Text('Размер: ${media.formattedFileSize}'),
            Text('Статус: ${media.status.displayName}'),
            Text('Загружено: ${_formatDateTime(media.uploadedAt)}'),
            if (media.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Теги: ${media.tags.join(', ')}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _addToGallery(MediaContent media) {
    // TODO: Реализовать добавление в галерею
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Добавление "${media.title}" в галерею будет реализовано'),
      ),
    );
  }

  void _deleteMedia(MediaContent media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить медиа'),
        content: Text('Вы уверены, что хотите удалить "${media.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _contentService.deleteMedia(media.id);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Медиа удалено'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления медиа: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showCreateGalleryDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    GalleryType selectedType = GalleryType.portfolio;
    bool isPublic = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Создать галерею'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название галереи',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GalleryType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Тип галереи',
                  border: OutlineInputBorder(),
                ),
                items: GalleryType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Text(type.icon),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Публичная галерея'),
                value: isPublic,
                onChanged: (value) {
                  setState(() {
                    isPublic = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: nameController.text.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      try {
                        await _contentService.createGallery(
                          name: nameController.text,
                          description: descriptionController.text,
                          type: selectedType,
                          isPublic: isPublic,
                        );
                        _loadData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Галерея создана'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка создания галереи: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: const Text('Создать'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleGalleryAction(String action, ContentGallery gallery) {
    switch (action) {
      case 'edit':
        _editGallery(gallery);
        break;
      case 'manage':
        _manageGalleryMedia(gallery);
        break;
      case 'delete':
        _deleteGallery(gallery);
        break;
    }
  }

  void _editGallery(ContentGallery gallery) {
    // TODO: Реализовать редактирование галереи
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Редактирование галереи "${gallery.name}" будет реализовано'),
      ),
    );
  }

  void _manageGalleryMedia(ContentGallery gallery) {
    // TODO: Реализовать управление медиа в галерее
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Управление медиа в галерее "${gallery.name}" будет реализовано'),
      ),
    );
  }

  void _deleteGallery(ContentGallery gallery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить галерею'),
        content:
            Text('Вы уверены, что хотите удалить галерею "${gallery.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _contentService.deleteGallery(gallery.id);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Галерея удалена'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка удаления галереи: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadMedia(
    String filePath,
    String title,
    String description,
    String tags,
    MediaType type,
  ) async {
    try {
      final tagsList = tags
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      await _contentService.uploadMedia(
        filePath: filePath,
        title: title,
        description: description.isEmpty ? null : description,
        type: type,
        tags: tagsList,
      );

      _loadData();
      setState(() {
        _selectedTab = 'media';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Медиа "$title" загружено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки медиа: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
