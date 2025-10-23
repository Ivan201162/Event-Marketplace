import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/discount_providers.dart';
import '../models/booking_discount.dart';
import '../models/price_history.dart';
import '../services/price_history_service.dart';
import 'responsive_layout.dart';
import 'responsive_text.dart';

/// Виджет для отображения скидки у заказчика
class CustomerDiscountDisplayWidget extends ConsumerWidget {
  const CustomerDiscountDisplayWidget({
    super.key,
    required this.bookingId,
    this.discount,
    this.onDiscountChanged,
  });
  final String bookingId;
  final BookingDiscount? discount;
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
          // Заголовок с иконкой и статусом
          Row(
            children: [
              Icon(_getDiscountIcon(), color: _getDiscountColor(), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                  child: ResponsiveText('Предложение скидки', isTitle: true)),
              _buildStatusChip(),
            ],
          ),

          const SizedBox(height: 16),

          // Основная информация о скидке
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getDiscountColor().withValues(alpha: 0.1),
                  _getDiscountColor().withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getDiscountColor(), width: 2),
            ),
            child: Column(
              children: [
                // Старая и новая цена
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ResponsiveText('Было:', isSubtitle: true),
                        ResponsiveText(
                          '${discount!.oldPrice?.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, color: Colors.grey),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const ResponsiveText('Стало:', isSubtitle: true),
                        ResponsiveText(
                          '${discount!.newPrice?.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            color: _getDiscountColor(),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Экономия
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.savings, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      ResponsiveText(
                        'Экономия: ${discount!.savings?.toStringAsFixed(0)} ₽ (${discount!.discountPercent?.toStringAsFixed(0)}%)',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Причина скидки
          if (discount!.reason != null) ...[
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
                  const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ResponsiveText('Причина: ${discount!.reason}',
                          isSubtitle: true)),
                ],
              ),
            ),
          ],

          // Время действия
          if (discount!.expiresAt != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                      child: ResponsiveText(_getTimeRemaining(),
                          isSubtitle: true)),
                ],
              ),
            ),
          ],

          // Кнопки действий
          if (discount!.isActive) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptDiscount(context, ref),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Принять скидку'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectDiscount(context, ref),
                    icon: const Icon(Icons.close),
                    label: const Text('Отклонить'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // История изменений цен
          const SizedBox(height: 16),
          _buildPriceHistorySection(context, ref),
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
        chipText = 'Ожидает ответа';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor),
      ),
      child: Text(
        chipText,
        style: TextStyle(
            color: chipColor, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriceHistorySection(BuildContext context, WidgetRef ref) =>
      Consumer(
        builder: (context, ref, child) => ref
            .watch(priceHistoryProvider(bookingId))
            .when(
              data: (priceHistory) {
                if (priceHistory.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.history, size: 20),
                        SizedBox(width: 8),
                        ResponsiveText('История изменений цены', isTitle: true),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...priceHistory.take(3).map(_buildPriceHistoryItem),
                    if (priceHistory.length > 3) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            _showFullPriceHistory(context, priceHistory),
                        child: const Text('Показать всю историю'),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
      );

  Widget _buildPriceHistoryItem(PriceHistory history) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              history.isDiscount ? Icons.trending_down : Icons.trending_up,
              color: history.isDiscount ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${history.oldPrice.toStringAsFixed(0)} ₽ → ${history.newPrice.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(history.reason,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Text(
              _formatDate(history.changedAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );

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

  Future<void> _acceptDiscount(BuildContext context, WidgetRef ref) async {
    try {
      final service = ref.read(discountServiceProvider);
      await service.acceptDiscount(
        'discount_id', // TODO(developer): Получить реальный ID скидки
        bookingId: bookingId,
        customerId: 'current_user_id', // TODO(developer): Получить из контекста
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Скидка принята! Цена обновлена.'),
          backgroundColor: Colors.green,
        ),
      );

      onDiscountChanged?.call();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red));
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

  void _showFullPriceHistory(
      BuildContext context, List<PriceHistory> priceHistory) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('История изменений цены'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: priceHistory.length,
            itemBuilder: (context, index) {
              final history = priceHistory[index];
              return _buildPriceHistoryItem(history);
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Закрыть')),
        ],
      ),
    );
  }
}

/// Диалог для отклонения скидки
class _RejectDiscountDialog extends StatefulWidget {
  const _RejectDiscountDialog(
      {required this.bookingId, required this.onRejected});
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

  Future<void> _rejectDiscount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final service = ref.read(discountServiceProvider);
      await service.rejectDiscount(
        bookingId: widget.bookingId,
        customerId: 'current_user_id', // TODO(developer): Получить из контекста
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Скидка отклонена'), backgroundColor: Colors.orange),
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

/// Провайдер для истории цен
final priceHistoryProvider = FutureProvider.family<List<PriceHistory>, String>((
  ref,
  bookingId,
) async {
  final service = ref.read(priceHistoryServiceProvider);
  return service.getBookingPriceHistory(bookingId);
});

/// Провайдер для сервиса истории цен
final priceHistoryServiceProvider =
    Provider<PriceHistoryService>((ref) => PriceHistoryService());

/// Провайдер для сервиса скидок
// TODO: Создать провайдер для DiscountService
// final discountServiceProvider = Provider<DiscountService>((ref) => DiscountService());
