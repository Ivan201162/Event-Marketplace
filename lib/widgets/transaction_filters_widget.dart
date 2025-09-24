import 'package:flutter/material.dart';

import '../services/transaction_history_service.dart';

/// Виджет фильтров транзакций
class TransactionFiltersWidget extends StatefulWidget {
  const TransactionFiltersWidget({
    super.key,
    this.selectedType,
    this.startDate,
    this.endDate,
    required this.onFiltersChanged,
  });

  final TransactionType? selectedType;
  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(TransactionType?, DateTime?, DateTime?) onFiltersChanged;

  @override
  State<TransactionFiltersWidget> createState() => _TransactionFiltersWidgetState();
}

class _TransactionFiltersWidgetState extends State<TransactionFiltersWidget> {
  TransactionType? _selectedType;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Фильтры транзакций',
                style: theme.textTheme.titleLarge,
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Тип транзакции
          Text(
            'Тип транзакции',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildTypeChip(TransactionType.advancePayment, 'Аванс'),
              _buildTypeChip(TransactionType.finalPayment, 'Финальный платеж'),
              _buildTypeChip(TransactionType.fullPayment, 'Полная оплата'),
              _buildTypeChip(TransactionType.refund, 'Возврат'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Период
          Text(
            'Период',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, true),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _startDate != null
                        ? _formatDate(_startDate!)
                        : 'Начальная дата',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('—'),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(context, false),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(
                    _endDate != null
                        ? _formatDate(_endDate!)
                        : 'Конечная дата',
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Быстрые фильтры
          Text(
            'Быстрые фильтры',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildQuickFilterChip('Сегодня', () => _setQuickFilter(0)),
              _buildQuickFilterChip('Неделя', () => _setQuickFilter(7)),
              _buildQuickFilterChip('Месяц', () => _setQuickFilter(30)),
              _buildQuickFilterChip('3 месяца', () => _setQuickFilter(90)),
              _buildQuickFilterChip('Год', () => _setQuickFilter(365)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Кнопки действий
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clearFilters,
                  child: const Text('Очистить'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(TransactionType type, String label) {
    final isSelected = _selectedType == type;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _selectDate(BuildContext context, bool isStartDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now().subtract(const Duration(days: 30)))
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  void _setQuickFilter(int daysBack) {
    final now = DateTime.now();
    setState(() {
      _startDate = now.subtract(Duration(days: daysBack));
      _endDate = now;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _startDate = null;
      _endDate = null;
    });
  }

  void _applyFilters() {
    widget.onFiltersChanged(_selectedType, _startDate, _endDate);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
           '${date.month.toString().padLeft(2, '0')}.'
           '${date.year}';
  }
}
