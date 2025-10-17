import 'package:flutter/material.dart';
import '../services/specialist_discount_service.dart';

/// Виджет для предложения скидки специалистом
class SpecialistDiscountOfferWidget extends StatefulWidget {
  const SpecialistDiscountOfferWidget({
    super.key,
    required this.specialistId,
    required this.bookingId,
    this.onDiscountOffered,
  });

  final String specialistId;
  final String bookingId;
  final void Function(SpecialistDiscount)? onDiscountOffered;

  @override
  State<SpecialistDiscountOfferWidget> createState() => _SpecialistDiscountOfferWidgetState();
}

class _SpecialistDiscountOfferWidgetState extends State<SpecialistDiscountOfferWidget> {
  final SpecialistDiscountService _service = SpecialistDiscountService();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;
  bool _canOfferDiscount = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkCanOfferDiscount();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _checkCanOfferDiscount() async {
    try {
      final canOffer = await _service.canOfferDiscount(
        widget.specialistId,
        widget.bookingId,
      );
      setState(() {
        _canOfferDiscount = canOffer;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _offerDiscount(double discountPercent) async {
    if (!_canOfferDiscount) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final discountId = await _service.offerDiscount(
        specialistId: widget.specialistId,
        bookingId: widget.bookingId,
        discountPercent: discountPercent,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      final discount = SpecialistDiscount(
        id: discountId,
        specialistId: widget.specialistId,
        bookingId: widget.bookingId,
        discountPercent: discountPercent,
        message: _messageController.text.isNotEmpty ? _messageController.text : null,
        isActive: true,
        isAccepted: false,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
      );

      setState(() {
        _canOfferDiscount = false;
        _isLoading = false;
      });

      _messageController.clear();
      widget.onDiscountOffered?.call(discount);
      _showSuccessSnackBar('Скидка предложена');
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _showErrorSnackBar('Ошибка предложения скидки: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _DiscountErrorWidget(
        error: _error!,
        onRetry: _checkCanOfferDiscount,
      );
    }

    if (!_canOfferDiscount) {
      return const SizedBox.shrink();
    }

    return _DiscountOfferForm(
      isLoading: _isLoading,
      messageController: _messageController,
      onOfferDiscount: _offerDiscount,
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

/// Форма предложения скидки
class _DiscountOfferForm extends StatefulWidget {
  const _DiscountOfferForm({
    required this.isLoading,
    required this.messageController,
    required this.onOfferDiscount,
  });

  final bool isLoading;
  final TextEditingController messageController;
  final void Function(double) onOfferDiscount;

  @override
  State<_DiscountOfferForm> createState() => _DiscountOfferFormState();
}

class _DiscountOfferFormState extends State<_DiscountOfferForm> {
  double _selectedDiscount = 10;
  bool _showForm = false;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_showForm) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_offer,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Предложить скидку заказчику',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => _showForm = true),
                          icon: const Icon(Icons.add),
                          label: const Text('Предложить'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Предложить скидку',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Размер скидки:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: _selectedDiscount,
                                min: 5,
                                max: 50,
                                divisions: 9,
                                label: '${_selectedDiscount.toStringAsFixed(0)}%',
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDiscount = value;
                                  });
                                },
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                '${_selectedDiscount.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: widget.messageController,
                          decoration: const InputDecoration(
                            labelText: 'Сообщение заказчику (необязательно)',
                            border: OutlineInputBorder(),
                            hintText: 'Например: "Специальное предложение для вашего мероприятия"',
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: widget.isLoading
                                    ? null
                                    : () => widget.onOfferDiscount(_selectedDiscount),
                                icon: widget.isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.send),
                                label: Text(
                                  widget.isLoading ? 'Отправка...' : 'Предложить скидку',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed:
                                  widget.isLoading ? null : () => setState(() => _showForm = false),
                              child: const Text('Отмена'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
              'Ошибка проверки возможности предложения скидки',
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
