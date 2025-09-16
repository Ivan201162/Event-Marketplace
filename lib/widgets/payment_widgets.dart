import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment.dart';
import '../providers/payment_providers.dart';

/// Виджет для отображения платежа
class PaymentCard extends ConsumerWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final bool showActions;

  const PaymentCard({
    super.key,
    required this.payment,
    this.onTap,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с типом и статусом
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      payment.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(payment.status),
                ],
              ),

              const SizedBox(height: 12),

              // Сумма
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Описание
              if (payment.description != null) ...[
                Text(
                  payment.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Информация о датах
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Создан: ${_formatDate(payment.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              if (payment.completedAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Завершен: ${_formatDate(payment.completedAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],

              // Действия
              if (showActions && payment.isPending) ...[
                const SizedBox(height: 12),
                _buildActionButtons(context, ref),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Построить чип статуса
  Widget _buildStatusChip(PaymentStatus status) {
    Color color;
    IconData icon;

    switch (status) {
      case PaymentStatus.pending:
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case PaymentStatus.processing:
        color = Colors.blue;
        icon = Icons.hourglass_empty;
        break;
      case PaymentStatus.completed:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case PaymentStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        break;
      case PaymentStatus.cancelled:
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      case PaymentStatus.refunded:
        color = Colors.purple;
        icon = Icons.undo;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            _getStatusDisplayName(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Построить кнопки действий
  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPaymentDialog(context, ref),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Оплатить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCancelDialog(context, ref),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Отменить'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  /// Показать диалог оплаты
  void _showPaymentDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => PaymentDialog(payment: payment),
    );
  }

  /// Показать диалог отмены
  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Отмена платежа'),
        content: const Text('Вы уверены, что хотите отменить этот платеж?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref
                    .read(paymentStateProvider.notifier)
                    .cancelPayment(payment.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Платеж отменен')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );
  }

  /// Получить отображаемое название статуса
  String _getStatusDisplayName(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return 'Ожидает';
      case PaymentStatus.processing:
        return 'Обрабатывается';
      case PaymentStatus.completed:
        return 'Завершен';
      case PaymentStatus.failed:
        return 'Неудачный';
      case PaymentStatus.cancelled:
        return 'Отменен';
      case PaymentStatus.refunded:
        return 'Возвращен';
    }
  }

  /// Форматировать дату
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Диалог оплаты
class PaymentDialog extends ConsumerStatefulWidget {
  final Payment payment;

  const PaymentDialog({
    super.key,
    required this.payment,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  String _selectedPaymentMethod = 'card';

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(paymentFormProvider);

    return AlertDialog(
      title: const Text('Оплата'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Сумма к оплате: ${widget.payment.amount.toStringAsFixed(0)} ${widget.payment.currency}'),
          const SizedBox(height: 16),
          const Text('Выберите способ оплаты:'),
          const SizedBox(height: 12),
          _buildPaymentMethodSelector(),
          if (formState.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formState.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: formState.isProcessing ? null : () => _processPayment(),
          child: formState.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Оплатить'),
        ),
      ],
    );
  }

  /// Построить селектор способа оплаты
  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Банковская карта'),
          subtitle: const Text('Visa, MasterCard, МИР'),
          value: 'card',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value!);
          },
        ),
        RadioListTile<String>(
          title: const Text('СБП'),
          subtitle: const Text('Система быстрых платежей'),
          value: 'sbp',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value!);
          },
        ),
        RadioListTile<String>(
          title: const Text('Электронные деньги'),
          subtitle: const Text('ЮMoney, QIWI, WebMoney'),
          value: 'ewallet',
          groupValue: _selectedPaymentMethod,
          onChanged: (value) {
            setState(() => _selectedPaymentMethod = value!);
          },
        ),
      ],
    );
  }

  /// Обработать платеж
  Future<void> _processPayment() async {
    ref.read(paymentFormProvider.notifier).startProcessing();

    try {
      await ref.read(paymentStateProvider.notifier).processPayment(
            widget.payment.id,
            _selectedPaymentMethod,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Платеж обработан')),
        );
      }
    } catch (e) {
      ref.read(paymentFormProvider.notifier).setError(e.toString());
    }
  }
}

/// Виджет статистики платежей
class PaymentStatisticsWidget extends ConsumerWidget {
  final PaymentStatistics statistics;

  const PaymentStatisticsWidget({
    super.key,
    required this.statistics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Статистика платежей',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Всего',
                    '${statistics.totalCount}',
                    '${statistics.totalAmount.toStringAsFixed(0)} ₽',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Завершено',
                    '${statistics.completedCount}',
                    '${statistics.completedAmount.toStringAsFixed(0)} ₽',
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Ожидает',
                    '${statistics.pendingCount}',
                    '${statistics.pendingAmount.toStringAsFixed(0)} ₽',
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Неудачные',
                    '${statistics.failedCount}',
                    '0 ₽',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: statistics.completionRate / 100,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                statistics.completionRate > 80 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Процент завершенных: ${statistics.completionRate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Построить элемент статистики
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String count,
    String amount,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Виджет расчета платежей
class PaymentCalculationWidget extends ConsumerWidget {
  final double totalAmount;
  final OrganizationType organizationType;

  const PaymentCalculationWidget({
    super.key,
    required this.totalAmount,
    required this.organizationType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculation = ref.watch(paymentCalculationProvider(
      PaymentCalculationParams(
        totalAmount: totalAmount,
        organizationType: organizationType,
      ),
    ));

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Расчет платежей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              calculation.paymentSchemeDescription,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            _buildPaymentRow(
              context,
              'Общая сумма',
              '${calculation.totalAmount.toStringAsFixed(0)} ₽',
              Colors.blue,
            ),
            if (calculation.hasAdvance) ...[
              const SizedBox(height: 8),
              _buildPaymentRow(
                context,
                'Аванс (${calculation.advancePercentage.toInt()}%)',
                '${calculation.advanceAmount.toStringAsFixed(0)} ₽',
                Colors.orange,
              ),
            ],
            if (calculation.hasFinalPayment) ...[
              const SizedBox(height: 8),
              _buildPaymentRow(
                context,
                'Финальный платеж',
                '${calculation.finalAmount.toStringAsFixed(0)} ₽',
                Colors.green,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Построить строку платежа
  Widget _buildPaymentRow(
    BuildContext context,
    String label,
    String amount,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
