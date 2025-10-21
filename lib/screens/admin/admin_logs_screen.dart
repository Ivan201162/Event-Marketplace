import 'package:flutter/material.dart';

import '../../models/admin_models.dart';
import '../../services/admin_service.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  final AdminService _adminService = AdminService();
  String? _selectedAdmin;
  AdminAction? _selectedAction;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Логи администратора'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFiltersDialog),
          IconButton(icon: const Icon(Icons.download), onPressed: _exportLogs),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersBar(),
          Expanded(
            child: StreamBuilder<List<AdminLog>>(
              stream: _adminService.getAdminLogsStream(
                adminId: _selectedAdmin,
                action: _selectedAction,
                startDate: _startDate,
                endDate: _endDate,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }

                final logs = snapshot.data ?? [];
                if (logs.isEmpty) {
                  return const Center(child: Text('Нет логов для отображения'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getActionColor(log.action),
                          child: Icon(_getActionIcon(log.action), color: Colors.white, size: 20),
                        ),
                        title: Text(
                          log.description ?? '${_getActionName(log.action)} ${log.target}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Администратор: ${log.adminEmail}'),
                            Text(
                              'Цель: ${log.target}${log.targetId != null ? ' (${log.targetId})' : ''}',
                            ),
                            Text('Время: ${_formatTimestamp(log.timestamp)}'),
                            if (log.metadata != null && log.metadata!.isNotEmpty)
                              Text('Детали: ${log.metadata.toString()}'),
                            if (log.errorMessage != null)
                              Text(
                                'Ошибка: ${log.errorMessage}',
                                style: const TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getStatusIcon(log.status),
                              color: _getStatusColor(log.status),
                              size: 16,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStatusName(log.status),
                              style: TextStyle(
                                fontSize: 10,
                                color: _getStatusColor(log.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          if (_selectedAdmin != null)
            Chip(
              label: Text('Админ: $_selectedAdmin'),
              onDeleted: () => setState(() => _selectedAdmin = null),
            ),
          if (_selectedAction != null)
            Chip(
              label: Text('Действие: ${_getActionName(_selectedAction!)}'),
              onDeleted: () => setState(() => _selectedAction = null),
            ),
          if (_startDate != null)
            Chip(
              label: Text('С: ${_formatDate(_startDate!)}'),
              onDeleted: () => setState(() => _startDate = null),
            ),
          if (_endDate != null)
            Chip(
              label: Text('По: ${_formatDate(_endDate!)}'),
              onDeleted: () => setState(() => _endDate = null),
            ),
          const Spacer(),
          TextButton(onPressed: _clearFilters, child: const Text('Очистить')),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры логов'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedAdmin,
              decoration: const InputDecoration(
                labelText: 'Администратор',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'admin_123', child: Text('admin@example.com')),
                DropdownMenuItem(value: 'admin_456', child: Text('superadmin@example.com')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedAdmin = value;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AdminAction>(
              initialValue: _selectedAction,
              decoration: const InputDecoration(
                labelText: 'Действие',
                border: OutlineInputBorder(),
              ),
              items: AdminAction.values.map((action) {
                return DropdownMenuItem(value: action, child: Text(_getActionName(action)));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAction = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Начальная дата'),
              subtitle: Text(_startDate != null ? _formatDate(_startDate!) : 'Не выбрана'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(true),
            ),
            ListTile(
              title: const Text('Конечная дата'),
              subtitle: Text(_endDate != null ? _formatDate(_endDate!) : 'Не выбрана'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(false),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedAdmin = null;
      _selectedAction = null;
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _exportLogs() async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Экспорт логов в CSV...')));

      // Simulate export delay
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Логи экспортированы успешно')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка экспорта: $e')));
    }
  }

  Color _getActionColor(AdminAction action) {
    switch (action) {
      case AdminAction.create:
        return Colors.green;
      case AdminAction.update:
        return Colors.blue;
      case AdminAction.delete:
        return Colors.red;
      case AdminAction.activate:
        return Colors.green;
      case AdminAction.deactivate:
        return Colors.orange;
      case AdminAction.approve:
        return Colors.green;
      case AdminAction.reject:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(AdminAction action) {
    switch (action) {
      case AdminAction.create:
        return Icons.add;
      case AdminAction.update:
        return Icons.edit;
      case AdminAction.delete:
        return Icons.delete;
      case AdminAction.activate:
        return Icons.play_arrow;
      case AdminAction.deactivate:
        return Icons.pause;
      case AdminAction.approve:
        return Icons.check;
      case AdminAction.reject:
        return Icons.close;
      case AdminAction.export:
        return Icons.download;
      case AdminAction.import:
        return Icons.upload;
      case AdminAction.sendNotification:
        return Icons.notifications;
      default:
        return Icons.info;
    }
  }

  String _getActionName(AdminAction action) {
    switch (action) {
      case AdminAction.create:
        return 'Создание';
      case AdminAction.update:
        return 'Обновление';
      case AdminAction.delete:
        return 'Удаление';
      case AdminAction.activate:
        return 'Активация';
      case AdminAction.deactivate:
        return 'Деактивация';
      case AdminAction.approve:
        return 'Одобрение';
      case AdminAction.reject:
        return 'Отклонение';
      case AdminAction.export:
        return 'Экспорт';
      case AdminAction.import:
        return 'Импорт';
      case AdminAction.sendNotification:
        return 'Отправка уведомления';
      case AdminAction.updatePricing:
        return 'Обновление цен';
      case AdminAction.createCampaign:
        return 'Создание кампании';
      case AdminAction.updateCampaign:
        return 'Обновление кампании';
      case AdminAction.deleteCampaign:
        return 'Удаление кампании';
      case AdminAction.createPromotion:
        return 'Создание акции';
      case AdminAction.updatePromotion:
        return 'Обновление акции';
      case AdminAction.deletePromotion:
        return 'Удаление акции';
      case AdminAction.createPartner:
        return 'Создание партнёра';
      case AdminAction.updatePartner:
        return 'Обновление партнёра';
      case AdminAction.deletePartner:
        return 'Удаление партнёра';
      case AdminAction.updateReferralSettings:
        return 'Обновление реферальных настроек';
      case AdminAction.sendBulkNotification:
        return 'Массовая рассылка';
      case AdminAction.updateSubscriptionPlan:
        return 'Обновление тарифа';
      case AdminAction.createSubscriptionPlan:
        return 'Создание тарифа';
      case AdminAction.deleteSubscriptionPlan:
        return 'Удаление тарифа';
    }
  }

  IconData _getStatusIcon(AdminActionStatus status) {
    switch (status) {
      case AdminActionStatus.completed:
        return Icons.check_circle;
      case AdminActionStatus.failed:
        return Icons.error;
      case AdminActionStatus.pending:
        return Icons.schedule;
      case AdminActionStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor(AdminActionStatus status) {
    switch (status) {
      case AdminActionStatus.completed:
        return Colors.green;
      case AdminActionStatus.failed:
        return Colors.red;
      case AdminActionStatus.pending:
        return Colors.orange;
      case AdminActionStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusName(AdminActionStatus status) {
    switch (status) {
      case AdminActionStatus.completed:
        return 'Выполнено';
      case AdminActionStatus.failed:
        return 'Ошибка';
      case AdminActionStatus.pending:
        return 'В ожидании';
      case AdminActionStatus.cancelled:
        return 'Отменено';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}.${timestamp.month}.${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
