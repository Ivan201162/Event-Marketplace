import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

/// Экран истории платежей
class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({
    super.key,
    required this.userId,
    this.isSpecialist = false,
  });

  final String userId;
  final bool isSpecialist;

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;
  PaymentStatus? _selectedStatus;
  PaymentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final payments = widget.isSpecialist
          ? await _paymentService.getSpecialistPayments(
              widget.userId,
              status: _selectedStatus,
              type: _selectedType,
            )
          : await _paymentService.getUserPayments(
              widget.userId,
              status: _selectedStatus,
              type: _selectedType,
            );

      setState(() {
        _payments = payments;
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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isSpecialist ? 'Платежи специалиста' : 'История платежей',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilters,
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPayments,
            ),
          ],
        ),
        body: Column(
          children: [
            if (_selectedStatus != null || _selectedType != null)
              _buildActiveFilters(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      );

  Widget _buildActiveFilters() => Container(
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Row(
          children: [
            const Text('Активные фильтры: '),
            if (_selectedStatus != null)
              Chip(
                label: Text(_selectedStatus!.statusName),
                onDeleted: () {
                  setState(() {
                    _selectedStatus = null;
                  });
                  _loadPayments();
                },
              ),
            if (_selectedType != null)
              Chip(
                label: Text(_selectedType!.typeName),
                onDeleted: () {
                  setState(() {
                    _selectedType = null;
                  });
                  _loadPayments();
                },
              ),
          ],
        ),
      );

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Ошибка: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPayments,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Платежи не найдены'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _payments.length,
      itemBuilder: (context, index) {
        final payment = _payments[index];
        return _PaymentCard(
          payment: payment,
          onTap: () => _showPaymentDetails(payment),
        );
      },
    );
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _FiltersBottomSheet(
        selectedStatus: _selectedStatus,
        selectedType: _selectedType,
        onApply: (status, type) {
          setState(() {
            _selectedStatus = status;
            _selectedType = type;
          });
          _loadPayments();
        },
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog<void>(
      context: context,
      builder: (context) => _PaymentDetailsDialog(payment: payment),
    );
  }
}

/// Карточка платежа
class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.payment,
    required this.onTap,
  });

  final Payment payment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getStatusColor(payment.status),
            child: Text(
              payment.typeIcon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(payment.typeName),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(payment.description),
              const SizedBox(height: 4),
              Text(
                '${payment.formattedAmount} • ${payment.statusName}',
                style: TextStyle(
                  color: _getStatusColor(payment.status),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (payment.dueDate != null)
                Text(
                  'Срок: ${_formatDate(payment.dueDate!)}',
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                payment.formattedAmount,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _formatDate(payment.createdAt),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          onTap: onTap,
        ),
      );

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.processing:
        return Colors.blue;
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.cancelled:
        return Colors.grey;
      case PaymentStatus.refunded:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
}

/// Диалог с деталями платежа
class _PaymentDetailsDialog extends StatelessWidget {
  const _PaymentDetailsDialog({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(payment.typeName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailRow('Сумма', payment.formattedAmount),
              _DetailRow('Статус', payment.statusName),
              _DetailRow('Метод оплаты', payment.methodName),
              _DetailRow('Описание', payment.description),
              if (payment.transactionId != null)
                _DetailRow('ID транзакции', payment.transactionId!),
              if (payment.paymentProvider != null)
                _DetailRow('Провайдер', payment.paymentProvider!),
              if (payment.fee != null)
                _DetailRow(
                  'Комиссия',
                  '${payment.fee!.toStringAsFixed(2)} ${payment.currency}',
                ),
              if (payment.tax != null)
                _DetailRow(
                  'Налог',
                  '${payment.tax!.toStringAsFixed(2)} ${payment.currency}',
                ),
              _DetailRow('Итого', payment.formattedTotalAmount),
              _DetailRow('Создан', _formatDate(payment.createdAt)),
              if (payment.processedAt != null)
                _DetailRow('Обработан', _formatDate(payment.processedAt!)),
              if (payment.completedAt != null)
                _DetailRow('Завершен', _formatDate(payment.completedAt!)),
              if (payment.failedAt != null)
                _DetailRow('Неудачен', _formatDate(payment.failedAt!)),
              if (payment.cancelledAt != null)
                _DetailRow('Отменен', _formatDate(payment.cancelledAt!)),
              if (payment.refundedAt != null)
                _DetailRow('Возвращен', _formatDate(payment.refundedAt!)),
              if (payment.dueDate != null)
                _DetailRow('Срок оплаты', _formatDate(payment.dueDate!)),
              if (payment.refundReason != null)
                _DetailRow('Причина возврата', payment.refundReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      );

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// Строка деталей
class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                '$label:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(value),
            ),
          ],
        ),
      );
}

/// Нижний лист с фильтрами
class _FiltersBottomSheet extends StatefulWidget {
  const _FiltersBottomSheet({
    required this.selectedStatus,
    required this.selectedType,
    required this.onApply,
  });

  final PaymentStatus? selectedStatus;
  final PaymentType? selectedType;
  final Function(PaymentStatus?, PaymentType?) onApply;

  @override
  State<_FiltersBottomSheet> createState() => _FiltersBottomSheetState();
}

class _FiltersBottomSheetState extends State<_FiltersBottomSheet> {
  PaymentStatus? _selectedStatus;
  PaymentType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedType = widget.selectedType;
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Фильтры',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Статус платежа:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = null;
                    });
                  },
                ),
                ...PaymentStatus.values.map(
                  (status) => _FilterChip(
                    label: status.statusName,
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Тип платежа:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _FilterChip(
                  label: 'Все',
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() {
                      _selectedType = null;
                    });
                  },
                ),
                ...PaymentType.values.map(
                  (type) => _FilterChip(
                    label: type.typeName,
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedType = null;
                      });
                    },
                    child: const Text('Сбросить'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedStatus, _selectedType);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

/// Чип фильтра
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Function(bool) onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
      );
}
