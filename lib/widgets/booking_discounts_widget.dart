import 'package:flutter/material.dart';
import '../services/specialist_discount_service.dart';

/// Виджет для отображения скидок в заказе
class BookingDiscountsWidget extends StatefulWidget {
  const BookingDiscountsWidget({
    super.key,
    required this.bookingId,
    this.onDiscountAccepted,
    this.onDiscountRejected,
  });

  final String bookingId;
  final void Function(SpecialistDiscount)? onDiscountAccepted;
  final void Function(SpecialistDiscount)? onDiscountRejected;

  @override
  State<BookingDiscountsWidget> createState() => _BookingDiscountsWidgetState();
}

class _BookingDiscountsWidgetState extends State<BookingDiscountsWidget> {
  final SpecialistDiscountService _service = SpecialistDiscountService();
  List<SpecialistDiscount> _discounts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDiscounts();
  }

  Future<void> _loadDiscounts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final discounts = await _service.getDiscountsForBooking(widget.bookingId);
      setState(() {
        _discounts = discounts;
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptDiscount(SpecialistDiscount discount) async {
    try {
      await _service.acceptDiscount(discount.id);
      setState(() {
        _discounts.removeWhere((d) => d.id == discount.id);
      });
      widget.onDiscountAccepted?.call(discount);
      _showSuccessSnackBar('Скидка принята');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка принятия скидки: $e');
    }
  }

  Future<void> _rejectDiscount(SpecialistDiscount discount) async {
    try {
      await _service.rejectDiscount(discount.id);
      setState(() {
        _discounts.removeWhere((d) => d.id == discount.id);
      });
      widget.onDiscountRejected?.call(discount);
      _showSuccessSnackBar('Скидка отклонена');
    } on Exception catch (e) {
      _showErrorSnackBar('Ошибка отклонения скидки: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const _DiscountLoadingWidget();
    }

    if (_error != null) {
      return _DiscountErrorWidget(
        error: _error!,
        onRetry: _loadDiscounts,
      );
    }

    if (_discounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return _DiscountsList(
      discounts: _discounts,
      onAccept: _acceptDiscount,
      onReject: _rejectDiscount,
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Виджет загрузки
class _DiscountLoadingWidget extends StatelessWidget {
  const _DiscountLoadingWidget();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Загружаем предложения скидок...'),
          ],
        ),
      );
}

/// Виджет ошибки
class _DiscountErrorWidget extends StatelessWidget {
  const _DiscountErrorWidget({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ошибка загрузки скидок',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
}

/// Список скидок
class _DiscountsList extends StatelessWidget {
  const _DiscountsList({
    required this.discounts,
    required this.onAccept,
    required this.onReject,
  });

  final List<SpecialistDiscount> discounts;
  final void Function(SpecialistDiscount) onAccept;
  final void Function(SpecialistDiscount) onReject;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_offer,
                    color: Colors.orange,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Предложения скидок',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ...discounts.map(
              (discount) => _DiscountCard(
                discount: discount,
                onAccept: () => onAccept(discount),
                onReject: () => onReject(discount),
              ),
            ),
          ],
        ),
      );
}

/// Карточка скидки
class _DiscountCard extends StatelessWidget {
  const _DiscountCard({
    required this.discount,
    required this.onAccept,
    required this.onReject,
  });

  final SpecialistDiscount discount;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Скидка: -${discount.discountPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'До: ${_formatDate(discount.expiresAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                if (discount.message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    discount.message!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAccept,
                        icon: const Icon(Icons.check, size: 16),
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
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Отклонить'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Форматирование даты
String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
