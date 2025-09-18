import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/feature_request.dart';
import '../services/feature_request_service.dart';
import '../core/feature_flags.dart';

/// Экран предложений по функционалу
class FeatureRequestScreen extends ConsumerStatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  ConsumerState<FeatureRequestScreen> createState() =>
      _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends ConsumerState<FeatureRequestScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FeatureRequestService _featureRequestService = FeatureRequestService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  FeatureCategory _selectedCategory = FeatureCategory.other;
  FeaturePriority _selectedPriority = FeaturePriority.medium;
  List<String> _selectedTags = [];

  bool _isLoading = false;
  List<FeatureRequest> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.featureRequestsEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Предложения по функционалу'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Предложения по функционалу временно недоступны',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Предложения по функционалу'),
        backgroundColor: Colors.amber[50],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Все предложения', icon: Icon(Icons.list)),
            Tab(text: 'Создать', icon: Icon(Icons.add)),
            Tab(text: 'Поиск', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllRequestsTab(),
          _buildCreateRequestTab(),
          _buildSearchTab(),
        ],
      ),
    );
  }

  Widget _buildAllRequestsTab() {
    return StreamBuilder<List<FeatureRequest>>(
      stream: _featureRequestService.getFeatureRequests(),
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
                Text('Ошибка загрузки: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Пока нет предложений',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Будьте первым, кто предложит улучшение!',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildRequestCard(request);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(FeatureRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'от ${request.userName} • ${request.categoryText}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: request.statusColor),
                      ),
                      child: Text(
                        request.statusText,
                        style: TextStyle(
                          color: request.statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: request.priorityColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: request.priorityColor),
                      ),
                      child: Text(
                        request.priorityText,
                        style: TextStyle(
                          color: request.priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: const TextStyle(fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (request.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: request.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${request.votes}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDate(request.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _showRequestDetails(request),
                  child: const Text('Подробнее'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _voteForRequest(request),
                  icon: const Icon(Icons.thumb_up, size: 16),
                  label: const Text('Голосовать'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreateForm(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Создать предложение',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Заголовок предложения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Описание предложения',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              maxLength: 1000,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeatureCategory>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Категория',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: FeatureCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(_getCategoryText(category)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FeaturePriority>(
              initialValue: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Приоритет',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: FeaturePriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityText(priority)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitRequest,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.send),
        label: Text(_isLoading ? 'Отправка...' : 'Отправить предложение'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Поиск предложений',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchResults = [];
                  });
                },
              ),
            ),
            onSubmitted: _performSearch,
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Введите запрос для поиска',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final request = _searchResults[index];
                    return _buildRequestCard(request);
                  },
                ),
        ),
      ],
    );
  }

  String _getCategoryText(FeatureCategory category) {
    switch (category) {
      case FeatureCategory.ui:
        return 'Пользовательский интерфейс';
      case FeatureCategory.functionality:
        return 'Функциональность';
      case FeatureCategory.performance:
        return 'Производительность';
      case FeatureCategory.security:
        return 'Безопасность';
      case FeatureCategory.integration:
        return 'Интеграция';
      case FeatureCategory.mobile:
        return 'Мобильное приложение';
      case FeatureCategory.web:
        return 'Веб-версия';
      case FeatureCategory.api:
        return 'API';
      case FeatureCategory.other:
        return 'Другое';
    }
  }

  String _getPriorityText(FeaturePriority priority) {
    switch (priority) {
      case FeaturePriority.low:
        return 'Низкий';
      case FeaturePriority.medium:
        return 'Средний';
      case FeaturePriority.high:
        return 'Высокий';
      case FeaturePriority.critical:
        return 'Критический';
    }
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

  Future<void> _submitRequest() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите заголовок предложения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите описание предложения'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _featureRequestService.createFeatureRequest(
        userId: 'current_user_id', // TODO: Получить реальный ID
        userName: 'Текущий пользователь', // TODO: Получить реальное имя
        userType: UserType.customer, // TODO: Получить реальный тип
        title: title,
        description: description,
        category: _selectedCategory,
        priority: _selectedPriority,
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedCategory = FeatureCategory.other;
        _selectedPriority = FeaturePriority.medium;
      });

      _tabController.animateTo(0);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение успешно отправлено!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка отправки: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final results = await _featureRequestService.searchFeatureRequests(query);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка поиска: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRequestDetails(FeatureRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'от ${request.userName} • ${_formatDate(request.createdAt)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.description,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (request.adminComment != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Комментарий администратора:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(request.adminComment!),
                            ],
                          ),
                        ),
                      ],
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

  Future<void> _voteForRequest(FeatureRequest request) async {
    try {
      await _featureRequestService.voteForFeatureRequest(
        request.id,
        'current_user_id', // TODO: Получить реальный ID
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ваш голос учтен!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка голосования: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
