import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/payment_models.dart';
import '../services/payment_service.dart';
import '../widgets/payment_history_item.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String userId;
  final bool isSpecialist;

  const PaymentHistoryScreen({
    super.key,
    required this.userId,
    this.isSpecialist = false,
  });

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSpecialist ? 'История платежей' : 'Мои платежи'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Card
          _buildStatisticsCard(),

          // Payment List
          Expanded(
            child: _buildPaymentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final theme = Theme.of(context);

    return FutureBuilder<PaymentStatistics>(
      future: _paymentService.getPaymentStatistics(
        customerId: widget.isSpecialist ? null : widget.userId,
        specialistId: widget.isSpecialist ? widget.userId : null,
        startDate: _startDate,
        endDate: _endDate,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 120,
            margin: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Ошибка загрузки статистики',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          );
        }

        final stats = snapshot.data!;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статистика',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Всего',
                      '${stats.totalPayments}',
                      Icons.payments,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Успешных',
                      '${stats.completedPayments}',
                      Icons.check_circle,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Сумма',
                      '${stats.totalAmount.toStringAsFixed(0)} ₽',
                      Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: theme.colorScheme.onPrimary.withOpacity(0.8),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentList() {
    return StreamBuilder<List<Payment>>(
      stream: widget.isSpecialist
          ? _paymentService.getSpecialistPayments(widget.userId)
          : _paymentService.getCustomerPayments(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ошибка загрузки платежей',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final payments = snapshot.data ?? [];
        final filteredPayments = _filterPayments(payments);

        if (filteredPayments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.payment,
                  size: 64,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет платежей',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Здесь будут отображаться ваши платежи',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredPayments.length,
          itemBuilder: (context, index) {
            final payment = filteredPayments[index];
            return PaymentHistoryItem(
              payment: payment,
              onTap: () => _showPaymentDetails(payment),
            );
          },
        );
      },
    );
  }

  List<Payment> _filterPayments(List<Payment> payments) {
    return payments.where((payment) {
      if (_selectedStatus != null && payment.status != _selectedStatus) {
        return false;
      }
      if (_selectedMethod != null && payment.method != _selectedMethod) {
        return false;
      }
      if (_startDate != null && payment.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && payment.createdAt.isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentFiltersSheet(
        selectedStatus: _selectedStatus,
        selectedMethod: _selectedMethod,
        startDate: _startDate,
        endDate: _endDate,
        onApplyFilters: (status, method, startDate, endDate) {
          setState(() {
            _selectedStatus = status;
            _selectedMethod = method;
            _startDate = startDate;
            _endDate = endDate;
          });
          Navigator.pop(context);
        },
        onClearFilters: () {
          setState(() {
            _selectedStatus = null;
            _selectedMethod = null;
            _startDate = null;
            _endDate = null;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => PaymentDetailsSheet(payment: payment),
    );
  }
}

class PaymentFiltersSheet extends StatefulWidget {
  final PaymentStatus? selectedStatus;
  final PaymentMethod? selectedMethod;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(PaymentStatus?, PaymentMethod?, DateTime?, DateTime?)
      onApplyFilters;
  final VoidCallback onClearFilters;

  const PaymentFiltersSheet({
    super.key,
    required this.selectedStatus,
    required this.selectedMethod,
    required this.startDate,
    required this.endDate,
    required this.onApplyFilters,
    required this.onClearFilters,
  });

  @override
  State<PaymentFiltersSheet> createState() => _PaymentFiltersSheetState();
}

class _PaymentFiltersSheetState extends State<PaymentFiltersSheet> {
  PaymentStatus? _selectedStatus;
  PaymentMethod? _selectedMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedMethod = widget.selectedMethod;
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Фильтры',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Status filter
          Text(
            'Статус',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'Все',
                _selectedStatus == null,
                () => setState(() => _selectedStatus = null),
              ),
              ...PaymentStatus.values.map((status) => _buildFilterChip(
                    _getStatusDisplayName(status),
                    _selectedStatus == status,
                    () => setState(() => _selectedStatus = status),
                  )),
            ],
          ),
          const SizedBox(height: 24),

          // Method filter
          Text(
            'Способ оплаты',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                'Все',
                _selectedMethod == null,
                () => setState(() => _selectedMethod = null),
              ),
              ...PaymentMethod.values.map((method) => _buildFilterChip(
                    _getMethodDisplayName(method),
                    _selectedMethod == method,
                    () => setState(() => _selectedMethod = method),
                  )),
            ],
          ),
          const SizedBox(height: 24),

          // Date range
          Text(
            'Период',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(true),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_startDate != null
                      ? DateFormat('dd.MM.yyyy').format(_startDate!)
                      : 'С даты'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(false),
                  icon: const Icon(Icons.calendar_today),
                  label: Text(_endDate != null
                      ? DateFormat('dd.MM.yyyy').format(_endDate!)
                      : 'По дату'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onClearFilters,
                  child: const Text('Сбросить'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onApplyFilters(
                    _selectedStatus,
                    _selectedMethod,
                    _startDate,
                    _endDate,
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
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

  String _getStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершена';
      case PaymentStatus.failed:
        return 'Неудачная';
      case PaymentStatus.cancelled:
        return 'Отменена';
      case PaymentStatus.refunded:
        return 'Возвращена';
      case PaymentStatus.disputed:
        return 'Спор';
    }
  }

  String _getMethodDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.sbp:
        return 'СБП';
      case PaymentMethod.yookassa:
        return 'ЮKassa';
      case PaymentMethod.tinkoff:
        return 'Tinkoff';
      case PaymentMethod.card:
        return 'Карта';
      case PaymentMethod.cash:
        return 'Наличные';
      case PaymentMethod.bankTransfer:
        return 'Перевод';
    }
  }
}

class PaymentDetailsSheet extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsSheet({
    super.key,
    required this.payment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Детали платежа',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          _buildDetailRow(context, 'ID', payment.id),
          _buildDetailRow(context, 'Тип', payment.typeDisplayName),
          _buildDetailRow(context, 'Способ', payment.methodDisplayName),
          _buildDetailRow(
              context, 'Статус', _getStatusDisplayName(payment.status)),
          _buildDetailRow(
              context, 'Сумма', '${payment.amount.toStringAsFixed(0)} ₽'),
          if (payment.taxAmount > 0)
            _buildDetailRow(
                context, 'Налог', '${payment.taxAmount.toStringAsFixed(0)} ₽'),
          if (payment.netAmount > 0)
            _buildDetailRow(context, 'К получению',
                '${payment.netAmount.toStringAsFixed(0)} ₽'),
          _buildDetailRow(context, 'Создан',
              DateFormat('dd.MM.yyyy HH:mm').format(payment.createdAt)),
          if (payment.completedAt != null)
            _buildDetailRow(context, 'Завершен',
                DateFormat('dd.MM.yyyy HH:mm').format(payment.completedAt!)),
          if (payment.failureReason != null)
            _buildDetailRow(context, 'Причина ошибки', payment.failureReason!),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает оплаты';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершена';
      case PaymentStatus.failed:
        return 'Неудачная';
      case PaymentStatus.cancelled:
        return 'Отменена';
      case PaymentStatus.refunded:
        return 'Возвращена';
      case PaymentStatus.disputed:
        return 'Спор';
    }
  }
}
