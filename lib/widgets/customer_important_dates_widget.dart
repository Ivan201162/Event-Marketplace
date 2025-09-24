import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer_profile.dart';
import '../services/customer_profile_service.dart';

/// Виджет важных дат заказчика
class CustomerImportantDatesWidget extends ConsumerWidget {
  const CustomerImportantDatesWidget({
    super.key,
    required this.customerId,
    this.isOwnProfile = false,
    this.onAddImportantDate,
    this.onEditImportantDate,
    this.onRemoveImportantDate,
  });

  final String customerId;
  final bool isOwnProfile;
  final VoidCallback? onAddImportantDate;
  final Function(String)? onEditImportantDate;
  final Function(String)? onRemoveImportantDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return StreamBuilder<CustomerProfile?>(
      stream: ref.read(customerProfileServiceProvider).getCustomerProfile(customerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(
            child: Text('Профиль не найден'),
          );
        }

        final profile = snapshot.data!;
        final importantDates = profile.importantDates;
        
        return Column(
          children: [
            // Заголовок с кнопкой добавления
            if (isOwnProfile)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Важные даты',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: onAddImportantDate,
                      icon: const Icon(Icons.add),
                      label: const Text('Добавить'),
                    ),
                  ],
                ),
              ),
            
            // Предстоящие даты
            if (importantDates.isNotEmpty) ...[
              _buildUpcomingDates(context, theme, importantDates),
              const SizedBox(height: 16),
            ],
            
            // Все даты
            if (importantDates.isEmpty)
              _buildEmptyState(context, theme)
            else
              _buildAllDates(context, theme, importantDates),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingDates(BuildContext context, ThemeData theme, List<ImportantDate> dates) {
    final now = DateTime.now();
    final upcomingDates = dates.where((date) {
      final daysUntil = date.date.difference(now).inDays;
      return daysUntil >= 0 && daysUntil <= 30; // Ближайшие 30 дней
    }).toList();

    if (upcomingDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Предстоящие события',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...upcomingDates.take(3).map((date) => _buildUpcomingDateItem(context, theme, date)),
        ],
      ),
    );
  }

  Widget _buildUpcomingDateItem(BuildContext context, ThemeData theme, ImportantDate date) {
    final now = DateTime.now();
    final daysUntil = date.date.difference(now).inDays;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getDateColor(date.category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getDateColor(date.category).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _getDateColor(date.category),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(date.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (daysUntil == 0)
                  Text(
                    'Сегодня!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else if (daysUntil == 1)
                  Text(
                    'Завтра',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    'Через $daysUntil дн.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          if (isOwnProfile)
            IconButton(
              onPressed: () => onEditImportantDate?.call(date.id),
              icon: const Icon(Icons.edit, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildAllDates(BuildContext context, ThemeData theme, List<ImportantDate> dates) {
    // Сортируем даты по категориям
    final sortedDates = List<ImportantDate>.from(dates);
    sortedDates.sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        return _buildDateItem(context, theme, date);
      },
    );
  }

  Widget _buildDateItem(BuildContext context, ThemeData theme, ImportantDate date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка категории
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getDateColor(date.category).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDateIcon(date.category),
                color: _getDateColor(date.category),
                size: 20,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Информация о дате
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(date.date),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  if (date.description != null && date.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      date.description!,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDateColor(date.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getCategoryText(date.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _getDateColor(date.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (date.isRecurring) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Повторяется',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // Кнопки действий
            if (isOwnProfile)
              PopupMenuButton<String>(
                onSelected: (value) => _handleDateAction(value, date),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Редактировать'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Удалить', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.event,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            isOwnProfile ? 'Добавьте важные даты' : 'Важные даты не указаны',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isOwnProfile 
                ? 'Добавьте важные даты для получения напоминаний'
                : 'Заказчик еще не добавил важные даты',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwnProfile) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAddImportantDate,
              icon: const Icon(Icons.add),
              label: const Text('Добавить дату'),
            ),
          ],
        ],
      ),
    );
  }

  Color _getDateColor(String category) {
    switch (category.toLowerCase()) {
      case 'birthday':
      case 'день рождения':
        return Colors.pink;
      case 'anniversary':
      case 'годовщина':
        return Colors.red;
      case 'holiday':
      case 'праздник':
        return Colors.purple;
      case 'personal':
      case 'личное':
        return Colors.blue;
      case 'family':
      case 'семья':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getDateIcon(String category) {
    switch (category.toLowerCase()) {
      case 'birthday':
      case 'день рождения':
        return Icons.cake;
      case 'anniversary':
      case 'годовщина':
        return Icons.favorite;
      case 'holiday':
      case 'праздник':
        return Icons.celebration;
      case 'personal':
      case 'личное':
        return Icons.person;
      case 'family':
      case 'семья':
        return Icons.family_restroom;
      default:
        return Icons.event;
    }
  }

  String _getCategoryText(String category) {
    switch (category.toLowerCase()) {
      case 'birthday':
        return 'День рождения';
      case 'anniversary':
        return 'Годовщина';
      case 'holiday':
        return 'Праздник';
      case 'personal':
        return 'Личное';
      case 'family':
        return 'Семья';
      default:
        return category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }

  void _handleDateAction(String action, ImportantDate date) {
    switch (action) {
      case 'edit':
        onEditImportantDate?.call(date.id);
        break;
      case 'delete':
        _showDeleteConfirmation(date);
        break;
    }
  }

  void _showDeleteConfirmation(ImportantDate date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить важную дату'),
        content: Text('Вы уверены, что хотите удалить "${date.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onRemoveImportantDate?.call(date.id);
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
