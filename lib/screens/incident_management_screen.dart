import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/incident_management.dart';
import '../services/incident_management_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления инцидентами
class IncidentManagementScreen extends ConsumerStatefulWidget {
  const IncidentManagementScreen({super.key});

  @override
  ConsumerState<IncidentManagementScreen> createState() =>
      _IncidentManagementScreenState();
}

class _IncidentManagementScreenState
    extends ConsumerState<IncidentManagementScreen> {
  final IncidentManagementService _incidentService =
      IncidentManagementService();
  List<Incident> _incidents = [];
  List<IncidentComment> _comments = [];
  List<IncidentSLA> _sla = [];
  bool _isLoading = true;
  String _selectedTab = 'incidents';
  Map<String, dynamic> _analysis = {};

  // Фильтры
  IncidentType? _selectedType;
  IncidentSeverity? _selectedSeverity;
  IncidentStatus? _selectedStatus;
  IncidentPriority? _selectedPriority;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupStreams();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление инцидентами')),
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
                  : _selectedTab == 'incidents'
                      ? _buildIncidentsTab()
                      : _selectedTab == 'comments'
                          ? _buildCommentsTab()
                          : _buildSLATab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton('incidents', 'Инциденты', Icons.warning),
            ),
            Expanded(
              child: _buildTabButton('comments', 'Комментарии', Icons.comment),
            ),
            Expanded(
              child: _buildTabButton('sla', 'SLA', Icons.schedule),
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
                hintText: 'Поиск по названию, описанию или тегам...',
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
                DropdownButton<IncidentType?>(
                  value: _selectedType,
                  hint: const Text('Все типы'),
                  items: [
                    const DropdownMenuItem<IncidentType?>(
                      child: Text('Все типы'),
                    ),
                    ...IncidentType.values.map(
                      (type) => DropdownMenuItem<IncidentType?>(
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

                // Фильтр по серьезности
                DropdownButton<IncidentSeverity?>(
                  value: _selectedSeverity,
                  hint: const Text('Все серьезности'),
                  items: [
                    const DropdownMenuItem<IncidentSeverity?>(
                      child: Text('Все серьезности'),
                    ),
                    ...IncidentSeverity.values.map(
                      (severity) => DropdownMenuItem<IncidentSeverity?>(
                        value: severity,
                        child: Text('${severity.icon} ${severity.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedSeverity = value;
                    });
                  },
                ),

                // Фильтр по статусу
                DropdownButton<IncidentStatus?>(
                  value: _selectedStatus,
                  hint: const Text('Все статусы'),
                  items: [
                    const DropdownMenuItem<IncidentStatus?>(
                      child: Text('Все статусы'),
                    ),
                    ...IncidentStatus.values.map(
                      (status) => DropdownMenuItem<IncidentStatus?>(
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

                // Фильтр по приоритету
                DropdownButton<IncidentPriority?>(
                  value: _selectedPriority,
                  hint: const Text('Все приоритеты'),
                  items: [
                    const DropdownMenuItem<IncidentPriority?>(
                      child: Text('Все приоритеты'),
                    ),
                    ...IncidentPriority.values.map(
                      (priority) => DropdownMenuItem<IncidentPriority?>(
                        value: priority,
                        child: Text('${priority.icon} ${priority.displayName}'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedPriority = value;
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
            'Анализ инцидентов',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisCard(
                  'Всего инцидентов',
                  '${_analysis['incidents']?['total'] ?? 0}',
                  Icons.warning,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Открытых',
                  '${_analysis['incidents']?['open'] ?? 0}',
                  Icons.lock_open,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Решенных',
                  '${_analysis['incidents']?['resolved'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalysisCard(
                  'Нарушенных SLA',
                  '${_analysis['sla']?['breached'] ?? 0}',
                  Icons.schedule,
                  Colors.orange,
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

  Widget _buildIncidentsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'Инциденты',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showCreateIncidentDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Создать'),
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

          // Список инцидентов
          Expanded(
            child: _getFilteredIncidents().isEmpty
                ? const Center(child: Text('Инциденты не найдены'))
                : ListView.builder(
                    itemCount: _getFilteredIncidents().length,
                    itemBuilder: (context, index) {
                      final incident = _getFilteredIncidents()[index];
                      return _buildIncidentCard(incident);
                    },
                  ),
          ),
        ],
      );

  Widget _buildIncidentCard(Incident incident) {
    final typeColor = _getTypeColor(incident.type);
    final severityColor = _getSeverityColor(incident.severity);
    final statusColor = _getStatusColor(incident.status);
    final priorityColor = _getPriorityColor(incident.priority);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                incident.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      incident.description,
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
                  incident.type.displayName,
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
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: severityColor),
                ),
                child: Text(
                  incident.severity.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: severityColor,
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
                  incident.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: priorityColor),
                ),
                child: Text(
                  incident.priority.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: priorityColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleIncidentAction(value, incident),
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
                    value: 'comment',
                    child: ListTile(
                      leading: Icon(Icons.comment),
                      title: Text('Комментарий'),
                    ),
                  ),
                  if (incident.status == IncidentStatus.open)
                    const PopupMenuItem(
                      value: 'acknowledge',
                      child: ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Подтвердить'),
                      ),
                    ),
                  if (incident.status == IncidentStatus.acknowledged)
                    const PopupMenuItem(
                      value: 'resolve',
                      child: ListTile(
                        leading: Icon(Icons.done),
                        title: Text('Решить'),
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
              if (incident.assignedToName != null)
                _buildInfoChip(
                  'Назначен',
                  incident.assignedToName!,
                  Colors.blue,
                ),
              const SizedBox(width: 8),
              if (incident.affectedServices.isNotEmpty)
                _buildInfoChip(
                  'Сервисы',
                  '${incident.affectedServices.length}',
                  Colors.green,
                ),
              const SizedBox(width: 8),
              if (incident.affectedUsers.isNotEmpty)
                _buildInfoChip(
                  'Пользователи',
                  '${incident.affectedUsers.length}',
                  Colors.orange,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Теги
          if (incident.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: incident.tags
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

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(incident.createdAt)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (incident.resolvedAt != null) ...[
                const Spacer(),
                const Icon(Icons.check_circle, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Решен: ${_formatDateTime(incident.resolvedAt!)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
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
                  'Комментарии к инцидентам',
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

  Widget _buildCommentCard(IncidentComment comment) {
    final incident = _incidentService.getIncident(comment.incidentId);
    final typeColor = _getCommentTypeColor(comment.type);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                comment.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
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
                    if (incident != null)
                      Text(
                        'К инциденту: ${incident.title}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
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
                  comment.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (comment.isInternal)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text(
                    'Внутренний',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

          // Время
          Row(
            children: [
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

  Widget _buildSLATab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text(
                  'SLA инцидентов',
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

          // Список SLA
          Expanded(
            child: _sla.isEmpty
                ? const Center(child: Text('SLA не найдены'))
                : ListView.builder(
                    itemCount: _sla.length,
                    itemBuilder: (context, index) {
                      final sla = _sla[index];
                      return _buildSLACard(sla);
                    },
                  ),
          ),
        ],
      );

  Widget _buildSLACard(IncidentSLA sla) {
    final incident = _incidentService.getIncident(sla.incidentId);
    final statusColor = _getSLAStatusColor(sla.status);

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Text(
                sla.status.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SLA для инцидента',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (incident != null)
                      Text(
                        incident.title,
                        style: const TextStyle(fontSize: 14),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  sla.status.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Метаданные
          Row(
            children: [
              if (sla.acknowledgedDeadline != null)
                _buildInfoChip(
                  'Дедлайн подтверждения',
                  _formatDateTime(sla.acknowledgedDeadline!),
                  Colors.blue,
                ),
              const SizedBox(width: 8),
              if (sla.resolvedDeadline != null)
                _buildInfoChip(
                  'Дедлайн решения',
                  _formatDateTime(sla.resolvedDeadline!),
                  Colors.green,
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Статусы выполнения
          Row(
            children: [
              _buildInfoChip(
                'Подтвержден вовремя',
                sla.acknowledgedOnTime ? 'Да' : 'Нет',
                sla.acknowledgedOnTime ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                'Решен вовремя',
                sla.resolvedOnTime ? 'Да' : 'Нет',
                sla.resolvedOnTime ? Colors.green : Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Время
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                'Создан: ${_formatDateTime(sla.createdAt)}',
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

  Color _getTypeColor(IncidentType type) {
    switch (type) {
      case IncidentType.technical:
        return Colors.blue;
      case IncidentType.security:
        return Colors.red;
      case IncidentType.performance:
        return Colors.orange;
      case IncidentType.availability:
        return Colors.green;
      case IncidentType.data:
        return Colors.purple;
      case IncidentType.user:
        return Colors.teal;
      case IncidentType.business:
        return Colors.brown;
      case IncidentType.compliance:
        return Colors.indigo;
    }
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return Colors.red;
      case IncidentSeverity.high:
        return Colors.red;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.low:
        return Colors.green;
      case IncidentSeverity.info:
        return Colors.blue;
    }
  }

  Color _getStatusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open:
        return Colors.red;
      case IncidentStatus.acknowledged:
        return Colors.orange;
      case IncidentStatus.investigating:
        return Colors.blue;
      case IncidentStatus.resolved:
        return Colors.green;
      case IncidentStatus.closed:
        return Colors.grey;
      case IncidentStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(IncidentPriority priority) {
    switch (priority) {
      case IncidentPriority.p1:
        return Colors.red;
      case IncidentPriority.p2:
        return Colors.red;
      case IncidentPriority.p3:
        return Colors.orange;
      case IncidentPriority.p4:
        return Colors.green;
      case IncidentPriority.p5:
        return Colors.blue;
    }
  }

  Color _getCommentTypeColor(CommentType type) {
    switch (type) {
      case CommentType.comment:
        return Colors.blue;
      case CommentType.update:
        return Colors.orange;
      case CommentType.resolution:
        return Colors.green;
      case CommentType.workaround:
        return Colors.purple;
      case CommentType.escalation:
        return Colors.red;
      case CommentType.notification:
        return Colors.teal;
    }
  }

  Color _getSLAStatusColor(SLAStatus status) {
    switch (status) {
      case SLAStatus.active:
        return Colors.blue;
      case SLAStatus.breached:
        return Colors.red;
      case SLAStatus.met:
        return Colors.green;
      case SLAStatus.cancelled:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  List<Incident> _getFilteredIncidents() {
    var filtered = _incidents;

    // Поиск
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (incident) =>
                incident.title
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                incident.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                incident.tags.any(
                  (tag) =>
                      tag.toLowerCase().contains(_searchQuery.toLowerCase()),
                ),
          )
          .toList();
    }

    // Фильтры
    if (_selectedType != null) {
      filtered =
          filtered.where((incident) => incident.type == _selectedType).toList();
    }

    if (_selectedSeverity != null) {
      filtered = filtered
          .where((incident) => incident.severity == _selectedSeverity)
          .toList();
    }

    if (_selectedStatus != null) {
      filtered = filtered
          .where((incident) => incident.status == _selectedStatus)
          .toList();
    }

    if (_selectedPriority != null) {
      filtered = filtered
          .where((incident) => incident.priority == _selectedPriority)
          .toList();
    }

    return filtered;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _incidentService.initialize();
      setState(() {
        _incidents = _incidentService.getAllIncidents();
        _comments = _incidentService.getAllComments();
        _sla = _incidentService.getAllSLA();
      });

      _analysis = await _incidentService.analyzeIncidents();
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
    _incidentService.incidentStream.listen((incident) {
      setState(() {
        final index = _incidents.indexWhere((i) => i.id == incident.id);
        if (index != -1) {
          _incidents[index] = incident;
        } else {
          _incidents.add(incident);
        }
      });
    });

    _incidentService.commentStream.listen((comment) {
      setState(() {
        final index = _comments.indexWhere((c) => c.id == comment.id);
        if (index != -1) {
          _comments[index] = comment;
        } else {
          _comments.add(comment);
        }
      });
    });

    _incidentService.slaStream.listen((sla) {
      setState(() {
        final index = _sla.indexWhere((s) => s.id == sla.id);
        if (index != -1) {
          _sla[index] = sla;
        } else {
          _sla.add(sla);
        }
      });
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedType = null;
      _selectedSeverity = null;
      _selectedStatus = null;
      _selectedPriority = null;
      _searchQuery = '';
    });
  }

  void _handleIncidentAction(String action, Incident incident) {
    switch (action) {
      case 'view':
        _viewIncident(incident);
        break;
      case 'edit':
        _editIncident(incident);
        break;
      case 'comment':
        _addComment(incident);
        break;
      case 'acknowledge':
        _acknowledgeIncident(incident);
        break;
      case 'resolve':
        _resolveIncident(incident);
        break;
    }
  }

  void _viewIncident(Incident incident) {
    // TODO: Реализовать просмотр инцидента
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Просмотр инцидента "${incident.title}" будет реализован'),
      ),
    );
  }

  void _editIncident(Incident incident) {
    // TODO: Реализовать редактирование инцидента
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Редактирование инцидента "${incident.title}" будет реализовано',
        ),
      ),
    );
  }

  void _addComment(Incident incident) {
    // TODO: Реализовать добавление комментария
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Добавление комментария к инциденту "${incident.title}" будет реализовано',
        ),
      ),
    );
  }

  Future<void> _acknowledgeIncident(Incident incident) async {
    try {
      await _incidentService.updateIncident(
        id: incident.id,
        status: IncidentStatus.acknowledged,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Инцидент "${incident.title}" подтвержден'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка подтверждения инцидента: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _resolveIncident(Incident incident) async {
    try {
      await _incidentService.updateIncident(
        id: incident.id,
        status: IncidentStatus.resolved,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Инцидент "${incident.title}" решен'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка решения инцидента: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateIncidentDialog() {
    // TODO: Реализовать диалог создания инцидента
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Создание инцидента будет реализовано'),
      ),
    );
  }
}
