import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/documentation_management.dart';
import '../services/documentation_management_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления документацией
class DocumentationManagementScreen extends ConsumerStatefulWidget {
  const DocumentationManagementScreen({super.key});

  @override
  ConsumerState<DocumentationManagementScreen> createState() =>
      _DocumentationManagementScreenState();
}

class _DocumentationManagementScreenState
    extends ConsumerState<DocumentationManagementScreen> {
  final DocumentationManagementService _docService =
      DocumentationManagementService();
  List<Documentation> _documents = [];
  List<DocumentTemplate> _templates = [];
  List<DocumentComment> _comments = [];
  bool _isLoading = true;
  String _selectedTab = 'documents';
  Map<String, dynamic> _analysis = {};

  // Фильтры
  DocumentType? _selectedType;
  DocumentCategory? _selectedCategory;
  DocumentStatus? _selectedStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление документацией')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Поиск и фильтры
            _buildSearchAndFilters(),

            // Анализ
            _buildAnalysis(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'documents'
                      ? _buildDocumentsTab()
                      : _selectedTab == 'templates'
                          ? _buildTemplatesTab()
                          : _buildCommentsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child:
                  _buildTabButton('documents', 'Документы', Icons.description),
            ),
            Expanded(
              child:
                  _buildTabButton('templates', 'Шаблоны', Icons.content_copy),
            ),
            Expanded(
              child: _buildTabButton('comments', 'Комментарии', Icons.comment),
            ),
          ],
        ),
      );

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

  Widget _buildSearchAndFilters() => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Поиск и фильтры',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),

            // Поиск
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по названию, содержанию или тегам...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),

            const SizedBox(height: 16),

            // Фильтры
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Фильтр по типу
                DropdownButton<DocumentType?>(
                  value: _selectedType,
                  hint: const Text('Все типы'),
                  items: [
                    const DropdownMenuItem<DocumentType?>(
                      child: Text('Все типы'),
                    ),
                    ...DocumentType.values.map(
                      (type) => DropdownMenuItem<DocumentType?>(
                        value: type,
                        child: Text('${type.icon} ${type.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),

                // Фильтр по категории
                DropdownButton<DocumentCategory?>(
                  value: _selectedCategory,
                  hint: const Text('Все категории'),
                  items: [
                    const DropdownMenuItem<DocumentCategory?>(
                      child: Text('Все категории'),
                    ),
                    ...DocumentCategory.values.map(
                      (category) => DropdownMenuItem<DocumentCategory?>(
                        value: category,
                        child: Text('${category.icon} ${category.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                // Фильтр по статусу
                DropdownButton<DocumentStatus?>(
                  value: _selectedStatus,
                  hint: const Text('Все статусы'),
                  items: [
                    const DropdownMenuItem<DocumentStatus?>(
                      child: Text('Все статусы'),
                    ),
                    ...DocumentStatus.values.map(
                      (status) => DropdownMenuItem<DocumentStatus?>(
                        value: status,
                        child: Text('${status.icon} ${status.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  },
                ),

                // Кнопка сброса фильтров
                ElevatedButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Сбросить'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildAnalysis() {
    if (_analysis.isEmpty) return const SizedBox.shrink();

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Анализ документации',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Всего документов',
                  '${_analysis['documents']?['total'] ?? 0}',
                  Icons.description,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Просмотры',
                  '${_analysis['documents']?['totalViews'] ?? 0}',
                  Icons.visibility,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Шаблоны',
                  '${_analysis['templates']?['total'] ?? 0}',
                  Icons.content_copy,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Комментарии',
                  '${_analysis['comments']?['total'] ?? 0}',
                  Icons.comment,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  Widget _buildDocumentsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Документы',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddDocumentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
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

          // Список документов
          Expanded(
            child: _getFilteredDocuments().isEmpty
                ? const Center(child: Text('Документы не найдены'))
                : ListView.builder(
                    itemCount: _getFilteredDocuments().length,
                    itemBuilder: (context, index) {
                      final document = _getFilteredDocuments()[index];
                      return _buildDocumentCard(document);
                    },
                  ),
          ),
        ],
      );

  Widget _buildDocumentCard(Documentation document) {
    final typeColor = _getTypeColor(document.type);
    final categoryColor = _getCategoryColor(document.category);
    final statusColor = _getStatusColor(document.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                document.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (document.summary != null)
                      Text(
                        document.summary!,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor),
                ),
                child: Text(
                  document.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor),
                ),
                child: Text(
                  document.category.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  document.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleDocumentAction(value, document),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Просмотр'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'comments',
                    child: ListTile(
                      leading: Icon(Icons.comment),
                      title: Text('Комментарии'),
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
              _buildInfoChip('Просмотры', '${document.viewCount}', Colors.blue),
              const SizedBox(width: 8),
              _buildInfoChip('Лайки', '${document.likeCount}', Colors.red),
              const SizedBox(width: 8),
              _buildInfoChip('Версия', document.version ?? '1.0', Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Теги
          if (document.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: document.tags
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Время и автор
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Автор: ${document.authorName}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Обновлен: ${_formatDateTime(document.updatedAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Шаблоны документов',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddTemplateDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить'),
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

          // Список шаблонов
          Expanded(
            child: _templates.isEmpty
                ? const Center(child: Text('Шаблоны не найдены'))
                : ListView.builder(
                    itemCount: _templates.length,
                    itemBuilder: (context, index) {
                      final template = _templates[index];
                      return _buildTemplateCard(template);
                    },
                  ),
          ),
        ],
      );

  Widget _buildTemplateCard(DocumentTemplate template) {
    final typeColor = _getTypeColor(template.type);
    final categoryColor = _getCategoryColor(template.category);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                template.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      template.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor),
                ),
                child: Text(
                  template.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor),
                ),
                child: Text(
                  template.category.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleTemplateAction(value, template),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Просмотр'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'use',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Использовать'),
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
              _buildInfoChip(
                'Использований',
                '${template.usageCount}',
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip('Теги', '${template.tags.length}', Colors.green),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(template.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Комментарии к документам',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список комментариев
          Expanded(
            child: _comments.isEmpty
                ? const Center(child: Text('Комментарии не найдены'))
                : ListView.builder(
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return _buildCommentCard(comment);
                    },
                  ),
          ),
        ],
      );

  Widget _buildCommentCard(DocumentComment comment) {
    final document = _docService.getDocument(comment.documentId);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const Icon(Icons.comment, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (document != null)
                      Text(
                        'К документу: ${document.title}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: comment.isResolved
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: comment.isResolved ? Colors.green : Colors.orange,
                  ),
                ),
                child: Text(
                  comment.isResolved ? 'Решен' : 'Открыт',
                  style: TextStyle(
                    fontSize: 12,
                    color: comment.isResolved ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleCommentAction(value, comment),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('Просмотр'),
                    ),
                  ),
                  if (!comment.isResolved)
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Решить'),
                      ),
                    ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Содержимое
          Text(
            comment.content,
            style: const TextStyle(fontSize: 14),
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              _buildInfoChip('Лайки', '${comment.likes.length}', Colors.red),
              const Spacer(),
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(comment.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color) => Container(
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

  Color _getTypeColor(DocumentType type) {
    switch (type) {
      case DocumentType.article:
        return Colors.blue;
      case DocumentType.tutorial:
        return Colors.green;
      case DocumentType.api:
        return Colors.purple;
      case DocumentType.faq:
        return Colors.orange;
      case DocumentType.changelog:
        return Colors.teal;
      case DocumentType.policy:
        return Colors.red;
      case DocumentType.guide:
        return Colors.cyan;
      case DocumentType.reference:
        return Colors.indigo;
      case DocumentType.specification:
        return Colors.brown;
      case DocumentType.manual:
        return Colors.pink;
    }
  }

  Color _getCategoryColor(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.general:
        return Colors.blue;
      case DocumentCategory.technical:
        return Colors.green;
      case DocumentCategory.user:
        return Colors.purple;
      case DocumentCategory.developer:
        return Colors.orange;
      case DocumentCategory.admin:
        return Colors.red;
      case DocumentCategory.business:
        return Colors.teal;
      case DocumentCategory.legal:
        return Colors.indigo;
      case DocumentCategory.support:
        return Colors.cyan;
      case DocumentCategory.marketing:
        return Colors.lime;
      case DocumentCategory.training:
        return Colors.pink;
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.draft:
        return Colors.grey;
      case DocumentStatus.review:
        return Colors.orange;
      case DocumentStatus.approved:
        return Colors.green;
      case DocumentStatus.published:
        return Colors.blue;
      case DocumentStatus.archived:
        return Colors.brown;
      case DocumentStatus.deprecated:
        return Colors.red;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  List<Documentation> _getFilteredDocuments() {
    var filtered = _documents;

    // Поиск
    if (_searchQuery.isNotEmpty) {
      filtered = _docService.searchDocuments(_searchQuery);
    }

    // Фильтры
    if (_selectedType != null) {
      filtered = filtered.where((doc) => doc.type == _selectedType).toList();
    }

    if (_selectedCategory != null) {
      filtered =
          filtered.where((doc) => doc.category == _selectedCategory).toList();
    }

    if (_selectedStatus != null) {
      filtered =
          filtered.where((doc) => doc.status == _selectedStatus).toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _docService.initialize();
      setState(() {
        _documents = _docService.getAllDocuments();
        _templates = _docService.getAllTemplates();
        _comments = _docService.getAllComments();
      });

      _analysis = await _docService.analyzeDocumentation();
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

  void _setupStreams() {
    _docService.documentStream.listen((document) {
      setState(() {
        final index = _documents.indexWhere((d) => d.id == document.id);
        if (index != -1) {
          _documents[index] = document;
        } else {
          _documents.add(document);
        }
      });
    });

    _docService.templateStream.listen((template) {
      setState(() {
        final index = _templates.indexWhere((t) => t.id == template.id);
        if (index != -1) {
          _templates[index] = template;
        } else {
          _templates.add(template);
        }
      });
    });

    _docService.commentStream.listen((comment) {
      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = comment;
        } else {
          _comments.add(comment);
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _selectedStatus = null;
      _searchQuery = '';
    });
  }

  void _handleDocumentAction(String action, Documentation document) {
    switch (action) {
      case 'view':
        _viewDocument(document);
        break;
      case 'edit':
        _editDocument(document);
        break;
      case 'comments':
        _viewDocumentComments(document);
        break;
    }
  }

  void _handleTemplateAction(String action, DocumentTemplate template) {
    switch (action) {
      case 'view':
        _viewTemplate(template);
        break;
      case 'edit':
        _editTemplate(template);
        break;
      case 'use':
        _useTemplate(template);
        break;
    }
  }

  void _handleCommentAction(String action, DocumentComment comment) {
    switch (action) {
      case 'view':
        _viewComment(comment);
        break;
      case 'resolve':
        _resolveComment(comment);
        break;
    }
  }

  void _viewDocument(Documentation document) {
    // TODO: Реализовать просмотр документа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Просмотр документа "${document.title}" будет реализован'),
      ),
    );
  }

  void _editDocument(Documentation document) {
    // TODO: Реализовать редактирование документа
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование документа "${document.title}" будет реализовано',
        ),
      ),
    );
  }

  void _viewDocumentComments(Documentation document) {
    // TODO: Реализовать просмотр комментариев к документу
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Комментарии к документу "${document.title}" будут реализованы',
        ),
      ),
    );
  }

  void _viewTemplate(DocumentTemplate template) {
    // TODO: Реализовать просмотр шаблона
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Просмотр шаблона "${template.name}" будет реализован'),
      ),
    );
  }

  void _editTemplate(DocumentTemplate template) {
    // TODO: Реализовать редактирование шаблона
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Редактирование шаблона "${template.name}" будет реализовано'),
      ),
    );
  }

  Future<void> _useTemplate(DocumentTemplate template) async {
    try {
      await _docService.incrementTemplateUsage(template.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Шаблон "${template.name}" использован'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка использования шаблона: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewComment(DocumentComment comment) {
    // TODO: Реализовать просмотр комментария
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Просмотр комментария будет реализован'),
      ),
    );
  }

  Future<void> _resolveComment(DocumentComment comment) async {
    try {
      await _docService.updateComment(
        id: comment.id,
        isResolved: true,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Комментарий решен'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка решения комментария: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddDocumentDialog() {
    // TODO: Реализовать диалог добавления документа
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Добавление документа будет реализовано'),
      ),
    );
  }

  void _showAddTemplateDialog() {
    // TODO: Реализовать диалог добавления шаблона
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Добавление шаблона будет реализовано'),
      ),
    );
  }
}
