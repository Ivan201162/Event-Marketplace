import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/support_ticket.dart';
import '../services/support_service.dart';
import '../widgets/support_ticket_widget.dart';
import 'support_ticket_detail_screen.dart';

/// Экран админ-панели поддержки
class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen> {
  final SupportService _supportService = SupportService();

  SupportStatus? _selectedStatus;
  SupportCategory? _selectedCategory;
  SupportPriority? _selectedPriority;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Админ-панель поддержки'),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
            ),
          ],
        ),
        body: Column(
          children: [
            // Статистика
            _buildStatsSection(),

            // Фильтры
            _buildFiltersSection(),

            // Список тикетов
            Expanded(
              child: _buildTicketsList(),
            ),
          ],
        ),
      );

  Widget _buildStatsSection() => FutureBuilder<SupportStats>(
        future: _supportService.getSupportStats('admin'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          final stats = snapshot.data ?? SupportStats.empty();
          if (stats.totalTickets == 0) {
            return const SizedBox.shrink();
          }

          return Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Статистика поддержки',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Всего тикетов',
                            stats.totalTickets.toString(),
                            Icons.support_agent,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Открытых',
                            stats.openTickets.toString(),
                            Icons.open_in_new,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'В работе',
                            stats.inProgressTickets.toString(),
                            Icons.work,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Решённых',
                            stats.resolvedTickets.toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Среднее время решения',
                            '${stats.averageResolutionTime.toStringAsFixed(1)} ч.',
                            Icons.timer,
                            Colors.purple,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Закрытых',
                            stats.closedTickets.toString(),
                            Icons.close,
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );

  Widget _buildFiltersSection() => Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Фильтр по статусу
            Expanded(
              child: DropdownButtonFormField<SupportStatus?>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Статус',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все статусы'),
                  ),
                  ...SupportStatus.values.map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: status.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.statusText),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            // Фильтр по категории
            Expanded(
              child: DropdownButtonFormField<SupportCategory?>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Категория',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все категории'),
                  ),
                  ...SupportCategory.values.map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(category.icon, size: 16),
                          const SizedBox(width: 8),
                          Text(category.categoryText),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),

            const SizedBox(width: 8),

            // Фильтр по приоритету
            Expanded(
              child: DropdownButtonFormField<SupportPriority?>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(
                    child: Text('Все приоритеты'),
                  ),
                  ...SupportPriority.values.map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priority.priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(priority.priorityText),
                        ],
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
            ),
          ],
        ),
      );

  Widget _buildTicketsList() => StreamBuilder<List<SupportTicket>>(
        stream: _supportService.getAllTickets(),
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
                  Text('Ошибка: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data ?? [];
          final filteredTickets = _filterTickets(tickets);

          if (filteredTickets.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: filteredTickets.length,
            itemBuilder: (context, index) {
              final ticket = filteredTickets[index];
              return SupportTicketWidget(
                ticket: ticket,
                onTap: () => _showTicketDetail(ticket),
              );
            },
          );
        },
      );

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет тикетов',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Попробуйте изменить фильтры',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets) =>
      tickets.where((ticket) {
        if (_selectedStatus != null && ticket.status != _selectedStatus) {
          return false;
        }
        if (_selectedCategory != null && ticket.category != _selectedCategory) {
          return false;
        }
        if (_selectedPriority != null && ticket.priority != _selectedPriority) {
          return false;
        }
        return true;
      }).toList();

  void _showTicketDetail(SupportTicket ticket) {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (context) => SupportTicketDetailScreen(
          ticketId: ticket.id,
        ),
      ),
    )
        .then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showFilterDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Фильтры'),
        content: const Text('Фильтры уже применены в интерфейсе'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}
