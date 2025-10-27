import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Упрощенный экран заявок
class RequestsScreenImproved extends ConsumerWidget {
  const RequestsScreenImproved({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // TODO: Implement refresh
          await Future.delayed(const Duration(seconds: 1));
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 10, // Mock data
          itemBuilder: (context, index) {
            return _RequestCard(
              title: 'Заявка ${index + 1}',
              description:
                  'Описание заявки номер ${index + 1}. Здесь будет подробное описание того, что нужно сделать.',
              budget: '${(index + 1) * 10000} ₽',
              deadline: '${index + 1} дней',
              category: _getCategory(index),
              status: _getStatus(index),
              onTap: () {
                // TODO: Navigate to request details
              },
              onApply: () {
                // TODO: Apply to request
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/create-request'),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getCategory(int index) {
    final categories = [
      'Фотография',
      'Видеосъемка',
      'Диджей',
      'Ведущий',
      'Декор'
    ];
    return categories[index % categories.length];
  }

  String _getStatus(int index) {
    final statuses = ['Активна', 'В работе', 'Завершена', 'Отменена'];
    return statuses[index % statuses.length];
  }
}

class _RequestCard extends StatelessWidget {
  final String title;
  final String description;
  final String budget;
  final String deadline;
  final String category;
  final String status;
  final VoidCallback onTap;
  final VoidCallback onApply;

  const _RequestCard({
    required this.title,
    required this.description,
    required this.budget,
    required this.deadline,
    required this.category,
    required this.status,
    required this.onTap,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Category
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Footer
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Бюджет: $budget',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Срок: $deadline',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Откликнуться'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Активна':
        return Colors.green;
      case 'В работе':
        return Colors.orange;
      case 'Завершена':
        return Colors.blue;
      case 'Отменена':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
