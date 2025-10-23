import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_template.dart';
import '../services/notification_service.dart';
import '../widgets/responsive_layout.dart';

/// Экран управления уведомлениями
class NotificationManagementScreen extends ConsumerStatefulWidget {
  const NotificationManagementScreen({super.key});

  @override
  ConsumerState<NotificationManagementScreen> createState() =>
      _NotificationManagementScreenState();
}

class _NotificationManagementScreenState
    extends ConsumerState<NotificationManagementScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationTemplate> _templates = [];
  List<SentNotification> _notifications = [];
  bool _isLoading = true;
  String _selectedTab = 'templates';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) => ResponsiveScaffold(
        appBar: AppBar(title: const Text('Управление уведомлениями')),
        body: Column(
          children: [
            // Вкладки
            _buildTabs(),

            // Контент
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _selectedTab == 'templates'
                      ? _buildTemplatesTab()
                      : _buildNotificationsTab(),
            ),
          ],
        ),
      );

  Widget _buildTabs() => ResponsiveCard(
        child: Row(
          children: [
            Expanded(
                child:
                    _buildTabButton('templates', 'Шаблоны', Icons.description)),
            Expanded(
                child: _buildTabButton(
                    'notifications', 'Отправленные', Icons.notifications)),
            Expanded(
                child: _buildTabButton(
                    'statistics', 'Статистика', Icons.analytics)),
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
        if (tab == 'statistics') {
          _loadStatistics();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? Colors.blue
                  : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.blue : Colors.grey, size: 24),
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

  Widget _buildTemplatesTab() => Column(
        children: [
          // Заголовок с кнопкой добавления
          ResponsiveCard(
            child: Row(
              children: [
                Text('Шаблоны уведомлений',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addTemplate,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить шаблон'),
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

  Widget _buildTemplateCard(NotificationTemplate template) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  _getTemplateIcon(template.type),
                  color: _getTemplateColor(template.type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(template.name,
                        style: Theme.of(context).textTheme.titleMedium)),
                _buildStatusChip(template.isActive),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTemplateAction(value, template),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Редактировать')),
                    ),
                    const PopupMenuItem(
                      value: 'toggle',
                      child: ListTile(
                        leading: Icon(Icons.toggle_on),
                        title: Text('Включить/Выключить'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete), title: Text('Удалить')),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Тип и канал
            Row(
              children: [
                _buildInfoChip('Тип', template.type.name, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip('Канал', template.channel.name, Colors.green),
              ],
            ),

            const SizedBox(height: 12),

            // Заголовок шаблона
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Заголовок:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(template.title),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Текст шаблона
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Текст:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(template.body),
                ],
              ),
            ),

            // Переменные
            if (template.variables.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Переменные:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: template.variables.entries
                    .map(
                      (entry) => Chip(
                        label: Text('{{${entry.key}}}'),
                        backgroundColor: Colors.blue.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      );

  Widget _buildNotificationsTab() => Column(
        children: [
          // Заголовок
          ResponsiveCard(
            child: Row(
              children: [
                Text('Отправленные уведомления',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Обновить'),
                ),
              ],
            ),
          ),

          // Список уведомлений
          Expanded(
            child: _notifications.isEmpty
                ? const Center(child: Text('Уведомления не найдены'))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      );

  Widget _buildNotificationCard(SentNotification notification) =>
      ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(notification.title,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                _buildStatusChip(notification.status.name),
              ],
            ),

            const SizedBox(height: 12),

            // Текст уведомления
            Text(notification.body),

            const SizedBox(height: 12),

            // Метаданные
            Row(
              children: [
                _buildInfoChip('Тип', notification.type.name, Colors.blue),
                const SizedBox(width: 8),
                _buildInfoChip(
                    'Канал', notification.channel.name, Colors.green),
                const SizedBox(width: 8),
                _buildInfoChip(
                  'Статус',
                  notification.status.name,
                  _getStatusColor(notification.status),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Время отправки
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Отправлено: ${_formatDateTime(notification.sentAt)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (notification.deliveredAt != null) ...[
                  const Spacer(),
                  Text(
                    'Доставлено: ${_formatDateTime(notification.deliveredAt!)}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ],
            ),

            if (notification.errorMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Ошибка: ${notification.errorMessage}',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _buildStatusChip(status) {
    Color color;
    String text;

    if (status is bool) {
      color = status ? Colors.green : Colors.red;
      text = status ? 'Активен' : 'Неактивен';
    } else if (status is String) {
      switch (status) {
        case 'sent':
          color = Colors.blue;
          break;
        case 'delivered':
          color = Colors.green;
          break;
        case 'read':
          color = Colors.purple;
          break;
        case 'failed':
          color = Colors.red;
          break;
        default:
          color = Colors.orange;
      }
      text = status;
    } else {
      color = Colors.grey;
      text = status.toString();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
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
              fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      );

  IconData _getTemplateIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.event;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.security:
        return Icons.security;
      default:
        return Icons.notifications;
    }
  }

  Color _getTemplateColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Colors.blue;
      case NotificationType.payment:
        return Colors.green;
      case NotificationType.message:
        return Colors.orange;
      case NotificationType.review:
        return Colors.purple;
      case NotificationType.reminder:
        return Colors.red;
      case NotificationType.promotion:
        return Colors.pink;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.security:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(NotificationType type) =>
      _getTemplateIcon(type);

  Color _getNotificationColor(NotificationType type) => _getTemplateColor(type);

  Color _getStatusColor(NotificationStatus status) {
    switch (status) {
      case NotificationStatus.sent:
        return Colors.blue;
      case NotificationStatus.delivered:
        return Colors.green;
      case NotificationStatus.read:
        return Colors.purple;
      case NotificationStatus.failed:
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDateTime(DateTime dateTime) =>
      '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([_loadTemplates(), _loadNotifications()]);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _notificationService.getNotificationTemplates();
      setState(() {
        _templates = templates;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки шаблонов: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadNotifications() async {
    try {
      // TODO(developer): Получить ID текущего пользователя
      final notifications =
          _notificationService.getUserNotifications('current_user_id');
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка загрузки уведомлений: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _loadStatistics() async {
    // TODO(developer): Реализовать загрузку статистики
  }

  void _addTemplate() {
    // TODO(developer): Реализовать добавление шаблона
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(
        content: Text('Функция добавления шаблона будет реализована')));
  }

  void _handleTemplateAction(String action, NotificationTemplate template) {
    switch (action) {
      case 'edit':
        // TODO(developer): Реализовать редактирование шаблона
        break;
      case 'toggle':
        // TODO(developer): Реализовать переключение статуса шаблона
        break;
      case 'delete':
        // TODO(developer): Реализовать удаление шаблона
        break;
    }
  }
}
