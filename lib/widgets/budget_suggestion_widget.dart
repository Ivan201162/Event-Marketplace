import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/budget_suggestion.dart';
import '../services/budget_suggestion_service.dart';
import 'responsive_layout.dart';
import 'responsive_text.dart';

/// Виджет для отображения предложения по увеличению бюджета
class BudgetSuggestionWidget extends ConsumerWidget {
  const BudgetSuggestionWidget(
      {super.key, required this.suggestion, this.onSuggestionChanged});
  final BudgetSuggestion suggestion;
  final VoidCallback? onSuggestionChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с статусом
            Row(
              children: [
                Icon(_getSuggestionIcon(),
                    color: suggestion.status.color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: ResponsiveText(
                    'Рекомендуем увеличить бюджет',
                    style: Theme.of(
                      context,
                    )
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),

            const SizedBox(height: 12),

            // Информация о предложении
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: suggestion.status.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: suggestion.status.color),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'Дополнительных услуг:',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      ResponsiveText(
                        '${suggestion.suggestionCount}',
                        style: TextStyle(
                            color: suggestion.status.color,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'Общая стоимость:',
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      ResponsiveText(
                        '${suggestion.totalCost.toStringAsFixed(0)} ₽',
                        style: TextStyle(
                            color: suggestion.status.color,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (suggestion.minCost != suggestion.maxCost) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          'Диапазон цен:',
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        ResponsiveText(
                          '${suggestion.minCost.toStringAsFixed(0)} - ${suggestion.maxCost.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                              color: suggestion.status.color,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Сообщение
            if (suggestion.message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ResponsiveText(
                        suggestion.message!,
                        style: Theme.of(
                          context,
                        )
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Список рекомендуемых услуг
            const SizedBox(height: 12),
            ResponsiveText(
              'Рекомендуемые услуги:',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...suggestion.suggestions.map(_buildServiceCard),

            // Кнопки действий
            if (suggestion.canRespond) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptSuggestion(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('Принять все'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectSuggestion(context, ref),
                      icon: const Icon(Icons.close),
                      label: const Text('Отклонить'),
                      style:
                          OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],

            // Информация о времени
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                ResponsiveText(
                  'Создано: ${_formatDate(suggestion.createdAt)}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildStatusChip() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: suggestion.status.color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: suggestion.status.color),
        ),
        child: Text(
          suggestion.status.displayName,
          style: TextStyle(
              color: suggestion.status.color,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
      );

  Widget _buildServiceCard(BudgetSuggestionItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        item.categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      if (item.specialistName != null) ...[
                        const SizedBox(height: 2),
                        ResponsiveText(
                          item.specialistName!,
                          style: Theme.of(
                            context,
                          )
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ],
                  ),
                ),
                if (item.estimatedPrice != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.estimatedPrice!.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            ResponsiveText(
              item.description,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            if (item.reason != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.reason!,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );

  IconData _getSuggestionIcon() {
    switch (suggestion.status) {
      case BudgetSuggestionStatus.pending:
        return Icons.trending_up;
      case BudgetSuggestionStatus.viewed:
        return Icons.visibility;
      case BudgetSuggestionStatus.accepted:
        return Icons.check_circle;
      case BudgetSuggestionStatus.rejected:
        return Icons.cancel;
      case BudgetSuggestionStatus.expired:
        return Icons.access_time;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}д назад';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}ч назад';
    } else {
      return '${difference.inMinutes}м назад';
    }
  }

  Future<void> _acceptSuggestion(BuildContext context, WidgetRef ref) async {
    try {
      // TODO(developer): Получить сервис через провайдер
      // final service = ref.read(budgetSuggestionServiceProvider);
      // await service.acceptBudgetSuggestion(
      //   suggestionId: suggestion.id,
      //   customerId: 'current_user_id', // TODO(developer): Получить из контекста
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение принято! Созданы бронирования.'),
          backgroundColor: Colors.green,
        ),
      );

      onSuggestionChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    }
  }

  void _rejectSuggestion(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _RejectSuggestionDialog(
        suggestion: suggestion,
        onRejected: () {
          onSuggestionChanged?.call();
        },
      ),
    );
  }
}

/// Виджет для создания предложения по увеличению бюджета
class CreateBudgetSuggestionWidget extends ConsumerStatefulWidget {
  const CreateBudgetSuggestionWidget({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.specialistId,
    this.onSuggestionCreated,
  });
  final String bookingId;
  final String customerId;
  final String specialistId;
  final VoidCallback? onSuggestionCreated;

  @override
  ConsumerState<CreateBudgetSuggestionWidget> createState() =>
      _CreateBudgetSuggestionWidgetState();
}

class _CreateBudgetSuggestionWidgetState
    extends ConsumerState<CreateBudgetSuggestionWidget> {
  final _messageController = TextEditingController();
  final List<BudgetSuggestionItem> _selectedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBudgetSuggestions();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.blue),
                const SizedBox(width: 8),
                ResponsiveText(
                  'Предложить увеличить бюджет',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 12),

            const Text(
              'Проанализируйте бюджет клиента и предложите дополнительные услуги для улучшения мероприятия.',
            ),

            const SizedBox(height: 16),

            // Кнопка анализа бюджета
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadBudgetSuggestions,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.analytics),
              label: Text(_isLoading ? 'Анализ...' : 'Проанализировать бюджет'),
            ),

            // Список рекомендуемых услуг
            if (_selectedItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              ResponsiveText(
                'Рекомендуемые услуги:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._selectedItems.map(_buildSelectedServiceCard),
            ],

            // Сообщение
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Сообщение клиенту (необязательно)',
                border: OutlineInputBorder(),
                hintText: 'Добавьте комментарий к предложению...',
              ),
              maxLines: 3,
            ),

            // Кнопка создания предложения
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _canCreateSuggestion() ? _createSuggestion : null,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                        _isLoading ? 'Создание...' : 'Создать предложение'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _buildSelectedServiceCard(BudgetSuggestionItem item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    item.categoryName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  if (item.specialistName != null) ...[
                    const SizedBox(height: 2),
                    ResponsiveText(
                      item.specialistName!,
                      style: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                  if (item.estimatedPrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.estimatedPrice!.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeService(item),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
          ],
        ),
      );

  bool _canCreateSuggestion() => _selectedItems.isNotEmpty && !_isLoading;

  Future<void> _loadBudgetSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO(developer): Получить сервис через провайдер
      // final service = ref.read(budgetSuggestionServiceProvider);
      final suggestions = await service.analyzeBudgetAndCreateSuggestions(
        bookingId: widget.bookingId,
        customerId: widget.customerId,
        specialistId: widget.specialistId,
      );

      setState(() {
        _selectedItems.clear();
        _selectedItems.addAll(suggestions);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка анализа бюджета: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeService(BudgetSuggestionItem item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  Future<void> _createSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO(developer): Получить сервис через провайдер
      // final service = ref.read(budgetSuggestionServiceProvider);
      // await service.createBudgetSuggestion(
      //   bookingId: widget.bookingId,
      //   customerId: widget.customerId,
      //   specialistId: widget.specialistId,
      //   suggestions: _selectedItems,
      //   message: _messageController.text.trim().isEmpty
      //       ? null
      //       : _messageController.text.trim(),
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Предложение создано и отправлено клиенту'),
          backgroundColor: Colors.green,
        ),
      );

      widget.onSuggestionCreated?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Диалог для отклонения предложения
class _RejectSuggestionDialog extends StatefulWidget {
  const _RejectSuggestionDialog(
      {required this.suggestion, required this.onRejected});
  final BudgetSuggestion suggestion;
  final VoidCallback onRejected;

  @override
  State<_RejectSuggestionDialog> createState() =>
      _RejectSuggestionDialogState();
}

class _RejectSuggestionDialogState extends State<_RejectSuggestionDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Отклонить предложение'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Вы уверены, что хотите отклонить это предложение?'),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина отклонения (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _rejectSuggestion,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Отклонить'),
          ),
        ],
      );

  Future<void> _rejectSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO(developer): Получить сервис через провайдер
      // final service = ref.read(budgetSuggestionServiceProvider);
      // await service.rejectBudgetSuggestion(
      //   suggestionId: widget.suggestion.id,
      //   customerId: 'current_user_id', // TODO(developer): Получить из контекста
      //   reason: _reasonController.text.trim().isEmpty
      //       ? null
      //       : _reasonController.text.trim(),
      // );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Предложение отклонено'),
            backgroundColor: Colors.orange),
      );

      widget.onRejected();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Провайдер для сервиса предложений по бюджету
final budgetSuggestionServiceProvider = Provider<BudgetSuggestionService>(
  (ref) => BudgetSuggestionService(),
);
