import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/payment_config.dart';
import '../../services/payment_service.dart';
import '../../widgets/donation/donation_amount_card.dart';

class DonationScreen extends ConsumerStatefulWidget {
  const DonationScreen({
    super.key,
    required this.specialistId,
    required this.specialistName,
    this.specialistAvatar,
  });
  final String specialistId;
  final String specialistName;
  final String? specialistAvatar;

  @override
  ConsumerState<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends ConsumerState<DonationScreen> {
  final PaymentService _paymentService = PaymentService();
  final TextEditingController _customAmountController = TextEditingController();
  bool _isLoading = false;
  double? _selectedAmount;
  String? _donorName;
  String? _donorMessage;

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Поблагодарить'),
          backgroundColor: Colors.pink,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Specialist Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.pink, Colors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: widget.specialistAvatar != null
                          ? NetworkImage(widget.specialistAvatar!)
                          : null,
                      child: widget.specialistAvatar == null
                          ? const Icon(
                              Icons.person,
                              size: 30,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Поблагодарить специалиста',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.specialistName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Donation Amounts
              const Text(
                'Выберите сумму:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Predefined amounts
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: PaymentConfig.donationAmounts
                    .map(
                      (amount) => DonationAmountCard(
                        amount: amount,
                        isSelected: _selectedAmount == amount,
                        onTap: () {
                          setState(() {
                            _selectedAmount = amount;
                            _customAmountController.clear();
                          });
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 16),

              // Custom amount
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Или введите свою сумму:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Сумма в рублях',
                        prefixText: '₽ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final amount = double.tryParse(value);
                        if (amount != null &&
                            amount >= PaymentConfig.minDonationAmount) {
                          setState(() {
                            _selectedAmount = amount;
                          });
                        } else {
                          setState(() {
                            _selectedAmount = null;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Donor Info (Optional)
              const Text(
                'Ваше сообщение (необязательно):',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Напишите слова благодарности...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  _donorMessage = value;
                },
              ),

              const SizedBox(height: 32),

              // Donate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedAmount != null && !_isLoading
                      ? _processDonation
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Поблагодарить ${_selectedAmount?.toInt() ?? 0} ₽',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Донаты помогают специалистам развиваться и создавать качественный контент. '
                        'Спасибо за вашу поддержку!',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Terms
              Text(
                'Минимальная сумма доната: ${PaymentConfig.minDonationAmount.toInt()} ₽. '
                'Оплата производится через защищенный сервис Stripe.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

  Future<void> _processDonation() async {
    if (_selectedAmount == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, we'll use a dummy user ID
      const donorUserId = 'demo_user_123';

      final success = await _paymentService.processDonation(
        userId: donorUserId,
        targetUserId: widget.specialistId,
        amount: _selectedAmount!,
      );

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      _showErrorDialog();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.pink),
            SizedBox(width: 8),
            Text('Спасибо!'),
          ],
        ),
        content: Text(
          'Ваш донат в размере ${_selectedAmount!.toInt()} ₽ '
          'успешно отправлен ${widget.specialistName}! '
          'Специалист получит уведомление о вашей поддержке.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Отлично'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Ошибка'),
          ],
        ),
        content: const Text(
          'Произошла ошибка при обработке доната. '
          'Попробуйте еще раз или обратитесь в поддержку.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}



