import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_discount.dart';
import '../services/discount_service.dart';
import 'responsive_layout.dart';
import 'responsive_text.dart';

/// Виджет для отображения скидки в карточке заявки
class DiscountWidget extends ConsumerWidget {
  const DiscountWidget({
    super.key,
    required this.bookingId,
    this.discount,
    this.isSpecialist = false,
    this.onDiscountChanged,
  });
  final String bookingId;
  final BookingDiscount? discount;
  final bool isSpecialist;
  final VoidCallback? onDiscountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (discount == null || !discount!.isOffered) {
      return const SizedBox.shrink();
    }

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDiscountIcon(),
                color: _getDiscountColor(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ResponsiveText(
                  'Предложение скидки',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              _buildStatusChip(),
            ],
          ),

          const SizedBox(height: 12),

          // Информация о скидке
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getDiscountColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _getDiscountColor()),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Старая цена:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ResponsiveText(
                      '${discount!.oldPrice?.toStringAsFixed(0)} ₽',
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Новая цена:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ResponsiveText(
                      '${discount!.newPrice?.toStringAsFixed(0)} ₽',
                      style: TextStyle(
                        color: _getDiscountColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ResponsiveText(
                      'Экономия:',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ResponsiveText(
                      '${discount!.savings?.toStringAsFixed(0)} ₽ (${discount!.discountPercent?.toStringAsFixed(0)}%)',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Причина скидки
          if (discount!.reason != null) ...[
            const SizedBox(height: 8),
            ResponsiveText(
              'Причина: ${discount!.reason}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],

          // Время действия
          if (discount!.expiresAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                ResponsiveText(
                  _getTimeRemaining(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],

          // Кнопки действий
          if (discount!.isActive && !isSpecialist) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptDiscount(context, ref),
                    icon: const Icon(Icons.check),
                    label: const Text('Принять'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectDiscount(context, ref),
                    icon: const Icon(Icons.close),
                    label: const Text('Отклонить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = discount!.status;
    Color chipColor;
    String chipText;

    switch (status) {
      case DiscountStatus.pending:
        chipColor = Colors.orange;
        chipText = 'Ожидает';
        break;
      case DiscountStatus.accepted:
        chipColor = Colors.green;
        chipText = 'Принята';
        break;
      case DiscountStatus.expired:
        chipColor = Colors.grey;
        chipText = 'Истекла';
        break;
      case DiscountStatus.notOffered:
        chipColor = Colors.grey;
        chipText = 'Не предложена';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        chipText,
        style: TextStyle(
          color: chipColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getDiscountIcon() {
    switch (discount!.status) {
      case DiscountStatus.pending:
        return Icons.local_offer;
      case DiscountStatus.accepted:
        return Icons.check_circle;
      case DiscountStatus.expired:
        return Icons.access_time;
      case DiscountStatus.notOffered:
        return Icons.local_offer;
    }
  }

  Color _getDiscountColor() {
    switch (discount!.status) {
      case DiscountStatus.pending:
        return Colors.orange;
      case DiscountStatus.accepted:
        return Colors.green;
      case DiscountStatus.expired:
        return Colors.grey;
      case DiscountStatus.notOffered:
        return Colors.blue;
    }
  }

  String _getTimeRemaining() {
    if (discount!.expiresAt == null) return '';

    final timeUntilExpiry = discount!.timeUntilExpiry;
    if (timeUntilExpiry == null) return '';

    if (timeUntilExpiry == Duration.zero) {
      return 'Скидка истекла';
    }

    final hours = timeUntilExpiry.inHours;
    final minutes = timeUntilExpiry.inMinutes % 60;

    if (hours > 0) {
      return 'Осталось: $hoursч $minutesм';
    } else {
      return 'Осталось: $minutesм';
    }
  }

  Future<void> _acceptDiscount(BuildContext context, WidgetRef ref) async {
    try {
      final service =
          ProviderScope.containerOf(context).read(discountServiceProvider);
      await service.acceptDiscount(
        bookingId: bookingId,
        customerId: 'current_user_id', // TODO: Получить из контекста
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скидка принята')),
      );

      onDiscountChanged?.call();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  void _rejectDiscount(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _RejectDiscountDialog(
        bookingId: bookingId,
        onRejected: () {
          onDiscountChanged?.call();
        },
      ),
    );
  }
}

/// Диалог для отклонения скидки
class _RejectDiscountDialog extends StatefulWidget {
  const _RejectDiscountDialog({
    required this.bookingId,
    required this.onRejected,
  });
  final String bookingId;
  final VoidCallback onRejected;

  @override
  State<_RejectDiscountDialog> createState() => _RejectDiscountDialogState();
}

class _RejectDiscountDialogState extends State<_RejectDiscountDialog> {
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Отклонить скидку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Вы уверены, что хотите отклонить предложение скидки?'),
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
            onPressed: _isLoading ? null : _rejectDiscount,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
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

  Future<void> _rejectDiscount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service =
          ProviderScope.containerOf(context).read(discountServiceProvider);
      await service.rejectDiscount(
        bookingId: widget.bookingId,
        customerId: 'current_user_id', // TODO: Получить из контекста
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скидка отклонена')),
      );

      widget.onRejected();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Виджет для предложения скидки (для специалистов)
class OfferDiscountWidget extends ConsumerWidget {
  const OfferDiscountWidget({
    super.key,
    required this.bookingId,
    required this.currentPrice,
    this.onDiscountOffered,
  });
  final String bookingId;
  final double currentPrice;
  final VoidCallback? onDiscountOffered;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResponsiveCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.blue),
                const SizedBox(width: 8),
                ResponsiveText(
                  'Предложить скидку',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Предложите клиенту скидку для увеличения шансов на бронирование.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _showOfferDiscountDialog(context, ref),
              icon: const Icon(Icons.local_offer),
              label: const Text('Предложить скидку'),
            ),
          ],
        ),
      );

  void _showOfferDiscountDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => _OfferDiscountDialog(
        bookingId: bookingId,
        currentPrice: currentPrice,
        onOffered: () {
          onDiscountOffered?.call();
        },
      ),
    );
  }
}

/// Диалог для предложения скидки
class _OfferDiscountDialog extends StatefulWidget {
  const _OfferDiscountDialog({
    required this.bookingId,
    required this.currentPrice,
    required this.onOffered,
  });
  final String bookingId;
  final double currentPrice;
  final VoidCallback onOffered;

  @override
  State<_OfferDiscountDialog> createState() => _OfferDiscountDialogState();
}

class _OfferDiscountDialogState extends State<_OfferDiscountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _newPriceController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _newPriceController.text = widget.currentPrice.toString();
  }

  @override
  void dispose() {
    _newPriceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newPrice =
        double.tryParse(_newPriceController.text) ?? widget.currentPrice;
    final discountPercent =
        ((widget.currentPrice - newPrice) / widget.currentPrice) * 100;
    final savings = widget.currentPrice - newPrice;

    return AlertDialog(
      title: const Text('Предложить скидку'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _newPriceController,
              decoration: const InputDecoration(
                labelText: 'Новая цена *',
                border: OutlineInputBorder(),
                suffixText: '₽',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите новую цену';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Цена должна быть больше 0';
                }
                if (price >= widget.currentPrice) {
                  return 'Новая цена должна быть меньше текущей';
                }
                return null;
              },
              onChanged: (value) => setState(() {}),
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Причина скидки (необязательно)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Предварительный расчет
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Текущая цена:'),
                      Text('${widget.currentPrice.toStringAsFixed(0)} ₽'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Новая цена:'),
                      Text('${newPrice.toStringAsFixed(0)} ₽'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Скидка:'),
                      Text(
                        '${discountPercent.toStringAsFixed(0)}% (${savings.toStringAsFixed(0)} ₽)',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _offerDiscount,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Предложить'),
        ),
      ],
    );
  }

  Future<void> _offerDiscount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final service =
          ProviderScope.containerOf(context).read(discountServiceProvider);
      await service.offerDiscount(
        bookingId: widget.bookingId,
        oldPrice: widget.currentPrice,
        newPrice: double.parse(_newPriceController.text),
        specialistId: 'current_specialist_id', // TODO: Получить из контекста
        customerId: 'current_customer_id', // TODO: Получить из контекста
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Скидка предложена')),
      );

      widget.onOffered();
    } on Exception catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

/// Провайдер для сервиса скидок
final discountServiceProvider =
    Provider<DiscountService>((ref) => DiscountService());
