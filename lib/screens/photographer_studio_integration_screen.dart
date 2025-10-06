import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/photo_studio.dart';
import '../models/photographer_studio_link.dart';
import '../providers/auth_providers.dart';
import '../services/photo_studio_service.dart';
import '../services/photographer_studio_link_service.dart';
import '../widgets/studio_suggestion_widget.dart';

/// Экран интеграции фотографов и фотостудий
class PhotographerStudioIntegrationScreen extends ConsumerStatefulWidget {
  const PhotographerStudioIntegrationScreen({
    super.key,
    required this.photographerId,
  });

  final String photographerId;

  @override
  ConsumerState<PhotographerStudioIntegrationScreen> createState() =>
      _PhotographerStudioIntegrationScreenState();
}

class _PhotographerStudioIntegrationScreenState
    extends ConsumerState<PhotographerStudioIntegrationScreen>
    with TickerProviderStateMixin {
  final PhotoStudioService _photoStudioService = PhotoStudioService();
  final PhotographerStudioLinkService _linkService =
      PhotographerStudioLinkService();

  List<PhotoStudio> _availableStudios = [];
  List<PhotographerStudioLink> _existingLinks = [];
  bool _isLoading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Загружаем доступные фотостудии и существующие связки параллельно
      final results = await Future.wait([
        _photoStudioService.getPhotoStudios(),
        _linkService.getPhotographerLinks(widget.photographerId),
      ]);

      if (mounted) {
        setState(() {
          _availableStudios = results[0] as List<PhotoStudio>;
          _existingLinks = results[1] as List<PhotographerStudioLink>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Ошибка загрузки: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Интеграция с фотостудиями'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Интеграция с фотостудиями'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAvailableStudiosTab(),
                _buildExistingLinksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() => Container(
        color: Theme.of(context).colorScheme.surface,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Доступные студии (${_availableStudios.length})',
            ),
            Tab(
              text: 'Мои связки (${_existingLinks.length})',
            ),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
        ),
      );

  Widget _buildAvailableStudiosTab() {
    if (_availableStudios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_camera_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет доступных фотостудий',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _availableStudios.length,
        itemBuilder: (context, index) {
          final studio = _availableStudios[index];
          final isLinked =
              _existingLinks.any((link) => link.studioId == studio.id);

          return StudioSuggestionWidget(
            photoStudio: studio,
            isSuggested: isLinked,
            onSuggest: () => _createLink(studio),
            onViewDetails: () => _showStudioDetails(studio),
          );
        },
      ),
    );
  }

  Widget _buildExistingLinksTab() {
    if (_existingLinks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'У вас нет связок с фотостудиями',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Перейдите на вкладку "Доступные студии" чтобы создать связку',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _existingLinks.length,
        itemBuilder: (context, index) {
          final link = _existingLinks[index];
          return _buildLinkCard(link);
        },
      ),
    );
  }

  Widget _buildLinkCard(PhotographerStudioLink link) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Expanded(
                  child: Text(
                    link.studioName ?? 'Фотостудия',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(link.status),
              ],
            ),
            const SizedBox(height: 8),

            // Информация о связке
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  link.timeAgo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                if (link.commissionRate != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.percent, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    link.formattedCommissionRate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),

            // Заметки
            if (link.notes != null && link.notes!.isNotEmpty) ...[
              Text(
                'Заметки: ${link.notes}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],

            // Действия
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showLinkDetails(link),
                    child: const Text('Подробнее'),
                  ),
                ),
                const SizedBox(width: 12),
                if (link.isPending) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _cancelLink(link),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Отменить'),
                    ),
                  ),
                ] else if (link.isActive) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _suspendLink(link),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Приостановить'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'active':
        color = Colors.green;
        text = 'Активна';
        break;
      case 'pending':
        color = Colors.orange;
        text = 'Ожидает';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Отклонена';
        break;
      case 'suspended':
        color = Colors.grey;
        text = 'Приостановлена';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _createLink(PhotoStudio studio) async {
    try {
      // Показываем диалог для создания связки
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _CreateLinkDialog(studio: studio),
      );

      if (result != null) {
        // Создаем связку
        await _linkService.createLink(
          CreatePhotographerStudioLink(
            photographerId: widget.photographerId,
            studioId: studio.id,
            notes: result['notes'],
            commissionRate: result['commissionRate'],
          ),
        );

        // Обновляем данные
        await _loadData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Запрос на связку с ${studio.name} отправлен'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка создания связки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showStudioDetails(PhotoStudio studio) {
    // TODO(developer): Переход к экрану профиля студии
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Переход к профилю ${studio.name}'),
      ),
    );
  }

  void _showLinkDetails(PhotographerStudioLink link) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(link.studioName ?? 'Связка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Статус: ${_getStatusText(link.status)}'),
            if (link.commissionRate != null)
              Text('Комиссия: ${link.formattedCommissionRate}'),
            if (link.notes != null && link.notes!.isNotEmpty)
              Text('Заметки: ${link.notes}'),
            Text('Создано: ${link.timeAgo}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelLink(PhotographerStudioLink link) async {
    try {
      await _linkService.deleteLink(link.id);
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Связка отменена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отмены связки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _suspendLink(PhotographerStudioLink link) async {
    try {
      await _linkService.updateLinkStatus(link.id, 'suspended');
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Связка приостановлена'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка приостановки связки: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Активна';
      case 'pending':
        return 'Ожидает';
      case 'rejected':
        return 'Отклонена';
      case 'suspended':
        return 'Приостановлена';
      default:
        return status;
    }
  }
}

/// Диалог для создания связки
class _CreateLinkDialog extends StatefulWidget {
  const _CreateLinkDialog({required this.studio});

  final PhotoStudio studio;

  @override
  State<_CreateLinkDialog> createState() => _CreateLinkDialogState();
}

class _CreateLinkDialogState extends State<_CreateLinkDialog> {
  final _notesController = TextEditingController();
  final _commissionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Создать связку с ${widget.studio.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки (необязательно)',
                hintText: 'Дополнительная информация о связке',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commissionController,
              decoration: const InputDecoration(
                labelText: 'Комиссия % (необязательно)',
                hintText: 'Например: 10',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _createLink,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Создать'),
          ),
        ],
      );

  Future<void> _createLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final commissionRate = _commissionController.text.isNotEmpty
          ? double.tryParse(_commissionController.text)
          : null;

      Navigator.of(context).pop({
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'commissionRate': commissionRate,
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
