import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/request.dart';
import '../../providers/requests_providers.dart';

/// Экран деталей заявки
class RequestDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends ConsumerState<RequestDetailsScreen> {
  Request? _request;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final request = await ref.read(requestsServiceProvider).getRequestById(widget.requestId);
      setState(() {
        _request = request;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ошибка'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Ошибка загрузки заявки: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRequest,
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Заявка не найдена'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Center(
          child: Text('Заявка не найдена'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали заявки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Удалить'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок и статус
            Row(
              children: [
                Expanded(
                  child: Text(
                    _request!.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(status: _request!.status),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Информация о заявке
            _InfoCard(
              title: 'Описание',
              content: _request!.description,
            ),
            
            const SizedBox(height: 16),
            
            // Детали
            _DetailsCard(request: _request!),
            
            const SizedBox(height: 16),
            
            // Вложения
            if (_request!.attachments.isNotEmpty)
              _AttachmentsCard(attachments: _request!.attachments),
            
            const SizedBox(height: 16),
            
            // Действия
            _ActionsCard(
              request: _request!,
              onStatusChange: _changeStatus,
              onMessage: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        // TODO: Открыть экран редактирования
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Редактирование заявки')),
        );
        break;
      case 'delete':
        _deleteRequest();
        break;
    }
  }

  void _changeStatus(String newStatus) async {
    try {
      await ref.read(requestsProvider.notifier).updateRequestStatus(
        _request!.id,
        newStatus,
      );
      await _loadRequest();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления статуса: $e')),
      );
    }
  }

  void _sendMessage() {
    // TODO: Открыть чат
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Открытие чата')),
    );
  }

  void _deleteRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заявку'),
        content: const Text('Вы уверены, что хотите удалить эту заявку?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(requestsProvider.notifier).deleteRequest(_request!.id);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления заявки: $e')),
        );
      }
    }
  }
}

/// Карточка с информацией
class _InfoCard extends StatelessWidget {
  final String title;
  final String content;

  const _InfoCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(content),
          ],
        ),
      ),
    );
  }
}

/// Карточка с деталями
class _DetailsCard extends StatelessWidget {
  final Request request;

  const _DetailsCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Детали',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Город',
              value: request.city,
            ),
            _DetailRow(
              icon: Icons.category,
              label: 'Категория',
              value: request.category,
            ),
            if (request.subCategory.isNotEmpty)
              _DetailRow(
                icon: Icons.subdirectory_arrow_right,
                label: 'Подкатегория',
                value: request.subCategory,
              ),
            _DetailRow(
              icon: Icons.attach_money,
              label: 'Бюджет',
              value: '${request.budgetMin} - ${request.budgetMax} ₽',
            ),
            _DetailRow(
              icon: Icons.calendar_today,
              label: 'Дата',
              value: '${request.dateTime.day}.${request.dateTime.month}.${request.dateTime.year}',
            ),
            if (request.time != null)
              _DetailRow(
                icon: Icons.access_time,
                label: 'Время',
                value: request.time!.format(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Строка детали
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Карточка вложений
class _AttachmentsCard extends StatelessWidget {
  final List<String> attachments;

  const _AttachmentsCard({required this.attachments});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вложения',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...attachments.map((attachment) => ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(attachment),
              onTap: () {
                // TODO: Открыть вложение
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Открытие вложения: $attachment')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }
}

/// Карточка действий
class _ActionsCard extends StatelessWidget {
  final Request request;
  final ValueChanged<String> onStatusChange;
  final VoidCallback onMessage;

  const _ActionsCard({
    required this.request,
    required this.onStatusChange,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Действия',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Написать'),
                  ),
                ),
                const SizedBox(width: 8),
                if (request.status == 'OPEN')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusChange('IN_PROGRESS'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Взять в работу'),
                    ),
                  ),
                if (request.status == 'IN_PROGRESS')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => onStatusChange('DONE'),
                      icon: const Icon(Icons.check),
                      label: const Text('Завершить'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Чип статуса
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    String statusText;

    switch (status) {
      case 'OPEN':
        backgroundColor = Colors.green;
        statusText = 'Открыта';
        break;
      case 'IN_PROGRESS':
        backgroundColor = Colors.orange;
        statusText = 'В работе';
        break;
      case 'DONE':
        backgroundColor = Colors.blue;
        statusText = 'Завершена';
        break;
      case 'CANCELED':
        backgroundColor = Colors.red;
        statusText = 'Отменена';
        break;
      default:
        backgroundColor = Colors.grey;
        statusText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
